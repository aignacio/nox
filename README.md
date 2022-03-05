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

## <a name="uarch"></a> RTL micro architecture
![NoX uArch](docs/img/nox_diagram.svg)

## <a name="lic"></a> License
NoX is licensed under the permissive MIT license. Please refer to the [LICENSE](LICENSE) file for details.
