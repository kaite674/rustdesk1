# GitHub Actions CI 构建指南 - TV 遥控器版本

本指南说明如何使用 GitHub Actions CI 构建带有 TV 遥控器支持的 RustDesk APK。

## 前置条件

1. 一个 GitHub 账户
2. 对 Git 和 GitHub 的基本了解
3. 大概 30-60 分钟的构建时间

## 步骤 1: Fork 项目

1. 访问 https://github.com/rustdesk/rustdesk
2. 点击右上角的 "Fork" 按钮
3. 选择你的个人账户作为目标
4. 等待 Fork 完成（通常几秒钟）

## 步骤 2: 克隆你的 Fork

```bash
# 克隆你的 fork（替换 YOUR_USERNAME）
git clone https://github.com/YOUR_USERNAME/rustdesk.git
cd rustdesk
```

## 步骤 3: 应用 TV 遥控器修改

### 方法 A: 使用 Patch 文件（推荐）

如果我们已经创建了 patch 文件：

```bash
# 从原始项目位置复制 patch 文件
# 或者使用我们在会话中创建的修改

# 1. 复制我们修改的文件到你的 fork
# 这些文件包括：
# - flutter/lib/models/tv_remote_controller.dart
# - flutter/lib/mobile/pages/remote_page.dart
# - flutter/android/app/src/main/AndroidManifest.xml
# - flutter/android/app/src/main/res/drawable/tv_banner.xml
# - flutter/android/app/src/main/res/values/styles_tv.xml

# 2. 添加并提交修改
git add .
git commit -m "feat: add TV remote control support"
```

### 方法 B: 手动修改文件

如果你想手动应用修改：

1. 复制我们在会话中创建/修改的所有文件到你的 fork
2. 确保所有文件都正确放置
3. 运行 `git status` 检查修改
4. 提交修改

## 步骤 4: 推送到 GitHub

```bash
# 推送到你的 fork
git push origin master

# 或者推送到一个新分支（推荐）
git checkout -b tv-remote-support
git push origin tv-remote-support
```

## 步骤 5: 启用 GitHub Actions

1. 访问你的 fork 在 GitHub 上的页面
2. 点击 "Settings" 标签
3. 在左侧菜单中点击 "Actions" -> "General"
4. 确保 "Actions permissions" 设置为 "Allow all actions and reusable workflows"
5. 保存设置

## 步骤 6: 触发构建

### 方法 A: 推送触发（自动）

当你推送代码到 GitHub 时，某些 workflows 可能会自动触发。

### 方法 B: 手动触发 Workflow

1. 访问你的 fork 的 "Actions" 标签
2. 在左侧选择一个 workflow：
   - `flutter-nightly.yml` - 用于 nightly 构建
   - `flutter-build.yml` - 用于正式构建
3. 点击 "Run workflow" 按钮
4. 选择分支（如果你使用了 tv-remote-support 分支）
5. 点击绿色的 "Run workflow" 按钮

### 推荐使用的 Workflow

对于 Android APK 构建，使用：
- **`flutter-nightly.yml`** - 更快，配置更简单
- **`flutter-build.yml`** - 更完整的构建，但可能需要更多配置

## 步骤 7: 监控构建

1. 在 Actions 页面查看正在运行的 workflow
2. 点击进入具体的构建运行
3. 查看各个 job 的日志：
   - `generate-bridge`
   - `build-rustdesk-android` (aarch64)
   - `build-rustdesk-android` (armv7)
   - `build-rustdesk-android` (x86_64)
   - `build-rustdesk-android-universal`

4. 构建通常需要 30-60 分钟

## 步骤 8: 下载 APK

构建成功完成后：

1. 在 workflow 运行页面，向下滚动到 "Artifacts" 部分
2. 你会看到类似这样的 artifacts：
   - `rustdesk-android-aarch64`
   - `rustdesk-android-armv7`
   - `rustdesk-android-x86_64`
   - `rustdesk-android-universal`

3. 点击你需要的 artifact 下载：
   - **universal** - 包含所有架构，文件较大但兼容性最好
   - **aarch64** - 适用于大多数现代 Android 设备（推荐）
   - **armv7** - 适用于旧设备
   - **x86_64** - 适用于模拟器或 x86 设备

4. 下载的文件通常是 zip 格式，解压后得到 APK

## 步骤 9: 安装和测试

1. 将 APK 传输到你的 Android TV 或 Android 设备
2. 在设备上允许安装未知来源应用
3. 安装 APK
4. 测试 TV 遥控器功能：
   - 打开 RustDesk
   - 连接到远程电脑
   - 使用方向键移动鼠标
   - 使用 OK 键点击
   - 使用 Back 键右键点击

## 故障排除

### 构建失败

1. 检查 Actions 日志中的错误信息
2. 确保所有文件都正确提交
3. 尝试使用 `flutter-nightly.yml` 而不是 `flutter-build.yml`
4. 查看原始项目的 Actions 了解最新状态

### APK 安装失败

1. 确保下载了正确架构的 APK
2. 尝试 universal APK
3. 检查 Android 版本是否满足要求（minSdk 22）

### TV 遥控器不工作

1. 确保你在远程控制页面（RemotePage）
2. 检查是否获得了焦点
3. 尝试按 OK 键选择输入区域
4. 查看我们的 `TV_REMOTE_SUPPORT.md` 文档

## 提示和技巧

1. **使用分支**: 建议在专用分支上工作，不要直接在 master 上
2. **查看原始 CI**: 在开始前先看看原始项目的 Actions 是否正常工作
3. **保存 artifacts**: 下载后保存好 APK，artifacts 会在一定时间后过期
4. **测试多个架构**: 如果不确定设备架构，可以先测试 aarch64 和 universal

## 需要的文件清单

确保这些文件都在你的提交中：

- [ ] `flutter/lib/models/tv_remote_controller.dart` (新建)
- [ ] `flutter/lib/mobile/pages/remote_page.dart` (修改)
- [ ] `flutter/android/app/src/main/AndroidManifest.xml` (修改)
- [ ] `flutter/android/app/src/main/res/drawable/tv_banner.xml` (新建)
- [ ] `flutter/android/app/src/main/res/values/styles_tv.xml` (新建)

可选的文档文件：
- [ ] `TV_REMOTE_SUPPORT.md`
- [ ] `package_tv_apk.sh`
- [ ] `ALTERNATIVE_PACKAGING.md`

祝你构建顺利！
