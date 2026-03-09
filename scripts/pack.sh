#!/usr/bin/env bash
# Compress all submodule directories into a tar.gz archive
# This creates a portable bundle for distribution via crates.io

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

echo -e "${GREEN}=== Compressing Submodules ===${NC}"
echo "Root directory: ${ROOT_DIR}"

# Ensure bundle directory exists
mkdir -p "${BUNDLE_DIR}"

# Collect all crates from components/ directory
COMPONENT_CRATES=()
while IFS= read -r -d '' crate_dir; do
    crate=$(basename "${crate_dir}")
    COMPONENT_CRATES+=("${crate}")
    echo -e "${BLUE}Found component: ${crate}${NC}"
done < <(find "${ROOT_DIR}/components" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

# Collect all submodules from os/ directory
OS_SUBMODULES=()
while IFS= read -r -d '' os_dir; do
    os_name=$(basename "${os_dir}")
    OS_SUBMODULES+=("${os_name}")
    echo -e "${BLUE}Found OS submodule: ${os_name}${NC}"
done < <(find "${ROOT_DIR}/os" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

TOTAL_COUNT=$((${#COMPONENT_CRATES[@]} + ${#OS_SUBMODULES[@]}))
if [[ ${TOTAL_COUNT} -eq 0 ]]; then
    echo -e "${RED}Error: No directories found${NC}"
    exit 1
fi

# Remove old archive if exists
if [[ -f "${ARCHIVE_PATH}" ]]; then
    echo -e "${YELLOW}Removing old archive...${NC}"
    rm "${ARCHIVE_PATH}"
fi

# Create new archive
# Use -h to dereference symlinks (follow symbolic links)
# Exclude target and .git directories to reduce size
echo -e "${GREEN}Creating archive: ${ARCHIVE_PATH}${NC}"

# Create temp directory structure for archiving
TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR}" EXIT

# Copy all component crates
mkdir -p "${TEMP_DIR}/components"
for crate in "${COMPONENT_CRATES[@]}"; do
    cp -r "${ROOT_DIR}/components/${crate}" "${TEMP_DIR}/components/"
done

# Copy all OS submodules
mkdir -p "${TEMP_DIR}/os"
for os in "${OS_SUBMODULES[@]}"; do
    cp -r "${ROOT_DIR}/os/${os}" "${TEMP_DIR}/os/"
done

# Create archive
cd "${TEMP_DIR}"
tar -czhf "${ARCHIVE_PATH}" \
    --exclude='target' \
    --exclude='.git' \
    components os

# Show result
ARCHIVE_SIZE=$(du -h "${ARCHIVE_PATH}" | cut -f1)
echo -e "${GREEN}=== Archive Created ===${NC}"
echo -e "Path: ${ARCHIVE_PATH}"
echo -e "Size: ${ARCHIVE_SIZE}"
echo -e "Components included: ${#COMPONENT_CRATES[@]}"
echo -e "OS submodules included: ${#OS_SUBMODULES[@]}"
echo -e "Total: ${TOTAL_COUNT}"
