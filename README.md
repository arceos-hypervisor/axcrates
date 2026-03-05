# axcrates

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

---

## 一、简介

ArceOS 组件统一管理仓库，通过 Git Submodule 关联所有组件，提供统一的版本管理和协同开发脚本。

> 📋 详细文档请参考 [协同开发方案](docs/协同开发方案.md) 和 [组件开发及管理规范](https://github.com/orgs/arceos-hypervisor/discussions/371)。

### 1.1 目录结构

```
axcrates/
├── components/         # 独立组件
│   ├── arceos/         # ArceOS 主仓库，内含多个组件
│   ├── axaddrspace/    # 地址空间管理
│   ├── axdevice/       # 设备抽象层
│   ├── axvcpu/         # VCPU 抽象层
│   ├── axvm/           # VM 管理
│   └── ...             # 其他组件
├── os/                 # 顶层 OS，同时也是一个独立 crates
│   └── axvisor/        # Axvisor
├── scripts/            # 维护脚本
└── docs/               # 文档
```

### 1.2 维护脚本

| 脚本 | 用法 | 说明 |
|------|------|------|
| checkout.sh | `bash scripts/checkout.sh all dev` | 批量切换分支 |
| | `bash scripts/checkout.sh reset all` | 恢复所有组件到默认分支 |
| check.sh | `bash scripts/check.sh all` | 批量代码检查（fmt/clippy/doc） |
| reset.sh | `bash scripts/reset.sh all` | 撤销所有组件的更改 |
| commit.sh | `bash scripts/commit.sh all "msg"` | 批量提交组件变更 |
| push.sh | `bash scripts/push.sh all` | 批量推送组件 |
| sync.sh | `bash scripts/sync.sh all dev` | 同步子模块到远程最新 |
| version.sh | `bash scripts/version.sh all 0.2.0` | 批量更新版本号 |
| tag.sh | `bash scripts/tag.sh all v0.2.0` | 批量创建标签 |
| publish.sh | `bash scripts/publish.sh` | 发布到 crates.io |
| pack.sh | `bash scripts/pack.sh` | 打包子模块 |
| unpack.sh | `bash scripts/unpack.sh` | 解包子模块 |

---

## 二、组件

| 组织 | 组件数量 | Submodule 数量 | 备注 |
|-----|---------|---------------|------|
| arceos-hypervisor | 18 | 17 | **axvisor_api：** axvisor_api, axvisor_api_proc <br> 其他独立 |
| arceos-org | 37 | 19 | **arceos：** arceos_api, axalloc, axconfig, axfeat, axhal, axlog, axmm, axruntime, axstd, axsync, axtask <br> **axmm_crates：** memory_addr, memory_set <br> **axconfig-gen：** axconfig-gen, axconfig-macros <br> **axplat_crates：** axplat, axplat-macros <br> **page_table_multiarch：** page_table_entry, page_table_multiarch <br> **percpu：** percpu, percpu-macros <br> **ctor_bare：** ctor_bare, ctor_bare_macros <br> 其他独立 |
| rcore-os | 1 | 1 | 每个组件独立仓库 |
| **总计** | **56** | **37** | |

### 2.1 arceos-hypervisor 组织组件

| 组件名称 | crates.io | 仓库地址 | Submodule 路径 | 描述 |
|---------|:--------:|---------|---------------|------|
| axvisor | [![Crates.io](https://img.shields.io/crates/v/axvisor)](https://crates.io/crates/axvisor) | https://github.com/arceos-hypervisor/axvisor | `os/axvisor` | ArceOS Hypervisor 主项目 |
| axaddrspace | [![Crates.io](https://img.shields.io/crates/v/axaddrspace)](https://crates.io/crates/axaddrspace) | https://github.com/arceos-hypervisor/axaddrspace | `components/axaddrspace` | Guest 地址空间管理 |
| axdevice | [![Crates.io](https://img.shields.io/crates/v/axdevice)](https://crates.io/crates/axdevice) | https://github.com/arceos-hypervisor/axdevice | `components/axdevice` | 设备抽象层 |
| axdevice_base | [![Crates.io](https://img.shields.io/crates/v/axdevice_base)](https://crates.io/crates/axdevice_base) | https://github.com/arceos-hypervisor/axdevice_base | `components/axdevice_base` | 设备模拟基础 trait |
| axhvc | [![Crates.io](https://img.shields.io/crates/v/axhvc)](https://crates.io/crates/axhvc) | https://github.com/arceos-hypervisor/axhvc | `components/axhvc` | HyperCall 定义 |
| axklib | [![Crates.io](https://img.shields.io/crates/v/axklib)](https://crates.io/crates/axklib) | https://github.com/arceos-hypervisor/axklib | `components/axklib` | 内核库 |
| axvcpu | [![Crates.io](https://img.shields.io/crates/v/axvcpu)](https://crates.io/crates/axvcpu) | https://github.com/arceos-hypervisor/axvcpu | `components/axvcpu` | VCPU 抽象层 |
| axvisor_api | [![Crates.io](https://img.shields.io/crates/v/axvisor_api)](https://crates.io/crates/axvisor_api) | https://github.com/arceos-hypervisor/axvisor_api | `components/axvisor_api` | Hypervisor API |
| axvisor_api_proc | [![Crates.io](https://img.shields.io/crates/v/axvisor_api_proc)](https://crates.io/crates/axvisor_api_proc) | https://github.com/arceos-hypervisor/axvisor_api | `components/axvisor_api` | Hypervisor API 宏（同仓库） |
| axvm | [![Crates.io](https://img.shields.io/crates/v/axvm)](https://crates.io/crates/axvm) | https://github.com/arceos-hypervisor/axvm | `components/axvm` | VM 资源管理 |
| axvmconfig | [![Crates.io](https://img.shields.io/crates/v/axvmconfig)](https://crates.io/crates/axvmconfig) | https://github.com/arceos-hypervisor/axvmconfig | `components/axvmconfig` | VM 配置工具 |
| range-alloc | [![Crates.io](https://img.shields.io/crates/v/range-alloc)](https://crates.io/crates/range-alloc) | https://github.com/arceos-hypervisor/range-alloc | `components/range-alloc-arceos` | 范围分配器 |
| x86_vcpu | [![Crates.io](https://img.shields.io/crates/v/x86_vcpu)](https://crates.io/crates/x86_vcpu) | https://github.com/arceos-hypervisor/x86_vcpu | `components/x86_vcpu` | x86 VCPU 实现 |
| x86_vlapic | [![Crates.io](https://img.shields.io/crates/v/x86_vlapic)](https://crates.io/crates/x86_vlapic) | https://github.com/arceos-hypervisor/x86_vlapic | `components/x86_vlapic` | x86 虚拟 Local APIC |
| arm_vcpu | [![Crates.io](https://img.shields.io/crates/v/arm_vcpu)](https://crates.io/crates/arm_vcpu) | https://github.com/arceos-hypervisor/arm_vcpu | `components/arm_vcpu` | ARM VCPU 实现 |
| arm_vgic | [![Crates.io](https://img.shields.io/crates/v/arm_vgic)](https://crates.io/crates/arm_vgic) | https://github.com/arceos-hypervisor/arm_vgic | `components/arm_vgic` | ARM 虚拟中断控制器 |
| riscv_vcpu | [![Crates.io](https://img.shields.io/crates/v/riscv_vcpu)](https://crates.io/crates/riscv_vcpu) | https://github.com/arceos-hypervisor/riscv_vcpu | `components/riscv_vcpu` | RISC-V VCPU 实现 |
| riscv-h | [![Crates.io](https://img.shields.io/crates/v/riscv-h)](https://crates.io/crates/riscv-h) | https://github.com/arceos-hypervisor/riscv-h | `components/riscv-h` | RISC-V H 扩展寄存器 |

### 2.2 arceos-org 组织组件

| 组件名称 | crates.io | 仓库地址 | Submodule 路径 | 描述 |
|---------|:--------:|---------|---------------|------|
| arceos_api | [![Crates.io](https://img.shields.io/crates/v/arceos_api)](https://crates.io/crates/arceos_api) | https://github.com/arceos-org/arceos | `components/arceos` (同仓库) | ArceOS API |
| axalloc | [![Crates.io](https://img.shields.io/crates/v/axalloc)](https://crates.io/crates/axalloc) | https://github.com/arceos-org/arceos | `components/arceos` (同仓库) | 内存分配模块 |
| axallocator | [![Crates.io](https://img.shields.io/crates/v/axallocator)](https://crates.io/crates/axallocator) | https://github.com/arceos-org/allocator | `components/axallocator` | 内存分配器接口 |
| axbacktrace | [![Crates.io](https://img.shields.io/crates/v/axbacktrace)](https://crates.io/crates/axbacktrace) | https://github.com/Starry-OS/axbacktrace | `components/axbacktrace` | 调用栈回溯 |
| axconfig | [![Crates.io](https://img.shields.io/crates/v/axconfig)](https://crates.io/crates/axconfig) | https://github.com/arceos-org/arceos | `components/arceos` (同仓库) | 配置模块 |
| axconfig-gen | [![Crates.io](https://img.shields.io/crates/v/axconfig-gen)](https://crates.io/crates/axconfig-gen) | https://github.com/arceos-org/axconfig-gen | `components/axconfig-gen` | 配置生成工具 |
| axconfig-macros | [![Crates.io](https://img.shields.io/crates/v/axconfig-macros)](https://crates.io/crates/axconfig-macros) | https://github.com/arceos-org/axconfig-gen | `components/axconfig-gen` (同仓库) | 配置宏 |
| axcpu | [![Crates.io](https://img.shields.io/crates/v/axcpu)](https://crates.io/crates/axcpu) | https://github.com/arceos-org/axcpu | `components/axcpu` | CPU 抽象层 |
| axerrno | [![Crates.io](https://img.shields.io/crates/v/axerrno)](https://crates.io/crates/axerrno) | https://github.com/arceos-org/axerrno | `components/axerrno` | 错误码定义 |
| axfeat | [![Crates.io](https://img.shields.io/crates/v/axfeat)](https://crates.io/crates/axfeat) | https://github.com/arceos-org/arceos | `components/arceos` (同仓库) | 特性管理 |
| axhal | [![Crates.io](https://img.shields.io/crates/v/axhal)](https://crates.io/crates/axhal) | https://github.com/arceos-org/arceos | `components/arceos` (同仓库) | 硬件抽象层 |
| axio | [![Crates.io](https://img.shields.io/crates/v/axio)](https://crates.io/crates/axio) | https://github.com/arceos-org/axio | `components/axio` | IO 抽象 |
| axlog | [![Crates.io](https://img.shields.io/crates/v/axlog)](https://crates.io/crates/axlog) | https://github.com/arceos-org/arceos | `components/arceos` (同仓库) | 日志模块 |
| axmm | [![Crates.io](https://img.shields.io/crates/v/axmm)](https://crates.io/crates/axmm) | https://github.com/arceos-org/arceos | `components/arceos` (同仓库) | 内存管理模块 |
| axplat | [![Crates.io](https://img.shields.io/crates/v/axplat)](https://crates.io/crates/axplat) | https://github.com/arceos-org/axplat_crates | `components/axplat_crates` | 平台抽象层 |
| axplat-macros | [![Crates.io](https://img.shields.io/crates/v/axplat-macros)](https://crates.io/crates/axplat-macros) | https://github.com/arceos-org/axplat_crates | `components/axplat_crates` (同仓库) | 平台抽象层宏 |
| axruntime | [![Crates.io](https://img.shields.io/crates/v/axruntime)](https://crates.io/crates/axruntime) | https://github.com/arceos-org/arceos | `components/arceos` (同仓库) | 运行时模块 |
| axsched | [![Crates.io](https://img.shields.io/crates/v/axsched)](https://crates.io/crates/axsched) | https://github.com/arceos-org/axsched | `components/axsched` | 调度器 |
| axstd | [![Crates.io](https://img.shields.io/crates/v/axstd)](https://crates.io/crates/axstd) | https://github.com/arceos-org/arceos | `components/arceos` (同仓库) | 标准库 |
| axsync | [![Crates.io](https://img.shields.io/crates/v/axsync)](https://crates.io/crates/axsync) | https://github.com/arceos-org/arceos | `components/arceos` (同仓库) | 同步原语 |
| axtask | [![Crates.io](https://img.shields.io/crates/v/axtask)](https://crates.io/crates/axtask) | https://github.com/arceos-org/arceos | `components/arceos` (同仓库) | 任务管理 |
| cpumask | [![Crates.io](https://img.shields.io/crates/v/cpumask)](https://crates.io/crates/cpumask) | https://github.com/arceos-org/cpumask | `components/cpumask` | CPU 掩码 |
| crate_interface | [![Crates.io](https://img.shields.io/crates/v/crate_interface)](https://crates.io/crates/crate_interface) | https://github.com/arceos-org/crate_interface | `components/crate_interface` | Crate 接口宏 |
| ctor_bare_macros | [![Crates.io](https://img.shields.io/crates/v/ctor_bare_macros)](https://crates.io/crates/ctor_bare_macros) | https://github.com/arceos-org/ctor_bare | `components/ctor_bare` (同仓库) | 裸机构造器宏 |
| ctor_bare |  [![Crates.io](https://img.shields.io/crates/v/ctor_bare)](https://crates.io/crates/ctor_bare)  | https://github.com/arceos-org/ctor_bare | `components/ctor_bare` | 裸机构造器 |
| handler_table | [![Crates.io](https://img.shields.io/crates/v/handler_table)](https://crates.io/crates/handler_table) | https://github.com/arceos-org/handler_table | `components/handler_table` | 处理函数表 |
| kernel_guard | [![Crates.io](https://img.shields.io/crates/v/kernel_guard)](https://crates.io/crates/kernel_guard) | https://github.com/arceos-org/kernel_guard | `components/kernel_guard` | 内核临界区保护 |
| kspin | [![Crates.io](https://img.shields.io/crates/v/kspin)](https://crates.io/crates/kspin) | https://github.com/arceos-org/kspin | `components/kspin` | 内核自旋锁 |
| lazyinit | [![Crates.io](https://img.shields.io/crates/v/lazyinit)](https://crates.io/crates/lazyinit) | https://github.com/arceos-org/lazyinit | `components/lazyinit` | 延迟初始化 |
| linked_list_r4l | [![Crates.io](https://img.shields.io/crates/v/linked_list_r4l)](https://crates.io/crates/linked_list_r4l) | https://github.com/arceos-org/linked_list_r4l | `components/linked_list_r4l` | 链表实现 |
| memory_addr | [![Crates.io](https://img.shields.io/crates/v/memory_addr)](https://crates.io/crates/memory_addr) | https://github.com/arceos-org/axmm_crates | `components/axmm_crates` | 内存地址类型 |
| memory_set | [![Crates.io](https://img.shields.io/crates/v/memory_set)](https://crates.io/crates/memory_set) | https://github.com/arceos-org/axmm_crates | `components/axmm_crates` (同仓库) | 内存区域集合 |
| page_table_entry | [![Crates.io](https://img.shields.io/crates/v/page_table_entry)](https://crates.io/crates/page_table_entry) | https://github.com/arceos-org/page_table_multiarch | `components/page_table_multiarch` | 页表项 |
| page_table_multiarch | [![Crates.io](https://img.shields.io/crates/v/page_table_multiarch)](https://crates.io/crates/page_table_multiarch) | https://github.com/arceos-org/page_table_multiarch | `components/page_table_multiarch` (同仓库) | 多架构页表 |
| percpu | [![Crates.io](https://img.shields.io/crates/v/percpu)](https://crates.io/crates/percpu) | https://github.com/arceos-org/percpu | `components/percpu` | Per-CPU 变量 |
| percpu-macros | [![Crates.io](https://img.shields.io/crates/v/percpu-macros)](https://crates.io/crates/percpu-macros) | https://github.com/arceos-org/percpu | `components/percpu` (同仓库) | Per-CPU 宏 |
| timer_list |  [![Crates.io](https://img.shields.io/crates/v/timer_list)](https://crates.io/crates/timer_list) | https://github.com/arceos-org/timer_list | `components/timer_list` | 定时器列表 |

### 2.3 rcore-os 组织组件

| 组件名称 | crates.io | 仓库地址 | Submodule 路径 | 描述 |
|---------|:--------:|---------|---------------|------|
| bitmap-allocator | [![Crates.io](https://img.shields.io/crates/v/bitmap-allocator)](https://crates.io/crates/bitmap-allocator) | https://github.com/rcore-os/bitmap-allocator | `components/bitmap-allocator` | 位图分配器 |

### 2.4 组件依赖关系

#### AxVisor

参见 [Axvisor 组件依赖关系与层级图](docs/axvisor-dependency.md)

#### Starry

TODO

---

## 三、环境准备

### 3.1 Git 配置

```bash
# 配置用户信息
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 配置 SSH 密钥（如已有可跳过）
ssh-keygen -t ed25519 -C "your.email@example.com"
cat ~/.ssh/id_ed25519.pub  # 添加到 GitHub SSH keys
```

### 3.2 Rust 工具链

```bash
# 安装 Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# 安装目标架构
rustup target add aarch64-unknown-none-softfloat
rustup target add x86_64-unknown-none
rustup target add riscv64gc-unknown-none-elf

# 安装必要组件
rustup component add rust-src llvm-tools rustfmt clippy
```

---

## 四、快速开始

```bash
# 通过 crates.io 下载
cargo install cargo-clone
cargo clone axcrates
cd axcrates
bash scripts/unpack.sh

# 查看文档
cd axvcpu && cargo doc --open

# 编译组件
cd arm_vcpu && cargo build --target aarch64-unknown-none-softfloat
```

---

## 五、开发

### 5.1 开发方式选择

| 方式 | 适用场景 | 特点 |
|------|----------|------|
| **独立子仓库开发** | 单组件修改 | 直接克隆子仓库，轻量快捷 |
| **axcrates 统一仓库开发** | 跨组件协作 | 通过主仓库统一管理所有组件 |

```
开始开发
    │
    ├── 只修改单个组件？ ──► 独立子仓库开发 (5.2)
    │
    └── 需要修改多个组件？ ──► axcrates 统一开发 (5.3)
```

### 5.2 单组件开发

适用于只修改单个组件的场景：

```bash
# 1. 克隆子仓库
git clone git@github.com:arceos-hypervisor/axvcpu.git
cd axvcpu

# 2. 创建功能分支
git checkout dev && git pull
git checkout -b feature/new-api

# 3. 修改代码并检查
cargo fmt --check
cargo clippy -- -D warnings
cargo build

# 4. 提交并推送
git add . && git commit -m "feat: add new API"
git push origin feature/new-api

# 5. 创建 PR（dev 分支可直接合并，main 分支需 review）
```

### 5.3 多组件开发

适用于跨组件协作或版本发布：

```bash
# 1. 克隆主仓库（包含所有子模块）
git clone --recurse-submodules git@github.com:arceos-hypervisor/axcrates.git
cd axcrates

# 2. 切换所有组件到目标分支
bash scripts/checkout.sh all dev

# 3. 修改组件代码...

# 4. 批量代码检查
bash scripts/check.sh all

# 5. 批量提交
bash scripts/commit.sh all "feat: update APIs"

# 6. 批量推送
bash scripts/push.sh all
```

### 5.4 版本发布

所有组件使用相同版本号，通过 axcrates 仓库统一发布：

#### 5.4.1 预览版（dev 分支）

```bash
# 1. 升级版本号
bash scripts/version.sh all 0.2.0-preview.1

# 2. 提交并推送
bash scripts/commit.sh all "chore: release v0.2.0-preview.1"
bash scripts/push.sh all

# 3. 创建标签（可选）
bash scripts/tag.sh all v0.2.0-preview.1

# 4. 发布到 crates.io（可选）
cargo login && bash scripts/publish.sh
```

#### 5.4.2 稳定版（main 分支）

```bash
# 1. 升级版本号
bash scripts/version.sh all 0.2.0

# 2. 提交
bash scripts/commit.sh all "chore: release v0.2.0"

# 3. 创建 PR 到 main 分支并合并

# 4. 合并后，同步并打标签
git checkout main && git pull --recurse-submodules
bash scripts/sync.sh all main
bash scripts/tag.sh all v0.2.0

# 5. 发布到 crates.io
cargo login && bash scripts/publish.sh
```

---

## 六、许可证

[Apache-2.0](LICENSE)
