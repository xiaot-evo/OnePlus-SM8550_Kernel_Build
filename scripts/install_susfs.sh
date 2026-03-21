#!/bin/bash
set -e # 遇到错误即刻停止脚本执行

# 从环境变量中读取参数并提供默认值
# ENABLE_SUSFS: 是否启用并安装 SUSFS 功能 (默认: false)
# ANDROID_VERSION: GKI 所对应的安卓版本 (默认: android13)
# KERNEL_VERSION: 内核的主要版本号 (默认: 1.15)
# SUSFS_COMMIT_MAP: 一组以逗号分隔的“分支:Commit哈希”映射表，用于精确检出特定的补丁版本
# KERNEL_DIR: 内核源码所在的目录名 (默认: sm8550)
# WORKSPACE: 当前工作区的根目录 (默认: 当前路径)

ENABLE_SUSFS="${ENABLE_SUSFS:-false}"
ANDROID_VERSION="${ANDROID_VERSION:-android13}"
KERNEL_VERSION="${KERNEL_VERSION:-1.15}" # CI 传递过来的默认内核版本
SUSFS_COMMIT_MAP="${SUSFS_COMMIT_MAP:-}"
KERNEL_DIR="${KERNEL_DIR:-sm8550}"
WORKSPACE="${WORKSPACE:-$(pwd)}"

# 如果开关未启用，则跳过 SUSFS 的安装步骤
if [ "$ENABLE_SUSFS" != "true" ]; then
    echo "跳过 SUSFS 安装过程 (ENABLE_SUSFS=$ENABLE_SUSFS)"
    exit 0
fi

# 根据 Android 版本和内核版本拼接对应的分支名称
SUSFS_BRANCH="gki-${ANDROID_VERSION}-${KERNEL_VERSION}"
SUSFS_REPO="https://gitlab.com/simonpunk/susfs4ksu.git"

echo "正在准备克隆 $SUSFS_BRANCH 分支的代码用于部署 SUSFS..."
cd "$WORKSPACE"

TARGET_COMMIT=""
# 如果提供了具体的 commit 映射表，则尝试解析并提取出当前分支所需的特定 commit hash
if [ -n "$SUSFS_COMMIT_MAP" ]; then
    # 以逗号分割成数组
    IFS=',' read -ra ENTRIES <<< "$SUSFS_COMMIT_MAP"
    for entry in "${ENTRIES[@]}"; do
        # 每组再以冒号分割出 branch 和 commit
        IFS=':' read -r branch commit <<< "$entry"
        if [ "$branch" == "$SUSFS_BRANCH" ]; then
            TARGET_COMMIT="$commit"
            break
        fi
    done
fi

# 开始拉取远程代码仓库
if [ -n "$TARGET_COMMIT" ]; then
    echo "找到 $SUSFS_BRANCH 的特定提交版本: $TARGET_COMMIT，正在进行回退..."
    git clone "$SUSFS_REPO" -b "$SUSFS_BRANCH" susfs4ksu
    cd susfs4ksu
    # 检出指定的 commit
    git checkout "$TARGET_COMMIT"
    cd ..
else
    echo "没有找到具体的提交映射，直接克隆 $SUSFS_BRANCH 最新代码库..."
    # 使用深度 1 以加速拉取
    git clone "$SUSFS_REPO" -b "$SUSFS_BRANCH" --depth=1 susfs4ksu
fi

# 手动将 SUSFS 相关的 KernelSU 编译选项写入片段文件，之后会在配置内核时将其注入
echo "正在启用 KernelSU 和 SUSFS 的编译配置选项..."
cat >> "$WORKSPACE/$KERNEL_DIR/wild_gki.fragment" << 'EOF'
# KernelSU SUSFS 专属编译选项
CONFIG_KSU_SUSFS=y
CONFIG_KSU_SUSFS_SUS_PATH=y
CONFIG_KSU_SUSFS_SUS_MOUNT=y
CONFIG_KSU_SUSFS_SUS_KSTAT=y
CONFIG_KSU_SUSFS_SPOOF_UNAME=y
CONFIG_KSU_SUSFS_ENABLE_LOG=y
CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y
CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y
CONFIG_KSU_SUSFS_OPEN_REDIRECT=y
CONFIG_KSU_SUSFS_SUS_MAP=y
EOF

# 应用 SUSFS 给内核源码的基础补丁
echo "正在向内核源码树应用基础 SUSFS 补丁..."
cd "$WORKSPACE/$KERNEL_DIR"

# 这里通过循环或者直接通配符拷贝的方式，把 SUSFS 对应的内核文件覆盖到本地源码中
if [ -d "$WORKSPACE/susfs4ksu/kernel_patches/fs" ]; then
    # 覆盖文件系统层的补丁文件
    cp -rv "$WORKSPACE/susfs4ksu/kernel_patches/fs/"* fs/
fi

if [ -d "$WORKSPACE/susfs4ksu/kernel_patches/include/linux" ]; then
    # 覆盖头文件
    cp -rv "$WORKSPACE/susfs4ksu/kernel_patches/include/linux/"* include/linux/
fi

# 根据分支版本号拼接出对应的统一 .patch 补丁文件并进行自动打补丁操作
PATCH_FILE="50_add_susfs_in_gki-${ANDROID_VERSION}-${KERNEL_VERSION}.patch"
if [ -f "$WORKSPACE/susfs4ksu/kernel_patches/$PATCH_FILE" ]; then
    cp "$WORKSPACE/susfs4ksu/kernel_patches/$PATCH_FILE" ./
    patch -p1 < "$PATCH_FILE" || echo "警告: SUSFS 的底层 patch 应用失败，尝试继续编译..."
else
    echo "警告: 在补丁目录中未找到 $PATCH_FILE 文件。"
fi

echo "SUSFS 安装及补丁配置完成！"
