#!/bin/bash
# 创建 TV 遥控器支持的 git patch 文件
# 这样可以方便地应用到其他分支或 fork

set -e

PROJECT_DIR=$(dirname "$0")
cd "$PROJECT_DIR"

echo "=========================================="
echo "创建 TV 遥控器支持的 Patch 文件"
echo "=========================================="
echo ""

# 检查是否在 git 仓库中
if [ ! -d ".git" ]; then
    echo "错误: 不在 git 仓库中"
    exit 1
fi

# 创建 patch 目录
PATCH_DIR="tv_remote_patches"
mkdir -p "$PATCH_DIR"

echo "步骤 1: 检查当前修改..."
echo ""
git status

echo ""
echo "步骤 2: 创建 patch 文件..."
echo ""

# 方法 1: 使用 git diff 创建单个 patch
if git diff --cached >/dev/null 2>&1; then
    echo "创建暂存区修改的 patch..."
    git diff --cached > "$PATCH_DIR/tv_remote_support.patch"
    echo "✓ 创建了 $PATCH_DIR/tv_remote_support.patch"
fi

# 方法 2: 创建所有修改的 patch（包括未暂存）
echo ""
echo "创建所有修改的 patch..."
git diff HEAD > "$PATCH_DIR/tv_remote_support_all.patch"
echo "✓ 创建了 $PATCH_DIR/tv_remote_support_all.patch"

# 方法 3: 分别为每个文件创建 patch
echo ""
echo "创建单个文件的 patches..."
MODIFIED_FILES=$(git diff --name-only HEAD)
for file in $MODIFIED_FILES; do
    if [ -f "$file" ]; then
        safe_name=$(echo "$file" | tr '/' '_' | tr '.' '_')
        git diff HEAD -- "$file" > "$PATCH_DIR/$safe_name.patch"
        echo "✓ 创建了 $PATCH_DIR/$safe_name.patch"
    fi
done

# 创建应用 patch 的脚本
cat > "$PATCH_DIR/apply_patch.sh" << 'EOF'
#!/bin/bash
# 应用 TV 遥控器支持的 patch

PATCH_DIR=$(dirname "$0")
cd "$PATCH_DIR/.."

echo "应用 TV 遥控器支持的 patch..."

if [ -f "$PATCH_DIR/tv_remote_support.patch" ]; then
    git apply "$PATCH_DIR/tv_remote_support.patch"
    echo "✓ Patch 已应用"
elif [ -f "$PATCH_DIR/tv_remote_support_all.patch" ]; then
    git apply "$PATCH_DIR/tv_remote_support_all.patch"
    echo "✓ Patch 已应用"
else
    echo "错误: 未找到 patch 文件"
    exit 1
fi

echo ""
echo "完成！现在可以提交这些修改了。"
EOF

chmod +x "$PATCH_DIR/apply_patch.sh"

echo ""
echo "=========================================="
echo "完成！"
echo "=========================================="
echo ""
echo "Patch 文件位置: $PATCH_DIR/"
echo ""
echo "使用方法："
echo "1. 复制 $PATCH_DIR/ 目录到你的目标仓库"
echo "2. 运行: cd /path/to/target/repo"
echo "3. 运行: $PATCH_DIR/apply_patch.sh"
echo ""
echo "或者手动应用："
echo "  git apply tv_remote_support.patch"
echo ""
ls -lah "$PATCH_DIR/"
