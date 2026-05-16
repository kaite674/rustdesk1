import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common.dart';
import '../models/model.dart';

/// TV 遥控器支持类
/// 用于处理电视遥控器的方向键控制鼠标移动
class TvRemoteController {
  /// 鼠标移动速度（像素/秒）
  static const double _defaultMouseSpeed = 400.0;
  
  /// 快速移动倍增系数
  static const double _fastSpeedMultiplier = 2.5;
  
  /// 重复按键前的延迟（毫秒）
  static const int _initialRepeatDelay = 500;
  
  /// 重复按键间隔（毫秒）
  static const int _repeatInterval = 30;

  /// 移动定时器
  Timer? _moveTimer;
  
  /// 当前移动方向
  Offset _moveDirection = Offset.zero;
  
  /// 移动速度
  double _moveSpeed = _defaultMouseSpeed;
  
  /// 当前是否正在快速移动
  bool _isFastMove = false;
  
  /// 最后按下的键
  LogicalKeyboardKey? _lastPressedKey;
  
  /// 重复开始时间
  DateTime? _repeatStartTime;

  /// FFI 引用
  final FFI ffi;

  TvRemoteController({required this.ffi});

  /// 处理 TV 遥控器按键事件
  /// 返回 true 表示已处理该事件
  bool handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      return _handleKeyDown(event.logicalKey, event is KeyRepeatEvent);
    } else if (event is KeyUpEvent) {
      return _handleKeyUp(event.logicalKey);
    }
    return false;
  }

  /// 处理 RawKeyEvent（用于旧版本兼容性）
  bool handleRawKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      return _handleKeyDown(event.logicalKey, event.repeat);
    } else if (event is RawKeyUpEvent) {
      return _handleKeyUp(event.logicalKey);
    }
    return false;
  }

  /// 处理按键按下
  bool _handleKeyDown(LogicalKeyboardKey key, bool isRepeat) {
    // 方向键处理
    if (_isDirectionKey(key)) {
      if (!isRepeat) {
        _lastPressedKey = key;
        _repeatStartTime = DateTime.now();
      }
      
      // 更新移动方向
      _updateMoveDirection(key, true);
      
      // 如果是第一次按下，立即移动一次
      if (!isRepeat) {
        _moveMouseOnce();
      }
      
      // 启动定时器（如果尚未启动）
      _startMoveTimer();
      
      return true;
    }
    
    // OK/Enter 键作为左键点击
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (!isRepeat) {
        _handleOkKeyDown();
      }
      return true;
    }
    
    // Back 键作为右键点击
    if (key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.escape) {
      if (!isRepeat) {
        _handleBackKeyDown();
      }
      return true;
    }
    
    // 快速移动切换键（Channel Up/Down 或 Volume Up/Down）
    if (key == LogicalKeyboardKey.channelUp ||
        key == LogicalKeyboardKey.volumeUp) {
      if (!isRepeat) {
        _toggleFastMove(true);
      }
      return true;
    }
    if (key == LogicalKeyboardKey.channelDown ||
        key == LogicalKeyboardKey.volumeDown) {
      if (!isRepeat) {
        _toggleFastMove(false);
      }
      return true;
    }
    
    return false;
  }

  /// 处理按键释放
  bool _handleKeyUp(LogicalKeyboardKey key) {
    // 方向键释放
    if (_isDirectionKey(key)) {
      _updateMoveDirection(key, false);
      
      // 如果没有方向键被按下了，停止定时器
      if (_moveDirection == Offset.zero) {
        _stopMoveTimer();
        _lastPressedKey = null;
        _repeatStartTime = null;
      }
      
      return true;
    }
    
    // OK/Enter 键释放
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _handleOkKeyUp();
      return true;
    }
    
    // Back 键释放
    if (key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.escape) {
      _handleBackKeyUp();
      return true;
    }
    
    // 快速移动切换键释放
    if (key == LogicalKeyboardKey.channelUp ||
        key == LogicalKeyboardKey.volumeUp ||
        key == LogicalKeyboardKey.channelDown ||
        key == LogicalKeyboardKey.volumeDown) {
      // 保持当前快速状态，除非用户显式切换
      return true;
    }
    
    return false;
  }

  /// 检查是否为方向键
  bool _isDirectionKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.dPadUp ||
        key == LogicalKeyboardKey.dPadDown ||
        key == LogicalKeyboardKey.dPadLeft ||
        key == LogicalKeyboardKey.dPadRight;
  }

  /// 更新移动方向
  void _updateMoveDirection(LogicalKeyboardKey key, bool isPressed) {
    double dx = _moveDirection.dx;
    double dy = _moveDirection.dy;

    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.dPadUp) {
      dy = isPressed ? -1.0 : (dy < 0 ? 0.0 : dy);
    } else if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.dPadDown) {
      dy = isPressed ? 1.0 : (dy > 0 ? 0.0 : dy);
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.dPadLeft) {
      dx = isPressed ? -1.0 : (dx < 0 ? 0.0 : dx);
    } else if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.dPadRight) {
      dx = isPressed ? 1.0 : (dx > 0 ? 0.0 : dx);
    }

    _moveDirection = Offset(dx, dy);
  }

  /// 启动移动定时器
  void _startMoveTimer() {
    if (_moveTimer != null) return;
    
    // 计算延迟
    final now = DateTime.now();
    int delay = _initialRepeatDelay;
    if (_repeatStartTime != null) {
      final elapsed = now.difference(_repeatStartTime!).inMilliseconds;
      if (elapsed >= _initialRepeatDelay) {
        delay = _repeatInterval;
      } else {
        delay = _initialRepeatDelay - elapsed;
      }
    }
    
    _moveTimer = Timer(Duration(milliseconds: delay), _onMoveTimerTick);
  }

  /// 停止移动定时器
  void _stopMoveTimer() {
    _moveTimer?.cancel();
    _moveTimer = null;
  }

  /// 定时器回调
  void _onMoveTimerTick() {
    _moveMouseOnce();
    
    // 如果需要继续移动，重新设置定时器
    if (_moveDirection != Offset.zero) {
      _moveTimer = Timer(const Duration(milliseconds: _repeatInterval), _onMoveTimerTick);
    }
  }

  /// 移动鼠标一次
  void _moveMouseOnce() {
    if (_moveDirection == Offset.zero) return;
    
    final speed = _isFastMove ? _moveSpeed * _fastSpeedMultiplier : _moveSpeed;
    final delta = _repeatInterval / 1000.0 * speed;
    
    // 归一化方向向量
    final normalized = _moveDirection.distance > 0 
        ? _moveDirection / _moveDirection.distance 
        : _moveDirection;
    
    final dx = (normalized.dx * delta).round();
    final dy = (normalized.dy * delta).round();
    
    if (dx != 0 || dy != 0) {
      // 使用 InputModel 的公开方法发送相对移动
      _sendRelativeMouseMove(dx, dy);
    }
  }

  /// 发送相对鼠标移动
  void _sendRelativeMouseMove(int dx, int dy) {
    if (!ffi.inputModel.keyboardPerm) return;
    if (ffi.inputModel.isViewCamera) return;
    
    // 直接使用 bind.sessionSendMouse 发送
    bind.sessionSendMouse(
      sessionId: ffi.sessionId,
      msg: json.encode(ffi.inputModel.modify({
        'type': 'move_relative',
        'x': '$dx',
        'y': '$dy',
      })),
    );
  }

  /// 处理 OK 键按下
  void _handleOkKeyDown() {
    ffi.inputModel.tapDown(MouseButtons.left);
  }

  /// 处理 OK 键释放
  void _handleOkKeyUp() {
    ffi.inputModel.tapUp(MouseButtons.left);
  }

  /// 处理 Back 键按下
  void _handleBackKeyDown() {
    ffi.inputModel.tapDown(MouseButtons.right);
  }

  /// 处理 Back 键释放
  void _handleBackKeyUp() {
    ffi.inputModel.tapUp(MouseButtons.right);
  }

  /// 切换快速移动模式
  void _toggleFastMove(bool enable) {
    _isFastMove = enable;
    // 可以在这里添加 UI 提示
  }

  /// 设置移动速度
  void setSpeed(double speed) {
    _moveSpeed = speed.clamp(100.0, 1000.0);
  }

  /// 清理资源
  void dispose() {
    _stopMoveTimer();
  }
}
