#!/usr/bin/env bash
# Extract all submodule directories from the tar.gz archive
# Restores the submodule contents for development
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd -P)
BUNDLE_DIR="${ROOT_DIR}/bundle"
ARCHIVE_NAME="submodules.tar.gz"
ARCHIVE_PATH="${BUNDLE_DIR}/${ARCHIVE_NAME}"

# Source common functions
source "${SCRIPT_DIR}/common.sh"

echo -e "${GREEN}=== Extracting Submodules ===${NC}"
echo "Root directory: ${ROOT_DIR}"
# Check if archive exists
if [[ ! -f "${ARCHIVE_PATH}" ]]; then
    echo -e "${RED}Error: Archive not found at ${ARCHIVE_PATH}${NC}"
    echo ""
    echo "Please ensure the bundle archive exists. You may need to:"
    echo "  1. Run scripts/pack.sh to create the archive, or"
    echo "  2. Download the crate from crates.io which includes the bundle"
    exit 1
fi
# Show archive info
archive_size=$(du -h "${ARCHIVE_PATH}" | cut -f1)
echo -e "${BLUE}Archive: ${ARCHIVE_PATH}${NC}"
echo -e "${BLUE}Size: ${archive_size}${NC}"
# Check for existing directories
components_exist=false
os_exist=false
if [[ -d "${ROOT_DIR}/components" && "$(ls -A ${ROOT_DIR}/components 2>/dev/null)" ]]; then
    components_exist=true
fi
if [[ -d "${ROOT_DIR}/os" && "$(ls -A ${ROOT_DIR}/os 2>/dev/null)" ]]; then
    os_exist=true
fi
if [[ "${components_exist}" == "true" || "${os_exist}" == "true" ]]; then
    echo ""
    echo -e "${YELLOW}Warning: Some directories already exist:${NC}"
    [[ "${components_exist}" == "true" ]] && echo -e "  ${YELLOW}* components/${NC}"
    [[ "${os_exist}" == "true" ]] && echo -e "  ${YELLOW}* os/${NC}"
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
component_count=$(tar -tzf "${ARCHIVE_PATH}" | grep -E '^components/[^/]+/$' | wc -l)
os_count=$(tar -tzf "${ARCHIVE_PATH}" | grep -E '^os/[^/]+/$' | wc -l)
echo -e "${GREEN}Components extracted to: ${ROOT_DIR}/components/ (${component_count} crates)${NC}"
echo -e "${GREEN}OS submodules extracted to: ${ROOT_DIR}/os/ (${os_count} submodules)${NC}"
