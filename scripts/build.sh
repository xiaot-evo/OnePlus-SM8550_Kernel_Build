#!/bin/bash
set -e # 如果命令运行失败则直接退出脚本

# 从环境变量中读取参数并提供默认值
# KERNEL_DIR: 内核源码所在的目录名 (默认: sm8550)
# WORKSPACE: 当前工作区的根目录 (默认: 当前路径)

KERNEL_DIR="${KERNEL_DIR:-sm8550}"
WORKSPACE="${WORKSPACE:-$(pwd)}"

echo "正在准备编译内核 (目录: $KERNEL_DIR)..."

# 导出构建环境依赖的环境变量，设定编译工具链为 Clang/LLVM
export LLVM=1       # 启用 LLVM 套件工具 
export LLVM_IAS=1   # 启用 LLVM 集成的汇编器
export CC=clang     # 指定 C 语言编译器为 Clang
export CXX=clang++  # 指定 C++ 语言编译器为 Clang++

# 检查系统中是否安装了 sccache (Mozilla 开发的一款 C/C++ 编译器缓存工具)
# 如果安装了，就通过 export SCCACHE=1 来开启缓存，极大地加速重新编译的时间
if command -v sccache &> /dev/null; then
    export SCCACHE=1
    echo "检测到 sccache，编译缓存已启用。"
fi

# 切换到真实的内核源码根目录，以便执行 Make 命令
cd "$WORKSPACE/$KERNEL_DIR"

# 编译前先根据默认配置文件生成 .config 终极配置文件
# O=out 表示将所有编译中间产物以及最终镜像输出到外置目录 'out' 中，保持源码层级干净
echo "步骤 1: 开始根据架构生成默认配置文件 (.config)..."
make SCCACHE=${SCCACHE:-0} ARCH=arm64 O=out gki_defconfig vendor/kalama_GKI.config vendor/oplus/kalama_GKI.config vendor/debugfs.config

# 开启多线程正式开始编译内核镜像（Image），并把所有的标准错误和输出日志记录到 build.log 文件
echo "步骤 2: 开始进行内核映像的多线程编译 ($(nproc) 线程)..."
make -j$(nproc) SCCACHE=${SCCACHE:-0} ARCH=arm64 O=out Image 2>&1 | tee "$WORKSPACE/$KERNEL_DIR/build.log"

echo "✅ 编译流程执行完毕。"
