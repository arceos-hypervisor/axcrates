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
//! # Submodules
//!
//! This bundle contains two categories of submodules:
//!
//! ## Components (`components/`)
//!
//! All component crates including:
//! - Hypervisor core (axaddrspace, axvcpu, axvm, etc.)
//! - Architecture-specific virtualization (arm_vcpu, x86_vcpu, riscv_vcpu, etc.)
//! - Memory management, device drivers, utilities, and more
//!
//! See [`SUBMODULE_CRATES`] for the complete list.
//!
//! ## OS Submodules (`os/`)
//!
//! - **axvisor**: AxVisor hypervisor implementation
//! - **StarryOS**: StarryOS operating system

/// Crate identifier for the workspace bundle.
pub const BUNDLE_NAME: &str = "axcrates";

/// Version of the bundle.
pub const BUNDLE_VERSION: &str = "0.2.0";

/// Repository URL.
pub const REPOSITORY_URL: &str = "https://github.com/arceos-hypervisor/axcrates";

/// Documentation URL.
pub const DOCUMENTATION_URL: &str = "https://docs.rs/axcrates";

/// List of all included submodule crates from components/ directory.
pub const SUBMODULE_CRATES: &[&str] = &[
    // Architecture-specific registers
    "aarch64_sysreg",
    // UART drivers
    "any-uart",
    "arm_pl011",
    "arm_pl031",
    // ArceOS framework
    "arceos",
    // ARM GIC driver
    "arm-gic-driver",
    // ARM Virtualization
    "arm_vcpu",
    "arm_vgic",
    // Axvisor Core Components
    "axaddrspace",
    "axvmconfig",
    "axhvc",
    "axdevice_base",
    "axvisor_api",
    "axvcpu",
    "axdevice",
    "axvm",
    // Memory management
    "axallocator",
    "axmm_crates",
    "bitmap-allocator",
    "page_table_multiarch",
    "range-alloc-arceos",
    // Platform abstraction
    "axplat_crates",
    "axcpu",
    // Utilities
    "axbacktrace",
    "axconfig-gen",
    "axerrno",
    "axfs-ng-vfs",
    "axio",
    "axklib",
    "axpoll",
    "axsched",
    // Drivers
    "axdriver_crates",
    "virtio-drivers",
    // Capabilities and access control
    "cap_access",
    "cpumask",
    // Concurrency and synchronization
    "crate_interface",
    "ctor_bare",
    "kernel_guard",
    "kspin",
    "lazyinit",
    "percpu",
    "scope-local",
    // Data structures
    "handler_table",
    "int_ratio",
    "linked_list_r4l",
    "timer_list",
    // RISC-V Virtualization
    "riscv-h",
    "riscv_plic",
    "riscv_vcpu",
    "riscv_vplic",
    // x86 Virtualization
    "x86_vcpu",
    "x86_vlapic",
    // StarryOS
    "starry-process",
    "starry-signal",
    "starry-smoltcp",
    "starry-vm",
    // File system
    "rsext4",
    // HAL
    "somehal",
];

/// OS-level submodules from os/ directory.
pub const OS_SUBMODULES: &[&str] = &["axvisor", "StarryOS"];

/// Returns the number of component crates.
pub fn component_count() -> usize {
    SUBMODULE_CRATES.len()
}

/// Returns the number of OS-level submodules.
pub fn os_count() -> usize {
    OS_SUBMODULES.len()
}

/// Returns the total number of all submodules (components + OS).
pub fn total_count() -> usize {
    SUBMODULE_CRATES.len() + OS_SUBMODULES.len()
}
