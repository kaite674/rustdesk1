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
  Future<void> _executeMove(String direction) async {
    if (ffi.sessionId == null) return;
    
    final effectiveStep = _moveStep * (_effectiveSpeed / 300.0);
    final inputModel = ffi.inputModel;
    
    switch (direction) {
      case 'up':
        await inputModel.moveMouse(0, -effectiveStep);
        break;
      case 'down':
        await inputModel.moveMouse(0, effectiveStep);
        break;
      case 'left':
        await inputModel.moveMouse(-effectiveStep, 0);
        break;
      case 'right':
        await inputModel.moveMouse(effectiveStep, 0);
        break;
    }
  }
  
  /// 处理左键点击
  Future<void> _handleLeftClick() async {
    if (ffi.sessionId == null) return;
    final inputModel = ffi.inputModel;
    await inputModel.tap(MouseButtons.left);
  }
  
  /// 处理右键点击
  Future<void> _handleRightClick() async {
    if (ffi.sessionId == null) return;
    final inputModel = ffi.inputModel;
    await inputModel.tap(MouseButtons.right);
  }
  
  /// 处理遥控器按键
  /// 返回 true 如果按键被处理，返回 false 如果需要传递给默认处理
  Future<bool> handleKey(RawKeyEvent event) async {
    // 只处理按下事件，忽略释放
    if (event is! RawKeyDownEvent) return false;
    
    final key = event.logicalKey;
    
    // 方向键处理
    if (key == LogicalKeyboardKey.arrowUp) {
      _startMove('up');
      return true;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _startMove('down');
      return true;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _startMove('left');
      return true;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _startMove('right');
      return true;
    }
    
    // 停止移动
    if (_currentDirection != null && 
        (key == LogicalKeyboardKey.enter || 
         key == LogicalKeyboardKey.select ||
         key == LogicalKeyboardKey.escape ||
         key == LogicalKeyboardKey.back)) {
      _stopMove();
    }
    
    // Enter/Select - 左键点击
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.select) {
      await _handleLeftClick();
      return true;
    }
    
    // Back/Escape - 右键点击
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.back) {
      await _handleRightClick();
      return true;
    }
    
    // 快速移动模式切换（使用加号和减号键）
    if (key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.equal || 
        key == LogicalKeyboardKey.numpadAdd) {
      toggleFastMode();
      return true;
    }
    if (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract) {
      toggleFastMode();
      return true;
    }
    
    return false;
  }
  
  /// 处理按键释放
  void handleKeyRelease(RawKeyEvent event) {
    if (event is! RawKeyUpEvent) return;
    
    final key = event.logicalKey;
    
    // 方向键释放时停止移动
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      _stopMove();
    }
  }
}
