#!/usr/bin/env bash
# 组件同步脚本 - 批量同步指定或全部子模块到当前分支最新
# 用法: scripts/sync.sh <crate|all>

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
        "组件同步脚本 - 批量同步指定或全部子模块到当前分支最新" \
        "" \
        "用法:" \
        "  scripts/sync.sh <crate|all>" \
        "" \
        "参数:" \
        "  crate  组件名称，如 axvcpu、axaddrspace 等" \
        "  all    同步所有组件" \
        "" \
        "示例:" \
        "  scripts/sync.sh axvcpu           # 同步 axvcpu 当前分支最新" \
        "  scripts/sync.sh all              # 同步所有组件当前分支最新" \
        "  scripts/sync.sh arm_vcpu,axvcpu  # 同步多个组件" \
        "" \
        "注意:" \
        "  - 同步操作会初始化子模块并更新到当前分支的最新 commit" \
        "  - 不会切换分支，保持子模块当前所在分支" \
        "  - 如果子模块有未提交的变更，会被跳过" \
        "  - 同步后需要在主仓库提交 submodule 引用更新"
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
    local crate_dir
    crate_dir=$(find_crate_abs_path "${crate}")
    
    [[ -n "${crate_dir}" ]] || { warn "[${crate}] 组件目录不存在，跳过"; return 0; }
    
    printf '\n%b========== %s ==========%b\n' "${BLUE}" "${crate}" "${NC}"
    
    # 检查是否已初始化
    if ! is_initialized "${crate_dir}"; then
        info "[${crate}] 子模块未初始化，正在初始化..."
        local submodule_path
        if [[ "${crate_dir}" == *"components"* ]]; then
            submodule_path="components/${crate}"
        else
            submodule_path="os/${crate}"
        fi
        git submodule update --init "${submodule_path}" >/dev/null 2>&1 || {
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
        warn "[${crate}] 有未提交的本地修改，跳过"
        info "[${crate}] 本地修改内容:"
        git status --short | while read -r line; do
            printf '  %s\n' "${line}"
        done
        popd >/dev/null
        return 0
    fi
    
    # 记录同步前的 commit
    local old_commit
    old_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    
    # 拉取最新代码（保持当前分支）
    info "[${crate}] 拉取 ${current_branch} 分支最新代码..."
    if git pull origin "${current_branch}" >/dev/null 2>&1; then
        local new_commit
        new_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        
        if [[ "${old_commit}" == "${new_commit}" ]]; then
            info "[${crate}] 已经是最新 (${new_commit})"
        else
            success "[${crate}] 同步完成: ${old_commit} → ${new_commit}"
        fi
    else
        warn "[${crate}] 拉取失败（可能是新分支或无上游）"
    fi
    
    popd >/dev/null
    return 0
}

sync_all() {
    local crates synced=() skipped=()
    mapfile -t crates < <(get_all_crate_names)
    
    info "同步所有组件 (${#crates[@]} 个)..."
    
    for crate in "${crates[@]}"; do
        local crate_dir
        crate_dir=$(find_crate_abs_path "${crate}")
        
        # 检查是否有本地修改，用于分类统计
        if [[ -n "${crate_dir}" ]] && [[ -d "${crate_dir}/.git" ]] && has_local_changes "${crate_dir}"; then
            skipped+=("${crate} (有本地修改)")
            continue
        fi
        
        if sync_crate "${crate}"; then
            synced+=("${crate}")
        else
            skipped+=("${crate}")
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
    
    success "同步完成！${#synced[@]} 个组件已同步"
    
    # 提示更新主仓库
    printf '\n%b提示:%b 运行以下命令更新主仓库 submodule 引用:\n' "${YELLOW}" "${NC}"
    printf '  git add .\n'
    printf '  git commit -m "chore: sync submodules"\n'
    printf '  git push origin $(git branch --show-current)\n'
}

# =============================================================================
# Main
# =============================================================================

main() {
    local crate="${1:-}"
    
    if [[ -z "${crate}" ]] || [[ "${crate}" == "-h" ]] || [[ "${crate}" == "--help" ]]; then
        usage; exit 0
    fi
    
    info "工作目录: ${ROOT_DIR}"
    cd "${ROOT_DIR}"
    
    if [[ "${crate}" == "all" ]]; then
        sync_all
    else
        # 支持逗号分隔的多个组件
        IFS=',' read -ra crate_list <<< "${crate}"
        for c in "${crate_list[@]}"; do
            c=$(echo "${c}" | xargs)  # 去除空格
            [[ -n "${c}" ]] || continue
            sync_crate "${c}" || warn "[${c}] 同步失败"
        done
    fi
}

main "$@"
