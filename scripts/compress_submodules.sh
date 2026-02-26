#!/usr/bin/env bash
# Compress all submodule directories into a tar.gz archive
# This creates a portable bundle for distribution via crates.io

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUNDLE_DIR="${ROOT_DIR}/bundle"
ARCHIVE_NAME="submodules.tar.gz"
ARCHIVE_PATH="${BUNDLE_DIR}/${ARCHIVE_NAME}"
CRATES_FILE="${SCRIPT_DIR}/crates.txt"

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

# Read crates list
if [[ ! -f "${CRATES_FILE}" ]]; then
    echo -e "${RED}Error: crates.txt not found at ${CRATES_FILE}${NC}"
    exit 1
fi

# Collect existing crate directories
CRATES=()
while IFS= read -r crate; do
    [[ -z "${crate}" ]] && continue
    CRATE_PATH="${ROOT_DIR}/${crate}"
    if [[ -d "${CRATE_PATH}" ]]; then
        CRATES+=("${crate}")
        echo -e "${BLUE}Found: ${crate}${NC}"
    else
        echo -e "${YELLOW}Warning: ${crate} not found, skipping${NC}"
    fi
done < "${CRATES_FILE}"

if [[ ${#CRATES[@]} -eq 0 ]]; then
    echo -e "${RED}Error: No crate directories found${NC}"
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
cd "${ROOT_DIR}"
tar -czhf "${ARCHIVE_PATH}" \
    --exclude='target' \
    --exclude='.git' \
    "${CRATES[@]}"

# Show result
ARCHIVE_SIZE=$(du -h "${ARCHIVE_PATH}" | cut -f1)
echo -e "${GREEN}=== Archive Created ===${NC}"
echo -e "Path: ${ARCHIVE_PATH}"
echo -e "Size: ${ARCHIVE_SIZE}"
echo -e "Crates included: ${#CRATES[@]}"
