#!/usr/bin/env bash
# 组件同步脚本 - 批量同步指定或全部子模块到远程最新
# 用法: scripts/sync.sh <crate|all> [branch]

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

DEFAULT_BRANCH="dev"

usage() {
    cat << EOF
组件同步脚本 - 批量同步指定或全部子模块到远程最新

用法:
  scripts/sync.sh <crate|all> [branch]

参数:
  crate     组件名称，如 axvcpu、axaddrspace 等
  all       同步所有组件
  branch    目标分支（可选，默认为 dev）

示例:
  scripts/sync.sh axvcpu              # 同步 axvcpu 到 dev 分支最新
  scripts/sync.sh axvcpu main         # 同步 axvcpu 到 main 分支最新
  scripts/sync.sh all                 # 同步所有组件到 dev 分支最新
  scripts/sync.sh all main            # 同步所有组件到 main 分支最新
  scripts/sync.sh arm_vcpu,axvcpu     # 同步多个组件

注意:
  - 同步操作会更新子模块到远程分支的最新 commit
  - 如果子模块有未提交的变更，会被提示
  - 同步后需要在主仓库提交 submodule 引用更新
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

# 检查子模块是否已初始化
is_initialized() {
    local crate_dir="$1"
    [[ -d "${crate_dir}/.git" ]]
}

# 检查是否有本地修改
has_local_changes() {
    local crate_dir="$1"
    [[ -n $(cd "${crate_dir}" && git status --porcelain 2>/dev/null) ]]
}

# 获取当前分支
get_current_branch() {
    git branch --show-current 2>/dev/null || echo "HEAD"
}

# =============================================================================
# Sync Functions
# =============================================================================

sync_crate() {
    local crate="$1"
    local branch="$2"
    local crate_dir="${ROOT_DIR}/components/${crate}"
    
    [[ -d "${crate_dir}" ]] || { warn "[${crate}] 组件目录不存在，跳过"; return 0; }
    
    printf '\n%b========== %s ==========%b\n' "${BLUE}" "${crate}" "${NC}"
    
    # 检查是否已初始化
    if ! is_initialized "${crate_dir}"; then
        info "[${crate}] 子模块未初始化，正在初始化..."
        git submodule update --init "components/${crate}" >/dev/null 2>&1 || {
            warn "[${crate}] 初始化失败，跳过"
            return 0
        }
        success "[${crate}] 初始化完成"
    fi
    
    pushd "${crate_dir}" >/dev/null
    
    local current_branch
    current_branch=$(get_current_branch)
    info "[${crate}] 当前分支: ${current_branch}"
    
    # 检查是否有本地修改
    if has_local_changes "${crate_dir}"; then
        warn "[${crate}] 有未提交的本地修改"
        info "[${crate}] 本地修改内容:"
        git status --short | while read -r line; do
            printf '  %s\n' "${line}"
        done
        warn "[${crate}] 请先提交或 stash 本地修改后再同步"
        popd >/dev/null
        return 1
    fi
    
    # 切换到目标分支
    if [[ "${current_branch}" != "${branch}" ]]; then
        info "[${crate}] 切换到分支 ${branch}..."
        if git checkout "${branch}" >/dev/null 2>&1; then
            success "[${crate}] 已切换到 ${branch}"
        else
            warn "[${crate}] 无法切换到 ${branch}，尝试获取远程分支..."
            if git fetch origin "${branch}:${branch}" >/dev/null 2>&1; then
                git checkout "${branch}" >/dev/null 2>&1
                success "[${crate}] 已获取并切换到 ${branch}"
            else
                warn "[${crate}] 无法获取 ${branch}，跳过"
                popd >/dev/null
                return 1
            fi
        fi
    fi
    
    # 记录同步前的 commit
    local old_commit
    old_commit=$(git rev-parse --short HEAD)
    
    # 拉取最新代码
    info "[${crate}] 拉取 ${branch} 分支最新代码..."
    if git pull origin "${branch}" >/dev/null 2>&1; then
        local new_commit
        new_commit=$(git rev-parse --short HEAD)
        
        if [[ "${old_commit}" == "${new_commit}" ]]; then
            info "[${crate}] 已经是最新 (${new_commit})"
        else
            success "[${crate}] 同步完成: ${old_commit} → ${new_commit}"
        fi
    else
        warn "[${crate}] 拉取失败"
        popd >/dev/null
        return 1
    fi
    
    popd >/dev/null
    return 0
}

sync_all() {
    local branch="$1"
    local crates synced=() skipped=() failed=()
    mapfile -t crates < <(read_crates)
    
    info "同步所有组件到 ${branch} 分支 (${#crates[@]} 个)..."
    
    for crate in "${crates[@]}"; do
        if sync_crate "${crate}" "${branch}"; then
            synced+=("${crate}")
        else
            # 检查失败原因
            local crate_dir="${ROOT_DIR}/components/${crate}"
            if [[ -d "${crate_dir}" ]] && has_local_changes "${crate_dir}"; then
                skipped+=("${crate} (有本地修改)")
            else
                failed+=("${crate}")
            fi
        fi
    done
    
    # 汇总结果
    printf '\n%b========================================%b\n' "${BLUE}" "${NC}"
    printf '%b           同步结果汇总%b\n' "${BLUE}" "${NC}"
    printf '%b========================================%b\n\n' "${BLUE}" "${NC}"
    
    if [[ ${#synced[@]} -gt 0 ]]; then
        success "已同步 ${#synced[@]} 个组件:"
        for crate in "${synced[@]}"; do
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
        die "同步完成，共 ${#failed[@]} 个组件失败"
    fi
    
    success "同步完成！${#synced[@]} 个组件已同步到 ${branch}"
    
    # 提示更新主仓库
    printf '\n%b提示:%b 运行以下命令更新主仓库 submodule 引用:\n' "${YELLOW}" "${NC}"
    printf '  git add .\n'
    printf '  git commit -m "chore: sync submodules to latest %s"\n' "${branch}"
    printf '  git push origin $(git branch --show-current)\n'
}

# =============================================================================
# Main
# =============================================================================

main() {
    local crate="${1:-}"
    local branch="${2:-${DEFAULT_BRANCH}}"
    
    if [[ -z "${crate}" ]] || [[ "${crate}" == "-h" ]] || [[ "${crate}" == "--help" ]]; then
        usage
        [[ -z "${crate}" ]] && exit 1
        exit 0
    fi
    
    info "工作目录: ${ROOT_DIR}"
    info "目标分支: ${branch}"
    cd "${ROOT_DIR}"
    
    if [[ "${crate}" == "all" ]]; then
        sync_all "${branch}"
    else
        # 支持逗号分隔的多个组件
        IFS=',' read -ra crate_list <<< "${crate}"
        for c in "${crate_list[@]}"; do
            c=$(echo "${c}" | xargs)  # 去除空格
            [[ -n "${c}" ]] || continue
            sync_crate "${c}" "${branch}" || warn "[${c}] 同步失败"
        done
    fi
}

main "$@"
