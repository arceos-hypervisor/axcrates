#!/usr/bin/env bash
# 提交并推送变更到远程仓库
# 用法: bash commit.sh <commit_message> [branch]
# 例如: bash commit.sh "feat: add new feature"
#       bash commit.sh "feat: add new feature" feature-xyz

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查参数
if [[ $# -lt 1 ]]; then
    echo -e "${RED}用法: $0 <commit_message> [branch]${NC}"
    echo "例如: $0 \"feat: add new feature\""
    echo "      $0 \"feat: add new feature\" feature-xyz"
    exit 1
fi

COMMIT_MESSAGE="$1"
BRANCH="${2:-}"

echo -e "${GREEN}=== Git 提交脚本 ===${NC}"
echo "工作目录: ${ROOT_DIR}"
echo "提交信息: ${COMMIT_MESSAGE}"
echo ""

cd "${ROOT_DIR}"

# 检查是否有变更
if [[ -z $(git status --porcelain) ]]; then
    echo -e "${YELLOW}没有需要提交的变更${NC}"
    exit 0
fi

# 显示变更状态
echo -e "${BLUE}当前变更:${NC}"
git status --short
echo ""

# 添加所有变更
echo -e "${BLUE}添加变更到暂存区...${NC}"
git add -A

# 提交变更
echo -e "${BLUE}提交变更...${NC}"
git commit -m "${COMMIT_MESSAGE}"

# 处理分支
CURRENT_BRANCH=$(git branch --show-current)

if [[ -n "${BRANCH}" && "${BRANCH}" != "${CURRENT_BRANCH}" ]]; then
    # 创建并切换到新分支
    echo -e "${BLUE}创建并切换到分支 ${BRANCH}...${NC}"
    git checkout -b "${BRANCH}"
    CURRENT_BRANCH="${BRANCH}"
fi

# 推送到远程
echo -e "${BLUE}推送分支 ${CURRENT_BRANCH} 到远程仓库...${NC}"
git push -u origin "${CURRENT_BRANCH}"

echo ""
echo -e "${GREEN}=== 提交完成 ===${NC}"
echo "提交信息: ${COMMIT_MESSAGE}"
echo "分支: ${CURRENT_BRANCH}"

if [[ "${CURRENT_BRANCH}" != "main" && "${CURRENT_BRANCH}" != "master" ]]; then
    echo ""
    echo -e "${YELLOW}下一步: 创建 Pull Request 合并到 main 分支${NC}"
fi
