`ifndef _UTILS_PKG_
`define _UTILS_PKG_
  package utils_pkg;
    //import axi_pkg::*;
    //import nox_pkg::*;
    //import core_bus_pkg::*;
    //export *::*;
    `include "axi_pkg.svh"
    `include "ahb_pkg.svh"
    `include "nox_pkg.svh"
    `include "core_bus_pkg.svh"
    `include "riscv_pkg.svh"
    `include "eth_pkg.svh"
  endpackage
`endif
