#!/bin/bash
# Quick Start: Apply TV Remote Patches to Your Fork

set -e

echo "============================================="
echo "RustDesk TV Remote Support - Quick Patch"
echo "============================================="
echo ""

# Check if we have our modified files
echo "Checking for modified files..."

REQUIRED_FILES=(
    "flutter/lib/models/tv_remote_controller.dart"
    "flutter/lib/mobile/pages/remote_page.dart"
    "flutter/android/app/src/main/AndroidManifest.xml"
    "flutter/android/app/src/main/res/drawable/tv_banner.xml"
    "flutter/android/app/src/main/res/values/styles_tv.xml"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo "ERROR: Missing required files:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    echo ""
    echo "Please make sure you're in the correct directory"
    echo "and all TV remote support files are present."
    exit 1
fi

echo "✓ All required files found!"
echo ""

# Create a temporary directory for the patch package
PATCH_DIR="tv_remote_patch_package_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$PATCH_DIR"

echo "Creating patch package in: $PATCH_DIR"
echo ""

# Copy all required files
echo "Copying files..."
cp -r --parents "${REQUIRED_FILES[@]}" "$PATCH_DIR/" 2>/dev/null || {
    # Fallback: copy manually if --parents doesn't work
    for file in "${REQUIRED_FILES[@]}"; do
        mkdir -p "$PATCH_DIR/$(dirname "$file")"
        cp "$file" "$PATCH_DIR/$file"
    done
}

# Copy documentation
cp TV_REMOTE_SUPPORT.md "$PATCH_DIR/" 2>/dev/null || true
cp GITHUB_ACTIONS_GUIDE.md "$PATCH_DIR/" 2>/dev/null || true
cp ALTERNATIVE_PACKAGING.md "$PATCH_DIR/" 2>/dev/null || true

# Create a simple install script
cat > "$PATCH_DIR/INSTALL_PATCH.sh" << 'EOF'
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
EOF

chmod +x "$PATCH_DIR/INSTALL_PATCH.sh"

# Create a README
cat > "$PATCH_DIR/README.txt" << 'EOF'
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
EOF

# Create a zip of the patch package
ZIP_NAME="rustdesk_tv_remote_patch_$(date +%Y%m%d_%H%M%S).zip"
if command -v zip &> /dev/null; then
    echo ""
    echo "Creating zip archive..."
    cd "$PATCH_DIR" && zip -r "../$ZIP_NAME" . && cd ..
    echo "✓ Created: $ZIP_NAME"
fi

echo ""
echo "============================================="
echo "Patch package created successfully!"
echo "============================================="
echo ""
echo "Patch directory: $PATCH_DIR"
if [ -f "$ZIP_NAME" ]; then
    echo "Zip archive: $ZIP_NAME"
fi
echo ""
echo "To use this patch:"
echo "1. Copy the $PATCH_DIR directory to your computer"
echo "2. Or extract the zip file if created"
echo "3. Follow the instructions in $PATCH_DIR/README.txt"
echo "4. See GITHUB_ACTIONS_GUIDE.md for detailed build steps"
echo ""
echo "Quick summary of files to copy:"
for file in "${REQUIRED_FILES[@]}"; do
    echo "  - $file"
done
echo ""
