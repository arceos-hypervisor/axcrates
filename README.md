# axcrates

ArceOS Hypervisor 组件汇总仓库。

## 简介

本仓库是一个 **meta crate**，用于将 ArceOS Hypervisor 的所有组件打包发布到 crates.io，方便用户通过 `cargo clone` 获取完整的工作区。

这是一个面向虚拟化开发的教学与生产级组件化 Hypervisor 框架，支持多种架构（AArch64、x86_64、RISC-V），可用于学习虚拟化技术或构建生产级 Hypervisor。

## 组件列表

### 核心组件

| 组件 | 描述 |
|------|------|
| **axaddrspace** | Guest 地址空间管理模块，提供内存虚拟化支持 |
| **axvmconfig** | VM 配置工具，支持 TOML 格式的虚拟机配置 |
| **axhvc** | HyperCall 定义，用于 Guest-Hypervisor 通信 |
| **axvcpu** | 虚拟 CPU 抽象层，定义 VCPU 通用接口 |
| **axvisor_api** | Hypervisor 基础 API，提供组件间统一接口 |
| **axdevice_base** | 设备模拟基础 trait 和结构 |
| **axdevice** | 设备抽象层，提供可复用的设备模拟组件 |
| **axvm** | 虚拟机资源管理，整合 VCPU、内存、设备等资源 |

### 架构相关组件

#### AArch64
| 组件 | 描述 |
|------|------|
| **arm_vcpu** | AArch64 VCPU 实现，提供 ARM 虚拟化支持 |
| **arm_vgic** | ARM 虚拟通用中断控制器 (VGIC) 实现 |

#### x86_64
| 组件 | 描述 |
|------|------|
| **x86_vcpu** | x86_64 VCPU 实现，支持 VMX 扩展 |
| **x86_vlapic** | x86 虚拟 Local APIC 实现 |

#### RISC-V
| 组件 | 描述 |
|------|------|
| **riscv_vcpu** | RISC-V VCPU 实现，支持 H 扩展 |
| **riscv-h** | RISC-V 虚拟化相关寄存器定义 |

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

解包后将得到完整目录（包含所有组件）。

### 方式 B：直接克隆仓库

```bash
git clone --recurse-submodules https://github.com/arceos-hypervisor/axcrates.git
cd axcrates
```

### 获取单独的组件

```bash
# 核心组件
cargo clone axaddrspace
cargo clone axvcpu
cargo clone axvm

# 架构相关组件
cargo clone arm_vcpu
cargo clone arm_vgic
cargo clone x86_vcpu
cargo clone riscv_vcpu
```

## 环境要求

- Rust toolchain: stable
- 目标架构:
  - `aarch64-unknown-none-elf` (ARM64)
  - `x86_64-unknown-none` (x86_64)
  - `riscv64gc-unknown-none-elf` (RISC-V 64)
- 组件: `rust-src`, `llvm-tools-preview`
- QEMU: `qemu-system-aarch64`, `qemu-system-x86_64`, `qemu-system-riscv64`

## 项目结构

```
axcrates/
├── Cargo.toml              # 元包配置
├── README.md               # 本文档
├── src/lib.rs              # 元包库代码
├── bundle/
│   └── submodules.tar.gz   # 子模块压缩包
├── scripts/
│   ├── crates.txt          # crate 列表
│   ├── compress_submodules.sh  # 压缩子模块
│   ├── extract_submodules.sh   # 解压子模块
│   ├── publish-all.sh      # 发布到 crates.io
│   ├── bump-version.sh     # 版本升级
│   ├── git-commit-push.sh  # Git 提交推送
│   └── git-tag-push.sh     # Git 标签管理
├── arm_vcpu/               # AArch64 VCPU
├── arm_vgic/               # ARM VGIC
├── axaddrspace/            # 地址空间管理
├── axdevice/               # 设备抽象层
├── axdevice_base/          # 设备基础
├── axhvc/                  # HyperCall
├── axvcpu/                 # VCPU 抽象
├── axvm/                   # VM 管理
├── axvmconfig/             # VM 配置
├── axvisor_api/            # Hypervisor API
├── riscv_vcpu/             # RISC-V VCPU
├── riscv-h/                # RISC-V H 扩展
├── x86_vcpu/               # x86 VCPU
└── x86_vlapic/             # x86 vLAPIC
```

## 维护者脚本

### 打包子模块

```bash
bash scripts/compress_submodules.sh
```

### 版本升级

```bash
bash scripts/bump-version.sh 0.2.0
```

### 发布到 crates.io

```bash
# 需要先登录 crates.io
cargo login <your-token>

# 按依赖顺序发布所有 crate
bash scripts/publish-all.sh
```

### Git 操作

```bash
# 提交并推送
bash scripts/git-commit-push.sh "feat: add new feature"

# 创建并推送标签
bash scripts/git-tag-push.sh v0.2.0
```

## 依赖关系图

```
Layer 0 (基础组件，无内部依赖):
  axaddrspace, axvmconfig, axhvc, riscv-h

Layer 1 (核心组件):
  axdevice_base, axvisor_api, axvcpu

Layer 2 (中断控制器):
  arm_vgic, x86_vlapic

Layer 3 (架构 VCPU):
  arm_vcpu, x86_vcpu, riscv_vcpu

Layer 4 (设备抽象):
  axdevice

Layer 5 (VM 管理):
  axvm
```

## 许可证

Apache-2.0
