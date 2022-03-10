<img align="right" alt="nox_logo" src="docs/img/rv_logo.png" width="100"/>

# NoX RISC-V Core
## Table of Contents
* [Quickstart](#quick)
* [Specifications](#spec)
* [RTL uArch](#uarch)
* [License](#lic)

## <a name="quick"></a> Quickstart

## <a name="spec"></a> Specifications

* RV32IZicsr

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

### CoreMark benchmark

NoX CoreMark score is **125** or **2.5 CoreMark/MHz**. If you have Vivado installed and want to try running in the Arty A7, please try the commands below.
```bash
fusesoc library add core  .
fusesoc run --run --target=coremark_synth core:nox:v0.0.1
```

#### Performance run

As mentioned in the [CoreMark](https://github.com/eembc/coremark) repository, the benchmark needs to run for two sets of seeds 0,0,0x66 and 0x3415,0x3415,0x66. These two sets correspond respectively to PERFORMANCE run and VALIDATION run. Thus the two outputs of the runs are presented down below. According to the reporting rules, the CoreMark score is defined by the metrics of number of iterations per second during the performance run.

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
## <a name="uarch"></a> RTL micro architecture
![NoX uArch](docs/img/nox_diagram.svg)

## <a name="lic"></a> License
NoX is licensed under the permissive MIT license. Please refer to the [LICENSE](LICENSE) file for details.
