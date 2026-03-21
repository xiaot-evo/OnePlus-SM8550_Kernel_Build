# OnePlus SM8550 Kernel Build

Automated kernel build workflow for OnePlus devices powered by SM8550 (Snapdragon 8 Gen 2).

## Supported Devices

- OnePlus 11 (PHB110)
- OnePlus 12R (CPH2609)
- OnePlus Ace 2 (PHV110)

## Features

- **Multiple Kernel Sources**: crdroidandroid, LineageOS, OnePlus12R-development
- **Root Solutions**: 
  - KernelSU-Next
  - KowSU
  - ReSukiSU
  - ReSukiSU-Manual
- **SUSFS Support**: Optional SuperUser Sandbox Filesystem
- **Caching**: LLVM, sccache, Git references, build output
- **CI/CD Optimized**: GitHub Actions with comprehensive caching

## Usage (GitHub Actions)

1. Go to [Actions](https://github.com/xiaot-evo/OnePlus-SM8550_Kernel_Build/actions)
2. Click "Build Kernel"
3. Select kernel source, branch, KSU type, and SUSFS option
4. Click "Run workflow"

## Local Build Environment

This project is fully refactored to allow exact reproductions of the GitHub Actions workflow locally. All logic resides in `scripts/`.

### Prerequisites
- LLVM/Clang 21+
- Python 3
- Build tools: bc, bison, flex, libssl-dev, libelf-dev
- Git

### Build Instructions

```bash
# Clone this repository
git clone https://github.com/xiaot-evo/OnePlus-SM8550_Kernel_Build
cd OnePlus-SM8550_Kernel_Build

# 1. Clone your target kernel
git clone --depth=1 -b <branch> https://github.com/<source>/android_kernel_oneplus_sm8550.git sm8550

# 2. Configure build features using environment variables
export KSU_TYPE="KernelSU-Next" # Options: None, KernelSU-Next, KowSU, ReSukiSU, ReSukiSU-Manual
export ENABLE_SUSFS="true"
export ENABLE_LTO="true"
export KERNEL_BRANCH="android14"

# 3. Apply patches and configure the kernel
bash scripts/install_ksu.sh
bash scripts/install_susfs.sh
bash scripts/config_kernel.sh

# 4. Build the kernel
bash scripts/build.sh

# 5. Validate the output and package AnyKernel3
bash scripts/validate_build.sh
bash scripts/package.sh
```

## Project Structure

```
.
├── .github/
│   └── workflows/         # CI/CD workflows
├── patches/               # Kernel patches (e.g., resksu_manual_hooks.patch)
├── scripts/               # Build and patching logic (mirrors CI)
├── configs/               # Kernel configs overrides
└── README.md
```

## License

GPL-2.0
