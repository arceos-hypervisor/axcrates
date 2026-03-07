#!/usr/bin/env python3
"""
analyze_cargo_lock.py
=====================
解析 Cargo.lock 文件，提取五大 GitHub 组织的内部 crate 及其依赖边，
输出结构化 JSON 数据，用于生成依赖关系分析文档。

用法:
  python3 analyze_cargo_lock.py --lock <Cargo.lock路径> [--output <输出JSON路径>]

输出 JSON 结构:
  stats            统计信息
  orgs             各组织 crate 列表（含 name/version/node_id/label/layer）
  edges            内部依赖有向边列表（from_node_id → to_node_id）
  layers           按层分组的 crate 列表
  external_cats    外部依赖按类别分组
"""

import re
import sys
import json
import argparse
from collections import defaultdict

# ─────────────────────────────────────────────────────────────
# 五大组织归属表
# key: crate 名称（精确匹配）
# value: 组织名
# ─────────────────────────────────────────────────────────────
ORG_CRATE_MAP = {
    # ── Starry-OS ──────────────────────────────────────────────
    "starryos":        "starry-os",
    "starry-kernel":   "starry-os",
    "starry-process":  "starry-os",
    "starry-signal":   "starry-os",
    "starry-smoltcp":  "starry-os",
    "starry-vm":       "starry-os",
    "axpoll":          "starry-os",
    "axbacktrace":     "starry-os",
    "axfs-ng-vfs":     "starry-os",
    "rsext4":          "starry-os",
    "scope-local":     "starry-os",

    # ── arceos-org ─────────────────────────────────────────────
    # 核心内核模块
    "axalloc":                        "arceos-org",
    "axallocator":                    "arceos-org",
    "axconfig":                       "arceos-org",
    "axconfig-gen":                   "arceos-org",
    "axconfig-macros":                "arceos-org",
    "axcpu":                          "arceos-org",
    "axdisplay":                      "arceos-org",
    "axdriver":                       "arceos-org",
    "axdriver_base":                  "arceos-org",
    "axdriver_block":                 "arceos-org",
    "axdriver_display":               "arceos-org",
    "axdriver_input":                 "arceos-org",
    "axdriver_net":                   "arceos-org",
    "axdriver_pci":                   "arceos-org",
    "axdriver_virtio":                "arceos-org",
    "axdriver_vsock":                 "arceos-org",
    "axerrno":                        "arceos-org",
    "axfatfs":                        "arceos-org",
    "axfeat":                         "arceos-org",
    "axfs":                           "arceos-org",
    "axfs-ng":                        "arceos-org",
    "axfs_devfs":                     "arceos-org",
    "axfs_ramfs":                     "arceos-org",
    "axfs_vfs":                       "arceos-org",
    "axhal":                          "arceos-org",
    "axinput":                        "arceos-org",
    "axio":                           "arceos-org",
    "axklib":                         "arceos-org",
    "axlog":                          "arceos-org",
    "axmm":                           "arceos-org",
    "axnet":                          "arceos-org",
    "axnet-ng":                       "arceos-org",
    "axplat":                         "arceos-org",
    "axplat-aarch64-peripherals":     "arceos-org",
    "axplat-aarch64-qemu-virt":       "arceos-org",
    "axplat-dyn":                     "arceos-org",
    "axplat-loongarch64-qemu-virt":   "arceos-org",
    "axplat-macros":                  "arceos-org",
    "axplat-riscv64-qemu-virt":       "arceos-org",
    "axplat-riscv64-visionfive2":     "arceos-org",
    "axplat-x86-pc":                  "arceos-org",
    "axruntime":                      "arceos-org",
    "axsched":                        "arceos-org",
    "axsync":                         "arceos-org",
    "axtask":                         "arceos-org",
    "ax_slab_allocator":              "arceos-org",
    # 基础组件
    "arm_pl011":                      "arceos-org",
    "arm_pl031":                      "arceos-org",
    "cap_access":                     "arceos-org",
    "cpumask":                        "arceos-org",
    "crate_interface":                "arceos-org",
    "ctor_bare":                      "arceos-org",
    "ctor_bare_macros":               "arceos-org",
    "handler_table":                  "arceos-org",
    "int_ratio":                      "arceos-org",
    "kernel_guard":                   "arceos-org",
    "kspin":                          "arceos-org",
    "lazyinit":                       "arceos-org",
    "linked_list_r4l":                "arceos-org",
    "memory_addr":                    "arceos-org",
    "memory_set":                     "arceos-org",
    "page_table_entry":               "arceos-org",
    "page_table_multiarch":           "arceos-org",
    "percpu":                         "arceos-org",
    "percpu_macros":                  "arceos-org",
    "riscv_plic":                     "arceos-org",
    "timer_list":                     "arceos-org",

    # ── rcore-os ───────────────────────────────────────────────
    "arm-gic-driver":      "rcore-os",
    "bitmap-allocator":    "rcore-os",
    "kasm-aarch64":        "rcore-os",
    "num-align":           "rcore-os",
    "page-table-generic":  "rcore-os",
    "some-serial":         "rcore-os",
    "someboot":            "rcore-os",
    "somehal":             "rcore-os",
    "somehal-macros":      "rcore-os",
    "virtio-drivers":      "rcore-os",

    # ── arceos-hypervisor ─────────────────────────────────────
    # StarryOS 为宏内核，无 hypervisor 相关 crate

    # ── drivercraft ───────────────────────────────────────────
    "aarch64-cpu-ext":  "drivercraft",
    "dma-api":          "drivercraft",
    "mbarrier":         "drivercraft",
    "pcie":             "drivercraft",
    "rdif-base":        "drivercraft",
    "rdif-def":         "drivercraft",
    "rdif-intc":        "drivercraft",
    "rdif-pcie":        "drivercraft",
    "rdif-serial":      "drivercraft",
    "rdrive":           "drivercraft",
    "rdrive-macros":    "drivercraft",
}

# ─────────────────────────────────────────────────────────────
# 层级分配规则（优先级从上到下，精确匹配优先）
# ─────────────────────────────────────────────────────────────
LAYER_RULES = [
    # (层级编号, 层名, crate名称集合或前缀规则)
    (0, "内核入口层",       {"starryos"}),
    (1, "OS核心逻辑层",     {"starry-kernel", "starry-process", "starry-signal",
                            "starry-vm", "starry-smoltcp"}),
    (2, "运行时/特性层",    {"axfeat", "axruntime"}),
    (3, "核心服务层",       {"axhal", "axtask", "axmm", "axalloc", "axsync",
                            "axlog", "axio", "axdisplay", "axinput",
                            "axnet", "axnet-ng", "axfs-ng", "axpoll", "axbacktrace"}),
    (4, "驱动/文件系统层",  {"axdriver", "axdriver_base", "axdriver_block",
                            "axdriver_display", "axdriver_input", "axdriver_net",
                            "axdriver_pci", "axdriver_virtio", "axdriver_vsock",
                            "axfs", "axfs_devfs", "axfs_ramfs", "axfs_vfs",
                            "axfs-ng-vfs", "rsext4", "axfatfs",
                            "rdrive", "rdif-intc", "rdif-pcie"}),
    (5, "HAL/平台抽象层",   {"axcpu", "axplat", "axplat-macros",
                            "axplat-aarch64-peripherals", "axplat-aarch64-qemu-virt",
                            "axplat-dyn", "axplat-loongarch64-qemu-virt",
                            "axplat-riscv64-qemu-virt", "axplat-riscv64-visionfive2",
                            "axplat-x86-pc", "axconfig", "axconfig-gen",
                            "axconfig-macros", "axsched", "axallocator",
                            "ax_slab_allocator", "arm_pl011", "arm_pl031",
                            "riscv_plic", "cap_access", "int_ratio", "axklib"}),
    (6, "基础组件层",       {"axerrno", "memory_addr", "memory_set",
                            "page_table_entry", "page_table_multiarch",
                            "percpu", "percpu_macros", "kspin", "kernel_guard",
                            "crate_interface", "lazyinit", "handler_table",
                            "cpumask", "timer_list", "ctor_bare", "ctor_bare_macros",
                            "linked_list_r4l", "scope-local",
                            "dma-api", "aarch64-cpu-ext", "pcie", "mbarrier",
                            "rdif-base", "rdif-def", "rdif-serial", "rdrive-macros"}),
    (7, "最底层库",         {"somehal", "someboot", "somehal-macros", "some-serial",
                            "virtio-drivers", "arm-gic-driver", "bitmap-allocator",
                            "num-align", "page-table-generic", "kasm-aarch64"}),
]

# ─────────────────────────────────────────────────────────────
# 外部依赖分类规则（关键词匹配）
# ─────────────────────────────────────────────────────────────
EXTERNAL_CATEGORIES = [
    ("序列化/数据格式",  ["serde", "toml", "json", "base64", "hex", "bincode", "borsh",
                         "byteorder", "bytes", "flatbuffers", "rkyv", "cbor", "xml",
                         "yaml", "csv", "mime"]),
    ("异步/并发",        ["tokio", "futures", "async", "crossbeam", "parking_lot",
                         "concurrent", "event-listener", "rayon", "smol", "monoio"]),
    ("网络/协议",        ["http", "hyper", "axum", "tower", "h2", "websocket",
                         "rustls", "webpki", "smoltcp", "socket2", "mio", "reqwest"]),
    ("加密/安全",        ["digest", "sha", "rand", "aead", "ring", "aws-lc", "rsa",
                         "aes", "hmac", "pbkdf", "chacha", "curve25519", "ed25519"]),
    ("日志/错误",        ["log", "tracing", "anyhow", "thiserror", "env_logger",
                         "flexi_logger", "simplelog", "error-chain"]),
    ("命令行/配置",      ["clap", "structopt", "argh", "anstyle", "bitflags",
                         "semver", "cargo_metadata", "glob", "shlex"]),
    ("系统/平台",        ["libc", "cc", "cmake", "linux-raw-sys", "rustix", "nix",
                         "windows", "winapi", "memchr", "memoffset", "cfg-if",
                         "raw-cpuid", "x86", "x86_64", "riscv", "loongArch"]),
    ("宏/代码生成",      ["syn", "quote", "proc-macro", "derive", "paste",
                         "linkme", "enumn", "strum", "darling", "heck"]),
    ("嵌入式/裸机",      ["cortex-m", "embedded", "tock-registers", "volatile",
                         "critical-section", "portable-atomic", "heapless",
                         "defmt", "uefi", "acpi", "aml", "multiboot",
                         "sbi", "uart", "x2apic", "riscv-pac"]),
    ("数据结构/算法",    ["hashbrown", "indexmap", "smallvec", "arrayvec", "bitvec",
                         "bitmaps", "lru", "intrusive", "ringbuf", "uluru",
                         "flatten_objects", "weak-map", "ranges-ext"]),
    ("设备树/固件解析",  ["fdt", "xmas-elf", "kernel-elf-parser", "multiboot",
                         "fitimage", "uboot"]),
    ("工具库/其他",      []),  # 兜底分类
]


def make_node_id(name: str, version: str) -> str:
    """生成 mermaid 安全节点 ID，格式: name_vX_Y_Z"""
    safe_name = re.sub(r'[-.]', '_', name)
    safe_ver  = re.sub(r'[-.]', '_', version)
    return f"{safe_name}_v{safe_ver}"


def make_label(name: str, version: str) -> str:
    """生成 mermaid 节点 label，格式: name["name\nvX.Y.Z"]"""
    return f'{make_node_id(name, version)}["{name}\\nv{version}"]'


def parse_cargo_lock(lock_path: str) -> list[dict]:
    """解析 Cargo.lock，返回 package 列表，每项含 name/version/source/deps"""
    content = open(lock_path, encoding="utf-8").read()
    packages = []

    # 按双换行分割块
    blocks = re.split(r'\n\n+', content)
    for block in blocks:
        if "[[package]]" not in block:
            continue
        name_m   = re.search(r'^name\s*=\s*"([^"]+)"',    block, re.MULTILINE)
        ver_m    = re.search(r'^version\s*=\s*"([^"]+)"', block, re.MULTILINE)
        source_m = re.search(r'^source\s*=\s*"([^"]+)"',  block, re.MULTILINE)
        if not name_m or not ver_m:
            continue
        # 提取 dependencies 列表中的 crate 名（去掉版本范围部分）
        deps_section = re.search(
            r'^dependencies\s*=\s*\[(.*?)\]', block, re.MULTILINE | re.DOTALL
        )
        deps = []
        if deps_section:
            raw_deps = re.findall(r'"([^"]+)"', deps_section.group(1))
            for d in raw_deps:
                # 依赖条目格式: "crate-name version" 或 "crate-name"
                dep_name = d.split()[0]
                deps.append(dep_name)

        packages.append({
            "name":    name_m.group(1),
            "version": ver_m.group(1),
            "source":  source_m.group(1) if source_m else "local",
            "deps":    deps,
        })
    return packages


def classify_packages(packages: list[dict]) -> dict:
    """将所有 package 按组织归类，返回 {org_name: [pkg,...], "external": [pkg,...]}"""
    result = defaultdict(list)
    for pkg in packages:
        org = ORG_CRATE_MAP.get(pkg["name"])
        if org:
            result[org].append(pkg)
        else:
            # 检查 git source 中是否包含已知组织
            src = pkg.get("source", "")
            found = False
            for org_key in ["Starry-OS", "arceos-org", "rcore-os",
                            "arceos-hypervisor", "drivercraft"]:
                if f"github.com/{org_key}/" in src:
                    norm = org_key.lower()
                    result[norm].append(pkg)
                    found = True
                    break
            if not found:
                result["external"].append(pkg)
    return result


def assign_layer(name: str) -> tuple[int, str]:
    """根据层级规则，返回 (层级号, 层名)"""
    for layer_num, layer_name, crate_set in LAYER_RULES:
        if name in crate_set:
            return layer_num, layer_name
    return -1, "未分类"


def categorize_external(pkg_name: str) -> str:
    """将外部 crate 归入类别"""
    name_lower = pkg_name.lower()
    for cat_name, keywords in EXTERNAL_CATEGORIES[:-1]:  # 排除兜底
        if any(kw in name_lower for kw in keywords):
            return cat_name
    return "工具库/其他"


def build_internal_set(classified: dict) -> set[str]:
    """构建内部 crate 名称集合（用于过滤依赖边）"""
    internal = set()
    for org, pkgs in classified.items():
        if org != "external":
            for pkg in pkgs:
                internal.add(pkg["name"])
    return internal


def build_output(packages: list[dict], classified: dict) -> dict:
    """构建完整输出 JSON"""
    internal_names = build_internal_set(classified)

    # 构建 (name, version) → org 映射
    pkg_org = {}
    for org, pkgs in classified.items():
        if org != "external":
            for pkg in pkgs:
                pkg_org[(pkg["name"], pkg["version"])] = org

    # 构建 name → [(name, version)] 映射（用于依赖边解析，name可能多版本）
    name_to_versions: dict[str, list[str]] = defaultdict(list)
    for pkg in packages:
        name_to_versions[pkg["name"]].append(pkg["version"])

    # orgs: 各组织 crate 详情
    orgs = defaultdict(list)
    for org in ["starry-os", "arceos-org", "rcore-os", "arceos-hypervisor", "drivercraft"]:
        for pkg in classified.get(org, []):
            layer_num, layer_name = assign_layer(pkg["name"])
            orgs[org].append({
                "name":       pkg["name"],
                "version":    pkg["version"],
                "node_id":    make_node_id(pkg["name"], pkg["version"]),
                "label":      make_label(pkg["name"], pkg["version"]),
                "layer":      layer_num,
                "layer_name": layer_name,
                "source":     pkg["source"],
            })
        orgs[org].sort(key=lambda x: (x["layer"], x["name"]))

    # edges: 内部依赖有向边
    edges = []
    seen_edges = set()
    for pkg in packages:
        if pkg["name"] not in internal_names:
            continue
        from_id = make_node_id(pkg["name"], pkg["version"])
        for dep_name in pkg["deps"]:
            if dep_name not in internal_names:
                continue
            # dep_name 可能多版本，优先取单版本，多版本全部展示
            dep_versions = name_to_versions.get(dep_name, [])
            for dep_ver in dep_versions:
                to_id = make_node_id(dep_name, dep_ver)
                edge_key = (from_id, to_id)
                if edge_key not in seen_edges:
                    seen_edges.add(edge_key)
                    edges.append({"from": from_id, "to": to_id,
                                  "from_name": pkg["name"], "from_ver": pkg["version"],
                                  "to_name": dep_name, "to_ver": dep_ver})

    # layers: 按层分组
    layers: dict[int, list] = defaultdict(list)
    for org, crate_list in orgs.items():
        for crate in crate_list:
            layers[crate["layer"]].append({
                "node_id": crate["node_id"],
                "name":    crate["name"],
                "version": crate["version"],
                "org":     org,
                "layer_name": crate["layer_name"],
            })
    layers_sorted = {k: layers[k] for k in sorted(layers.keys())}

    # external_cats: 外部依赖按类别分组
    ext_cats: dict[str, list] = defaultdict(list)
    for pkg in classified.get("external", []):
        cat = categorize_external(pkg["name"])
        ext_cats[cat].append(f"{pkg['name']} {pkg['version']}")
    for cat in ext_cats:
        ext_cats[cat].sort()

    # stats
    internal_count = sum(
        len(v) for k, v in classified.items() if k != "external"
    )
    stats = {
        "total_crates":     len(packages),
        "internal_crates":  internal_count,
        "external_crates":  len(classified.get("external", [])),
        "by_org": {
            org: len(classified.get(org, []))
            for org in ["starry-os", "arceos-org", "rcore-os",
                        "arceos-hypervisor", "drivercraft"]
        },
    }

    return {
        "stats":          stats,
        "orgs":           dict(orgs),
        "edges":          edges,
        "layers":         layers_sorted,
        "external_cats":  dict(ext_cats),
    }


def main():
    parser = argparse.ArgumentParser(description="分析 Cargo.lock 中的五大组织 crate 依赖关系")
    parser.add_argument("--lock",   default="Cargo.lock",   help="Cargo.lock 文件路径")
    parser.add_argument("--output", default="-",            help="输出 JSON 路径（默认 stdout）")
    args = parser.parse_args()

    packages  = parse_cargo_lock(args.lock)
    classified = classify_packages(packages)
    output    = build_output(packages, classified)

    result_json = json.dumps(output, ensure_ascii=False, indent=2)
    if args.output == "-":
        print(result_json)
    else:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(result_json)
        print(f"[OK] 结构化数据已写入 {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
