# GitHub Actions CI 构建详解

## 1. 整体架构

```
用户点击 "Run workflow"
        ↓
Full Flutter CI (flutter-ci.yml)
        ↓
调用 Build the flutter version (flutter-build.yml)
        ↓
并行执行多个 Jobs:
├─ generate-bridge (生成 Dart ↔ Rust 桥接代码)
├─ build-RustDeskTempTopMostWindow (Windows 辅助窗口)
├─ build-for-windows-flutter (Windows 版本)
├─ build-rustdesk-android (Android APK) ← 我们需要的
├─ build-rustdesk-ios (iOS 版本)
└─ build-rustdesk-linux (Linux 版本)
```

---

## 2. 为什么需要这么复杂？

RustDesk 是一个**混合架构**的应用：

```
┌────────────────────────────────────────────────────────────┐
│                    RustDesk 架构                            │
├────────────────────────────────────────────────────────────┤
│  Flutter UI (Dart)                                         │
│     ↓ ↑                                                     │
│  Flutter Rust Bridge (自动生成)                            │
│     ↓ ↑                                                     │
│  Rust Core (Rust)                                          │
│     ↓ ↑                                                     │
│  librustdesk.so (Native 库)                               │
│     ↓ ↑                                                     │
│  vcpkg (C++ 依赖管理)                                       │
└────────────────────────────────────────────────────────────┘
```

**不能简单用 `flutter build apk` 的原因：**
1. ❌ 有 Rust 原生代码需要编译
2. ❌ 需要交叉编译到 4 种 Android 架构
3. ❌ 需要 vcpkg 管理 C++ 依赖（ffmpeg 等）
4. ❌ 需要 Flutter Rust Bridge 生成桥接代码

---

## 3. Android 构建详细流程

### 3.1 环境准备 (Environment Setup)

```yaml
环境变量配置:
  FLUTTER_VERSION: "3.24.5"      # Flutter SDK 版本
  RUST_VERSION: "1.75"           # Rust 编译器版本
  NDK_VERSION: "r28c"            # Android NDK 版本
  VCPKG_COMMIT_ID: "..."        # vcpkg 依赖版本
  VERSION: "1.4.6"              # RustDesk 版本号
```

**系统要求：**
- Ubuntu 24.04 操作系统
- Flutter 3.24.5 SDK
- Rust 1.75 编译器
- Android NDK r28c
- Java 17
- vcpkg (C++ 包管理器)

### 3.2 Job 依赖关系图

```
generate-bridge (最先执行)
       ↓
build-rustdesk-android (等待 bridge 完成)
       ↓
┌──────┴──────┬────────┐
↓             ↓        ↓
aarch64     armv7    x86_64
(arm64)    (arm32)   (x86_64)
   ↓          ↓         ↓
librustdesk.so × 3 个架构
```

### 3.3 详细构建步骤

#### Step 1: 安装系统依赖

```bash
sudo apt-get update
sudo apt-get install -y \
    clang cmake curl gcc-multilib git \
    g++ g++-multilib \
    libayatana-appindicator3-dev \
    libasound2-dev libclang-dev \
    libgstreamer1.0-dev \
    libgtk-3-dev libpulse-dev \
    llvm-dev nasm ninja-build \
    openjdk-17-jdk-headless \
    pkg-config wget ...
```

#### Step 2: 克隆代码 + 子模块

```bash
git clone https://github.com/kaite674/rustdesk1.git
cd rustdesk1
git submodule update --init --recursive
```

#### Step 3: 安装 Flutter

```yaml
- uses: subosito/flutter-action@v2
  with:
    channel: "stable"
    flutter-version: "3.24.5"
```

#### Step 4: 安装 Android NDK

```yaml
- uses: nttld/setup-ndk@v1
  with:
    ndk-version: r28c
```

#### Step 5: 安装 vcpkg 依赖

```bash
./flutter/build_android_deps.sh arm64-v8a
```

**vcpkg 管理的依赖包括：**
- ffmpeg (音视频编解码)
- opus (音频编解码)
- libsodium (加密)
- ...

#### Step 6: 生成 Bridge 代码

```bash
# flutter_rust_bridge 自动生成
# 生成文件: lib/generated_bridge.dart
```

#### Step 7: 编译 Rust 核心库

```bash
# 为每种架构编译
cargo build --release --target aarch64-linux-android
cargo build --release --target armv7-linux-androideabi
cargo build --release --target x86_64-linux-android
```

**生成：**
```
target/aarch64-linux-android/release/liblibrustdesk.so
target/armv7-linux-androideabi/release/liblibrustdesk.so
target/x86_64-linux-android/release/liblibrustdesk.so
```

#### Step 8: 复制 Native 库到 Flutter 项目

```bash
# arm64-v8a
mkdir -p ./flutter/android/app/src/main/jniLibs/arm64-v8a
cp ./target/aarch64-linux-android/release/liblibrustdesk.so \
   ./flutter/android/app/src/main/jniLibs/arm64-v8a/

# armv7 (armeabi-v7a)
mkdir -p ./flutter/android/app/src/main/jniLibs/armeabi-v7a
cp ./target/armv7-linux-androideabi/release/liblibrustdesk.so \
   ./flutter/android/app/src/main/jniLibs/armeabi-v7a/

# x86_64
mkdir -p ./flutter/android/app/src/main/jniLibs/x86_64
cp ./target/x86_64-linux-android/release/liblibrustdesk.so \
   ./flutter/android/app/src/main/jniLibs/x86_64/
```

**最终 APK 结构：**
```
app-release.apk
  └── lib/
      ├── arm64-v8a/librustdesk.so
      ├── armeabi-v7a/librustdesk.so
      └── x86_64/librustdesk.so
```

#### Step 9: 构建 Flutter APK

```bash
cd flutter
flutter build apk --release --target-platform android-arm64
flutter build apk --release --target-platform android-arm
flutter build apk --release --target-platform android-x64
```

#### Step 10: 签名 APK (可选)

```yaml
- uses: r0adkll/sign-android-release@v1
  with:
    releaseDirectory: ./signed-apk
    signingKeyBase64: ${{ secrets.ANDROID_SIGNING_KEY }}
    alias: ${{ secrets.ANDROID_ALIAS }}
```

#### Step 11: 上传构建产物

```yaml
- uses: actions/upload-artifact@master
  with:
    name: rustdesk-1.4.6-aarch64.apk
    path: ./signed-apk/rustdesk-1.4.6-aarch64.apk
```

---

## 4. Matrix 构建 (并行编译)

```yaml
strategy:
  fail-fast: false
  matrix:
    job:
      - { arch: aarch64, target: aarch64-linux-android, os: ubuntu-24.04 }
      - { arch: armv7,  target: armv7-linux-androideabi, os: ubuntu-24.04 }
      - { arch: x86_64, target: x86_64-linux-android, os: ubuntu-24.04 }
```

**并行执行：**
```
Job 1: aarch64 (arm64) ──┐
Job 2: armv7 (arm32)  ───┼──→ 并行构建，节省时间
Job 3: x86_64        ────┘

原来: 60min × 3 = 180min
现在: 60min (并行) ≈ 60min
```

---

## 5. 缓存机制

### 5.1 Rust 缓存

```yaml
- uses: Swatinem/rust-cache@v2
  with:
    prefix-key: rustdesk-lib-cache-android
    key: aarch64-linux-android
```

**缓存内容：**
- Cargo 编译缓存 (~/.cargo)
- target 目录

**效果：**
- 首次构建: 60 分钟
- 后续构建: 20-30 分钟 (缓存命中)

### 5.2 vcpkg 缓存

```yaml
- uses: lukka/run-vcpkg@v11
  with:
    vcpkgDirectory: /opt/artifacts/vcpkg
    vcpkgGitCommitId: "120deac3..."
```

**缓存内容：**
- vcpkg 安装的 C++ 库
- 编译好的 .a / .so 文件

### 5.3 GitHub Actions 缓存

```yaml
- name: Export GitHub Actions cache environment variables
  uses: actions/github-script@v6
  with:
    script: |
      core.exportVariable('ACTIONS_CACHE_URL', process.env.ACTIONS_CACHE_URL || '');
      core.exportVariable('ACTIONS_RUNTIME_TOKEN', process.env.ACTIONS_RUNTIME_TOKEN || '');
```

---

## 6. 工件 (Artifacts) 说明

### 6.1 中间产物

| 工件名称 | 说明 | 大小 |
|---------|------|------|
| bridge-artifact | Flutter Rust Bridge 生成的文件 | ~1MB |
| librustdesk.so.aarch64 | arm64 原生库 | ~10MB |
| librustdesk.so.armv7 | arm32 原生库 | ~8MB |
| librustdesk.so.x86_64 | x86_64 原生库 | ~10MB |

### 6.2 最终产物

| 工件名称 | 说明 | 大小 |
|---------|------|------|
| rustdesk-1.4.6-aarch64.apk | arm64 Android APK | ~50MB |
| rustdesk-1.4.6-armv7.apk | arm32 Android APK | ~45MB |
| rustdesk-1.4.6-x86_64.apk | x86_64 Android APK | ~55MB |
| rustdesk-android-universal.zip | 包含所有架构的 APK | ~150MB |

---

## 7. 构建时间分析

| 阶段 | 首次构建 | 缓存命中 |
|------|---------|---------|
| 环境准备 | 5 min | 2 min |
| Flutter 安装 | 3 min | 0 min |
| Android NDK | 2 min | 0 min |
| vcpkg 依赖 | 10 min | 5 min |
| Rust 编译 (×3) | 45 min | 15 min |
| Flutter 构建 | 15 min | 10 min |
| 签名 & 上传 | 2 min | 2 min |
| **总计** | **~70 min** | **~30 min** |

---

## 8. 为什么 Full Flutter CI 比 Flutter Nightly Build 好？

| 特性 | Full Flutter CI | Flutter Nightly Build |
|------|----------------|---------------------|
| 触发方式 | `workflow_dispatch` (手动) | 定时 (nightly) |
| Artifact 上传 | ✅ 支持 | ❌ 已禁用 |
| APK 下载 | ✅ 可以 | ❌ 不可以 |
| 状态 | 启用 | 禁用 |

---

## 9. 完整构建日志示例

```
Run CI
  ✔ generate-bridge (3m 12s)
  │
  ├─✔ build-rustdesk-android/aarch64 (25m 30s)
  │    ✔ build-rustdesk-android/armv7 (24m 15s)
  │    ✔ build-rustdesk-android/x86_64 (26m 45s)
  │
  ├─✔ build-rustdesk-ios (18m 20s)
  │
  └─✔ build-rustdesk-linux (15m 10s)

Total: ~27 minutes
```

---

## 10. 故障排除

### 问题 1: vcpkg 下载失败

**症状：**
```
Error: vcpkg failed to install
```

**解决方案：**
- 检查网络连接
- GitHub Actions 有速率限制
- 可以配置私有 vcpkg 缓存

### 问题 2: Rust 编译超时

**症状：**
```
Error: The runner running this job didn't respond
```

**解决方案：**
- GitHub Actions 免费版有 6 小时超时
- 通常不会超时，可以重试

### 问题 3: 签名失败

**症状：**
```
Error: signing key not found
```

**解决方案：**
- 需要配置 `ANDROID_SIGNING_KEY` secret
- Full Flutter CI 已设置 `upload-artifact: false`，不需要签名

---

## 11. 如何优化构建速度

1. **使用缓存**
   - GitHub Actions 自动使用 Rust 和 vcpkg 缓存
   - 不要禁用缓存

2. **使用 matrix 并行**
   - 3 个架构并行编译
   - 节省 2/3 时间

3. **小技巧**
   - 不要频繁修改 `Cargo.toml`
   - 不要修改 vcpkg 依赖版本
   - 保持 Flutter 版本一致

---

## 12. 总结

**Full Flutter CI 工作原理：**

```
1. 用户手动触发 workflow
   ↓
2. GitHub 分配虚拟机 (Ubuntu 24.04)
   ↓
3. 安装 Flutter + Rust + Android NDK + vcpkg
   ↓
4. 并行编译 3 个架构的 Rust 库
   ↓
5. 生成 Flutter Bridge 代码
   ↓
6. 构建 Flutter APK
   ↓
7. 签名 (可选) + 上传 Artifact
   ↓
8. 用户下载 APK
```

**关键点：**
- ✅ 混合架构 (Flutter + Rust + C++)
- ✅ 交叉编译 (Linux → Android)
- ✅ 并行构建 (Matrix)
- ✅ 智能缓存 (Rust + vcpkg)
- ✅ 自动签名 (可选)

现在你完全理解了整个构建系统！🚀
