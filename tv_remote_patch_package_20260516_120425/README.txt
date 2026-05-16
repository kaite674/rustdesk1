RustDesk TV Remote Support Patch
=================================

This package contains all the files needed to add TV remote control
support to RustDesk and build an Android TV APK.

Contents:
- flutter/lib/models/tv_remote_controller.dart - TV remote controller
- flutter/lib/mobile/pages/remote_page.dart - Modified remote page
- flutter/android/app/src/main/AndroidManifest.xml - TV support config
- flutter/android/app/src/main/res/drawable/tv_banner.xml - TV banner
- flutter/android/app/src/main/res/values/styles_tv.xml - TV theme
- TV_REMOTE_SUPPORT.md - Full documentation
- GITHUB_ACTIONS_GUIDE.md - GitHub Actions build guide
- INSTALL_PATCH.sh - Quick install script

Quick Install:
1. Copy this entire directory to your RustDesk fork
2. Run: ./INSTALL_PATCH.sh
3. Follow the prompts

Or manually:
1. Copy all the flutter/ files to your RustDesk repository
2. Overwrite existing files when prompted
3. Commit and push
4. Use GitHub Actions to build the APK

For full details, see GITHUB_ACTIONS_GUIDE.md
