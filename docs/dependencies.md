# os/axvisor 依赖组件清单

本文档列出了 os/axvisor 依赖的所有来自 `arceos-hypervisor`、`arceos-org`、`drivercraft`、`rcore-os` 组织的组件。

## arceos-hypervisor 组织组件

| 组件名称 | 版本 | 仓库地址 | Submodule 路径 |
|---------|------|---------|---------------|
| axvisor | v0.1.0-preview.4 | https://github.com/arceos-hypervisor/axvisor | `os/axvisor` |
| axaddrspace | v0.1.4 | https://github.com/arceos-hypervisor/axaddrspace | `components/axaddrspace` |
| axdevice | v0.2.1 | https://github.com/arceos-hypervisor/axdevice | `components/axdevice` |
| axdevice_base | v0.2.1 | https://github.com/arceos-hypervisor/axdevice_base | `components/axdevice_base` |
| axhvc | v0.2.0 | https://github.com/arceos-hypervisor/axhvc | `components/axhvc` |
| axklib | v0.2.0 | https://github.com/arceos-hypervisor/axklib | `components/axklib` |
| axvcpu | v0.2.1 | https://github.com/arceos-hypervisor/axvcpu | `components/axvcpu` |
| axvisor_api | v0.1.0 | https://github.com/arceos-hypervisor/axvisor_api | `components/axvisor_api` |
| axvisor_api_proc | v0.1.0 | https://github.com/arceos-hypervisor/axvisor_api | (包含于 axvisor_api) |
| axvm | v0.2.1 | https://github.com/arceos-hypervisor/axvm | `components/axvm` |
| axvmconfig | v0.2.1 | https://github.com/arceos-hypervisor/axvmconfig | `components/axvmconfig` |
| range-alloc-arceos | v0.1.4-pre.1 | https://github.com/arceos-hypervisor/range-alloc | `components/range-alloc-arceos` |
| x86_vcpu | v0.2.1 | https://github.com/arceos-hypervisor/x86_vcpu | `components/x86_vcpu` |
| x86_vlapic | v0.2.1 | https://github.com/arceos-hypervisor/x86_vlapic | `components/x86_vlapic` |
| arm_vcpu | - | https://github.com/arceos-hypervisor/arm_vcpu | `components/arm_vcpu` (非当前依赖) |
| arm_vgic | - | https://github.com/arceos-hypervisor/arm_vgic | `components/arm_vgic` (非当前依赖) |
| riscv_vcpu | - | https://github.com/arceos-hypervisor/riscv_vcpu | `components/riscv_vcpu` (非当前依赖) |
| riscv-h | - | https://github.com/arceos-hypervisor/riscv-h | `components/riscv-h` (非当前依赖) |

## arceos-org 组织组件

| 组件名称 | 版本 | 仓库地址 | Submodule 路径 |
|---------|------|---------|---------------|
| arceos_api | v0.2.2-hv.5 | https://github.com/arceos-org/arceos/tree/main/api/arceos_api | `components/arceos` |
| axalloc | v0.2.2-hv.5 | https://github.com/arceos-org/arceos/tree/main/modules/axalloc | `components/arceos` |
| axallocator | v0.1.3-preview.1 | https://github.com/arceos-org/allocator | `components/axallocator` |
| axbacktrace | v0.1.1 | https://github.com/Starry-OS/axbacktrace | `components/axbacktrace` |
| axconfig | v0.2.2-hv.5 | https://github.com/arceos-org/arceos/tree/main/modules/axconfig | `components/arceos` |
| axconfig-gen | v0.2.1 | https://github.com/arceos-org/axconfig-gen | `components/axconfig-gen` |
| axconfig-macros | v0.2.1 | https://github.com/arceos-org/axconfig-gen | `components/axconfig-gen` |
| axcpu | v0.3.0-preview.4 | https://github.com/arceos-org/axcpu/tree/dev | `components/axcpu` |
| axerrno | v0.1.2 / v0.2.2 | https://github.com/arceos-org/axerrno | `components/axerrno` |
| axfeat | v0.2.2-hv.5 | https://github.com/arceos-org/arceos/tree/main/api/axfeat | `components/arceos` |
| axhal | v0.2.2-hv.5 | https://github.com/arceos-org/arceos/tree/main/modules/axhal | `components/arceos` |
| axio | v0.3.0-pre.1 | https://github.com/arceos-org/axio | `components/axio` |
| axlog | v0.2.2-preview.1 | https://github.com/arceos-org/arceos/tree/main/modules/axlog | `components/arceos` |
| axmm | v0.2.2-hv.5 | https://github.com/arceos-org/arceos/tree/main/modules/axmm | `components/arceos` |
| axplat | v0.3.0-preview.2 | https://github.com/arceos-org/axplat_crates | `components/axplat_crates` |
| axplat-macros | v0.1.0 | https://github.com/arceos-org/axplat_crates | `components/axplat_crates` |
| axruntime | v0.2.2-hv.5 | https://github.com/arceos-org/arceos/tree/main/modules/axruntime | `components/arceos` |
| axsched | v0.3.1 | https://github.com/arceos-org/axsched | `components/axsched` |
| axstd | v0.2.2-hv.5 | https://github.com/arceos-org/arceos/tree/main/ulib/axstd | `components/arceos` |
| axsync | v0.2.2-hv.5 | https://github.com/arceos-org/arceos/tree/main/modules/axsync | `components/arceos` |
| axtask | v0.2.2-hv.5 | https://github.com/arceos-org/arceos/tree/main/modules/axtask | `components/arceos` |
| cpumask | v0.1.0 | https://github.com/arceos-org/cpumask | `components/cpumask` |
| crate_interface | v0.1.4 | https://github.com/arceos-org/crate_interface | `components/crate_interface` |
| ctor_bare | v0.2.1 | https://github.com/arceos-org/ctor_bare | `components/ctor_bare` |
| ctor_bare_macros | v0.2.1 | https://github.com/arceos-org/ctor_bare | `components/ctor_bare` |
| handler_table | v0.1.2 | https://github.com/arceos-org/handler_table | `components/handler_table` |
| kernel_guard | v0.1.3 | https://github.com/arceos-org/kernel_guard | `components/kernel_guard` |
| kspin | v0.1.1 | https://github.com/arceos-org/kspin | `components/kspin` |
| lazyinit | v0.2.2 | https://github.com/arceos-org/lazyinit | `components/lazyinit` |
| linked_list_r4l | v0.3.0 | https://github.com/arceos-org/linked_list_r4l | `components/linked_list_r4l` |
| memory_addr | v0.4.1 | https://github.com/arceos-org/axmm_crates | `components/axmm_crates` |
| memory_set | v0.4.1 | https://github.com/arceos-org/axmm_crates | `components/axmm_crates` |
| page_table_entry | v0.5.7 | https://github.com/arceos-org/page_table_multiarch | `components/page_table_multiarch` |
| page_table_multiarch | v0.5.7 | https://github.com/arceos-org/page_table_multiarch | `components/page_table_multiarch` |
| percpu | v0.2.0 | https://github.com/arceos-org/percpu | `components/percpu` |
| percpu_macros | v0.2.0 | https://github.com/arceos-org/percpu | `components/percpu` |
| timer_list | v0.1.0 | https://github.com/arceos-org/timer_list | `components/timer_list` |

## drivercraft 组织组件

| 组件名称 | 版本 | 仓库地址 | Submodule 路径 |
|---------|------|---------|---------------|
| rdrive | v0.18.11 | https://github.com/drivercraft/rdrive | `components/rdrive` |
| rdrive-macros | v0.4.1 | https://github.com/drivercraft/rdrive | `components/rdrive` |
| rdif-base | v0.7.0 | https://github.com/drivercraft/rdrive | `components/rdrive` |
| rdif-block | v0.6.2 | https://github.com/drivercraft/rdrive | `components/rdrive` |
| rdif-clk | v0.4.2 | https://github.com/drivercraft/rdrive | `components/rdrive` |
| rdif-def | v0.2.0 | https://github.com/drivercraft/rdrive | `components/rdrive` |
| rdif-intc | v0.12.1 | https://github.com/drivercraft/rdrive | `components/rdrive` |
| rdif-pcie | v0.1.4 | https://github.com/drivercraft/rdrive | `components/rdrive` |
| pcie | v0.4.5 | https://github.com/drivercraft/rdrive | `components/rdrive` |
| dma-api | v0.5.2 | https://github.com/drivercraft/dma-api | `components/dma-api` |

## rcore-os 组织组件

| 组件名称 | 版本 | 仓库地址 | Submodule 路径 |
|---------|------|---------|---------------|
| bitmap-allocator | v0.2.1 | https://github.com/rcore-os/bitmap-allocator | `components/bitmap-allocator` |

## 统计汇总

| 组织 | 组件数量 | 已添加 Submodule |
|-----|---------|-----------------|
| arceos-hypervisor | 18 | 18 |
| arceos-org | 37 | 37 |
| drivercraft | 10 | 10 |
| rcore-os | 1 | 1 |
| **总计** | **66** | **66** |

## Submodule 仓库列表

以下是目前项目中所有 submodule 仓库（共 41 个）：

| 序号 | Submodule 路径 | 仓库地址 |
|-----|---------------|---------|
| 1 | `components/arceos` | git@github.com:arceos-org/arceos.git |
| 2 | `components/arm_vcpu` | git@github.com:arceos-hypervisor/arm_vcpu.git |
| 3 | `components/arm_vgic` | git@github.com:arceos-hypervisor/arm_vgic.git |
| 4 | `components/axaddrspace` | git@github.com:arceos-hypervisor/axaddrspace.git |
| 5 | `components/axallocator` | git@github.com:arceos-org/allocator.git |
| 6 | `components/axbacktrace` | git@github.com:Starry-OS/axbacktrace.git |
| 7 | `components/axconfig-gen` | git@github.com:arceos-org/axconfig-gen.git |
| 8 | `components/axcpu` | git@github.com:arceos-org/axcpu.git |
| 9 | `components/axdevice` | git@github.com:arceos-hypervisor/axdevice.git |
| 10 | `components/axdevice_base` | git@github.com:arceos-hypervisor/axdevice_base.git |
| 11 | `components/axerrno` | git@github.com:arceos-org/axerrno.git |
| 12 | `components/axhvc` | git@github.com:arceos-hypervisor/axhvc.git |
| 13 | `components/axio` | git@github.com:arceos-org/axio.git |
| 14 | `components/axklib` | git@github.com:arceos-hypervisor/axklib.git |
| 15 | `components/axmm_crates` | git@github.com:arceos-org/axmm_crates.git |
| 16 | `components/axplat_crates` | git@github.com:arceos-org/axplat_crates.git |
| 17 | `components/axsched` | git@github.com:arceos-org/axsched.git |
| 18 | `components/axvcpu` | git@github.com:arceos-hypervisor/axvcpu.git |
| 19 | `components/axvisor_api` | git@github.com:arceos-hypervisor/axvisor_api.git |
| 20 | `components/axvm` | git@github.com:arceos-hypervisor/axvm.git |
| 21 | `components/axvmconfig` | git@github.com:arceos-hypervisor/axvmconfig.git |
| 22 | `components/bitmap-allocator` | git@github.com:rcore-os/bitmap-allocator.git |
| 23 | `components/cpumask` | git@github.com:arceos-org/cpumask.git |
| 24 | `components/crate_interface` | git@github.com:arceos-org/crate_interface.git |
| 25 | `components/ctor_bare` | git@github.com:arceos-org/ctor_bare.git |
| 26 | `components/dma-api` | git@github.com:drivercraft/dma-api.git |
| 27 | `components/handler_table` | git@github.com:arceos-org/handler_table.git |
| 28 | `components/kernel_guard` | git@github.com:arceos-org/kernel_guard.git |
| 29 | `components/kspin` | git@github.com:arceos-org/kspin.git |
| 30 | `components/lazyinit` | git@github.com:arceos-org/lazyinit.git |
| 31 | `components/linked_list_r4l` | git@github.com:arceos-org/linked_list_r4l.git |
| 32 | `components/page_table_multiarch` | git@github.com:arceos-org/page_table_multiarch.git |
| 33 | `components/percpu` | git@github.com:arceos-org/percpu.git |
| 34 | `components/range-alloc-arceos` | git@github.com:arceos-hypervisor/range-alloc.git |
| 35 | `components/rdrive` | git@github.com:drivercraft/rdrive.git |
| 36 | `components/riscv-h` | git@github.com:arceos-hypervisor/riscv-h.git |
| 37 | `components/riscv_vcpu` | git@github.com:arceos-hypervisor/riscv_vcpu.git |
| 38 | `components/timer_list` | git@github.com:arceos-org/timer_list.git |
| 39 | `components/x86_vcpu` | git@github.com:arceos-hypervisor/x86_vcpu.git |
| 40 | `components/x86_vlapic` | git@github.com:arceos-hypervisor/x86_vlapic.git |
| 41 | `os/axvisor` | git@github.com:arceos-hypervisor/axvisor.git |

---

*文档生成时间: 2026-03-05*
*最后更新: 2026-03-05 (已添加所有依赖组件为 submodule)*
