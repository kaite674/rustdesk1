# RustDesk TV 遥控器支持 - 替代打包方案

由于当前环境缺少完整的构建工具链，以下是几种替代打包方案：

## 方案 1: 使用 GitHub Actions CI 构建（推荐）

这是最简单的方法，利用项目已有的 CI/CD 流程。

### 步骤:

1. **Fork 项目到你的 GitHub**
   ```bash
   # 在 GitHub 上 fork rustdesk/rustdesk
   ```

2. **应用 TV 遥控器修改**
   - 将我们的修改提交到你的 fork
   - 或者使用 patch 文件

3. **启用 GitHub Actions**
   - 进入你的 fork 的 Settings -> Actions
   - 确保 Actions 已启用

4. **触发构建**
   - 推送修改到你的 fork
   - 或者在 Actions 页面手动触发 workflow
   - 使用 `flutter-nightly.yml` 或 `flutter-build.yml`

5. **下载 Artifacts**
   - 构建完成后，在 Actions 运行页面下载 APK

## 方案 2: 使用预构建的 nightly + 本地修改

如果你只需要测试 TV 遥控器功能，可以：

1. **下载 nightly 构建**
   ```
   访问 https://github.com/rustdesk/rustdesk/releases/tag/nightly
   下载最新的 Android APK
   ```

2. **修改现有 APK（仅用于测试）**
   - 使用 apktool 反编译 APK
   - 修改 AndroidManifest.xml 添加 TV 支持
   - 重新签名打包

   注意：这不会添加遥控器功能的代码，仅用于测试 TV Launcher。

## 方案 3: 在本地配置完整构建环境

如果你有时间和资源，可以配置完整环境：

### 环境要求:
- Ubuntu 24.04（推荐）
- Flutter 3.24.5
- Rust 1.75+
- Android SDK (API 33)
- Android NDK r28c
- vcpkg
- 大量磁盘空间（20GB+）

### 大致步骤:

1. **安装系统依赖**
   ```bash
   sudo apt-get update
   sudo apt-get install -y clang cmake curl gcc-multilib git g++ g++-multilib \
       libasound2-dev libc6-dev libclang-dev libunwind-dev \
       libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
       libgtk-3-dev libpam0g-dev libpulse-dev libva-dev \
       libxcb-randr0-dev libxcb-shape0-dev libxcb-xfixes0-dev \
       libxdo-dev libxfixes-dev llvm-dev nasm yasm ninja-build
   ```

2. **安装 Flutter**
   ```bash
   # 下载 Flutter 3.24.5
   wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
   tar xf flutter_linux_3.24.5-stable.tar.xz
   export PATH="$PATH:`pwd`/flutter/bin"
   ```

3. **安装 Rust**
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh
   chmod +x rustup.sh
   ./rustup.sh -y
   source $HOME/.cargo/env
   rustup install 1.75
   rustup default 1.75
   ```

4. **配置 Android SDK/NDK**
   ```bash
   # 安装 Android Studio 或使用命令行工具
   # 设置环境变量:
   export ANDROID_HOME=/path/to/android-sdk
   export ANDROID_NDK_HOME=/path/to/android-ndk-r28c
   ```

5. **安装 vcpkg**
   ```bash
   git clone --branch 2023.04.15 --depth=1 https://github.com/microsoft/vcpkg
   cd vcpkg
   ./bootstrap-vcpkg.sh -disableMetrics
   export VCPKG_ROOT=`pwd`
   $VCPKG_ROOT/vcpkg install libvpx libyuv opus aom
   ```

6. **构建**
   ```bash
   cd /path/to/rustdesk
   cd flutter
   flutter pub get
   # 然后按照 CI 流程构建 Rust 部分和 APK
   ```

## 方案 4: 使用 Docker（如果有可用的 Android 构建镜像）

你可以尝试查找或创建一个包含所有依赖的 Docker 镜像。

## 当前修改总结

我们已经完成的代码修改：

1. ✅ `flutter/lib/models/tv_remote_controller.dart` - TV 遥控器控制器
2. ✅ `flutter/lib/mobile/pages/remote_page.dart` - 集成到 RemotePage
3. ✅ `flutter/android/app/src/main/AndroidManifest.xml` - TV 配置
4. ✅ `flutter/android/app/src/main/res/drawable/tv_banner.xml` - TV Banner
5. ✅ `flutter/android/app/src/main/res/values/styles_tv.xml` - TV 主题
6. ✅ `TV_REMOTE_SUPPORT.md` - 完整文档
7. ✅ `package_tv_apk.sh` - 打包指南

## 快速测试 TV 遥控器代码

如果你只是想验证 Dart 代码是否有语法错误，可以：

```bash
cd flutter
flutter pub get
flutter analyze
```

这会检查代码是否有错误，但不会构建 APK。

## 推荐下一步

1. **最简单**: Fork 项目到 GitHub，使用 GitHub Actions CI 构建
2. **最灵活**: 配置本地完整环境进行开发和调试
3. **仅测试**: 下载 nightly APK 手动修改 AndroidManifest.xml 测试 TV Launcher

选择方案 1（GitHub Actions）通常是最省时省力的方法！
