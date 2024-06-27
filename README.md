[![Lint](https://github.com/aignacio/nox/actions/workflows/lint.yaml/badge.svg)](https://github.com/aignacio/nox/actions/workflows/lint.yaml) 

<img align="right" alt="rvss" src="docs/img/rv_logo.png" width="100"/>
<img alt="nox" src="docs/img/logo_nox.svg" width="200"/>

# NoX RISC-V Core

## Table of Contents
* [Introduction](#intro)
* [Quickstart](#quick)
* [RTL uArch](#uarch)
* [NoX SoC](#nox_soc)
* [FreeRTOS](#freertos)
* [Compliance Tests](#compliance)
* [CoreMark](#coremark)
* [Synthesis](#synth)
* [License](#lic)

## <a name="intro"></a> Introduction
NoX is a 32-bit RISC-V core designed in System Verilog language aiming both `FPGA` and `ASIC` flows. The core was projected to be easily integrated and simulated as part of an SoC, with `makefile` targets for simple standalone simulation or with an interconnect and peripherals. In short, the core specs are listed here:

- RV32IZicsr
- 4 stages / single-issue / in-order pipeline
- M-mode privileged spec.
- 2.5 CoreMark/MHz
- Software/External/Timer interrupt
- Support non/vectored IRQs
- Configurable fetch FIFO size
- AXI4 or AHB I/F

The CSRs that are implemented in the core are listed down below, more CSRs can be easily integrated within [rtl/csr.sv](rtl/csr.sv) by extending the decoder. Instructions such as `ECALL/EBREAK` are supported as well and will synchronously trap the core, forcing a jump to the `MTVEC` value. All interrupts will redirect the core to the `MTVEC` as well as it is considered asynchronous traps.

|    |    CSR   |           Description           |
|:--:|:--------:|:-------------------------------:|
|  1 |  mstatus |         Status register         |
|  2 |    mie   |     Machine Interrupt enable    |
|  3 |   mtvec  |     Trap-vector base-address    |
|  4 | mscratch |         Scratch register        |
|  5 |   mepc   |    Exception program counter    |
|  6 |  mcause  |      Machine cause register     |
|  7 |   mtval  |        Machine trap value       |
|  8 |    mip   |    Machine pending interrupt    |
|  9 |   cycle  |       RO shadow of mcycle       |
| 10 |  cycleh  | RO shadow of mcycle [Upper 32b] |
| 11 |   misa   |       Machine ISA register      |
| 12 |  mhartid |         Hart ID register        |

## <a name="quick"></a> Quickstart
**NoX** uses a [docker container](https://hub.docker.com/repository/docker/aignacio/nox) to build and simulate a standalone instance of the core or an SoC requiring no additional tools to the user apart from docker itself. Please be aware that the process of building the simulator might require more resources than what is allocated to the `docker`, therefore if the output shows `Killed`, increase the **memory** and the **cpu** resources. To quickly build a simple instance of the core with two memories and simulate it through linux, follow:

```bash
make all # Will first download the docker container and build the design
make run # Should simulate the design for 100k clock cycles 
```
You should expect in the terminal an output like this:
```bash

  _   _       __  __
 | \ | |  ___ \ \/ /
 |  \| | / _ \ \  /
 | |\  || (_) |/  \
 |_| \_| \___//_/\_\
 NoX RISC-V Core RV32I

 CSRs:
 mstatus        0x1880
 misa           0x40000100
 mhartid        0x0
 mie            0x0
 mip            0x0
 mtvec          0x80000101
 mepc           0x0
 mscratch       0x0
 mtval          0x0
 mcause         0x0
 cycle          110

[ASYNC TRAP] IRQ Software
[ASYNC TRAP] IRQ timer
[ASYNC TRAP] IRQ External
[ASYNC TRAP] IRQ External
[ASYNC TRAP] IRQ Software
[ASYNC TRAP] IRQ timer
...
```
If you have [gtkwave](http://gtkwave.sourceforge.net) installed, you can also open the simulation run `fst` with:
```
make GTKWAVE_PRE="" wave
```
For more `targets`, please run
```bash
make help
```

## <a name="uarch"></a> RTL micro architecture
NoX core is a **4-stages** single issue, in-order pipeline with [**full bypass**](https://en.wikipedia.org/wiki/Classic_RISC_pipeline#Solution_A._Bypassing), which means that all data hazards will have no impact in terms of stalling the design. The only scenario where we can have a *stall* is when the core has back-pressure from the LSU due to some pending operation on-the-fly. The micro-architecture is presented in the figure below with all the signals matching the top [rtl/nox.sv](rtl/nox.sv).
![NoX uArch](docs/img/nox_diagram.svg)
In the file [rtl/inc/nox_pkg.svh](rtl/inc/nox_pkg.svh), there are two presets of `verilog` macros (Lines 8/9) that can be un/commented depending on the final target. For `TARGET_FPGA`, it is defined an **active-low** & **synchronous reset**. Otherwise, if the macro `TARGET_ASIC` is defined, then this change to **active-high** & **asynchronous reset**. In case it is required another combination of both, please follow what is coded there.

As an estimative of resources utilization, listed below are the synthesis numbers of the design for the [Kintex 7 K325T](https://www.xilinx.com/support/documentation/data_sheets/ds182_Kintex_7_Data_Sheet.pdf) (`xc7k325tffg676-1`) @100MHz using Vivado 2020.2.

| **Name**                           | **Slice LUTs** | **Slice Registers** | **F7 Muxes** | **F8 Muxes** | **Slice** | **LUT as Logic** |
|------------------------------------|:--------------:|:-------------------:|:------------:|:------------:|:---------:|:----------------:|
|   u_nox (nox)                      |   2517         |   1873              |   182        |   89         |   1225    |   2517           |
|   u_wb (wb)                        |   32           |   33                |   0          |   0          |   34      |   32             |
|   u_reset_sync (reset_sync)        |   1            |   2                 |   0          |   0          |   2       |   1              |
|   u_lsu (lsu)                      |   538          |   105               |   1          |   0          |   266     |   538            |
|   u_fetch (fetch)                  |   276          |   134               |   0          |   0          |   154     |   276            |
|   u_fifo_l0 (fifo)                 |   259          |   68                |   0          |   0          |   125     |   259            |
|   u_execute (execute)              |   229          |   359               |   0          |   0          |   254     |   229            |
|   u_csr (csr)                      |   187          |   255               |   0          |   0          |   206     |   187            |
|   u_decode (decode)                |   1445         |   1240              |   181        |   89         |   1000    |   1445           |
|   u_register_file (register_file)  |   615          |   1056              |   181        |   89         |   664     |   615            |

## <a name="nox_soc"></a> NoX SoC

Inside this repository it is also available a System-on-a-chip **(SoC)** with the following micro-architecture. It contains a **boot ROM** memory with the bootloader program [(sw/bootloader)](sw/bootloader) that can be used to transfer new programs to the SoC by using the [bootloader_elf.py](sw/bootloader_elf.py) script. The script will read an [ELF file](https://youtu.be/nC1U1LJQL8o) and transfer it through the serial UART to the address defined in its content memory map, also in the end of the transfer, it will set the `entry point address` of the ELF to the **RST Ctrl** peripheral forcing the NoX CPU to boot from this address in the next reset cycle. To return back to the bootloader program, an additional input (`bootloader_i`), once it is asserted, will force the RST Ctrl to be set back to the boot ROM address. To program an `Arty A7 FPGA` and download a program to the SoC, follow the steps below.

![nox_soc](docs/img/nox_soc.svg)

To generate the FPGA image and program the board (vivado required):
```bash
fusesoc library add core  .
fusesoc run --run --target=a7_synth core:nox:v0.0.1
```

Once it is finished and the board is programmed, the following output will be shown:
```bash
  __    __            __    __         ______              ______   
 |  \  |  \          |  \  |  \       /      \            /      \  
 | $$\ | $$  ______  | $$  | $$      |  $$$$$$\  ______  |  $$$$$$\ 
 | $$$\| $$ /      \  \$$\/  $$      | $$___\$$ /      \ | $$   \$$ 
 | $$$$\ $$|  $$$$$$\  >$$  $$        \$$    \ |  $$$$$$\| $$       
 | $$\$$ $$| $$  | $$ /  $$$$\        _\$$$$$$\| $$  | $$| $$   __  
 | $$ \$$$$| $$__/ $$|  $$ \$$\      |  \__| $$| $$__/ $$| $$__/  \ 
 | $$  \$$$ \$$    $$| $$  | $$       \$$    $$ \$$    $$ \$$    $$ 
  \$$   \$$  \$$$$$$  \$$   \$$        \$$$$$$   \$$$$$$   \$$$$$$  

 NoX SoC UART Bootloader 

 CSRs:
 mstatus        0x1880
 misa           0x40000100
 mhartid        0x0
 mie            0x0
 mip            0x0
 mtvec          0x101
 mepc           0x0
 mscratch       0x0
 mtval          0x0
 mcause         0x0
 cycle          2823444

 Freq. system:  50000000 Hz
 UART Speed:    115200 bits/s
 Type h+[ENTER] for help!

> 
```

To transfer a program through the bootloader script:
```bash
make -C sw/bootloader all
make -C sw/soc_hello_world all
python3 sw/bootloader_elf.py --elf sw/soc_hello_world/output/soc_hello_world.elf
# Press rst button in the board
```

### Example running on Kintex 7 Qmtech Board

If you have a [Kintex 7 Qmtech board](https://github.com/ChinaQMTECH/QMTECH_XC7K325T_CORE_BOARD?spm=a2g0o.detail.1000023.1.425dffdb5DOMQd), you can build/program the target with the commands below. 
```bash
make -C sw/bootloader all
fusesoc library add core  .
fusesoc run --run --target=x7_synth core:nox:v0.0.1
# Once the FPGA bitstream is downloaed, change the program to the demo
python3 sw/bootloader_elf.py --elf sw/soc_hello_world/output/soc_hello_world.elf --device YOUR_SERIAL_ADAPTER --speed 230400
```

The bootloader PB and the reset CPU are respectively SW2 and SW1 for the [K7 core board](https://github.com/ChinaQMTECH/DB_FPGA/blob/main/QMTECH_DB_For_FPGA_V04.pdf). You should have something like this:
![NoX SoC K7](docs/img/nox_soc_qmtech_k7.gif)

## <a name="freertos"></a> FreeRTOS

If you are willing to use FreeRTOS with this core, there is a template available here [NoX FreeRTOS template](https://github.com/aignacio/nox_freertos) with a running demo with `4x Tasks` running in parallel in the **NoX SoC**.

## <a name="compliance"></a> RISC-V ISA Compliance tests
To run the compliance tests, two steps needs to be followed.
1. Compile nox_sim with 2MB IRAM / 128KB DRAM
2. Run the RISCOF framework using SAIL-C RISC-V simulator as reference

```bash
make build_comp # It might take a while...
make run_comp
```
Once it is finished, you can open the report file available at **riscof_compliance/riscof_work/report.html** to check the status. The run should finished with a similar report like the one available at [docs/report_compliance.html](docs/report_compliance.html).

## <a name="coremark"></a> CoreMark
Inside the [sw/coremark](sw/coremark), there is a folder called **nox** which is the platform port of the [CoreMark benchmark](https://github.com/eembc/coremark) to the core. NoX CoreMark score is **125** or **2.5 CoreMark/MHz**. If you have [Vivado](https://www.xilinx.com/products/design-tools/vivado.html) installed and want to try running in the [Arty A7 FPGA board](https://digilent.com/shop/arty-a7-artix-7-fpga-development-board/), please follow the commands below.
```bash
fusesoc library add core  .
fusesoc run --run --target=coremark_synth core:nox:v0.0.1
```
As mentioned in the [CoreMark](https://github.com/eembc/coremark) repository, the benchmark needs to run for two sets of seeds 0,0,0x66 and 0x3415,0x3415,0x66. These two sets correspond respectively to PERFORMANCE run and VALIDATION run. Thus the two outputs of the runs are presented down below. According to the reporting rules, the CoreMark score is defined by the metrics of number of iterations per second during the performance run.

**Performance run:**
```bash
 -----------
 [NoX] Coremark Start
 -----------
2K performance run parameters for coremark.
CoreMark Size    : 666
Total ticks      : 848608849
Total time (secs): 16
Iterations/Sec   : 125
Iterations       : 2000
Compiler version : riscv-none-embed-gcc (xPack GNU RISC-V Embedded GCC x86_64) 10.2.0
Compiler flags   : -O0 -g -march=rv32i -mabi=ilp32 -Wall -Wno-unused -ffreestanding --specs=nano.specs -DPRINTF_DISABLE_SUPPORT_FLOAT -DPRINTF_DISABLE_SUPPORT_EXPONENTIAL -DPRINTF_DISABLE_SUPPORT_LONG_LONG -Wall -Wno-main -DPERFORMANCE_RUN=1  -O0 -g
Memory location  : STACK
seedcrc          : 0xe9f5
[0]crclist       : 0xe714
[0]crcmatrix     : 0x1fd7
[0]crcstate      : 0x8e3a
[0]crcfinal      : 0x4983
Correct operation validated. See README.md for run and reporting rules.
```
**Validation run:**
```bash
 -----------
 [NoX] Coremark Start
 -----------
2K validation run parameters for coremark.
CoreMark Size    : 666
Total ticks      : 1080616261
Total time (secs): 21
Iterations/Sec   : 95
Iterations       : 2000
Compiler version : riscv-none-embed-gcc (xPack GNU RISC-V Embedded GCC x86_64) 10.2.0
Compiler flags   : -O0 -g -march=rv32i -mabi=ilp32 -Wall -Wno-unused -ffreestanding --specs=nano.specs -DPRINTF_DISABLE_SUPPORT_FLOAT -DPRINTF_DISABLE_SUPPORT_EXPONENTIAL -DPRINTF_DISABLE_SUPPORT_LONG_LONG -Wall -Wno-main -DVALIDATION_RUN=1  -O0 -g
Memory location  : STACK
seedcrc          : 0x18f2
[0]crclist       : 0xe3c1
[0]crcmatrix     : 0x0747
[0]crcstate      : 0x8d84
[0]crcfinal      : 0x0cac
Correct operation validated. See README.md for run and reporting rules.
```
## <a name="synth"></a> Synthesis

Adapting the setup to [Ibex Core - low risc](https://github.com/lowRISC/ibex/tree/master/syn), attached is the command to perform synthesis on the 45nm nangate PDK.
```bash
docker run  -v .:/test -w /test --rm aignacio/oss_cad_suite:latest bash -c "cd /test/synth && ./syn_yosys.sh"
```

### Area results:
* 27.04 kGE @ 250MHz in 45nm

```bash
...
End of script. Logfile hash: 39230763f8, CPU: user 15.51s system 0.15s, MEM: 175.05 MB peak
Yosys 0.40+25 (git sha1 171577f90, clang++ 14.0.0-1ubuntu1.1 -fPIC -Os)
Time spent: 72% 2416x select (5 sec), 22% 2x read_verilog (1 sec), ...
Area in kGE =  27.04
```

## <a name="lic"></a> License

NoX is licensed under the permissive MIT license. Please refer to the [LICENSE](LICENSE) file for details.

## Ref.

```tex
@misc{silva2024noxcompactopensourceriscv,
      title={NoX: a Compact Open-Source RISC-V Processor for Multi-Processor Systems-on-Chip}, 
      author={Anderson I. Silva and Altamiro Susin and Fernanda L. Kastensmidt and Antonio Carlos S. Beck and Jose Rodrigo Azambuja},
      year={2024},
      eprint={2406.17878},
      archivePrefix={arXiv},
      primaryClass={cs.AR},
      url={https://arxiv.org/abs/2406.17878}, 
}
```
