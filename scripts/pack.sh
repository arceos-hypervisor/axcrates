#!/usr/bin/env bash
# Compress all submodule directories into a tar.gz archive
# This creates a portable bundle for distribution via crates.io
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd -P)
BUNDLE_DIR="${ROOT_DIR}/bundle"
ARCHIVE_NAME="submodules.tar.gz"
ARCHIVE_PATH="${BUNDLE_DIR}/${ARCHIVE_NAME}"

# Source common functions
source "${SCRIPT_DIR}/common.sh"

echo -e "${GREEN}=== Compressing Submodules ===${NC}"
echo "Root directory: ${ROOT_DIR}"
# Ensure bundle directory exists
mkdir -p "${BUNDLE_DIR}"
echo -e "${BLUE}Scanning for valid submodules...${NC}"
mapfile -t ALL_SUBMODULES < <(scan_submodules)
TOTAL_COUNT=${#ALL_SUBMODULES[@]}
if [[ ${TOTAL_COUNT} -eq 0 ]]; then
    echo -e "${RED}Error: No valid submodules found${NC}"
    exit 1
fi
echo -e "${BLUE}Found ${TOTAL_COUNT} valid submodules${NC}"
# Remove old archive if exists
if [[ -f "${ARCHIVE_PATH}" ]]; then
    echo -e "${YELLOW}Removing old archive...${NC}"
    rm "${ARCHIVE_PATH}"
fi
# Create temp directory structure for archiving
TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR}" EXIT
# Copy all submodules using relative paths from scan_submodules
for rel_path in "${ALL_SUBMODULES[@]}"; do
    parent_dir=$(dirname "${TEMP_DIR}/${rel_path}")
    mkdir -p "${parent_dir}"
    cp -r "${ROOT_DIR}/${rel_path}" "${TEMP_DIR}/${rel_path}/"
done
echo -e "${GREEN}Creating archive: ${ARCHIVE_PATH}${NC}"
cd "${TEMP_DIR}"
tar -czhf "${ARCHIVE_PATH}" \
    --exclude='target' \
    --exclude='.git' \
    components os
archive_size=$(du -h "${ARCHIVE_PATH}" | cut -f1)
echo -e "${GREEN}=== Archive Created ===${NC}"
echo -e "Path: ${ARCHIVE_PATH}"
echo -e "Size: ${archive_size}"
echo -e "Total submodules: ${TOTAL_COUNT}"
