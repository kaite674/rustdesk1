import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/models/input_model.dart';
import 'package:flutter_hbb/models/model.dart';

/// TV 遥控器控制器
/// 支持 Android TV 和 Android 盒子的遥控器输入
class TvRemoteController {
  final FFI ffi;
  
  // 移动速度（像素/秒）
  double _speed = 300.0;
  double get speed => _speed;
  
  // 是否启用快速移动模式
  bool _isFastMode = false;
  bool get isFastMode => _isFastMode;
  
  // 快速模式速度倍率
  static const double _fastModeMultiplier = 2.5;
  
  // 移动步进（像素）
  static const double _moveStep = 10.0;
  
  // 按键重复延迟（毫秒）
  static const int _initialDelay = 300;
  static const int _repeatDelay = 50;
  
  // 状态
  Timer? _moveTimer;
  String? _currentDirection;
  DateTime? _lastKeyTime;
  
  TvRemoteController({required this.ffi});
  
  /// 清理资源
  void dispose() {
    _moveTimer?.cancel();
    _moveTimer = null;
    _currentDirection = null;
    _lastKeyTime = null;
  }
  
  /// 设置移动速度
  void setSpeed(double speed) {
    _speed = speed.clamp(100.0, 1000.0);
  }
  
  /// 切换快速移动模式
  void toggleFastMode() {
    _isFastMode = !_isFastMode;
  }
  
  /// 获取实际移动速度
  double get _effectiveSpeed => _isFastMode ? _speed * _fastModeMultiplier : _speed;
  
  /// 开始移动
  void _startMove(String direction) {
    if (_currentDirection == direction) return;
    
    _stopMove();
    _currentDirection = direction;
    _lastKeyTime = DateTime.now();
    
    // 立即执行一次移动
    _executeMove(direction);
    
    // 设置定时器进行连续移动
    _moveTimer = Timer(Duration(milliseconds: _initialDelay), () {
      _moveTimer = Timer.periodic(Duration(milliseconds: _repeatDelay), (_) {
        _executeMove(direction);
      });
    });
  }
  
  /// 停止移动
  void _stopMove() {
    _moveTimer?.cancel();
    _moveTimer = null;
    if (_currentDirection != null) {
      _lastKeyTime = null;
    }
    _currentDirection = null;
  }
  
  /// 执行一次移动
  void _executeMove(String direction) {
    if (ffi.sessionId.isEmpty) return;
    
    final effectiveStep = _moveStep * (_effectiveSpeed / 300.0);
    final inputModel = ffi.inputModel;
    
    switch (direction) {
      case 'up':
        inputModel.touchMove(0, -effectiveStep);
        break;
      case 'down':
        inputModel.touchMove(0, effectiveStep);
        break;
      case 'left':
        inputModel.touchMove(-effectiveStep, 0);
        break;
      case 'right':
        inputModel.touchMove(effectiveStep, 0);
        break;
    }
  }
  
  /// 处理左键点击
  void _handleLeftClick() {
    if (ffi.sessionId.isEmpty) return;
    final inputModel = ffi.inputModel;
    inputModel.tap(MouseButtons.left);
  }
  
  /// 处理右键点击
  void _handleRightClick() {
    if (ffi.sessionId.isEmpty) return;
    final inputModel = ffi.inputModel;
    inputModel.tap(MouseButtons.right);
  }
  
  /// 处理按键按下事件（用于 KeyEvent）
  bool handleKeyDown(KeyEvent event) {
    // 方向键映射
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      switch (event.logicalKey) {
        // 方向键
        case LogicalKeyboardKey.arrowUp:
          _startMove('up');
          return true;
        case LogicalKeyboardKey.arrowDown:
          _startMove('down');
          return true;
        case LogicalKeyboardKey.arrowLeft:
          _startMove('left');
          return true;
        case LogicalKeyboardKey.arrowRight:
          _startMove('right');
          return true;
        
        // 确认键 - 左键点击
        case LogicalKeyboardKey.enter:
          _handleLeftClick();
          return true;
        
        // 返回键 - 右键点击
        case LogicalKeyboardKey.escape:
        case LogicalKeyboardKey.backspace:
          _handleRightClick();
          return true;
        
        // 空格键也可以作为确认
        case LogicalKeyboardKey.space:
          _handleLeftClick();
          return true;
      }
    }
    
    // 处理按键释放
    if (event is KeyUpEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
        case LogicalKeyboardKey.arrowDown:
        case LogicalKeyboardKey.arrowLeft:
        case LogicalKeyboardKey.arrowRight:
          _stopMove();
          return true;
      }
    }
    
    return false;
  }
  
  /// 处理 RawKeyEvent（用于 RawKeyboard）
  bool handleRawKeyEvent(RawKeyEvent event) {
    // 对于 TV 遥控器，我们主要使用 KeyEvent
    // RawKeyEvent 主要用于物理键盘
    return false;
  }
}
