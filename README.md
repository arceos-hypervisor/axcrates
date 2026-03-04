# axcrates

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

ArceOS 组件统一管理仓库，通过 Git Submodule 关联所有组件，提供统一的版本管理和协同开发脚本。

> 📋 详细文档请参考 [协同开发方案](docs/协同开发方案.md) 和 [组件开发及管理规范](https://github.com/orgs/arceos-hypervisor/discussions/371)。

---

## 一、仓库架构

### 1.1 开发方式

| 方式 | 适用场景 | 特点 |
|------|----------|------|
| **独立子仓库开发** | 单组件修改 | 直接克隆子仓库，轻量快捷 |
| **axcrates 统一仓库开发** | 跨组件协作 | 通过主仓库统一管理所有组件 |

### 1.2 组件列表

| 组件 | 分类 | 描述 |
|------|------|------|
| axaddrspace | 核心 | Guest 地址空间管理，内存虚拟化 |
| axvmconfig | 核心 | VM 配置工具，TOML 格式支持 |
| axhvc | 核心 | HyperCall 定义，Guest-Hypervisor 通信 |
| axvcpu | 核心 | VCPU 抽象层，通用接口定义 |
| axvisor_api | 核心 | Hypervisor 基础 API |
| axdevice_base | 核心 | 设备模拟基础 trait |
| axdevice | 核心 | 设备抽象层 |
| axvm | 核心 | VM 资源管理 |
| arm_vcpu | AArch64 | ARM VCPU 实现 |
| arm_vgic | AArch64 | 虚拟中断控制器 |
| x86_vcpu | x86_64 | x86 VCPU 实现 (VMX) |
| x86_vlapic | x86_64 | 虚拟 Local APIC |
| riscv_vcpu | RISC-V | RISC-V VCPU 实现 |
| riscv-h | RISC-V | H 扩展寄存器定义 |

### 1.3 组件依赖关系

```
Layer 0 (基础)     Layer 1 (核心)     Layer 2 (中断)     Layer 3 (架构VCPU)  Layer 4 (设备)   Layer 5 (VM)
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  ┌─────────────┐
│ axaddrspace │───►│ axdevice_   │───►│  arm_vgic   │───►│  arm_vcpu   │───►│             │  │             │
│ axvmconfig  │    │    base     │    │ x86_vlapic  │    │  x86_vcpu   │───►│  axdevice   │─►│    axvm     │
│ axhvc       │    │ axvisor_api │    └─────────────┘    │ riscv_vcpu  │    │             │  │             │
│ riscv-h     │    │   axvcpu    │                       └─────────────┘    └─────────────┘  └─────────────┘
└─────────────┘    └─────────────┘
```

---

## 二、环境准备

### 2.1 Git 配置

```bash
# 配置用户信息
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 配置 SSH 密钥（如已有可跳过）
ssh-keygen -t ed25519 -C "your.email@example.com"
cat ~/.ssh/id_ed25519.pub  # 添加到 GitHub SSH keys
```

### 2.2 Rust 工具链

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

## 三、开发工作流

### 3.1 工作流选择

```
开始开发
    │
    ├── 只修改单个组件？ ──► 独立子仓库开发 (3.2)
    │
    └── 需要修改多个组件？ ──► axcrates 统一开发 (3.3)
```

### 3.2 独立子仓库开发

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

### 3.3 axcrates 统一开发

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

---

## 四、维护脚本

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

## 五、版本发布

所有组件使用相同版本号，通过 axcrates 仓库统一发布：

### 5.1 预览版（dev 分支）

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

### 5.2 稳定版（main 分支）

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

## 六、快速体验

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

## 许可证

[Apache-2.0](LICENSE)
