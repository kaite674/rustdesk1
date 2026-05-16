# RustDesk TV 遥控器支持

本文件说明如何为 RustDesk 添加电视遥控器支持和打包为 Android TV APK。

## 功能特性

### 电视遥控器支持
- **方向键控制**: 使用电视遥控器的方向键（↑ ↓ ← →）控制鼠标移动
- **OK/Enter 键**: 作为鼠标左键点击
- **Back/Escape 键**: 作为鼠标右键点击
- **快速移动**: 使用 Channel Up/Down 或 Volume Up/Down 切换快速移动模式（2.5倍速度）
- **自动重复**: 长按方向键会自动连续移动鼠标

### Android TV 支持
- TV Launcher 支持（LEANBACK_LAUNCHER）
- TV Banner 图标
- 优化的触摸输入支持（非必需）
- 游戏手柄支持

## 关键文件修改

### 1. Android 配置 (`flutter/android/app/src/main/AndroidManifest.xml`)
- 添加 TV 特性声明
- 添加 TV Launcher intent-filter
- 添加 TV banner 引用

### 2. TV 遥控器控制器 (`flutter/lib/models/tv_remote_controller.dart`)
- 实现方向键到鼠标移动的映射
- 处理按键重复和速度控制
- 支持快速移动模式

### 3. RemotePage 集成 (`flutter/lib/mobile/pages/remote_page.dart`)
- 将 TV 遥控器控制器集成到远程控制页面
- 添加自定义的 `_TvRemoteKeyFocusScope` 组件
- 在初始化和清理时管理 TV 遥控器控制器

### 4. TV 资源
- TV Banner (`flutter/android/app/src/main/res/drawable/tv_banner.xml`)
- TV 主题 (`flutter/android/app/src/main/res/values/styles_tv.xml`)

## 打包 APK

### 前置要求
- Flutter SDK 3.1.0+
- Android SDK 22+
- Rust 工具链（用于 RustDesk 核心）

### 构建步骤

1. **进入 Flutter 目录**
   ```bash
   cd flutter
   ```

2. **获取依赖**
   ```bash
   flutter pub get
   ```

3. **构建 APK**
   ```bash
   # 构建 Debug APK
   flutter build apk --debug
   
   # 构建 Release APK
   flutter build apk --release
   
   # 构建 App Bundle (推荐用于 Google Play)
   flutter build appbundle --release
   ```

4. **APK 位置**
   ```
   flutter/build/app/outputs/flutter-apk/app-release.apk
   ```

### TV 专用构建

虽然本修改已支持 TV，但可以通过以下方式优化 TV 体验：

1. **在 `android/app/build.gradle` 中添加 TV 产品风味**（可选）
   ```groovy
   flavorDimensions "default"
   
   productFlavors {
       mobile {
           dimension "default"
       }
       tv {
           dimension "default"
           minSdkVersion 21
       }
   }
   ```

2. **构建 TV 专用 APK**
   ```bash
   flutter build apk --flavor tv --release
   ```

## 使用说明

### 遥控器按键映射

| 遥控器按键 | 功能 |
|------------|------|
| ↑ ↓ ← → | 移动鼠标 |
| OK/Enter | 左键点击 |
| Back/Escape | 右键点击 |
| Channel Up | 启用快速移动 |
| Channel Down | 禁用快速移动 |
| Volume Up | 启用快速移动 |
| Volume Down | 禁用快速移动 |

### 鼠标移动速度
- **正常速度**: 400 像素/秒
- **快速移动**: 1000 像素/秒（2.5倍）

## 技术细节

### TV 遥控器控制器工作原理

1. **按键捕获**: 通过 `Focus` widget 的 `onKey` 和 `onKeyEvent` 捕获遥控器按键
2. **方向处理**: 维护当前移动方向向量
3. **定时器控制**: 使用 `Timer` 实现平滑的连续移动
4. **相对移动**: 通过 `sessionSendMouse` 发送 `move_relative` 类型的鼠标事件

### 焦点管理

- 确保 RemotePage 中的 `_physicalFocusNode` 始终保持焦点
- 使用自定义的 `_TvRemoteKeyFocusScope` 优先处理 TV 遥控器按键
- 如果不是 TV 遥控器按键，则回退到原有的 `InputModel` 处理

## 注意事项

1. **焦点问题**: 确保在进入远程控制页面时 `_physicalFocusNode` 请求焦点
2. **性能**: TV 设备性能可能较低，避免过于复杂的动画
3. **输入模式**: 某些 TV 可能需要用户在系统设置中启用"外部输入"
4. **测试**: 建议在真实 Android TV 设备或 Android TV 模拟器上测试

## 未来改进

- [ ] 添加 TV 专用的 UI 布局（更大的按钮、文字）
- [ ] 支持更多的遥控器按键（如播放/暂停、快进/快退）
- [ ] 添加语音输入支持
- [ ] 优化 TV 上的网络连接体验
- [ ] 添加 TV 专用的设置页面
