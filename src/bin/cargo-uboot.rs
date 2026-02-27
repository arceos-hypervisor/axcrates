//! Cargo subcommand wrapper for run_uboot.sh
//! Usage: cargo run --bin cargo-uboot -- [args]

use std::env;
use std::path::PathBuf;
use std::process::Command;

fn main() {
    let manifest_dir = env::var("CARGO_MANIFEST_DIR").unwrap_or_else(|_| ".".to_string());
    let script_path = PathBuf::from(&manifest_dir)
        .join("scripts")
        .join("run_uboot.sh");

    let args: Vec<String> = env::args().skip(1).collect();

    let status = Command::new("bash")
        .arg(&script_path)
        .args(&args)
        .status()
        .expect("Failed to execute run_uboot.sh");

    std::process::exit(status.code().unwrap_or(1));
}
