#!/bin/bash
set -e # 遇到错误即刻停止脚本执行

# 从环境变量中读取输入参数，并提供默认值
# KSU_TYPE: 已安装的 KernelSU 类型 (可选值: None, KernelSU-Next, KowSU, ReSukiSU, ReSukiSU-Manual)
# ENABLE_SUSFS: 是否启用了 SUSFS 功能 (默认: false)
# ENABLE_LTO: 是否启用 Clang LTO 优化功能 (默认: false)
# KERNEL_DIR: 内核源码所在的目录名 (默认: sm8550)
# WORKSPACE: 当前工作区的根目录 (默认: 当前路径)

KSU_TYPE="${KSU_TYPE:-None}"
ENABLE_SUSFS="${ENABLE_SUSFS:-false}"
ENABLE_LTO="${ENABLE_LTO:-false}"
KERNEL_DIR="${KERNEL_DIR:-sm8550}"
WORKSPACE="${WORKSPACE:-$(pwd)}"

# 定义内核默认配置文件 (defconfig) 的存放路径
DEFCONFIG_FILE="$WORKSPACE/$KERNEL_DIR/arch/arm64/configs/gki_defconfig"

echo "开始动态配置内核编译参数 (KSU类型=$KSU_TYPE, SUSFS启用=$ENABLE_SUSFS, LTO优化=$ENABLE_LTO)..."

# 检查 defconfig 文件是否存在，如果不存在则报错退出
if [ ! -f "$DEFCONFIG_FILE" ]; then
    echo "严重错误: 在 $DEFCONFIG_FILE 没有找到内核默认配置文件！"
    exit 1
fi

# 向配置文件注入通用的 KernelSU 和一些辅助的文件系统属性功能
echo "正在向配置文件注入基础 KernelSU 选项..."
printf 'CONFIG_KSU=y\nCONFIG_TMPFS_XATTR=y\nCONFIG_TMPFS_POSIX_ACL=y\n' >> "$DEFCONFIG_FILE"

# 若用户开启了 SUSFS，则将其配置一并写入 defconfig
if [ "$ENABLE_SUSFS" = "true" ]; then
    echo "正在注入 SUSFS 配置模块选项..."
    echo "CONFIG_KSU_SUSFS=y" >> "$DEFCONFIG_FILE"
    
    # 将 install_susfs.sh 生成的更详尽的配置片段附加到默认配置文件中
    if [ -f "$WORKSPACE/$KERNEL_DIR/wild_gki.fragment" ]; then
        cat "$WORKSPACE/$KERNEL_DIR/wild_gki.fragment" >> "$DEFCONFIG_FILE"
    fi
fi

# 若用户选用了 ReSukiSU-Manual（也就是需要支持全自动 Hook 配置的 KSU）
if [ "$KSU_TYPE" = "ReSukiSU-Manual" ]; then
    echo "检测到手动 ReSukiSU-Manual 挂载钩子支持，正在追加 Hook 参数选项..."
    printf 'CONFIG_KSU_MANUAL_HOOK=y\nCONFIG_KSU_MANUAL_HOOK_AUTO_INPUT_HOOK=y\nCONFIG_KSU_MANUAL_HOOK_AUTO_SETUID_HOOK=y\nCONFIG_KSU_MANUAL_HOOK_AUTO_INITRC_HOOK=y\n' >> "$DEFCONFIG_FILE"
fi

# 检查是否开启了 LTO (链接时优化，能够提升内核执行效率但会大幅增加编译时间)
if [ "$ENABLE_LTO" = "true" ]; then
    echo "检测到启用 LTO，正在注入 Clang ThinLTO 链接优化参数..."
    echo "CONFIG_LTO=y" >> "$DEFCONFIG_FILE"
    echo "CONFIG_LTO_CLANG=y" >> "$DEFCONFIG_FILE"
    echo "CONFIG_THINLTO=y" >> "$DEFCONFIG_FILE"
fi

# 检验所有修改是否成功被写入文件之中
echo "校验刚才追加的编译配置选项："
grep -E "CONFIG_KSU|CONFIG_TMPFS|CONFIG_LTO" "$DEFCONFIG_FILE" || true
echo "内核动态参数配置完成！"
