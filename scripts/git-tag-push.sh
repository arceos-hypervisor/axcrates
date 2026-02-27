#!/usr/bin/env bash
# 创建并推送 git 标签到远程仓库
# 用法: bash git-tag-push.sh <tag_name> [commit_hash]
# 例如: bash git-tag-push.sh v0.2.0
#       bash git-tag-push.sh v0.2.0-beta abc123

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
    echo -e "${RED}用法: $0 <tag_name> [commit_hash]${NC}"
    echo "例如: $0 v0.2.0"
    echo "      $0 v0.2.0-beta abc123"
    exit 1
fi

TAG_NAME="$1"
COMMIT_HASH="${2:-HEAD}"

echo -e "${GREEN}=== Git 标签脚本 ===${NC}"
echo "工作目录: ${ROOT_DIR}"
echo "标签名称: ${TAG_NAME}"
echo "目标提交: ${COMMIT_HASH}"
echo ""

cd "${ROOT_DIR}"

# 检查标签是否已存在
if git rev-parse "${TAG_NAME}" >/dev/null 2>&1; then
    echo -e "${YELLOW}标签 ${TAG_NAME} 已存在${NC}"
    read -p "是否删除并重新创建? (y/N): " confirm
    if [[ "${confirm}" == "y" || "${confirm}" == "Y" ]]; then
        git tag -d "${TAG_NAME}"
        git push --delete origin "${TAG_NAME}" 2>/dev/null || true
        echo -e "${BLUE}已删除旧标签${NC}"
    else
        echo -e "${RED}操作取消${NC}"
        exit 1
    fi
fi

# 创建标签
echo -e "${BLUE}创建标签 ${TAG_NAME}...${NC}"
git tag -a "${TAG_NAME}" "${COMMIT_HASH}" -m "Release ${TAG_NAME}"

# 推送标签
echo -e "${BLUE}推送标签到远程仓库...${NC}"
git push origin "${TAG_NAME}"

echo ""
echo -e "${GREEN}=== 标签创建完成 ===${NC}"
echo "标签名称: ${TAG_NAME}"
echo ""
echo "下一步:"
echo "  1. 检查 GitHub Actions 或 CI/CD 状态"
echo "  2. 发布到 crates.io: bash scripts/publish-all.sh"
