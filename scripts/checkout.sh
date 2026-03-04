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
组件分支切换脚本

用法:
  scripts/checkout.sh <crate|all> <branch>

参数:
  crate     组件名称，如 axvcpu、axaddrspace 等
  all       切换所有组件
  branch    目标分支名称，如 main、dev、feature/xxx

示例:
  scripts/checkout.sh axvcpu dev              # 切换 axvcpu 到 dev 分支
  scripts/checkout.sh axvcpu feature/new-api  # 切换 axvcpu 到 feature 分支
  scripts/checkout.sh all main                # 切换所有组件到 main 分支
  scripts/checkout.sh all dev                 # 切换所有组件到 dev 分支
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

# =============================================================================
# Checkout Functions
# =============================================================================

checkout_crate() {
    local crate="$1" branch="$2" crate_dir="${ROOT_DIR}/components/${crate}"
    
    [[ -d "${crate_dir}" ]] || { warn "[${crate}] 目录不存在，跳过"; return 0; }
    [[ -e "${crate_dir}/.git" ]] || { warn "[${crate}] 不是 git 仓库，跳过"; return 0; }
    
    pushd "${crate_dir}" >/dev/null
    
    # 获取当前分支
    local current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    
    # 如果已经在目标分支，跳过
    if [[ "${current_branch}" == "${branch}" ]]; then
        success "[${crate}] 已经在 ${branch} 分支"
        popd >/dev/null
        return 0
    fi
    
    # 检查是否有未提交的变更
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        warn "[${crate}] 有未提交的变更，请先提交或暂存"
        info "[${crate}] 当前分支: ${current_branch}"
        git status --short
        popd >/dev/null
        return 1
    fi
    
    # 尝试切换分支
    info "[${crate}] 切换分支: ${current_branch} → ${branch}"
    
    # 先尝试直接切换（本地已有分支）
    if git checkout "${branch}" 2>/dev/null; then
        success "[${crate}] 已切换到 ${branch} 分支"
        popd >/dev/null
        return 0
    fi
    
    # 如果本地没有，尝试从远程获取并创建跟踪分支
    if git fetch origin "${branch}:${branch}" 2>/dev/null && git checkout "${branch}" 2>/dev/null; then
        success "[${crate}] 已从远程获取并切换到 ${branch} 分支"
        popd >/dev/null
        return 0
    fi
    
    # 尝试从 origin/branch 检出
    if git checkout -b "${branch}" "origin/${branch}" 2>/dev/null; then
        success "[${crate}] 已从 origin/${branch} 创建并切换到 ${branch} 分支"
        popd >/dev/null
        return 0
    fi
    
    # 尝试从当前分支创建新分支（如果分支不存在）
    if git checkout -b "${branch}" 2>/dev/null; then
        success "[${crate}] 已创建并切换到新分支 ${branch}"
        popd >/dev/null
        return 0
    fi
    
    die "[${crate}] 切换分支失败: ${branch}"
    popd >/dev/null
    return 1
}

checkout_all() {
    local branch="$1"
    local crates skipped=() switched=() failed=()
    mapfile -t crates < <(read_crates)
    
    info "切换所有组件到 ${branch} 分支 (${#crates[@]} 个)..."
    
    for crate in "${crates[@]}"; do
        if [[ ! -d "${ROOT_DIR}/components/${crate}" ]]; then
            skipped+=("${crate}")
            continue
        fi
        
        if checkout_crate "${crate}" "${branch}"; then
            switched+=("${crate}")
        else
            failed+=("${crate}")
        fi
    done
    
    printf '\n%b========== 分支切换汇总 ==========%b\n' "${BLUE}" "${NC}"
    
    if [[ ${#switched[@]} -gt 0 ]]; then
        success "已切换 (${#switched[@]}):"
        for crate in "${switched[@]}"; do
            printf '  %b✓%b %s\n' "${GREEN}" "${NC}" "${crate}"
        done
        printf '\n'
    fi
    
    if [[ ${#skipped[@]} -gt 0 ]]; then
        warn "跳过 (${#skipped[@]}):"
        for crate in "${skipped[@]}"; do
            printf '  %b⚠%b %s\n' "${YELLOW}" "${NC}" "${crate}"
        done
        printf '\n'
    fi
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        die "失败 (${#failed[@]}): ${failed[*]}"
    else
        success "分支切换完成"
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    local crate="${1:-}" branch="${2:-}"
    
    if [[ -z "${crate}" ]] || [[ -z "${branch}" ]] || [[ "${crate}" == "-h" ]] || [[ "${crate}" == "--help" ]]; then
        usage; exit 0
    fi
    
    cd "${ROOT_DIR}"
    
    if [[ "${crate}" == "all" ]]; then
        checkout_all "${branch}"
    else
        checkout_crate "${crate}" "${branch}"
    fi
}

main "$@"
