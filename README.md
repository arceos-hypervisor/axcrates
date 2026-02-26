# axcrates

ArceOS Hypervisor 组件汇总仓库。

## 简介

本仓库是一个 **meta crate**，用于将 ArceOS Hypervisor 的所有组件打包发布到 crates.io，方便用户通过 `cargo clone` 获取完整的工作区。

## 组件列表

- **arm_vcpu**: AArch64 VCPU 实现，为 ArceOS Hypervisor 提供虚拟 CPU 支持
- **arm_vgic**: ARM 虚拟通用中断控制器 (VGIC) 实现

## 如何使用

### 方式 A：通过 crates.io 获取（推荐）

先安装 cargo-clone：

```bash
cargo install cargo-clone
```

拉取集合包并解包完整工作区：

```bash
cargo clone axcrates
cd axcrates
bash scripts/extract_submodules.sh
```

解包后将得到完整目录（包含 arm_vcpu、arm_vgic 等组件）。

### 方式 B：直接克隆仓库

```bash
git clone --recurse-submodules https://github.com/arceos-hypervisor/axcrates.git
cd axcrates
```

### 获取单独的组件

```bash
cargo clone arm_vcpu
cargo clone arm_vgic
```

## 环境要求

- Rust toolchain: stable
- 目标架构: `aarch64-unknown-none-elf`
- 组件: `rust-src`, `llvm-tools-preview`

## 打包发布

维护者可以使用打包脚本创建分发包：

```bash
cd axcrates
bash scripts/compress_submodules.sh
```

这会将所有子模块打包到 `bundle/submodules.tar.gz`。

## 许可证

Apache-2.0
