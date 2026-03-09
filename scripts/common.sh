#!/usr/bin/env bash
# Common functions for submodule management
# This script can be sourced by other scripts OR executed directly
# 
# When executed directly:
#   ./common.sh              # 输出所有子模块相对路径
#   ./common.sh --names      # 输出所有子模块名称
#   ./common.sh --paths      # 输出所有子模块绝对路径
#   ./common.sh --help       # 显示帮助信息

set -euo pipefail

# =============================================================================
# Setup ROOT_DIR
# =============================================================================

# Determine ROOT_DIR whether sourced or executed directly
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
    ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
else
    ROOT_DIR="$(pwd -P)"
    SCRIPT_DIR="${ROOT_DIR}/scripts"
fi

# =============================================================================
# Submodule Discovery Functions
# =============================================================================

# Cache for submodule list (to avoid repeated scanning)
_SUBMODULES_CACHE=""

# Scan all valid submodules and return their relative paths
# Valid submodule: directory under components/ or os/ that contains Cargo.toml
# Output format: components/aarch64_sysreg or os/axvisor
scan_submodules() {
    # Return cached result if available
    if [[ -n "${_SUBMODULES_CACHE}" ]]; then
        printf '%s\n' "${_SUBMODULES_CACHE}"
        return
    fi
    
    local submodules=()
    
    # Scan components/ directory
    if [[ -d "${ROOT_DIR}/components" ]]; then
        while IFS= read -r -d '' dir; do
            local name
            name=$(basename "${dir}")
            local rel_path="components/${name}"
            
            # Check if it's a valid crate (has Cargo.toml)
            if [[ -f "${ROOT_DIR}/${rel_path}/Cargo.toml" ]]; then
                submodules+=("${rel_path}")
            fi
        done < <(find "${ROOT_DIR}/components" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
    fi
    
    # Scan os/ directory
    if [[ -d "${ROOT_DIR}/os" ]]; then
        while IFS= read -r -d '' dir; do
            local name
            name=$(basename "${dir}")
            local rel_path="os/${name}"
            
            # Check if it's a valid crate (has Cargo.toml)
            if [[ -f "${ROOT_DIR}/${rel_path}/Cargo.toml" ]]; then
                submodules+=("${rel_path}")
            fi
        done < <(find "${ROOT_DIR}/os" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
    fi
    
    # Cache and output
    _SUBMODULES_CACHE=$(printf '%s\n' "${submodules[@]}")
    printf '%s\n' "${submodules[@]}"
}

# Get all crate names (basename of submodules)
# Output: aarch64_sysreg, axvcpu, etc.
get_all_crate_names() {
    scan_submodules | while IFS= read -r rel_path; do
        basename "${rel_path}"
    done
}

# Find crate relative path by name (e.g., "axvcpu" -> "components/axvcpu")
# Returns empty string if not found
find_crate_rel_path() {
    local crate_name="$1"
    while IFS= read -r rel_path; do
        if [[ "$(basename "${rel_path}")" == "${crate_name}" ]]; then
            echo "${rel_path}"
            return 0
        fi
    done < <(scan_submodules)
    return 1
}

# Find crate absolute path by name (e.g., "axvcpu" -> "/home/user/axcrates/components/axvcpu")
# Returns empty string if not found
find_crate_abs_path() {
    local crate_name="$1"
    local rel_path
    rel_path=$(find_crate_rel_path "${crate_name}")
    if [[ -n "${rel_path}" ]]; then
        echo "${ROOT_DIR}/${rel_path}"
    fi
}

# Get submodule name from relative path (e.g., "components/aarch64_sysreg" -> "aarch64_sysreg")
get_submodule_name() {
    local rel_path="$1"
    basename "${rel_path}"
}

# Get submodule absolute path from relative path
get_submodule_path() {
    local rel_path="$1"
    echo "${ROOT_DIR}/${rel_path}"
}

# Check if a submodule is a git repository
is_git_repo() {
    local rel_path="$1"
    local abs_path="${ROOT_DIR}/${rel_path}"
    [[ -d "${abs_path}/.git" || -f "${abs_path}/.git" ]]
}

# Check if a submodule has uncommitted changes
has_changes() {
    local rel_path="$1"
    local abs_path="${ROOT_DIR}/${rel_path}"
    
    if ! is_git_repo "${rel_path}"; then
        return 1
    fi
    
    pushd "${abs_path}" >/dev/null
    local result
    result=$(git status --porcelain 2>/dev/null)
    popd >/dev/null
    
    [[ -n "${result}" ]]
}

# Get current branch of a submodule
get_current_branch() {
    local rel_path="$1"
    local abs_path="${ROOT_DIR}/${rel_path}"
    
    if ! is_git_repo "${rel_path}"; then
        echo "unknown"
        return
    fi
    
    pushd "${abs_path}" >/dev/null
    git branch --show-current 2>/dev/null || echo "HEAD"
    popd >/dev/null
}

# =============================================================================
# Output Functions
# =============================================================================

# Colors
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
# Command Line Interface (when executed directly)
# =============================================================================

# Check if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    MODE="${1:---relative}"
    
    case "${MODE}" in
        --names|-n)
            scan_submodules | while IFS= read -r rel_path; do
                basename "${rel_path}"
            done
            ;;
        --paths|-p)
            scan_submodules | while IFS= read -r rel_path; do
                echo "${ROOT_DIR}/${rel_path}"
            done
            ;;
        --relative|-r)
            scan_submodules
            ;;
        --help|-h)
            cat << EOHELP
用法: $0 [选项]

选项:
  -r, --relative    输出相对路径（默认）: components/aarch64_sysreg
  -n, --names       只输出名称: aarch64_sysreg
  -p, --paths       输出绝对路径: /home/user/axcrates/components/aarch64_sysreg
  -h, --help        显示帮助信息

示例:
  # 在脚本中获取子模块数组
  source scripts/common.sh
  mapfile -t submodules < <(scan_submodules)
  
  # 直接执行输出所有子模块
  ./scripts/common.sh
  
  # 只获取名称
  ./scripts/common.sh --names
EOHELP
            ;;
        *)
            scan_submodules
            ;;
    esac
fi
