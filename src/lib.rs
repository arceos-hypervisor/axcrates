//! Meta crate for the ArceOS Hypervisor workspace.
//!
//! This crate is a distribution bundle so users can fetch the full
//! hypervisor workspace via crates.io tooling (for example, cargo-clone).
//!
//! # Usage
//!
//! After cloning this crate via `cargo clone axcrates`, you can
//! extract all the submodules by running:
//!
//! ```bash
//! bash scripts/extract_submodules.sh
//! ```
//!
//! This will extract all component crates from the bundle directory,
//! enabling you to build and develop the full workspace.
//!
//! # Components
//!
//! The bundle contains:
//! - **arm_vcpu**: AArch64 VCPU implementation for ArceOS Hypervisor
//! - **arm_vgic**: ARM Virtual Generic Interrupt Controller (VGIC) implementation

/// Crate identifier for the workspace bundle.
pub const BUNDLE_NAME: &str = "axcrates";

/// Version of the bundle.
pub const BUNDLE_VERSION: &str = "0.1.0";

/// List of all included submodule crates.
pub const SUBMODULE_CRATES: &[&str] = &[
    "arm_vcpu",
    "arm_vgic",
];
