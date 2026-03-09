#!/usr/bin/env bash
# Extract all submodule directories from the tar.gz archive
# Restores the submodule contents for development

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUNDLE_DIR="${ROOT_DIR}/bundle"
ARCHIVE_NAME="submodules.tar.gz"
ARCHIVE_PATH="${BUNDLE_DIR}/${ARCHIVE_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Extracting Submodules ===${NC}"
echo "Root directory: ${ROOT_DIR}"

# Check if archive exists
if [[ ! -f "${ARCHIVE_PATH}" ]]; then
    echo -e "${RED}Error: Archive not found at ${ARCHIVE_PATH}${NC}"
    echo ""
    echo "Please ensure the bundle archive exists. You may need to:"
    echo "  1. Run scripts/compress_submodules.sh to create the archive, or"
    echo "  2. Download the crate from crates.io which includes the bundle"
    exit 1
fi

# Show archive info
ARCHIVE_SIZE=$(du -h "${ARCHIVE_PATH}" | cut -f1)
echo -e "${BLUE}Archive: ${ARCHIVE_PATH}${NC}"
echo -e "${BLUE}Size: ${ARCHIVE_SIZE}${NC}"

# Check for existing directories
COMPONENTS_EXIST=false
OS_EXIST=false
if [[ -d "${ROOT_DIR}/components" && "$(ls -A ${ROOT_DIR}/components 2>/dev/null)" ]]; then
    COMPONENTS_EXIST=true
fi
if [[ -d "${ROOT_DIR}/os" && "$(ls -A ${ROOT_DIR}/os 2>/dev/null)" ]]; then
    OS_EXIST=true
fi

if [[ "${COMPONENTS_EXIST}" == "true" || "${OS_EXIST}" == "true" ]]; then
    echo ""
    echo -e "${YELLOW}Warning: Some directories already exist:${NC}"
    [[ "${COMPONENTS_EXIST}" == "true" ]] && echo -e "  ${YELLOW}* components/${NC}"
    [[ "${OS_EXIST}" == "true" ]] && echo -e "  ${YELLOW}* os/${NC}"
    echo ""
    read -p "Overwrite existing directories? (y/N): " confirm
    if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
        echo -e "${RED}Extraction cancelled${NC}"
        exit 0
    fi
fi

# Extract archive to root directory
echo -e "${GREEN}Extracting...${NC}"
cd "${ROOT_DIR}"
tar -xzf "${ARCHIVE_PATH}"

echo -e "${GREEN}=== Extraction Complete ===${NC}"

# Count extracted items
COMPONENT_COUNT=$(tar -tzf "${ARCHIVE_PATH}" | grep -E '^components/[^/]+/$' | wc -l)
OS_COUNT=$(tar -tzf "${ARCHIVE_PATH}" | grep -E '^os/[^/]+/$' | wc -l)

echo -e "${GREEN}Components extracted to: ${ROOT_DIR}/components/ (${COMPONENT_COUNT} crates)${NC}"
echo -e "${GREEN}OS submodules extracted to: ${ROOT_DIR}/os/ (${OS_COUNT} submodules)${NC}"
