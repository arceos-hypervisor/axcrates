#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd -P)
CRATES_FILE="${SCRIPT_DIR}/crates.txt"

# =============================================================================
# Colors and Output Functions
# =============================================================================

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

die() { printf '%b✗%b %s\n' "${RED}" "${NC}" "$*" >&2; exit 1; }
info() { printf '%b→%b %s\n' "${BLUE}" "${NC}" "$*"; }
success() { printf '%b✓%b %s\n' "${GREEN}" "${NC}" "$*"; }
warn() { printf '%b⚠%b %s\n' "${YELLOW}" "${NC}" "$*"; }

# =============================================================================
# Helper Functions
# =============================================================================

usage() {
    cat << EOF
组件版本管理脚本

用法:
  scripts/version.sh <crate|all> <version>

参数:
  crate     组件名称，如 axvcpu、axaddrspace 等
  all       更新所有组件版本号
  version   新版本号，如 0.2.0、0.2.0-preview.1

版本格式:
  稳定版: X.Y.Z (如 0.2.0)
  预览版: X.Y.Z-preview.N (如 0.2.0-preview.1)

示例:
  scripts/version.sh axvcpu 0.2.0              # 更新 axvcpu 版本
  scripts/version.sh axvcpu 0.2.0-preview.1    # 更新 axvcpu 为预览版
  scripts/version.sh all 0.2.0                 # 更新所有组件版本
  scripts/version.sh all 0.2.0-preview.1       # 更新所有组件为预览版
EOF
}

read_crates() {
    local crates=()
    while IFS= read -r crate || [[ -n "${crate}" ]]; do
        crate="${crate%$'\r'}"
        [[ -z "${crate}" ]] && continue
        crates+=("${crate}")
    done < "${CRATES_FILE}"
    printf '%s\n' "${crates[@]}"
}

validate_version() {
    local version="$1"
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
        die "版本格式无效: $version\n应为 X.Y.Z 或 X.Y.Z-suffix (如 0.2.0 或 0.2.0-preview.1)"
    fi
}

update_cargo_toml() {
    local file="$1" version="$2"
    local current_version
    
    [[ -f "${file}" ]] || return 0
    
    current_version=$(grep -m1 '^version = ' "${file}" | sed 's/version = "\(.*\)"/\1/')
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^version = \".*\"/version = \"${version}\"/" "${file}"
    else
        sed -i "s/^version = \".*\"/version = \"${version}\"/" "${file}"
    fi
    
    printf '%s' "${current_version}"
}

# =============================================================================
# Version Functions
# =============================================================================

version_crate() {
    local crate="$1" version="$2" crate_dir="${ROOT_DIR}/${crate}"
    local cargo_path="${crate_dir}/Cargo.toml"
    
    [[ -d "${crate_dir}" ]] || { warn "[${crate}] 目录不存在，跳过"; return 0; }
    [[ -f "${cargo_path}" ]] || { warn "[${crate}] Cargo.toml 不存在，跳过"; return 0; }
    
    local current_version
    current_version=$(update_cargo_toml "${cargo_path}" "${version}")
    
    if [[ -n "${current_version}" ]]; then
        success "[${crate}] ${current_version} → ${version}"
    else
        warn "[${crate}] 未找到版本号"
    fi
}

version_all() {
    local version="$1"
    local crates updated=() skipped=()
    mapfile -t crates < <(read_crates)
    
    info "更新所有组件版本号 (${#crates[@]} 个)..."
    
    for crate in "${crates[@]}"; do
        local cargo_path="${ROOT_DIR}/${crate}/Cargo.toml"
        if [[ -f "${cargo_path}" ]]; then
            local current_version
            current_version=$(update_cargo_toml "${cargo_path}" "${version}")
            if [[ -n "${current_version}" ]]; then
                success "[${crate}] ${current_version} → ${version}"
                updated+=("${crate}")
            else
                warn "[${crate}] 未找到版本号"
                skipped+=("${crate}")
            fi
        else
            warn "[${crate}] Cargo.toml 不存在"
            skipped+=("${crate}")
        fi
    done
    
    # 更新根 Cargo.toml
    local root_cargo="${ROOT_DIR}/Cargo.toml"
    if [[ -f "${root_cargo}" ]]; then
        local current_version
        current_version=$(update_cargo_toml "${root_cargo}" "${version}")
        if [[ -n "${current_version}" ]]; then
            success "[axcrates] ${current_version} → ${version}"
            updated+=("axcrates")
        fi
    fi
    
    # 更新 src/lib.rs 中的版本常量
    local lib_rs="${ROOT_DIR}/src/lib.rs"
    if [[ -f "${lib_rs}" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/pub const BUNDLE_VERSION: \&str = \".*\";/pub const BUNDLE_VERSION: \&str = \"${version}\";/" "${lib_rs}"
        else
            sed -i "s/pub const BUNDLE_VERSION: \&str = \".*\";/pub const BUNDLE_VERSION: \&str = \"${version}\";/" "${lib_rs}"
        fi
        success "[src/lib.rs] 版本常量已更新为 ${version}"
    fi
    
    printf '\n%b========== 版本更新汇总 ==========%b\n' "${BLUE}" "${NC}"
    
    if [[ ${#updated[@]} -gt 0 ]]; then
        success "已更新 (${#updated[@]} 个):"
        for crate in "${updated[@]}"; do
            printf '  %b✓%b %s\n' "${GREEN}" "${NC}" "${crate}"
        done
        printf '\n'
    fi
    
    if [[ ${#skipped[@]} -gt 0 ]]; then
        warn "跳过 (${#skipped[@]} 个): ${skipped[*]}"
    fi
    
    success "版本更新完成: ${version}"
    info "下一步:"
    info "  1. 检查变更: git diff"
    info "  2. 提交变更: git add . && git commit -m \"chore: bump version to ${version}\""
    info "  3. 打标签: bash scripts/tag.sh v${version}"
    info "  4. 发布: bash scripts/publish.sh"
}

# =============================================================================
# Main
# =============================================================================

main() {
    local crate="${1:-}" version="${2:-}"
    
    if [[ -z "${crate}" ]] || [[ -z "${version}" ]] || [[ "${crate}" == "-h" ]] || [[ "${crate}" == "--help" ]]; then
        usage; exit 0
    fi
    
    validate_version "${version}"
    
    cd "${ROOT_DIR}"
    
    info "新版本: ${version}"
    info "工作目录: ${ROOT_DIR}"
    printf '\n'
    
    if [[ "${crate}" == "all" ]]; then
        version_all "${version}"
    else
        version_crate "${crate}" "${version}"
    fi
}

main "$@"
