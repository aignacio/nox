`ifndef _NOX_PKG_
`define _NOX_PKG_
  //package NOX_pkg;

  //**********************//
  //  Core Defines
  //**********************//
  `define CORE_VERSION  "v0.1"
  `define TARGET_FPGA
  //`define TARGET_ASIC
  //`define EN_RTL_VERBOSE

  `define TARGET_IF_AXI
  //`define TARGET_IF_AHB

  `ifdef TARGET_FPGA
    `define ACT_L_RESET
    `define SYNC_RESET
    `define OP_RST_H  '1
    `define OP_RST_L  '0
    //`define OP_RST_H  'x
    //`define OP_RST_L  'x
  `endif

  `ifdef TARGET_ASIC
    `define ACT_H_RESET
    `define ASYNC_RESET
    `define OP_RST_H  '1
    `define OP_RST_L  '0
  `endif

  //`define M_VENDOR_ID   "None" //needs to follow JEDEC
  //`define M_ARCH_ID     "32I"  //needs to follow JEDEC
  //`define M_IMPL_ID     "4STG"
  `define M_HART_ID     0
  `define M_ISA_ID      'h40000100
  `define M_ISA_ID_M    'h40001100

  // Reset Macros for different sets
  `ifdef ACT_H_RESET
    `define RST_MODE          1
    `define RST_TYPE(_rst)    if (_rst)
    `define _RST_EVENT(_rst)  posedge _rst
  `elsif ACT_L_RESET
    `define RST_MODE          0
    `define RST_TYPE(_rst)    if (~_rst)
    `define _RST_EVENT(_rst)  negedge _rst
  `endif

  `ifdef SYNC_RESET
    `define CLK_PROC(_clk, _rst)  always_ff @ (posedge _clk)
  `elsif ASYNC_RESET
    `define CLK_PROC(_clk, _rst)  always_ff @ (posedge _clk or `_RST_EVENT(_rst))
  `endif

  `ifdef EN_RTL_VERBOSE
    `define P_VAR(_stage,_var,_val) $display(`"[%0t] INFO STAGE [%s] %s => %h`", \
                                    $realtime, _stage, _var, _val);
    `define P_MSG(_stage,_msg)      $display(`"[%0t] INFO STAGE [%s] %s`", \
                                    $realtime, _stage, _msg);
  `else
    `define P_VAR(_stage,_var,_val)
    `define P_MSG(_stage,_msg)
  `endif

  `define ERROR(_msg,_val)          assert (0) $display ("[ERROR] %s => %h", _msg, _val);

  `define DUMP_WAVES_XCELIUM  initial begin                 \
                                $shm_open(`"waves.shm`");   \
                                $shm_probe(`"ASM`");        \
                              end

  //**********************//
  //  Core Types
  //**********************//
  typedef logic valid_t;
  typedef logic ready_t;

  //endpackage
`endif
