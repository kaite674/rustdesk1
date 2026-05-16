#!/bin/bash
# RustDesk TV 遥控器版 APK 打包指南脚本
# 此脚本说明如何准备环境并打包带有 TV 遥控器支持的 RustDesk APK

set -e

echo "=========================================="
echo "RustDesk TV 遥控器支持 - APK 打包指南"
echo "=========================================="
echo ""

# 检查是否在正确的目录
if [ ! -d "flutter" ] || [ ! -f "Cargo.toml" ]; then
    echo "错误: 请在 RustDesk 项目根目录运行此脚本"
    exit 1
fi

echo "当前目录: $(pwd)"
echo ""

# 打印已完成的修改
echo "✅ 已完成的 TV 遥控器支持修改："
echo "  1. AndroidManifest.xml - TV 特性和 Launcher"
echo "  2. tv_remote_controller.dart - 遥控器控制逻辑"
echo "  3. remote_page.dart - 集成到远程控制页面"
echo "  4. tv_banner.xml - TV 横幅图标"
echo "  5. styles_tv.xml - TV 主题"
echo "  6. TV_REMOTE_SUPPORT.md - 详细文档"
echo ""

# 显示构建要求
echo "=========================================="
echo "构建要求"
echo "=========================================="
echo "1. Flutter SDK 3.24.5"
echo "2. Rust 1.75+"
echo "3. Android SDK (API 22+)"
echo "4. Android NDK r28c"
echo "5. vcpkg (用于依赖)"
echo ""

# 显示构建步骤
echo "=========================================="
echo "构建步骤"
echo "=========================================="
echo ""
echo "步骤 1: 设置环境变量"
echo "  export ANDROID_HOME=/path/to/android-sdk"
echo "  export ANDROID_NDK_HOME=/path/to/android-ndk"
echo "  export VCPKG_ROOT=/path/to/vcpkg"
echo ""
echo "步骤 2: 安装 Flutter 依赖"
echo "  cd flutter"
echo "  flutter pub get"
echo ""
echo "步骤 3: 构建 Rust 部分（参考 GitHub Actions）"
echo "  # 需要先构建 Rust 库并复制到 android/app/src/main/jniLibs/"
echo "  # 详细请参考 .github/workflows/flutter-build.yml"
echo ""
echo "步骤 4: 构建 APK"
echo "  cd flutter"
echo "  # Debug APK"
echo "  flutter build apk --debug"
echo ""
echo "  # Release APK"
echo "  flutter build apk --release"
echo ""
echo "  # App Bundle (Google Play)"
echo "  flutter build appbundle --release"
echo ""
echo "步骤 5: 查找输出"
echo "  APK 位置: flutter/build/app/outputs/flutter-apk/"
echo "  AAB 位置: flutter/build/app/outputs/bundle/"
echo ""

# 显示遥控器按键映射
echo "=========================================="
echo "遥控器按键映射"
echo "=========================================="
echo "↑ ↓ ← →  : 移动鼠标"
echo "OK/Enter : 左键点击"
echo "Back/Esc : 右键点击"
echo "Channel Up: 快速移动 (2.5x)"
echo "Channel Down: 正常速度"
echo ""

# 验证修改
echo "=========================================="
echo "验证当前修改"
echo "=========================================="
if git diff --name-only --cached >/dev/null 2>&1; then
    echo "Git 暂存区中的修改："
    git diff --name-only --cached
else
    echo "未找到 Git 暂存修改"
fi

echo ""
echo "=========================================="
echo "完成！"
echo "=========================================="
echo "请确保有完整的构建环境后再执行实际打包。"
echo "参考 .github/workflows/flutter-build.yml 了解完整构建流程。"
