#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd -P)

# Source common functions
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Helper Functions
# =============================================================================

usage() {
    printf '%s\n' \
        "组件更改撤销脚本" \
        "" \
        "用法:" \
        "  scripts/reset.sh <crate|all> [-f|--force]" \
        "" \
        "参数:" \
        "  crate        组件名称，如 axvcpu、axaddrspace 等" \
        "  all          撤销所有组件的更改" \
        "  -f, --force  强制执行，不显示未跟踪文件" \
        "" \
        "示例:" \
        "  scripts/reset.sh axvcpu" \
        "  scripts/reset.sh axvcpu -f" \
        "  scripts/reset.sh all" \
        "  scripts/reset.sh all --force"
}

# =============================================================================
# Reset Functions
# =============================================================================

reset_crate() {
    local crate="$1" crate_dir
    crate_dir=$(find_crate_abs_path "${crate}")
    
    [[ -n "${crate_dir}" ]] || { warn "[${crate}] 目录不存在，跳过"; return 0; }
    
    printf '\n%b========== %s ==========%b\n' "${BLUE}" "${crate}" "${NC}"
    
    pushd "${crate_dir}" >/dev/null
    
    # 检查是否有更改
    if git diff --quiet HEAD 2>/dev/null && git diff --quiet --cached HEAD 2>/dev/null; then
        if [[ "${FORCE:-}" != "true" ]]; then
            # 检查是否有未跟踪的文件
            local untracked
            untracked=$(git ls-files --others --exclude-standard 2>/dev/null || true)
            if [[ -n "${untracked}" ]]; then
                printf '\n%b⚠ 未跟踪的文件:%b\n' "${YELLOW}" "${NC}"
                printf '%s\n' "${untracked}"
                read -p "是否删除未跟踪文件? (y/N): " confirm
                if [[ "${confirm}" == "y" || "${confirm}" == "Y" ]]; then
                    git clean -fd
                    success "[${crate}] 已删除未跟踪文件"
                else
                    info "[${crate}] 保留未跟踪文件"
                fi
            fi
        fi
        info "[${crate}] 没有更改，跳过"
        popd >/dev/null
        return 0
    fi
    
    # 撤销更改
    info "[${crate}] 正在撤销更改..."
    git checkout -- .
    git clean -fd
    
    success "[${crate}] 更改已撤销"
    
    popd >/dev/null
    return 0
}

reset_all() {
    local crates passed=() failed=()
    mapfile -t crates < <(get_all_crate_names)
    
    info "撤销所有组件更改 (${#crates[@]} 个)..."
    
    for crate in "${crates[@]}"; do
        if reset_crate "${crate}"; then
            passed+=("${crate}")
        else
            failed+=("${crate}")
        fi
    done
    
    printf '\n%b========================================%b\n' "${BLUE}" "${NC}"
    printf '%b           撤销结果汇总           %b\n' "${BLUE}" "${NC}"
    printf '%b========================================%b\n' "${BLUE}" "${NC}"
    
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
        usage; exit 0
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
