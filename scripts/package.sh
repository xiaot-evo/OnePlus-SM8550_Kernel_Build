#!/bin/bash
set -e # 若存在任何非 0 退出的错误则终止脚本执行

# 从环境变量中读取输入参数并提供默认值
# KERNEL_DIR: 内核源码所在的目录名 (默认: sm8550)
# WORKSPACE: 当前工作区的根目录 (默认: 当前路径)
# KERNEL_COMMIT: 编译用到的 Git 的 commit hash 摘要，通常用于给 AnyKernel 打上版本印记

KERNEL_DIR="${KERNEL_DIR:-sm8550}"
WORKSPACE="${WORKSPACE:-$(pwd)}"
KERNEL_COMMIT="${KERNEL_COMMIT:-未知版本(Unknown)}"

# 定义刚刚编译完成后的内核映像文件位置
IMAGE_PATH="$WORKSPACE/$KERNEL_DIR/out/arch/arm64/boot/Image"

# 防御性检查: 再次确认如果找不到镜像就停止后续可能破坏环境的打包行为
if [ ! -f "$IMAGE_PATH" ]; then
    echo "严重错误: 在 $IMAGE_PATH 没有找到刚刚构建出的 Image"
    exit 1
fi

echo "开始准备打包出可以在 TWRP/Recovery 下刷入的 AnyKernel3 ZIP 包..."
# 回退到工作区根目录
cd "$WORKSPACE"

# 使用深度浅克隆 `--depth=1` 获取 KernelSU 官方原版或经过他们维护过的通用的 AnyKernel3 仓库模板代码
git clone --depth=1 https://github.com/Kernel-SU/AnyKernel3.git AnyKernel3

# 因为我们要将其作为产物导出，所以直接删掉版本控制的历史数据，减小压缩包体积和干扰
rm -rf AnyKernel3/.git

# 将刚才成功编译出的纯净未压缩的内核映像 (Image) 复制到 AnyKernel3 目录结构中
cp "$IMAGE_PATH" "$WORKSPACE/AnyKernel3/Image"

cd "$WORKSPACE/AnyKernel3"
# 编辑 anykernel.sh (通常负责配置刷机界面的基本信息显示和要 hook 拦截的分区路径)
# 这里使用 sed 流编辑器修改其中的版本声明等字符串以便于用户知道这是一款什么样的内核包
if [ -f anykernel.sh ]; then
    echo "正在向 anykernel.sh 注入设备标识和 commit 摘要..."
    # 替换原本的显示名为 OnePlus SM8550 
    sed -i "s/kernel.string=.*/kernel.string=OnePlus SM8550 Custom Kernel/" anykernel.sh
    # 将版本号强行设定为传递进来的这串特定的提交哈希值
    sed -i "s/kernel.version=.*/kernel.version=${KERNEL_COMMIT}/" anykernel.sh
fi

echo "✅ AnyKernel3 目录结构已准备就绪，位于 $WORKSPACE/AnyKernel3"
echo "你可以接着把整个文件夹打包为 zip 发行！"
