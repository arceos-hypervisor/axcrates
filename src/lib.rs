//! Meta crate for the ArceOS Hypervisor workspace.
//!
//! This crate is a distribution bundle so users can fetch the full
//! hypervisor workspace via crates.io tooling (for example, cargo-clone).
//!
//! # Overview
//!
//! The AxCrates workspace provides a modular, multi-architecture hypervisor
//! framework built on ArceOS. It supports:
//!
//! - **AArch64**: ARM Virtualization Extensions (EL2)
//! - **x86_64**: Intel VT-x / AMD-V (VMX/SVM)
//! - **RISC-V**: H-extension for hypervisor mode
//!
//! # Usage
//!
//! After cloning this crate via `cargo clone axcrates`, you can
//! extract all the submodules by running:
//!
//! ```bash
//! bash scripts/unpack.sh
//! ```
//!
//! This will extract all component crates from the bundle directory,
//! enabling you to build and develop the full workspace.
//!
//! # Components
//!
//! ## Core Components
//!
//! - **axaddrspace**: Guest address space management module
//! - **axvmconfig**: VM configuration tool with TOML support
//! - **axhvc**: HyperCall definitions for guest-hypervisor communication
//! - **axvcpu**: Virtual CPU abstraction layer
//! - **axvisor_api**: Basic API for hypervisor components
//! - **axdevice_base**: Basic traits and structures for emulated devices
//! - **axdevice**: Reusable device abstraction layer
//! - **axvm**: Virtual machine resource management
//!
//! ## Architecture-Specific Components
//!
//! ### AArch64
//! - **arm_vcpu**: AArch64 VCPU implementation
//! - **arm_vgic**: ARM Virtual Generic Interrupt Controller (VGIC)
//!
//! ### x86_64
//! - **x86_vcpu**: x86_64 VCPU implementation with VMX support
//! - **x86_vlapic**: x86 Virtual Local APIC
//!
//! ### RISC-V
//! - **riscv_vcpu**: RISC-V VCPU implementation with H-extension
//! - **riscv-h**: RISC-V virtualization-related registers
//!
//! # Dependency Layers
//!
//! The crates are organized in dependency layers:
//!
//! ```text
//! Layer 0: axaddrspace, axvmconfig, axhvc, riscv-h (no internal deps)
//! Layer 1: axdevice_base, axvisor_api, axvcpu (depend on L0)
//! Layer 2: arm_vgic, x86_vlapic (depend on L0-L1)
//! Layer 3: arm_vcpu, x86_vcpu, riscv_vcpu (depend on L0-L2)
//! Layer 4: axdevice (depend on L0-L3)
//! Layer 5: axvm (depend on L0-L4)
//! ```

/// Crate identifier for the workspace bundle.
pub const BUNDLE_NAME: &str = "axcrates";

/// Version of the bundle.
pub const BUNDLE_VERSION: &str = "0.1.0";

/// Repository URL.
pub const REPOSITORY_URL: &str = "https://github.com/arceos-hypervisor/axcrates";

/// Documentation URL.
pub const DOCUMENTATION_URL: &str = "https://docs.rs/axcrates";

/// List of all included submodule crates.
pub const SUBMODULE_CRATES: &[&str] = &[
    // Layer 0: Basic components (no internal dependencies)
    "axaddrspace",
    "axvmconfig",
    "axhvc",
    "riscv-h",
    // Layer 1: Core components
    "axdevice_base",
    "axvisor_api",
    "axvcpu",
    // Layer 2: Interrupt controllers
    "arm_vgic",
    "x86_vlapic",
    // Layer 3: Architecture-specific VCPU
    "arm_vcpu",
    "x86_vcpu",
    "riscv_vcpu",
    // Layer 4: Device abstraction
    "axdevice",
    // Layer 5: VM management
    "axvm",
];

/// Core components (no architecture-specific code).
pub const CORE_CRATES: &[&str] = &[
    "axaddrspace",
    "axvmconfig",
    "axhvc",
    "axvcpu",
    "axvisor_api",
    "axdevice_base",
    "axdevice",
    "axvm",
];

/// AArch64-specific components.
pub const AARCH64_CRATES: &[&str] = &["arm_vcpu", "arm_vgic"];

/// x86_64-specific components.
pub const X86_64_CRATES: &[&str] = &["x86_vcpu", "x86_vlapic"];

/// RISC-V-specific components.
pub const RISCV_CRATES: &[&str] = &["riscv_vcpu", "riscv-h"];

/// Returns the total number of included crates.
pub fn crate_count() -> usize {
    SUBMODULE_CRATES.len()
}

/// Returns the number of core crates.
pub fn core_crate_count() -> usize {
    CORE_CRATES.len()
}

/// Returns the number of AArch64-specific crates.
pub fn aarch64_crate_count() -> usize {
    AARCH64_CRATES.len()
}

/// Returns the number of x86_64-specific crates.
pub fn x86_64_crate_count() -> usize {
    X86_64_CRATES.len()
}

/// Returns the number of RISC-V-specific crates.
pub fn riscv_crate_count() -> usize {
    RISCV_CRATES.len()
}
