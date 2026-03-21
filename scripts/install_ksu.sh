#!/bin/bash
set -e # 遇到错误即刻停止脚本执行

# 从环境变量中读取输入参数，并提供默认值
# KSU_TYPE: 要安装的 KernelSU 类型 (可选值: None, KernelSU-Next, KowSU, ReSukiSU, ReSukiSU-Manual)
# KERNEL_BRANCH: 内核源码所在的具体分支 (例如 android13, android14)
# KERNEL_DIR: 内核源码所在的相对目录 (默认: sm8550)
# WORKSPACE: 当前的工作区根目录 (默认: 当前路径)

KERNEL_DIR="${KERNEL_DIR:-sm8550}"
WORKSPACE="${WORKSPACE:-$(pwd)}"
KSU_TYPE="${KSU_TYPE:-None}"
KERNEL_BRANCH="${KERNEL_BRANCH:-}"

# 如果用户选择了 None，则跳过 KernelSU 的安装过程
if [ "$KSU_TYPE" = "None" ]; then
    echo "跳过 KernelSU 安装 (KSU_TYPE=None)"
    exit 0
fi

echo "正在将 $KSU_TYPE 安装到 $KERNEL_DIR 目录..."
cd "$KERNEL_DIR"

# 根据不同的 KSU_TYPE 执行对应的在线安装脚本
if [ "$KSU_TYPE" = "KernelSU-Next" ]; then
    # KernelSU-Next 会根据 Android 分支的不同选择 main 分支或 dev_susfs 分支
    if [ "$KERNEL_BRANCH" = "android14" ]; then
        echo "检测到 android14 分支，使用 KernelSU-Next 的 main 分支..."
        curl -LSs https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/refs/heads/main/kernel/setup.sh | bash -s main
    else
        echo "非 android14 分支，默认使用 KernelSU-Next 的 dev_susfs 分支..."
        curl -LSs https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/refs/heads/dev_susfs/kernel/setup.sh | bash -s dev_susfs
    fi

elif [ "$KSU_TYPE" = "KowSU" ]; then
    # 安装 KowSU 的 master 分支
    curl -LSs https://raw.githubusercontent.com/KOWX712/KernelSU/main/kernel/setup.sh | bash -s master

elif [ "$KSU_TYPE" = "ReSukiSU" ]; then
    # 安装 ReSukiSU 的 main 分支
    curl -LSs https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/main/kernel/setup.sh | bash -s main

elif [ "$KSU_TYPE" = "ReSukiSU-Manual" ]; then
    # 安装带有手动 Hook 支持的 ReSukiSU
    curl -LSs https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/main/kernel/setup.sh | bash -s main
    
    # 检测并应用存在于 patches 文件夹中的手动 Hook 补丁
    if [ -f "$WORKSPACE/patches/resksu_manual_hooks.patch" ]; then
        echo "正在应用 ReSukiSU 手动 Hook 补丁..."
        cp "$WORKSPACE/patches/resksu_manual_hooks.patch" ./
        patch -p1 < resksu_manual_hooks.patch || echo "警告: 补丁应用失败"
    else
        echo "警告: 在 $WORKSPACE/patches/ 目录中未找到 resksu_manual_hooks.patch，跳过补丁应用。"
    fi
else
    # 对于未知的 KSU_TYPE 报错并退出
    echo "未知的 KSU 类型: $KSU_TYPE"
    exit 1
fi

echo "正在验证 KernelSU 是否安装成功..."
# 检查是否成功生成了 supersu 或 KernelSU 的代码目录
if [ -d "kernel/supersu" ] || [ -d "KernelSU" ] || [ -d "kernel/KernelSU" ]; then
    echo "KernelSU 目录已成功创建。"
else
    echo "警告: 未找到 KernelSU 代码目录，安装可能已经失败。"
fi
