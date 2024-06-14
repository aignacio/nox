#!/bin/bash

# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# This script drives the experimental Ibex synthesis flow. More details can be
# found in README.md

set -e
set -o pipefail

error () {
    echo >&2 "$@"
    exit 1
}

teelog () {
    tee "$LR_SYNTH_OUT_DIR/log/$1.log"
}

if [ ! -f syn_setup_nox.sh ]; then
    error "No syn_setup.sh file: see README.md for instructions"
fi

#-------------------------------------------------------------------------
# setup flow variables
#-------------------------------------------------------------------------
source syn_setup_nox.sh

#-------------------------------------------------------------------------
# use sv2v to convert all SystemVerilog files to Verilog
#-------------------------------------------------------------------------

LR_DEP_SOURCES=(
    "prim_generic/rtl/prim_generic_buf.sv"
    "prim_generic/rtl/prim_generic_flop.sv"
)

mkdir -p "$LR_SYNTH_OUT_DIR/generated"
mkdir -p "$LR_SYNTH_OUT_DIR/log"
mkdir -p "$LR_SYNTH_OUT_DIR/reports/timing"

# Convert dependency sources
for file in "${LR_DEP_SOURCES[@]}"; do
    module=$(basename -s .sv "$file")

    sv2v \
        --define=SYNTHESIS --define=YOSYS \
        -Iprim/rtl \
        "$file" \
        > "$LR_SYNTH_OUT_DIR"/generated/"${module}".v
done

# Convert NoX s.verilog file
#nox_core=$(find "../rtl" -iname "*.sv" -type f)

#nox_files=(" ../bus_arch_sv_pkg/amba_axi_pkg.sv"
           #" ../bus_arch_sv_pkg/amba_ahb_pkg.sv"
           #" ../rtl/inc/nox_pkg.svh"
           #" ../rtl/inc/core_bus_pkg.svh"
           #" ../rtl/inc/riscv_pkg.svh"
           #" ../rtl/inc/nox_utils_pkg.sv"
#)
#sv2v            \
  #-I../rtl/inc  \
  #$nox_files > nox.v

# Convert core sources
for file in ../rtl/*.sv; do
  module=$(basename -s .sv "$file")

  # Skip packages
  if echo "$module" | grep -q '_pkg$'; then
      continue
  fi

  sv2v \
    --define=SYNTHESIS --define=YOSYS --define=NO_ASSERTIONS \
    ../rtl/inc/nox_pkg.svh \
    ../rtl/inc/core_bus_pkg.svh \
    ../rtl/inc/riscv_pkg.svh \
    ../rtl/inc/nox_utils_pkg.sv \
    ../bus_arch_sv_pkg/*_pkg.sv \
    -I../rtl/inc \
    -I../vendor/lowrisc_ip/dv/sv/dv_utils \
    "$file" \
    > "$LR_SYNTH_OUT_DIR"/generated/"${module}".v

  # Make sure auto-generated primitives are resolved to generic primitives
  # where available.
  #sed -i 's/prim_buf/prim_generic_buf/g'  "$LR_SYNTH_OUT_DIR"/generated/"${module}".v
  #sed -i 's/prim_flop/prim_generic_flop/g' "$LR_SYNTH_OUT_DIR"/generated/"${module}".v
done

# remove tracer (not needed for synthesis)
#rm -f "$LR_SYNTH_OUT_DIR"/generated/ibex_tracer.v

# remove the FPGA & register-based register file (because we will use the
# latch-based one instead)
#rm -f "$LR_SYNTH_OUT_DIR"/generated/ibex_register_file_ff.v
#rm -f "$LR_SYNTH_OUT_DIR"/generated/ibex_register_file_fpga.v

yosys -c ./tcl/yosys_run_synth.tcl |& teelog syn || {
    error "Failed to synthesize RTL with Yosys"
}

sta ./tcl/sta_run_reports.tcl |& teelog sta || {
    error "Failed to run static timing analysis"
}

./translate_timing_rpts.sh

python/get_kge.py "$LR_SYNTH_CELL_LIBRARY_PATH" "$LR_SYNTH_OUT_DIR"/reports/area.rpt
