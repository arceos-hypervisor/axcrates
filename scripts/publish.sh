#!/usr/bin/env bash
# 按依赖拓扑顺序发布所有 crate 到 crates.io
# 用法: bash publish-all.sh
# 需要已登录 crates.io: cargo login <token>

set -e

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WAIT_SECS=40   # crates.io 索引刷新等待时间

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 统计
_SKIPPED=()
_FAILED=()

publish_crate() {
    local dir="$BASE/$1"
    local name="$2"
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  发布: $name${NC}"
    echo -e "${GREEN}  路径: $dir${NC}"
    echo -e "${GREEN}========================================${NC}"

    # 捕获 cargo publish 的完整输出（stdout + stderr 合并）
    local output
    local exit_code=0
    output=$(cd "$dir" && cargo publish --allow-dirty 2>&1) || exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}  ✓ $name 发布完成${NC}"
        return 0
    fi

    # 判断是否为"版本已存在"错误
    # crates.io 返回的错误消息形如：
    #   "already uploaded"  /  "already exists"  /  "crate version already exists"
    if echo "$output" | grep -qiE "already uploaded|already exists|crate version already"; then
        echo -e "${YELLOW}  - $name 该版本已存在于 crates.io，跳过${NC}"
        _SKIPPED+=("$name")
        return 0
    fi

    # 其他真实错误：打印输出并记录，但不退出（继续后续 crate）
    echo "$output"
    echo -e "${RED}  ✗ $name 发布失败（非'已存在'错误）${NC}"
    _FAILED+=("$name")
}

wait_index() {
    echo ""
    echo -e "${BLUE}>>> 等待 ${WAIT_SECS}s，让 crates.io 索引更新 ...${NC}"
    sleep "$WAIT_SECS"
}

echo -e "${GREEN}=== AxCrates 发布脚本 ===${NC}"
echo "工作目录: $BASE"
echo ""

# ── Layer 0：无内部依赖 ────────────────────────────────────────────────────────
echo -e "${BLUE}=== Layer 0: 基础组件（无内部依赖）===${NC}"
publish_crate "axaddrspace" "axaddrspace"
publish_crate "axvmconfig" "axvmconfig"
publish_crate "axhvc" "axhvc"
publish_crate "riscv-h" "riscv-h"

wait_index

# ── Layer 1：依赖 L0 ───────────────────────────────────────────────────────────
echo -e "${BLUE}=== Layer 1: 核心组件 ===${NC}"
publish_crate "axdevice_base" "axdevice_base"
publish_crate "axvisor_api/axvisor_api_proc" "axvisor_api_proc"
publish_crate "axvisor_api" "axvisor_api"
publish_crate "axvcpu" "axvcpu"

wait_index

# ── Layer 2：依赖 L0-L1 ────────────────────────────────────────────────────────
echo -e "${BLUE}=== Layer 2: 架构相关中断控制器 ===${NC}"
publish_crate "arm_vgic" "arm_vgic"
publish_crate "x86_vlapic" "x86_vlapic"

wait_index

# ── Layer 3：依赖 L0-L2 ────────────────────────────────────────────────────────
echo -e "${BLUE}=== Layer 3: 架构相关 VCPU ===${NC}"
publish_crate "arm_vcpu" "arm_vcpu"
publish_crate "x86_vcpu" "x86_vcpu"
publish_crate "riscv_vcpu" "riscv_vcpu"

wait_index

# ── Layer 4：依赖 L0-L3 ────────────────────────────────────────────────────────
echo -e "${BLUE}=== Layer 4: 设备抽象层 ===${NC}"
publish_crate "axdevice" "axdevice"

wait_index

# ── Layer 5：依赖 L0-L4 ────────────────────────────────────────────────────────
echo -e "${BLUE}=== Layer 5: 虚拟机管理 ===${NC}"
publish_crate "axvm" "axvm"

wait_index

# ── Final: 元包 ────────────────────────────────────────────────────────────────
echo -e "${BLUE}=== Final: 元包 ===${NC}"
publish_crate "." "axcrates"

# ── 发布报告 ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  发布完成${NC}"
echo -e "${GREEN}========================================${NC}"

if [[ ${#_SKIPPED[@]} -gt 0 ]]; then
    echo -e "${YELLOW}跳过（已存在）: ${#_SKIPPED[@]} 个${NC}"
    for name in "${_SKIPPED[@]}"; do
        echo -e "  ${YELLOW}- $name${NC}"
    done
fi

if [[ ${#_FAILED[@]} -gt 0 ]]; then
    echo -e "${RED}失败: ${#_FAILED[@]} 个${NC}"
    for name in "${_FAILED[@]}"; do
        echo -e "  ${RED}- $name${NC}"
    done
    exit 1
fi

echo -e "${GREEN}所有 crate 发布成功！${NC}"
