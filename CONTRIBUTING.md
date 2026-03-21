# 项目开发与使用指南 (Project Guide & Contributing)

欢迎来到 OnePlus SM8550 自动化内核构建项目！本项目旨在通过高度自动化的脚本与 GitHub Actions，为运行骁龙 8 Gen 2 (SM8550) 的 OnePlus 设备编译定制化内核。

为了保持项目的整洁、可维护以及便于本地调试，我们在最近的重构中将所有核心逻辑从 CI 配置文件中抽离，实现了**脚本化**和**模块化**。本指南将帮助你了解如何使用本项目、它的整体结构，以及在贡献代码时需要遵守的规范。

---

## 1. 项目结构 (Project Structure)

在项目的根目录下，包含以下核心目录：

```text
.
├── .github/
│   └── workflows/         # 存放 CI/CD 自动化构建配置文件 (如 build.yml)
├── configs/               # 存放内核编译的自定义配置文件 (如 custom.config)
├── patches/               # 存放通用的内核补丁文件 (*.patch)
├── scripts/               # 核心逻辑脚本目录 (本地与 CI 共用)
│   ├── install_ksu.sh     # 负责下载并注入不同的 KernelSU 变体
│   ├── install_susfs.sh   # 负责下载并打上 SUSFS 补丁
│   ├── config_kernel.sh   # 负责向内核配置文件动态注入编译选项 (如 LTO, KSU)
│   ├── build.sh           # 负责执行内核 make 编译的主脚本
│   ├── validate_build.sh  # 检查编译输出是否合法的验证脚本
│   └── package.sh         # 负责将 Image 打包为 AnyKernel3 刷机包的脚本
├── CONTRIBUTING.md        # 本项目指南
└── README.md              # 项目简介
```

---

## 2. 如何使用本项目 (How to Use)

### 2.1 云端编译 (GitHub Actions)

这是最推荐的使用方式，因为环境是完全统一且包含强大缓存的。
1. Fork 本项目到你的 GitHub 账号。
2. 进入 `Actions` 标签页，点击左侧的 **Build Kernel**。
3. 点击右侧的 **Run workflow**，在弹出的菜单中选择你需要的：
   - 内核源码库 (如 LineageOS 等)
   - 分支名称 (如 `android14` 或 `lineage-21`)
   - 想要的 KSU 版本和是否启用 SUSFS 及 LTO 优化。
4. 等待编译完成后，在页面的 Artifacts 中下载 AnyKernel3 刷机包即可。

### 2.2 本地编译测试 (Local Development)

由于所有逻辑都已被模块化到 `scripts/` 中，本地编译的流程和 CI 完全一致。

**环境准备：**
一台 Linux 机器（推荐 Ubuntu），并安装基础编译依赖：
```bash
sudo apt install bc bison build-essential cpio curl dwarves flex libssl-dev libelf-dev libdw-dev lz4 python3 git ccache patch unzip xz-utils
```
还需要安装 Clang/LLVM 环境（推荐版本 >= 21）。

**执行编译：**
```bash
# 1. 克隆本仓库
git clone https://github.com/xiaot-evo/OnePlus-SM8550_Kernel_Build.git
cd OnePlus-SM8550_Kernel_Build

# 2. 克隆你的目标内核源码到 sm8550 目录
git clone --depth=1 -b <目标分支> https://github.com/<源码作者>/android_kernel_oneplus_sm8550.git sm8550

# 3. 设置环境变量以配置编译选项
export KSU_TYPE="KernelSU-Next"    # 可选: None, KernelSU-Next, KowSU, ReSukiSU, ReSukiSU-Manual
export ENABLE_SUSFS="true"         # 是否启用 SUSFS
export ENABLE_LTO="true"           # 是否启用 LTO 优化
export KERNEL_BRANCH="android14"   # 源码分支，用于决定 KSU/SUSFS 使用的匹配脚本

# 4. 按顺序执行模块化脚本
bash scripts/install_ksu.sh
bash scripts/install_susfs.sh
bash scripts/config_kernel.sh

# 5. 执行内核编译
bash scripts/build.sh

# 6. 验证产物并打包
bash scripts/validate_build.sh
bash scripts/package.sh
```
打包成功后，产物会输出在项目根目录的 `AnyKernel3/` 文件夹中。

---

## 3. 代码开发与添加规范 (Coding Guidelines)

我们鼓励开发者为本项目添加新的特性（例如支持更多的 KSU 变体、添加新的性能优化配置等）。请在提交 Pull Request 前遵循以下规范：

### 3.1 Shell 脚本规范
- **环境变量驱动**：尽量避免使用 `$1`, `$2` 这种位置参数。所有脚本应使用统一的环境变量作为输入（例如 `KERNEL_DIR`, `WORKSPACE`, `KSU_TYPE`），并在脚本顶部赋予默认值。
  ```bash
  # ✅ 推荐做法
  WORKSPACE="${WORKSPACE:-$(pwd)}"
  KSU_TYPE="${KSU_TYPE:-None}"
  ```
- **错误即退出 (`set -e`)**：所有的 shell 脚本必须在第二行包含 `set -e`，以确保任何一条命令失败时脚本会立即停止，防止错误级联导致打出错误的刷机包。
- **输出清晰的日志**：在执行关键步骤时，使用 `echo` 打印清晰的提示信息，方便在 GitHub Actions 的日志面板中排错。

### 3.2 添加新的 KSU 或 Root 方案
如果你想添加对一种新的 KSU 变体的支持：
1. 打开 `scripts/install_ksu.sh`。
2. 在 `elif [ "$KSU_TYPE" = "..." ]; then` 逻辑中新增你的分支。
3. 确保安装命令能在非交互式环境（如 CI）下自动完成（如使用 `| bash -s main`）。
4. 在 `.github/workflows/build.yml` 的 `ksu_type` 输入选项 (`options`) 中添加你的新选项。

### 3.3 添加/修改内核配置 (Config)
- **动态配置**：如果配置项是可选的（例如仅在启用某功能时开启），请将其添加到 `scripts/config_kernel.sh` 中，使用 `echo "CONFIG_XXX=y" >> "$DEFCONFIG_FILE"` 的形式注入。
- **静态配置**：如果配置项是长期存在的通用优化，请将它们写入 `configs/custom.config` 中，并在 `config_kernel.sh` 中实现合并逻辑。

### 3.4 补丁管理规范 (Patches)
- 所有补丁应放在 `patches/` 目录下。
- 补丁命名应具有描述性，例如 `fix_wifi_driver.patch`。
- 如果某个补丁只在特定条件下应用，请在相应的 `scripts/` 脚本中编写 `if` 条件逻辑，利用 `patch -p1 < "$WORKSPACE/patches/xxx.patch"` 进行应用。

---

## 4. 提交流程 (Pull Request Flow)

1. 在你的 Fork 仓库中新建一个分支（例如 `feature/add-new-ksu`）。
2. 根据上述规范修改 `scripts/` 或 `build.yml`。
3. **关键：** 在提交 PR 之前，请务必在你个人的 Actions 中触发一次构建，确保该功能不会引起现有编译流程的崩溃。
4. 确认编译成功且产物（Image/Zip）正常后，提交 Pull Request。在 PR 描述中简要说明你添加的功能和解决的问题。

感谢你为 OnePlus SM8550_Kernel_Build 做出贡献！
