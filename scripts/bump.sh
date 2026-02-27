#!/usr/bin/env bash
# 批量升级所有 crate 的版本号
# 用法: bash bump-version.sh <new_version>
# 例如: bash bump-version.sh 0.2.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CRATES_FILE="${SCRIPT_DIR}/crates.txt"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查参数
if [[ $# -lt 1 ]]; then
    echo -e "${RED}用法: $0 <new_version>${NC}"
    echo "例如: $0 0.2.0"
    exit 1
fi

NEW_VERSION="$1"

# 验证版本格式
if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
    echo -e "${RED}错误: 版本格式无效，应为 X.Y.Z 或 X.Y.Z-suffix${NC}"
    exit 1
fi

echo -e "${GREEN}=== 版本升级脚本 ===${NC}"
echo "新版本: ${NEW_VERSION}"
echo "工作目录: ${ROOT_DIR}"
echo ""

# 读取 crate 列表
CRATES=()
while IFS= read -r crate || [[ -n "${crate}" ]]; do
    crate="${crate%$'\r'}"
    [[ -z "${crate}" ]] && continue
    CRATES+=("${crate}")
done < "${CRATES_FILE}"

# 更新每个 crate 的版本
for crate in "${CRATES[@]}"; do
    CARGO_PATH="${ROOT_DIR}/${crate}/Cargo.toml"
    
    if [[ ! -f "${CARGO_PATH}" ]]; then
        echo -e "${YELLOW}跳过: ${crate} (Cargo.toml 不存在)${NC}"
        continue
    fi
    
    # 获取当前版本
    CURRENT_VERSION=$(grep -m1 '^version = ' "${CARGO_PATH}" | sed 's/version = "\(.*\)"/\1/')
    
    # 使用 sed 更新版本号
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/^version = \".*\"/version = \"${NEW_VERSION}\"/" "${CARGO_PATH}"
    else
        # Linux
        sed -i "s/^version = \".*\"/version = \"${NEW_VERSION}\"/" "${CARGO_PATH}"
    fi
    
    echo -e "${GREEN}✓ ${crate}${NC}: ${CURRENT_VERSION} -> ${NEW_VERSION}"
done

# 更新根 Cargo.toml
ROOT_CARGO="${ROOT_DIR}/Cargo.toml"
if [[ -f "${ROOT_CARGO}" ]]; then
    CURRENT_VERSION=$(grep -m1 '^version = ' "${ROOT_CARGO}" | sed 's/version = "\(.*\)"/\1/')
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^version = \".*\"/version = \"${NEW_VERSION}\"/" "${ROOT_CARGO}"
    else
        sed -i "s/^version = \".*\"/version = \"${NEW_VERSION}\"/" "${ROOT_CARGO}"
    fi
    
    echo -e "${GREEN}✓ axcrates (root)${NC}: ${CURRENT_VERSION} -> ${NEW_VERSION}"
fi

# 更新 src/lib.rs 中的版本常量
LIB_RS="${ROOT_DIR}/src/lib.rs"
if [[ -f "${LIB_RS}" ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/pub const BUNDLE_VERSION: &str = \".*\";/pub const BUNDLE_VERSION: \&str = \"${NEW_VERSION}\";/" "${LIB_RS}"
    else
        sed -i "s/pub const BUNDLE_VERSION: &str = \".*\";/pub const BUNDLE_VERSION: \&str = \"${NEW_VERSION}\";/" "${LIB_RS}"
    fi
    echo -e "${GREEN}✓ src/lib.rs${NC}: 版本常量已更新"
fi

echo ""
echo -e "${GREEN}=== 版本升级完成 ===${NC}"
echo -e "${BLUE}新版本: ${NEW_VERSION}${NC}"
echo ""
echo "下一步:"
echo "  1. 检查变更: git diff"
echo "  2. 提交变更: bash scripts/git-commit-push.sh \"bump version to ${NEW_VERSION}\""
echo "  3. 创建标签: bash scripts/git-tag-push.sh v${NEW_VERSION}"
echo "  4. 发布到 crates.io: bash scripts/publish-all.sh"
