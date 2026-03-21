#!/bin/bash
set -e # 若存在任何非 0 退出的错误则终止脚本

# 从环境变量中读取参数并提供默认值
# KERNEL_DIR: 内核源码所在的目录名 (默认: sm8550)
# WORKSPACE: 当前工作区的根目录 (默认: 当前路径)

KERNEL_DIR="${KERNEL_DIR:-sm8550}"
WORKSPACE="${WORKSPACE:-$(pwd)}"

# 设定刚刚编译出的内核未压缩裸映像 (Image) 应该存在的标准路径
IMAGE_PATH="$WORKSPACE/$KERNEL_DIR/out/arch/arm64/boot/Image"

echo "开始验证刚才生成的内核映像合法性..."

# 检查文件是否确实存在
# 如果不存在，抛出异常，并且把 build.log (编译错误日志) 的最后 50 行打印出来方便排错
if [ ! -f "$IMAGE_PATH" ]; then
    echo "严重错误: 在预期位置没有找到生成的映像文件 ($IMAGE_PATH)"
    if [ -f "$WORKSPACE/$KERNEL_DIR/build.log" ]; then
        echo "检查最近的编译报错信息 (build.log 的尾部):"
        tail -50 "$WORKSPACE/$KERNEL_DIR/build.log"
    fi
    exit 1
fi

# 使用 stat 命令获取文件字节大小
SIZE=$(stat -c%s "$IMAGE_PATH")
echo "映像字节大小: $SIZE bytes"

# 如果一个正常编译出的 GKI 内核（哪怕是未包含模块的 Image）小于 10MB (10000000 字节)
# 那这大概率是个空的或者编译中途失败的残缺文件
if [ $SIZE -lt 10000000 ]; then
    echo "警告: 内核映像的大小异常地小 (可能文件有损坏或者只输出了头信息)"
    exit 1
fi

# 使用 xxd 检查十六进制头文件，MZ 是典型的 Windows 可执行文件 (PE/COFF 格式) 的标志
# 有时如果交叉编译参数传错了导致编译出并非 Linux 的 ELF 或原二进制文件，可能会被检测出来
echo "检查映像头部签名信息..."
if xxd -l 32 "$IMAGE_PATH" | grep -q "MZ"; then
    echo "错误: 该文件是一个 Windows 类型的 PE/COFF 可执行文件，并非合格的 Linux 内核镜像"
    exit 1
fi

# 调用系统的 file 命令智能解析文件头部来判断类型
FILE_INFO=$(file "$IMAGE_PATH")
echo "系统 file 命令检测出的类型: $FILE_INFO"

# 我们期望文件信息中包含 "kernel" 字样（例如：MS-DOS executable, ..., Linux kernel...）
if echo "$FILE_INFO" | grep -q "kernel"; then
    echo "✅ 成功确认这是一个有效的 Linux 内核映像！"
else
    # 有时候 file 命令不准，或者只是纯二进制文件未包含任何特殊头信息
    # 这里只是给出一个警告而不直接阻断整个工作流
    echo "警告: 解析的文件类型并不包含 kernel 字符，有可能是纯净格式。继续后续步骤..."
fi

echo "✅ 编译产物验证通过，即将转入打包阶段。"
