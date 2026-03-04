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
组件更改撤销脚本

用法:
  scripts/reset.sh <crate|all> [-f|--force]

参数:
  crate     组件名称，如 axvcpu、axaddrspace 等
  all       撤销所有组件的更改
  -f, --force  强制执行，不显示未跟踪文件

示例:
  scripts/reset.sh axvcpu
  scripts/reset.sh axvcpu -f
  scripts/reset.sh all
  scripts/reset.sh all --force
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
# Reset Functions
# =============================================================================

reset_crate() {
    local crate="$1" crate_dir="${ROOT_DIR}/components/${1}"
    
    [[ -d "${crate_dir}" ]] || die "组件 ${crate} 不存在"
    
    printf '\n%b========== %s ==========%b\n' "${BLUE}" "${crate}" "${NC}"
    
    pushd "${crate_dir}" >/dev/null
    
    # 检查是否有更改
    if git diff --quiet HEAD 2>/dev/null && git diff --quiet --cached HEAD 2>/dev/null; then
        if [[ "${FORCE:-}" != "true" ]]; then
            # 检查是否有未跟踪的文件
            local untracked
            untracked=$(git ls-files --others --exclude-standard 2>/dev/null || true)
            if [[ -n "${untracked}" ]]; then
                warn "[${crate}] 没有已跟踪文件的更改，但有未跟踪文件:"
                echo "${untracked}" | head -5
                [[ $(echo "${untracked}" | wc -l) -gt 5 ]] && echo "  ..."
            else
                info "[${crate}] 没有更改"
            fi
        else
            info "[${crate}] 没有更改"
        fi
        popd >/dev/null
        return 0
    fi
    
    # 显示将要撤销的更改
    info "[${crate}] 以下更改将被撤销:"
    git status --short 2>/dev/null | head -10
    local total
    total=$(git status --short 2>/dev/null | wc -l)
    [[ ${total} -gt 10 ]] && echo "  ... 共 ${total} 个文件"
    
    # 撤销更改
    info "[${crate}] 正在撤销更改..."
    git checkout -- . 2>/dev/null || git restore . 2>/dev/null
    
    # 撤销暂存区的更改
    if ! git diff --quiet --cached HEAD 2>/dev/null; then
        git reset HEAD . 2>/dev/null || true
    fi
    
    popd >/dev/null
    success "[${crate}] 更改已撤销"
}

reset_all() {
    local crates passed=() failed=()
    mapfile -t crates < <(read_crates)
    
    info "撤销所有组件的更改 (${#crates[@]} 个)..."
    
    for crate in "${crates[@]}"; do
        # 使用子 shell 隔离错误，确保一个组件失败不影响其他组件
        if (reset_crate "${crate}"); then
            passed+=("${crate}")
        else
            failed+=("${crate}")
        fi
    done
    
    printf '\n%b========================================%b\n' "${BLUE}" "${NC}"
    printf '%b           撤销结果汇总%b\n' "${BLUE}" "${NC}"
    printf '%b========================================%b\n\n' "${BLUE}" "${NC}"

    if [[ ${#passed[@]} -gt 0 ]]; then
        success "处理 ${#passed[@]} 个:"
        for crate in "${passed[@]}"; do
            printf '  %b✓%b %s\n' "${GREEN}" "${NC}" "${crate}"
        done
        printf '\n'
    fi

    if [[ ${#failed[@]} -gt 0 ]]; then
        printf '%b失败 %d 个:%b\n' "${RED}" "${#failed[@]}" "${NC}"
        for crate in "${failed[@]}"; do
            printf '  %b✗%b %s\n' "${RED}" "${NC}" "${crate}"
        done
        printf '\n'
        die "撤销完成，共 ${#failed[@]} 个组件失败"
    else
        success "所有 ${#passed[@]} 个组件处理完成"
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    local crate="" force=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage; exit 0
                ;;
            -f|--force)
                force=true
                shift
                ;;
            *)
                if [[ -z "${crate}" ]]; then
                    crate="$1"
                fi
                shift
                ;;
        esac
    done
    
    if [[ -z "${crate}" ]]; then
        usage; exit 1
    fi
    
    export FORCE="${force}"
    cd "${ROOT_DIR}"
    
    if [[ "${crate}" == "all" ]]; then
        reset_all
    else
        reset_crate "${crate}"
    fi
}

main "$@"
