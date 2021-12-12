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

  `ifdef TARGET_FPGA
    `define ACT_L_RESET
    `define SYNC_RESET
    `define OP_RST_H  'x
    `define OP_RST_L  'x
  `endif

  `ifdef TARGET_ASIC
    `define ACT_H_RESET
    `define ASYNC_RESET
    `define OP_RST_H  '1
    `define OP_RST_L  '0
  `endif

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

  typedef enum logic [1:0] {
    FF,
    BRAM_XILINX
  } mem_t;

  typedef enum logic {
    false,
    true
  } bool_t;

  typedef enum logic [1:0] {
    IDLE,
    FETCH_CLEAR,
    FETCH_RUN
  } fetch_fsm_t;

  //endpackage
`endif
