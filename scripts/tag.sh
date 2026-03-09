#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd -P)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd -P)

# Source common functions
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Helper Functions
# =============================================================================

usage() {
    printf '%s\n' \
        "组件标签管理脚本" \
        "" \
        "用法:" \
        "  scripts/tag.sh [-d|--delete] <crate|all> <tag_name>" \
        "" \
        "参数:" \
        "  -d, --delete  删除标签（本地和远程）" \
        "  crate         组件名称，如 axvcpu、axaddrspace 等" \
        "  all           为所有组件创建/删除标签" \
        "  tag_name      标签名称，如 v0.2.0、v0.2.0-preview.1" \
        "" \
        "注意:" \
        "  - 标签必须在 main/master 分支上创建" \
        "  - 确保 PR 已合并后再创建标签" \
        "  - 标签创建后会自动推送到远程" \
        "  - 删除操作会同时删除本地和远程标签" \
        "" \
        "示例:" \
        "  scripts/tag.sh axvcpu v0.2.0              # 为 axvcpu 创建标签" \
        "  scripts/tag.sh axvcpu v0.2.0-preview.1    # 为 axvcpu 创建预览版标签" \
        "  scripts/tag.sh all v0.2.0                 # 为所有组件创建标签" \
        "  scripts/tag.sh all v0.2.0-preview.1       # 为所有组件创建预览版标签" \
        "  scripts/tag.sh -d axvcpu v0.2.0           # 删除 axvcpu 的标签" \
        "  scripts/tag.sh --delete all v0.2.0        # 删除所有组件的标签"
}

# =============================================================================
# Tag Functions
# =============================================================================

validate_tag() {
    local tag="$1"
    if ! [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
        die "标签格式无效: $tag\n应为 vX.Y.Z 或 vX.Y.Z-suffix (如 v0.2.0 或 v0.2.0-preview.1)"
    fi
}

check_branch() {
    local crate="$1" crate_dir="$2"
    pushd "${crate_dir}" > /dev/null
    local current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    popd > /dev/null
    
    if [[ "${current_branch}" != "main" && "${current_branch}" != "master" ]]; then
        warn "[${crate}] 当前分支: ${current_branch} (非 main/master)"
        return 1
    fi
    return 0
}

check_clean() {
    local crate="$1" crate_dir="$2"
    pushd "${crate_dir}" > /dev/null
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        warn "[${crate}] 工作区有未提交的变更"
        popd > /dev/null
        return 1
    fi
    popd > /dev/null
    return 0
}

create_tag() {
    local crate="$1" tag="$2" crate_dir="$3"
    
    pushd "${crate_dir}" > /dev/null
    
    # 获取当前分支
    local current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    
    # 同步远程标签
    git fetch --tags 2>/dev/null || true
    
    # 检查标签是否已存在
    if git rev-parse "${tag}" >/dev/null 2>&1; then
        warn "[${crate}] 标签 ${tag} 已存在"
        popd > /dev/null
        return 1
    fi
    
    # 创建标签
    if git tag -a "${tag}" -m "Release ${tag}" 2>/dev/null; then
        success "[${crate}] 标签创建成功: ${tag} (${current_branch})"
    else
        die "[${crate}] 标签创建失败: ${tag}"
        popd > /dev/null
        return 1
    fi
    
    # 推送标签
    if git push origin "${tag}" 2>/dev/null; then
        success "[${crate}] 标签推送成功: ${tag}"
    else
        die "[${crate}] 标签推送失败: ${tag}"
        popd > /dev/null
        return 1
    fi
    
    popd > /dev/null
    return 0
}

delete_tag() {
    local crate="$1" tag="$2" crate_dir="$3"
    
    pushd "${crate_dir}" > /dev/null
    
    # 同步远程标签
    git fetch --tags 2>/dev/null || true
    
    local tag_exists=false
    local remote_tag_exists=false
    
    # 检查本地标签是否存在
    if git rev-parse "${tag}" >/dev/null 2>&1; then
        tag_exists=true
    fi
    
    # 检查远程标签是否存在
    if git ls-remote --tags origin 2>/dev/null | grep -q "refs/tags/${tag}$"; then
        remote_tag_exists=true
    fi
    
    # 删除本地标签
    if [[ "${tag_exists}" == "true" ]]; then
        if git tag -d "${tag}" 2>/dev/null; then
            success "[${crate}] 本地标签删除成功: ${tag}"
        else
            warn "[${crate}] 本地标签删除失败: ${tag}"
        fi
    else
        info "[${crate}] 本地标签不存在: ${tag}"
    fi
    
    # 删除远程标签
    if [[ "${remote_tag_exists}" == "true" ]]; then
        if git push origin --delete "${tag}" 2>/dev/null; then
            success "[${crate}] 远程标签删除成功: ${tag}"
        else
            warn "[${crate}] 远程标签删除失败: ${tag}"
            popd > /dev/null
            return 1
        fi
    else
        info "[${crate}] 远程标签不存在: ${tag}"
    fi
    
    popd > /dev/null
    return 0
}

# =============================================================================
# Tag Functions
# =============================================================================

tag_crate() {
    local crate="$1" tag="$2" crate_dir
    crate_dir=$(find_crate_abs_path "${crate}")
    
    [[ -n "${crate_dir}" ]] || { warn "[${crate}] 目录不存在，跳过"; return 0; }
    [[ -e "${crate_dir}/.git" ]] || { warn "[${crate}] 不是 git 仓库，跳过"; return 0; }
    
    printf '\n%b========== %s ==========%b\n' "${BLUE}" "${crate}" "${NC}"
    
    # 检查分支
    if ! check_branch "${crate}" "${crate_dir}"; then
        read -p "是否继续创建标签? (y/N): " confirm
        [[ "${confirm}" == "y" || "${confirm}" == "Y" ]] || return 1
    fi
    
    # 检查工作区
    if ! check_clean "${crate}" "${crate_dir}"; then
        read -p "是否继续创建标签? (y/N): " confirm
        [[ "${confirm}" == "y" || "${confirm}" == "Y" ]] || return 1
    fi
    
    # 创建并推送标签
    create_tag "${crate}" "${tag}" "${crate_dir}"
}

tag_all() {
    local tag="$1"
    local crates tagged=() skipped=() failed=()
    mapfile -t crates < <(get_all_crate_names)
    
    info "为所有组件创建标签: ${tag} (${#crates[@]} 个)..."
    
    for crate in "${crates[@]}"; do
        local crate_dir
        crate_dir=$(find_crate_abs_path "${crate}")
        if [[ -z "${crate_dir}" ]] || [[ ! -e "${crate_dir}/.git" ]]; then
            skipped+=("${crate}")
            continue
        fi
        
        # 检查分支和工作区
        local branch_ok=true
        local clean_ok=true
        
        if ! check_branch "${crate}" "${crate_dir}"; then
            branch_ok=false
        fi
        
        if ! check_clean "${crate}" "${crate_dir}"; then
            clean_ok=false
        fi
        
        if [[ "${branch_ok}" == "false" || "${clean_ok}" == "false" ]]; then
            warn "[${crate}] 检查不通过，跳过"
            failed+=("${crate}")
            continue
        fi
        
        # 创建标签
        if (create_tag "${crate}" "${tag}" "${crate_dir}"); then
            tagged+=("${crate}")
        else
            failed+=("${crate}")
        fi
    done
    
    # 为主仓库创建标签
    printf '\n%b========== %s ==========%b\n' "${BLUE}" "axcrates" "${NC}"
    local main_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    if [[ "${main_branch}" != "main" && "${main_branch}" != "master" ]]; then
        warn "[axcrates] 当前分支: ${main_branch} (非 main/master)"
    elif [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        warn "[axcrates] 工作区有未提交的变更"
    else
        git fetch --tags 2>/dev/null || true
        if ! git rev-parse "${tag}" >/dev/null 2>&1; then
            if git tag -a "${tag}" -m "Release ${tag}" && git push origin "${tag}"; then
                success "[axcrates] 标签创建并推送成功: ${tag} (${main_branch})"
                tagged+=("axcrates")
            else
                warn "[axcrates] 标签创建失败"
                failed+=("axcrates")
            fi
        else
            warn "[axcrates] 标签 ${tag} 已存在"
        fi
    fi
    
    printf '\n%b========== 标签创建汇总 ==========%b\n' "${BLUE}" "${NC}"
    
    if [[ ${#tagged[@]} -gt 0 ]]; then
        success "已创建标签 (${#tagged[@]} 个):"
        for crate in "${tagged[@]}"; do
            printf '  %b✓%b %s\n' "${GREEN}" "${NC}" "${crate}"
        done
        printf '\n'
    fi
    
    if [[ ${#skipped[@]} -gt 0 ]]; then
        warn "跳过 (${#skipped[@]} 个): ${skipped[*]}"
    fi
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        die "失败 (${#failed[@]} 个): ${failed[*]}"
    else
        success "标签创建完成: ${tag}"
        info "下一步:"
        info "  1. 检查 GitHub Actions 或 CI/CD 状态"
        info "  2. 发布到 crates.io: bash scripts/publish.sh"
    fi
}

# =============================================================================
# Delete Functions
# =============================================================================

delete_crate() {
    local crate="$1" tag="$2" crate_dir
    crate_dir=$(find_crate_abs_path "${crate}")
    
    [[ -n "${crate_dir}" ]] || { warn "[${crate}] 目录不存在，跳过"; return 0; }
    [[ -e "${crate_dir}/.git" ]] || { warn "[${crate}] 不是 git 仓库，跳过"; return 0; }
    
    printf '\n%b========== %s ==========%b\n' "${BLUE}" "${crate}" "${NC}"
    
    # 删除标签
    delete_tag "${crate}" "${tag}" "${crate_dir}"
}

delete_all() {
    local tag="$1"
    local crates deleted=() skipped=() failed=()
    mapfile -t crates < <(get_all_crate_names)
    
    info "为所有组件删除标签: ${tag} (${#crates[@]} 个)..."
    
    for crate in "${crates[@]}"; do
        local crate_dir
        crate_dir=$(find_crate_abs_path "${crate}")
        if [[ -z "${crate_dir}" ]] || [[ ! -e "${crate_dir}/.git" ]]; then
            skipped+=("${crate}")
            continue
        fi
        
        # 删除标签
        if (delete_tag "${crate}" "${tag}" "${crate_dir}"); then
            deleted+=("${crate}")
        else
            failed+=("${crate}")
        fi
    done
    
    # 为主仓库删除标签
    printf '\n%b========== %s ==========%b\n' "${BLUE}" "axcrates" "${NC}"
    git fetch --tags 2>/dev/null || true
    
    local local_exists=false
    local remote_exists=false
    
    if git rev-parse "${tag}" >/dev/null 2>&1; then
        local_exists=true
    fi
    if git ls-remote --tags origin 2>/dev/null | grep -q "refs/tags/${tag}$"; then
        remote_exists=true
    fi
    
    if [[ "${local_exists}" == "true" ]] || [[ "${remote_exists}" == "true" ]]; then
        [[ "${local_exists}" == "true" ]] && git tag -d "${tag}" 2>/dev/null
        [[ "${remote_exists}" == "true" ]] && git push origin --delete "${tag}" 2>/dev/null
        success "[axcrates] 标签删除完成: ${tag}"
        deleted+=("axcrates")
    else
        info "[axcrates] 标签不存在: ${tag}"
    fi
    
    printf '\n%b========== 标签删除汇总 ==========%b\n' "${BLUE}" "${NC}"
    
    if [[ ${#deleted[@]} -gt 0 ]]; then
        success "已删除标签 (${#deleted[@]} 个):"
        for crate in "${deleted[@]}"; do
            printf '  %b✓%b %s\n' "${GREEN}" "${NC}" "${crate}"
        done
        printf '\n'
    fi
    
    if [[ ${#skipped[@]} -gt 0 ]]; then
        warn "跳过 (${#skipped[@]} 个): ${skipped[*]}"
    fi
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        die "失败 (${#failed[@]} 个): ${failed[*]}"
    else
        success "标签删除完成: ${tag}"
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    local delete_mode=false
    local crate="" tag=""
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--delete)
                delete_mode=true
                shift
                ;;
            -h|--help)
                usage; exit 0
                ;;
            *)
                if [[ -z "${crate}" ]]; then
                    crate="$1"
                elif [[ -z "${tag}" ]]; then
                    tag="$1"
                fi
                shift
                ;;
        esac
    done
    
    if [[ -z "${crate}" ]] || [[ -z "${tag}" ]]; then
        usage; exit 0
    fi
    
    validate_tag "${tag}"
    
    cd "${ROOT_DIR}"
    
    if [[ "${delete_mode}" == "true" ]]; then
        info "删除模式: 开启"
    fi
    info "标签名称: ${tag}"
    info "工作目录: ${ROOT_DIR}"
    printf '\n'
    
    if [[ "${delete_mode}" == "true" ]]; then
        if [[ "${crate}" == "all" ]]; then
            delete_all "${tag}"
        else
            delete_crate "${crate}" "${tag}"
        fi
    else
        if [[ "${crate}" == "all" ]]; then
            tag_all "${tag}"
        else
            tag_crate "${crate}" "${tag}"
        fi
    fi
}

main "$@"
