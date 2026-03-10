# ArceOS 生态系统架构图

本文档展示了 ArceOS 生态系统的完整架构，包括所有 121 个组件的位置和关系。

## 1. 完整操作系统架构图

```mermaid
graph TB
    %% 用户空间
    subgraph UserSpace["用户空间 (User Space)"]
        direction LR
        UAPP["用户应用<br/>User Applications"]
        SSVC["系统服务<br/>System Services"]
    end

    %% 标准库与 API
    subgraph APILayer["API 与标准库层"]
        direction LR
        STD["axstd<br/>标准库"]
        API1["arceos_api<br/>ArceOS API"]
        API2["axvisor_api<br/>Hypervisor API"]
    end

    %% 运行时与配置
    subgraph RuntimeLayer["运行时与配置层"]
        direction LR
        RUNTIME["axruntime<br/>运行时"]
        FEAT["axfeat<br/>特性管理"]
        CFG["axconfig<br/>配置系统"]
        CFGGEN["axconfig-gen<br/>配置生成"]
    end

    %% 内核子系统
    subgraph KernelLayer["内核子系统层"]
        direction TB
        
        subgraph KernSub1["进程与任务管理"]
            TASK["axtask<br/>任务管理"]
            SCHED["axsched<br/>调度器"]
            PROC["starry-process<br/>进程管理"]
            SIG["starry-signal<br/>信号处理"]
            CPU["cpumask<br/>CPU掩码"]
        end
        
        subgraph KernSub2["内存管理"]
            MM["axmm<br/>内存管理器"]
            ALLOC["axalloc/axallocator<br/>分配器"]
            VM["starry-vm<br/>虚拟内存"]
            ADDR["axaddrspace<br/>地址空间"]
            PT["page_table_multiarch<br/>多架构页表"]
        end
        
        subgraph KernSub3["文件系统"]
            FS["axfs<br/>文件系统"]
            VFS["axfs_vfs/axfs-ng-vfs<br/>VFS"]
            DEVFS["axfs_devfs<br/>设备文件系统"]
            RAMFS["axfs_ramfs<br/>内存文件系统"]
            EXT4["rsext4<br/>Ext4"]
        end
        
        subgraph KernSub4["网络子系统"]
            NET["starry-smoltcp<br/>网络协议栈"]
            POLL["axpoll<br/>IO多路复用"]
        end
        
        subgraph KernSub5["虚拟化"]
            VCPU["axvcpu<br/>VCPU抽象"]
            ARMV["arm_vcpu/arm_vgic<br/>ARM虚拟化"]
            RVV["riscv_vcpu/riscv_vplic<br/>RISC-V虚拟化"]
            X86V["x86_vcpu/x86_vlapic<br/>x86虚拟化"]
            VMGT["axvm/axvmconfig<br/>VM管理"]
            VDEV["axdevice/axhvc<br/>虚拟设备"]
        end
        
        subgraph KernSub6["同步与并发"]
            SYNC["axsync<br/>同步原语"]
            LOCK["kspin/kernel_guard<br/>锁机制"]
            PCPU["percpu<br/>Per-CPU变量"]
        end
        
        subgraph KernSub7["内核库"]
            KLIB["axklib<br/>内核库"]
            ERR["axerrno<br/>错误处理"]
            IO["axio<br/>IO抽象"]
            LOG["axlog<br/>日志系统"]
        end
    end

    %% 硬件抽象层
    subgraph HALLayer["硬件抽象层"]
        direction TB
        
        subgraph HALCore["核心 HAL"]
            HAL["axhal<br/>硬件抽象层"]
            CPUL["axcpu<br/>CPU抽象"]
            SHAL["somehal<br/>硬件抽象"]
        end
        
        subgraph PlatformLayer["平台抽象"]
            PLAT["axplat<br/>平台抽象"]
            PLAT1["ARM64平台<br/>axplat-aarch64-*"]
            PLAT2["RISC-V平台<br/>axplat-riscv64-*"]
            PLAT3["x86平台<br/>axplat-x86-*"]
            PLAT4["龙芯平台<br/>axplat-loongarch64-*"]
        end
        
        subgraph ArchSpec["架构特定"]
            REG["aarch64_sysreg<br/>系统寄存器"]
            ASM["kasm-aarch64<br/>汇编支持"]
        end
    end

    %% 驱动层
    subgraph DriverLayer["驱动层"]
        direction TB
        
        subgraph DrvFrame["驱动框架"]
            DRV["axdriver<br/>驱动框架"]
            DRVBASE["axdriver_base<br/>驱动基础"]
            RDRV["rdrive<br/>Rust驱动框架"]
        end
        
        subgraph DrvBus["总线驱动"]
            BUS["axdriver_pci/pcie<br/>PCI/PCIe"]
        end
        
        subgraph DrvDev["设备驱动"]
            BLK["axdriver_block/sdmmc<br/>块设备"]
            VIO["virtio-drivers<br/>VirtIO"]
            SER["any-uart/arm_pl011<br/>串口"]
            INTC["arm-gic-driver/riscv_plic<br/>中断控制器"]
            TMR["arm_pl031/timer_list<br/>定时器"]
            PLATD["phytium-mci/rk*-clk<br/>平台驱动"]
        end
    end

    %% 工具与库
    subgraph UtilLayer["工具与库"]
        direction LR
        INIT["lazyinit/ctor_bare<br/>初始化"]
        DATA["linked_list_r4l/handler_table<br/>数据结构"]
        UTIL["crate_interface/cap_access<br/>工具库"]
    end

    %% 硬件
    subgraph Hardware["硬件"]
        direction LR
        HW["CPU / 内存 / 设备"]
    end

    %% 连接关系
    UserSpace --> APILayer
    APILayer --> RuntimeLayer
    RuntimeLayer --> KernelLayer
    KernelLayer --> HALLayer
    HALLayer --> DriverLayer
    DriverLayer --> Hardware
    
    UtilLayer -.-> KernelLayer
    UtilLayer -.-> HALLayer

    %% 样式定义
    classDef userSpace fill:#e3f2fd,stroke:#1976d2,stroke-width:3px
    classDef api fill:#f3e5f5,stroke:#7b1fa2,stroke-width:3px
    classDef runtime fill:#fff3e0,stroke:#f57c00,stroke-width:3px
    classDef kernel fill:#e8f5e9,stroke:#388e3c,stroke-width:3px
    classDef hal fill:#fce4ec,stroke:#c2185b,stroke-width:3px
    classDef driver fill:#fff9c4,stroke:#f9a825,stroke-width:3px
    classDef util fill:#e0f2f1,stroke:#00796b,stroke-width:2px
    classDef hardware fill:#ffebee,stroke:#d32f2f,stroke-width:4px

    class UAPP,SSVC userSpace
    class STD,API1,API2 api
    class RUNTIME,FEAT,CFG,CFGGEN runtime
    class TASK,SCHED,PROC,SIG,CPU,MM,ALLOC,VM,ADDR,PT,FS,VFS,DEVFS,RAMFS,EXT4,NET,POLL,VCPU,ARMV,RVV,X86V,VMGT,VDEV,SYNC,LOCK,PCPU,KLIB,ERR,IO,LOG kernel
    class HAL,CPUL,SHAL,PLAT,PLAT1,PLAT2,PLAT3,PLAT4,REG,ASM hal
    class DRV,DRVBASE,RDRV,BUS,BLK,VIO,SER,INTC,TMR,PLATD driver
    class INIT,DATA,UTIL util
    class HW hardware
```

## 2. 分层架构图（类似 Linux 内核架构）

```mermaid
graph TB
    %% ==================== 用户空间 ====================
    subgraph Layer1["第 1 层: 用户空间 (User Space)"]
        direction LR
        USR["用户应用与系统服务<br/>Applications & System Services"]
    end

    %% ==================== 系统调用接口 ====================
    subgraph Layer2["第 2 层: 系统调用接口 (System Call Interface)"]
        direction LR
        STD1["axstd<br/>标准库"]
        SYS1["arceos_api<br/>POSIX-like API"]
        SYS2["axvisor_api<br/>Hypervisor API"]
    end

    %% ==================== 内核空间 - 运行时 ====================
    subgraph Layer3["第 3 层: 内核运行时 (Kernel Runtime)"]
        direction LR
        RT1["axruntime<br/>运行时环境"]
        RT2["axfeat<br/>特性管理"]
        RT3["axconfig<br/>配置系统"]
    end

    %% ==================== 内核子系统 ====================
    subgraph Layer4["第 4 层: 内核子系统 (Kernel Subsystems)"]
        direction TB
        
        %% 进程管理
        subgraph PM["进程管理"]
            direction LR
            PM1["axtask<br/>任务"]
            PM2["axsched<br/>调度"]
            PM3["starry-process<br/>进程"]
            PM4["starry-signal<br/>信号"]
        end
        
        %% 内存管理
        subgraph MM["内存管理"]
            direction LR
            MM1["axmm<br/>内存管理"]
            MM2["axalloc<br/>分配器"]
            MM3["starry-vm<br/>虚拟内存"]
            MM4["page_table<br/>页表"]
        end
        
        %% 文件系统
        subgraph FS["文件系统"]
            direction LR
            FS1["axfs<br/>文件系统"]
            FS2["VFS<br/>虚拟文件系统"]
            FS3["devfs/ramfs/ext4<br/>文件系统实现"]
        end
        
        %% 网络
        subgraph NET["网络"]
            direction LR
            NET1["starry-smoltcp<br/>TCP/IP栈"]
            NET2["axpoll<br/>IO多路复用"]
        end
        
        %% 虚拟化
        subgraph VIRT["虚拟化"]
            direction LR
            VT1["axvcpu<br/>VCPU"]
            VT2["arm/riscv/x86_vcpu<br/>架构实现"]
            VT3["axvm<br/>VM管理"]
            VT4["axdevice<br/>虚拟设备"]
        end
        
        %% IPC与同步
        subgraph IPC["IPC 与同步"]
            direction LR
            IPC1["axsync<br/>同步原语"]
            IPC2["kspin<br/>自旋锁"]
            IPC3["percpu<br/>Per-CPU"]
        end
    end

    %% ==================== 内核库 ====================
    subgraph Layer5["第 5 层: 内核库 (Kernel Library)"]
        direction LR
        KL1["axklib<br/>内核库"]
        KL2["axerrno<br/>错误处理"]
        KL3["axio<br/>IO抽象"]
        KL4["axlog<br/>日志"]
    end

    %% ==================== 硬件抽象层 ====================
    subgraph Layer6["第 6 层: 硬件抽象层 (HAL)"]
        direction TB
        
        subgraph HAL1["核心 HAL"]
            direction LR
            H1["axhal<br/>HAL"]
            H2["axcpu<br/>CPU抽象"]
            H3["somehal<br/>HAL扩展"]
        end
        
        subgraph HAL2["平台抽象"]
            direction LR
            P1["axplat<br/>平台抽象层"]
            P2["ARM64平台"]
            P3["RISC-V平台"]
            P4["x86平台"]
            P5["龙芯平台"]
        end
    end

    %% ==================== 设备驱动 ====================
    subgraph Layer7["第 7 层: 设备驱动 (Device Drivers)"]
        direction TB
        
        subgraph DRV1["驱动框架"]
            direction LR
            D1["axdriver<br/>驱动框架"]
            D2["axdriver_base<br/>驱动基础"]
            D3["rdrive<br/>Rust驱动"]
        end
        
        subgraph DRV2["驱动实现"]
            direction LR
            D4["PCI/PCIe<br/>总线驱动"]
            D5["块设备<br/>存储驱动"]
            D6["串口/中断/定时器<br/>设备驱动"]
            D7["平台特定驱动<br/>RK/Phytium等"]
        end
    end

    %% ==================== 工具与库 ====================
    subgraph Layer8["第 8 层: 基础工具库 (Utilities)"]
        direction LR
        U1["lazyinit/ctor_bare<br/>初始化"]
        U2["linked_list/handler_table<br/>数据结构"]
        U3["cap_access/crate_interface<br/>工具库"]
    end

    %% ==================== 硬件 ====================
    subgraph Layer9["硬件层 (Hardware)"]
        direction LR
        HW["CPU • 内存 • 存储设备 • 网络设备 • 其他外设"]
    end

    %% ==================== 连接关系 ====================
    Layer1 --> Layer2
    Layer2 --> Layer3
    Layer3 --> Layer4
    Layer4 --> Layer5
    Layer5 --> Layer6
    Layer6 --> Layer7
    Layer7 --> Layer9
    Layer8 -.-> Layer4
    Layer8 -.-> Layer6

    %% ==================== 样式定义 ====================
    classDef layer1 fill:#e3f2fd,stroke:#1565c0,stroke-width:4px,color:#000
    classDef layer2 fill:#f3e5f5,stroke:#6a1b9a,stroke-width:4px,color:#000
    classDef layer3 fill:#fff3e0,stroke:#e65100,stroke-width:4px,color:#000
    classDef layer4 fill:#e8f5e9,stroke:#2e7d32,stroke-width:4px,color:#000
    classDef layer5 fill:#fce4ec,stroke:#ad1457,stroke-width:4px,color:#000
    classDef layer6 fill:#f1f8e9,stroke:#558b2f,stroke-width:4px,color:#000
    classDef layer7 fill:#fff9c4,stroke:#f57f17,stroke-width:4px,color:#000
    classDef layer8 fill:#e0f2f1,stroke:#00695c,stroke-width:3px,color:#000
    classDef layer9 fill:#ffebee,stroke:#c62828,stroke-width:5px,color:#000

    class USR layer1
    class STD1,SYS1,SYS2 layer2
    class RT1,RT2,RT3 layer3
    class PM1,PM2,PM3,PM4,MM1,MM2,MM3,MM4,FS1,FS2,FS3,NET1,NET2,VT1,VT2,VT3,VT4,IPC1,IPC2,IPC3 layer4
    class KL1,KL2,KL3,KL4 layer5
    class H1,H2,H3,P1,P2,P3,P4,P5 layer6
    class D1,D2,D3,D4,D5,D6,D7 layer7
    class U1,U2,U3 layer8
    class HW layer9
```

### 层次说明

#### 第1层 - 应用层
- 用户应用和系统服务

#### 第2层 - 标准库与API
- `axstd`: ArceOS 标准库
- `arceos_api`: ArceOS API
- `axvisor_api`: Hypervisor API

#### 第3层 - 运行时与特性
- `axruntime`, `axfeat`: 运行时和特性管理
- `axconfig`, `axconfig-gen`: 配置系统

#### 第4层 - 内核核心服务
- **进程与任务**: `axtask`, `axsched`, `starry-process`, `starry-signal`
- **同步与并发**: `axsync`, `kspin`, `kernel_guard`
- **内核库**: `axklib`, `axerrno`, `axio`, `axlog`

#### 第5层 - 子系统
- **内存管理**: `axmm`, `axalloc`, `starry-vm`, `axaddrspace`, `page_table_multiarch`
- **文件系统**: `axfs`, `axfs_vfs`, `axfs_devfs`, `axfs_ramfs`, `rsext4`
- **网络**: `starry-smoltcp`, `axpoll`
- **虚拟化**: `axvcpu`, `arm_vcpu`, `riscv_vcpu`, `x86_vcpu`, `axvm`, `axdevice`

#### 第6层 - 硬件抽象层
- **核心HAL**: `axhal`, `axcpu`, `somehal`
- **平台抽象**: `axplat` + 6个平台实现(ARM64/RISC-V/x86/龙芯)
- **架构特定**: `aarch64_sysreg`, `kasm-aarch64`

#### 第7层 - 驱动层
- **驱动框架**: `axdriver`, `axdriver_base`, `rdrive`
- **总线驱动**: PCI/PCIe
- **设备驱动**: 块设备、VirtIO、串口、中断控制器、定时器等

#### 第8层 - 工具与库
- 初始化、数据结构、Per-CPU、工具库等

#### 第9层 - 开发工具
- `ostool`, `fitimage`, `jkconfig`, `uboot-shell`

## 3. 组织贡献分布图（按技术领域）

```mermaid
graph TB
    %% ==================== 虚拟化技术 (arceos-hypervisor) ====================
    subgraph HYPERVISOR["arceos-hypervisor 组织 - 虚拟化技术 (20个组件)"]
        direction TB
        
        subgraph HV_Core["Hypervisor 核心"]
            direction LR
            HV1["axvisor<br/>Hypervisor"]
            HV2["axvisor_api<br/>API"]
        end
        
        subgraph HV_VCPU["VCPU 实现"]
            direction LR
            HV3["axvcpu<br/>抽象层"]
            HV4["arm_vcpu/vgic<br/>ARM"]
            HV5["riscv_vcpu/vplic<br/>RISC-V"]
            HV6["x86_vcpu/vlapic<br/>x86"]
        end
        
        subgraph HV_VM["虚拟机管理"]
            direction LR
            HV7["axvm<br/>VM管理"]
            HV8["axvmconfig<br/>配置"]
            HV9["axdevice<br/>虚拟设备"]
            HV10["axhvc<br/>HyperCall"]
        end
        
        subgraph HV_Support["支持组件"]
            direction LR
            HV11["axaddrspace<br/>地址空间"]
            HV12["aarch64_sysreg<br/>寄存器"]
            HV13["axklib<br/>内核库"]
        end
    end

    %% ==================== 核心OS (arceos-org) ====================
    subgraph ARCEOS["arceos-org 组织 - 核心OS (57个组件)"]
        direction TB
        
        subgraph AR_Core["核心模块"]
            direction LR
            AR1["axstd<br/>标准库"]
            AR2["axruntime<br/>运行时"]
            AR3["axhal<br/>HAL"]
            AR4["axconfig<br/>配置"]
        end
        
        subgraph AR_Kernel["内核子系统"]
            direction LR
            AR5["axtask/axsched<br/>任务调度"]
            AR6["axmm/axalloc<br/>内存管理"]
            AR7["axfs/axfs_vfs<br/>文件系统"]
            AR8["axsync/kspin<br/>同步原语"]
        end
        
        subgraph AR_Plat["平台支持"]
            direction LR
            AR9["axplat<br/>平台抽象"]
            AR10["axplat-aarch64-*<br/>ARM64平台"]
            AR11["axplat-riscv64-*<br/>RISC-V平台"]
            AR12["axplat-x86-*<br/>x86平台"]
        end
        
        subgraph AR_Driver["驱动框架"]
            direction LR
            AR13["axdriver<br/>驱动框架"]
            AR14["axdriver_*<br/>驱动实现"]
            AR15["arm_pl011/pl031<br/>ARM驱动"]
        end
        
        subgraph AR_Lib["工具库"]
            direction LR
            AR16["percpu/axerrno<br/>基础库"]
            AR17["lazyinit/ctor_bare<br/>初始化"]
            AR18["linked_list/handler_table<br/>数据结构"]
        end
    end

    %% ==================== 基础组件 (rcore-os) ====================
    subgraph RCORE["rcore-os 组织 - 基础组件 (13个组件)"]
        direction TB
        
        subgraph RC_Driver["驱动"]
            direction LR
            RC1["virtio-drivers<br/>VirtIO"]
            RC2["arm-gic-driver<br/>GIC"]
            RC3["any-uart<br/>UART"]
        end
        
        subgraph RC_Alloc["分配器"]
            direction LR
            RC4["bitmap-allocator<br/>位图分配器"]
        end
        
        subgraph RC_HAL["硬件抽象"]
            direction LR
            RC5["somehal<br/>HAL"]
            RC6["page-table-*<br/>页表"]
            RC7["pie-boot-*<br/>启动"]
        end
    end

    %% ==================== 系统扩展 (Starry-OS) ====================
    subgraph STARRY["Starry-OS 组织 - 系统扩展 (10个组件)"]
        direction TB
        
        subgraph ST_Proc["进程与内存"]
            direction LR
            ST1["starry-process<br/>进程管理"]
            ST2["starry-vm<br/>虚拟内存"]
            ST3["starry-signal<br/>信号"]
        end
        
        subgraph ST_FS["文件系统"]
            direction LR
            ST4["axfs-ng-vfs<br/>VFS"]
            ST5["rsext4<br/>Ext4"]
        end
        
        subgraph ST_Net["网络"]
            direction LR
            ST6["starry-smoltcp<br/>TCP/IP"]
            ST7["axpoll<br/>IO复用"]
        end
        
        subgraph ST_Debug["调试"]
            direction LR
            ST8["axbacktrace<br/>回溯"]
        end
    end

    %% ==================== 驱动生态 (drivercraft) ====================
    subgraph DRIVERCRAFT["drivercraft 组织 - 驱动生态 (22个组件)"]
        direction TB
        
        subgraph DC_Frame["驱动框架"]
            direction LR
            DC1["rdrive<br/>Rust驱动框架"]
            DC2["rdif-*<br/>驱动接口"]
        end
        
        subgraph DC_Plat["平台驱动"]
            direction LR
            DC3["phytium-mci<br/>Phytium"]
            DC4["rk*-clk<br/>Rockchip"]
            DC5["sdmmc<br/>SD/MMC"]
        end
        
        subgraph DC_Tool["开发工具"]
            direction LR
            DC6["ostool<br/>OS工具"]
            DC7["fitimage<br/>镜像"]
            DC8["uboot-shell<br/>U-Boot"]
        end
    end

    %% ==================== 连接关系 ====================
    HYPERVISOR -.-> ARCEOS
    STARRY -.-> ARCEOS
    ARCEOS --> RCORE
    ARCEOS --> DRIVERCRAFT

    %% ==================== 样式定义 ====================
    classDef hypervisor fill:#e1f5ff,stroke:#01579b,stroke-width:3px,color:#000
    classDef arceos fill:#fff3e0,stroke:#e65100,stroke-width:3px,color:#000
    classDef rcore fill:#f3e5f5,stroke:#4a148c,stroke-width:3px,color:#000
    classDef starry fill:#e8f5e9,stroke:#1b5e20,stroke-width:3px,color:#000
    classDef drivercraft fill:#fff9c4,stroke:#f57f17,stroke-width:3px,color:#000

    class HV1,HV2,HV3,HV4,HV5,HV6,HV7,HV8,HV9,HV10,HV11,HV12,HV13 hypervisor
    class AR1,AR2,AR3,AR4,AR5,AR6,AR7,AR8,AR9,AR10,AR11,AR12,AR13,AR14,AR15,AR16,AR17,AR18 arceos
    class RC1,RC2,RC3,RC4,RC5,RC6,RC7 rcore
    class ST1,ST2,ST3,ST4,ST5,ST6,ST7,ST8 starry
    class DC1,DC2,DC3,DC4,DC5,DC6,DC7,DC8 drivercraft
```

### 组织贡献统计

| 组织 | 组件数量 | Submodule 数量 | 主要贡献领域 |
|-----|---------|---------------|-------------|
| arceos-hypervisor | 20 | 19 | 虚拟化技术（Hypervisor、VCPU、VM管理） |
| arceos-org | 57 | 26 | 核心OS组件（内核、HAL、驱动、文件系统） |
| rcore-os | 13 | 5 | 基础组件（分配器、驱动、硬件抽象） |
| Starry-OS | 10 | 10 | 系统扩展（进程管理、网络、调试） |
| drivercraft | 22 | 0 | 驱动生态（驱动框架、平台驱动、开发工具） |
| **总计** | **121** | **60** | |

## 4. 操作系统核心组成部分

### 架构图说明

本文档包含三个不同视角的架构图：

1. **完整操作系统架构图**：展示所有组件的完整视图，从用户空间到硬件的垂直分层
2. **分层架构图**：类似 Linux 内核的 9 层架构，清晰展示各层职责
3. **组织贡献分布图**：按技术领域展示不同组织的贡献

这些图采用从上到下的分层设计，类似于传统操作系统架构图，便于理解组件间的依赖关系。

### 4.1 进程管理
- **starry-process**: 进程管理核心
- **axtask**: 任务管理
- **axsched**: 调度器
- **starry-signal**: 信号处理
- **cpumask**: CPU 掩码管理

### 4.2 内存管理
- **axmm**: 内存管理器
- **axalloc**, **axallocator**: 内存分配器
- **bitmap-allocator**: 位图分配器
- **starry-vm**: 虚拟内存管理
- **axaddrspace**: 地址空间管理
- **memory_set**: 内存区域集合
- **page_table_multiarch**: 多架构页表支持

### 4.3 文件系统
- **axfs**: 文件系统框架
- **axfs_vfs**, **axfs-ng-vfs**: 虚拟文件系统
- **axfs_devfs**: 设备文件系统
- **axfs_ramfs**: 内存文件系统
- **rsext4**: Ext4 文件系统

### 4.4 设备驱动
- **axdriver**: 驱动框架
- **串口驱动**: any-uart, arm_pl011
- **中断控制器**: arm-gic-driver, riscv_plic
- **VirtIO**: virtio-drivers
- **平台驱动**: RK3568, RK3588, Phytium 等

### 4.5 虚拟化
- **axvcpu**: VCPU 抽象层
- **架构实现**: arm_vcpu, riscv_vcpu, x86_vcpu
- **虚拟中断**: arm_vgic, riscv_vplic, x86_vlapic
- **VM 管理**: axvm, axvmconfig
- **虚拟设备**: axdevice, axhvc
- **Hypervisor API**: axvisor_api

### 4.6 网络
- **starry-smoltcp**: 网络协议栈
- **axpoll**: IO 多路复用

### 4.7 硬件抽象层
- **axhal**: 核心硬件抽象层
- **axcpu**: CPU 抽象
- **somehal**: 硬件抽象
- **axplat**: 平台抽象层
- **平台实现**: ARM64, RISC-V, x86, 龙芯等

### 4.8 同步与并发
- **axsync**: 同步原语
- **kspin**: 内核自旋锁
- **kernel_guard**: 临界区保护
- **percpu**: Per-CPU 变量

## 5. 架构特点

### 5.1 模块化设计
- 每个组件职责单一，接口清晰
- 通过 trait 定义抽象接口
- 支持多种实现替换

### 5.2 多架构支持
- ARM64 (aarch64)
- RISC-V 64
- x86_64
- LoongArch64

### 5.3 虚拟化支持
- 完整的 Hypervisor 实现
- 多架构 VCPU 支持
- 虚拟设备和中断控制器

### 5.4 可扩展性
- 从宏内核到微内核的灵活配置
- 支持多种文件系统
- 丰富的驱动生态

### 5.5 组件复用
- 跨项目共享组件
- 统一的接口标准
- 独立的版本管理

## 6. 操作系统实例

### 6.1 Axvisor
- **定位**: Type-1 Hypervisor
- **特点**: 
  - 基于组件化设计
  - 支持 ARM64, RISC-V, x86
  - 完整的虚拟化功能
  - 实时性支持

### 6.2 StarryOS
- **定位**: 完整的宏内核操作系统
- **特点**:
  - 进程管理和调度
  - 完整的文件系统支持
  - 网络协议栈
  - 多种设备驱动

## 7. 开发工具

### 7.1 配置工具
- **axconfig-gen**: 配置生成工具
- **jkconfig**: 配置管理

### 7.2 构建工具
- **ostool**: 操作系统工具集
- **fitimage**: FIT 镜像生成
- **uboot-shell**: U-Boot 交互工具

### 7.3 调试工具
- **axbacktrace**: 调用栈回溯
- **axlog**: 日志系统

---

*本架构图基于 README.md 中的 121 个组件绘制，展示了 ArceOS 生态系统的完整结构和组织协作模式。*
