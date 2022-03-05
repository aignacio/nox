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

% Please add the following required packages to your document preamble:
% \usepackage{graphicx}
\begin{table}[]
\resizebox{\textwidth}{!}{%
\begin{tabular}{|c|c|c|}
\hline
            & \textbf{CSR} & \textbf{Description}                \\ \hline
\textbf{1}  & mstatus      & Status register                     \\ \hline
\textbf{2}  & mie          & Machine Interrupt enable            \\ \hline
\textbf{3}  & mtvec        & Trap-vector base-address            \\ \hline
\textbf{4}  & mscratch     & Scratch register                    \\ \hline
\textbf{5}  & mepc         & Exception program counter           \\ \hline
\textbf{6}  & mcause       & Machine cause register              \\ \hline
\textbf{7}  & mtval        & Machine trap value                  \\ \hline
\textbf{8}  & mip          & Machine pending interrupt           \\ \hline
\textbf{9}  & cycle        & RO shadow of mcycle                 \\ \hline
\textbf{10} & cycleh       & RO shadow of mcycle {[}Upper 32b{]} \\ \hline
\textbf{11} & misa         & Machine ISA register                \\ \hline
\textbf{12} & mhartid      & Hart ID register                    \\ \hline
\end{tabular}%
}
\end{table}

## <a name="uarch"></a> RTL micro architecture
![NoX uArch](docs/img/nox_diagram.svg)

## <a name="lic"></a> License
NoX is licensed under the permissive MIT license. Please refer to the [LICENSE](LICENSE) file for details.
