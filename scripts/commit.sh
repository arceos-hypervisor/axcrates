#!/usr/bin/env bash
# 组件提交脚本 - 批量提交指定或全部组件的变更
# 用法: scripts/commit.sh <crate|all> <commit_message>

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd -P)

# Source common functions
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Configuration
# =============================================================================

usage() {
    printf '%s\n' \
        "组件提交脚本 - 批量提交指定或全部组件的变更" \
        "" \
        "用法:" \
        "  scripts/commit.sh <crate|all> <commit_message>" \
        "" \
        "参数:" \
        "  crate          组件名称，如 axvcpu、axaddrspace 等" \
        "  all            提交所有组件" \
        "  commit_message 提交信息" \
        "" \
        "示例:" \
        "  scripts/commit.sh axvcpu \"feat: add new vCPU feature\"" \
        "  scripts/commit.sh all \"chore: update dependencies\"" \
        "  scripts/commit.sh arm_vcpu,axvcpu \"refactor: update API\"" \
        "" \
        "注意:" \
        "  - 只提交有变更的组件" \
        "  - 无变更的组件会自动跳过" \
        "  - 提交后会自动推送到当前分支"
}

# =============================================================================
# Helper Functions
# =============================================================================

# 检查组件是否有变更
has_changes() {
    local crate_dir="$1"
    [[ -d "${crate_dir}" ]] || return 1
    cd "${crate_dir}"
    [[ -n $(git status --porcelain 2>/dev/null) ]]
}

# 获取当前分支名称
get_current_branch() {
    git branch --show-current 2>/dev/null || echo "HEAD"
}

# =============================================================================
# Commit Functions
# =============================================================================

commit_crate() {
    local crate="$1"
    local message="$2"
    local crate_dir
    crate_dir=$(find_crate_abs_path "${crate}")

    [[ -n "${crate_dir}" ]] || { warn "[${crate}] 组件目录不存在，跳过"; return 0; }
    [[ -d "${crate_dir}/.git" ]] || { warn "[${crate}] 不是 Git 仓库，跳过"; return 0; }

    # 检查是否有变更
    if ! has_changes "${crate_dir}"; then
        info "[${crate}] 无变更，跳过"
        return 0
    fi

    printf '\n%b========== %s ==========%b\n' "${BLUE}" "${crate}" "${NC}"

    pushd "${crate_dir}" >/dev/null

    local branch
    branch=$(get_current_branch)
    info "[${crate}] 当前分支: ${branch}"

    # 显示变更文件
    info "[${crate}] 变更文件:"
    git status --short | while read -r line; do
        printf '  %s\n' "${line}"
    done

    # 添加并提交
    info "[${crate}] 提交变更..."
    git add -A
    if git commit -m "${message}" >/dev/null 2>&1; then
        success "[${crate}] 提交成功: ${message:0:50}"
    else
        warn "[${crate}] 提交失败"
        popd >/dev/null
        return 1
    fi

    # 推送
    info "[${crate}] 推送到远程 ${branch}..."
    if git push origin "${branch}" >/dev/null 2>&1; then
        success "[${crate}] 推送成功"
    else
        warn "[${crate}] 推送失败"
        popd >/dev/null
        return 1
    fi

    popd >/dev/null
    return 0
}

commit_all() {
    local message="$1"
    local crates committed=() skipped=() failed=()
    mapfile -t crates < <(get_all_crate_names)

    info "检查所有组件 (${#crates[@]} 个)..."

    for crate in "${crates[@]}"; do
        if commit_crate "${crate}" "${message}"; then
            # 检查是否真的提交了（有变更）
            local crate_dir
            crate_dir=$(find_crate_abs_path "${crate}")
            if [[ -n "${crate_dir}" ]] && [[ -n $(cd "${crate_dir}" 2>/dev/null && git status --porcelain 2>/dev/null) ]]; then
                skipped+=("${crate}")
            else
                committed+=("${crate}")
            fi
        else
            failed+=("${crate}")
        fi
    done

    # 汇总结果
    printf '\n%b========================================%b\n' "${BLUE}" "${NC}"
    printf '%b           提交结果汇总%b\n' "${BLUE}" "${NC}"
    printf '%b========================================%b\n\n' "${BLUE}" "${NC}"

    if [[ ${#committed[@]} -gt 0 ]]; then
        success "已提交并推送 ${#committed[@]} 个组件:"
        for crate in "${committed[@]}"; do
            printf '  %b✓%b %s\n' "${GREEN}" "${NC}" "${crate}"
        done
        printf '\n'
    fi

    if [[ ${#skipped[@]} -gt 0 ]]; then
        warn "无变更跳过 ${#skipped[@]} 个组件:"
        for crate in "${skipped[@]}"; do
            printf '  %b⚠%b %s\n' "${YELLOW}" "${NC}" "${crate}"
        done
        printf '\n'
    fi

    if [[ ${#failed[@]} -gt 0 ]]; then
        printf '%b失败 %d 个组件:%b\n' "${RED}" "${#failed[@]}" "${NC}"
        for crate in "${failed[@]}"; do
            printf '  %b✗%b %s\n' "${RED}" "${NC}" "${crate}"
        done
        printf '\n'
        die "提交完成，共 ${#failed[@]} 个组件失败"
    fi

    success "提交完成！${#committed[@]} 个组件已提交"
}

# =============================================================================
# Main
# =============================================================================

main() {
    local crate="${1:-}"
    local message="${2:-}"

    if [[ -z "${crate}" ]] || [[ -z "${message}" ]] || [[ "${crate}" == "-h" ]] || [[ "${crate}" == "--help" ]]; then
        usage; exit 0
    fi

    info "工作目录: ${ROOT_DIR}"
    info "提交信息: ${message}"
    cd "${ROOT_DIR}"

    if [[ "${crate}" == "all" ]]; then
        commit_all "${message}"
    else
        # 支持逗号分隔的多个组件
        IFS=',' read -ra crate_list <<< "${crate}"
        for c in "${crate_list[@]}"; do
            c=$(echo "${c}" | xargs)  # 去除空格
            [[ -n "${c}" ]] || continue
            commit_crate "${c}" "${message}" || warn "[${c}] 处理失败"
        done
    fi
}

main "$@"
