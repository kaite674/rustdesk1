#!/bin/bash
# Install TV Remote Support Patch

set -e

echo "Installing RustDesk TV Remote Support..."
echo ""

# Check if we're in a RustDesk repository
if [ ! -d "flutter" ] || [ ! -f "Cargo.toml" ]; then
    echo "ERROR: This doesn't look like a RustDesk repository"
    echo "Please run this script from the RustDesk root directory"
    exit 1
fi

echo "Copying files..."
cp -r flutter/ libs/ src/ 2>/dev/null || true

# Make sure directories exist
mkdir -p flutter/lib/models
mkdir -p flutter/lib/mobile/pages
mkdir -p flutter/android/app/src/main/res/drawable
mkdir -p flutter/android/app/src/main/res/values

# Copy individual files with confirmation
echo ""
read -p "This will overwrite some files. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Copy files
cp flutter/lib/models/tv_remote_controller.dart flutter/lib/models/ 2>/dev/null || {
    echo "Copying tv_remote_controller.dart..."
    cp ../flutter/lib/models/tv_remote_controller.dart flutter/lib/models/
}

echo "✓ Patch applied successfully!"
echo ""
echo "Next steps:"
echo "1. Run 'git status' to see changes"
echo "2. Run 'git add .' to stage changes"
echo "3. Run 'git commit -m \"feat: add TV remote control support\"'"
echo "4. Push to your GitHub fork"
echo "5. Follow GITHUB_ACTIONS_GUIDE.md to build APK"
