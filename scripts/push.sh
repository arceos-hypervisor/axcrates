#!/usr/bin/env bash
# 组件推送脚本 - 批量推送指定或全部组件的变更
# 用法: scripts/push.sh <crate|all>

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
# Configuration
# =============================================================================

usage() {
    cat << EOF
组件推送脚本 - 批量推送指定或全部组件的变更

用法:
  scripts/push.sh <crate|all> [branch]

参数:
  crate     组件名称，如 axvcpu、axaddrspace 等
  all       推送所有组件
  branch    可选，指定推送到哪个分支（默认为当前分支）

示例:
  scripts/push.sh axvcpu              # 推送 axvcpu 的当前分支
  scripts/push.sh all                 # 推送所有组件的当前分支
  scripts/push.sh all dev             # 推送所有组件到 dev 分支
  scripts/push.sh arm_vcpu,axvcpu     # 推送多个组件

注意:
  - 只推送有未推送提交的组件
  - 无未推送提交的组件会自动跳过
  - 不会自动提交，只推送已提交的变更
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
# Helper Functions
# =============================================================================

# 获取当前分支名称
get_current_branch() {
    git branch --show-current 2>/dev/null || echo "HEAD"
}

# 检查是否有未推送的提交
has_unpushed_commits() {
    local branch="$1"
    local upstream="origin/${branch}"
    
    # 检查是否有上游分支
    if ! git rev-parse --abbrev-ref "${branch}@{upstream}" >/dev/null 2>&1; then
        # 没有上游分支，认为有未推送提交（需要推送新分支）
        return 0
    fi
    
    # 检查是否有未推送的提交
    [[ -n $(git log "${upstream}..${branch}" --oneline 2>/dev/null) ]]
}

# 检查工作区是否干净
is_worktree_clean() {
    [[ -z $(git status --porcelain 2>/dev/null) ]]
}

# =============================================================================
# Push Functions
# =============================================================================

push_crate() {
    local crate="$1"
    local target_branch="${2:-}"
    local crate_dir="${ROOT_DIR}/components/${crate}"
    
    [[ -d "${crate_dir}" ]] || { warn "[${crate}] 组件目录不存在，跳过"; return 0; }
    [[ -d "${crate_dir}/.git" ]] || { warn "[${crate}] 不是 Git 仓库，跳过"; return 0; }
    
    printf '\n%b========== %s ==========%b\n' "${BLUE}" "${crate}" "${NC}"
    
    pushd "${crate_dir}" >/dev/null
    
    local current_branch
    current_branch=$(get_current_branch)
    local push_branch="${target_branch:-${current_branch}}"
    
    info "[${crate}] 当前分支: ${current_branch}"
    info "[${crate}] 推送分支: ${push_branch}"
    
    # 检查工作区是否干净
    if ! is_worktree_clean; then
        warn "[${crate}] 工作区有未提交变更，跳过"
        info "[${crate}] 提示: 使用 commit.sh 提交变更后再推送"
        popd >/dev/null
        return 0
    fi
    
    # 如果需要切换到目标分支
    if [[ -n "${target_branch}" && "${target_branch}" != "${current_branch}" ]]; then
        info "[${crate}] 切换到分支 ${target_branch}..."
        if git checkout "${target_branch}" >/dev/null 2>&1; then
            success "[${crate}] 已切换到 ${target_branch}"
        else
            warn "[${crate}] 切换失败，尝试创建分支..."
            if git checkout -b "${target_branch}" >/dev/null 2>&1; then
                success "[${crate}] 已创建并切换到 ${target_branch}"
            else
                die "[${crate}] 无法切换到分支 ${target_branch}"
            fi
        fi
        current_branch="${target_branch}"
    fi
    
    # 检查是否有未推送的提交
    if ! has_unpushed_commits "${current_branch}"; then
        info "[${crate}] 没有未推送的提交，跳过"
        popd >/dev/null
        return 0
    fi
    
    # 显示待推送的提交
    info "[${crate}] 待推送的提交:"
    git log "origin/${current_branch}..${current_branch}" --oneline 2>/dev/null | head -5 | while read -r line; do
        printf '  %s\n' "${line}"
    done
    
    # 推送
    info "[${crate}] 推送到远程 ${current_branch}..."
    if git push origin "${current_branch}" >/dev/null 2>&1; then
        success "[${crate}] 推送成功"
    else
        # 尝试设置上游分支后再次推送
        if git push -u origin "${current_branch}" >/dev/null 2>&1; then
            success "[${crate}] 推送成功（已设置上游分支）"
        else
            warn "[${crate}] 推送失败"
            popd >/dev/null
            return 1
        fi
    fi
    
    popd >/dev/null
    return 0
}

push_all() {
    local target_branch="${1:-}"
    local crates pushed=() skipped=() failed=()
    mapfile -t crates < <(read_crates)
    
    info "检查所有组件 (${#crates[@]} 个)..."
    [[ -n "${target_branch}" ]] && info "目标分支: ${target_branch}"
    
    for crate in "${crates[@]}"; do
        if push_crate "${crate}" "${target_branch}"; then
            # 判断是否实际推送了（有未推送提交且工作区干净）
            local crate_dir="${ROOT_DIR}/components/${crate}"
            if [[ -d "${crate_dir}/.git" ]]; then
                pushd "${crate_dir}" >/dev/null
                local branch
                branch=$(get_current_branch)
                if ! is_worktree_clean; then
                    skipped+=("${crate} (有未提交变更)")
                elif ! has_unpushed_commits "${branch}"; then
                    skipped+=("${crate} (无未推送提交)")
                else
                    pushed+=("${crate}")
                fi
                popd >/dev/null
            fi
        else
            failed+=("${crate}")
        fi
    done
    
    # 汇总结果
    printf '\n%b========================================%b\n' "${BLUE}" "${NC}"
    printf '%b           推送结果汇总%b\n' "${BLUE}" "${NC}"
    printf '%b========================================%b\n\n' "${BLUE}" "${NC}"
    
    if [[ ${#pushed[@]} -gt 0 ]]; then
        success "已推送 ${#pushed[@]} 个组件:"
        for crate in "${pushed[@]}"; do
            printf '  %b✓%b %s\n' "${GREEN}" "${NC}" "${crate}"
        done
        printf '\n'
    fi
    
    if [[ ${#skipped[@]} -gt 0 ]]; then
        warn "跳过 ${#skipped[@]} 个组件:"
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
        die "推送完成，共 ${#failed[@]} 个组件失败"
    fi
    
    success "推送完成！${#pushed[@]} 个组件已推送"
}

# =============================================================================
# Main
# =============================================================================

main() {
    local crate="${1:-}"
    local branch="${2:-}"
    
    if [[ -z "${crate}" ]] || [[ "${crate}" == "-h" ]] || [[ "${crate}" == "--help" ]]; then
        usage
        [[ -z "${crate}" ]] && exit 1
        exit 0
    fi
    
    info "工作目录: ${ROOT_DIR}"
    cd "${ROOT_DIR}"
    
    if [[ "${crate}" == "all" ]]; then
        push_all "${branch}"
    else
        # 支持逗号分隔的多个组件
        IFS=',' read -ra crate_list <<< "${crate}"
        for c in "${crate_list[@]}"; do
            c=$(echo "${c}" | xargs)  # 去除空格
            [[ -n "${c}" ]] || continue
            push_crate "${c}" "${branch}" || warn "[${c}] 处理失败"
        done
    fi
}

main "$@"
