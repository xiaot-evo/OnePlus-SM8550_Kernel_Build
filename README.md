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

## Usage

1. Go to [Actions](https://github.com/xiaot-evo/OnePlus-SM8550_Kernel_Build/actions)
2. Click "Build Kernel"
3. Select kernel source, branch, KSU type, and SUSFS option
4. Click "Run workflow"

## Manual Build

```bash
# Clone kernel source
git clone --depth=1 -b <branch> https://github.com/<source>/android_kernel_oneplus_sm8550.git sm8550
cd sm8550

# Install LLVM (requires LLVM 21)
export LLVM=1
export LLVM_IAS=1
export CC=clang
export CXX=clang++

# Configure and build
make ARCH=arm64 O=out gki_defconfig vendor/kalama_GKI.config vendor/oplus/kalama_GKI.config vendor/debugfs.config
make -j$(nproc) ARCH=arm64 O=out Image
```

## Project Structure

```
.
├── .github/
│   ├── actions/           # Custom actions
│   └── workflows/         # CI/CD workflows
├── patches/               # Kernel patches
├── scripts/               # Build scripts
├── configs/               # Kernel configs
└── README.md
```

## Dependencies

- LLVM/Clang 21+
- Python 3
- Build tools: bc, bison, flex, libssl-dev, libelf-dev
- Git

## License

GPL-2.0
