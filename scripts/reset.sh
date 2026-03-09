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
        "  scripts/reset.sh [-f|--force] [-b|--branch] <crate|all>" \
        "" \
        "参数:" \
        "  -f, --force  强制执行，不显示未跟踪文件" \
        "  -b, --branch 恢复到默认分支 (main/master)" \
        "  crate        组件名称，如 axvcpu、axaddrspace 等" \
        "  all          撤销所有组件的更改" \
        "" \
        "示例:" \
        "  scripts/reset.sh axvcpu              # 撤销 axvcpu 的更改" \
        "  scripts/reset.sh -f axvcpu           # 强制撤销，不提示未跟踪文件" \
        "  scripts/reset.sh -b axvcpu           # 撤销更改并恢复到默认分支" \
        "  scripts/reset.sh all                 # 撤销所有组件的更改" \
        "  scripts/reset.sh --force all         # 强制撤销所有组件" \
        "  scripts/reset.sh --branch all        # 撤销所有组件并恢复到默认分支"
}

# =============================================================================
# Reset Functions
# =============================================================================

# 获取默认分支名称 (main 或 master)
get_default_branch() {
    local branch=""
    # 尝试获取远程默认分支
    branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    if [[ -n "${branch}" ]]; then
        echo "${branch}"
        return
    fi
    # 回退到检查 main 或 master
    if git rev-parse --verify main >/dev/null 2>&1; then
        echo "main"
    elif git rev-parse --verify master >/dev/null 2>&1; then
        echo "master"
    else
        echo "main"
    fi
}

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
        info "[${crate}] 没有更改"
    else
        # 撤销更改
        info "[${crate}] 正在撤销更改..."
        git checkout -- .
        git clean -fd
        success "[${crate}] 更改已撤销"
    fi
    
    # 如果指定了 -b/--branch 参数，切换到默认分支
    if [[ "${RESET_BRANCH:-}" == "true" ]]; then
        local default_branch current_branch
        default_branch=$(get_default_branch)
        current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
        
        if [[ "${current_branch}" != "${default_branch}" ]]; then
            info "[${crate}] 切换到默认分支: ${current_branch} → ${default_branch}"
            if git checkout "${default_branch}" >/dev/null 2>&1; then
                success "[${crate}] 已切换到 ${default_branch} 分支"
            else
                warn "[${crate}] 切换到 ${default_branch} 分支失败"
            fi
        else
            info "[${crate}] 已在默认分支 ${default_branch}"
        fi
    fi
    
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
    local crate="" force=false reset_branch=false
    
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
            -b|--branch)
                reset_branch=true
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
    
    export FORCE="${force}" RESET_BRANCH="${reset_branch}"
    cd "${ROOT_DIR}"
    
    if [[ "${crate}" == "all" ]]; then
        reset_all
    else
        reset_crate "${crate}"
    fi
}

main "$@"
