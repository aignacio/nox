/**
* File              : fetch.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 16.10.2021
 * Last Modified Date: 24.02.2022
 */
module fetch
  import utils_pkg::*;
#(
  parameter int SUPPORT_DEBUG  = 1,
  parameter int L0_BUFFER_SIZE = 2, // Max instrs locally stored
  parameter int MAX_OT_TXN     = 4  // Max outstanding txns, low numbers might impact perf.
)(
  input                 clk,
  input                 rst,
  // Core bus fetch I/F
  output  s_cb_mosi_t   instr_cb_mosi_o,
  input   s_cb_miso_t   instr_cb_miso_i,
  // Start I/F
  input                 fetch_start_i,
  input   pc_t          fetch_start_addr_i,
  // From EXEC stg
  input                 fetch_req_i,
  input   pc_t          fetch_addr_i,
  // To DEC I/F
  output  valid_t       fetch_valid_o,
  input   ready_t       fetch_ready_i,
  output  instr_raw_t   fetch_instr_o,
  // Trap - Instruction access fault
  output  s_trap_info_t trap_info_o
);
  typedef logic [$clog2(L0_BUFFER_SIZE>1?L0_BUFFER_SIZE:2):0] buffer_t;

  typedef enum logic [1:0] {
    IDLE,
    FETCH_CLEAR,
    FETCH_STOP,
    FETCH_RUN
  } fetch_fsm_t;

  fetch_fsm_t   fetch_st_ff, next_fetch_sm;
  logic         instr_access_fault;
  cb_addr_t     pc_addr_ff, next_pc_addr;
  cb_addr_t     new_addr_ff, next_new_pc;
  logic         requested_ff, next_requested;
  logic         ignore_data;
  logic         ap_received;
  logic         received_data;
  logic         full_fifo;

  logic         clear_buffer;
  logic         get_next_instr;
  logic         write_instr;
  buffer_t      buffer_space;
  instr_raw_t   instr_buffer;
  instr_raw_t   instr_from_mem;

  always_comb begin
    instr_cb_mosi_o = s_cb_mosi_t'('0);
    next_requested  = requested_ff;
    next_pc_addr    = pc_addr_ff;
    ignore_data     = 'b0;
    received_data   = instr_cb_miso_i.rd_valid;
    instr_from_mem  = instr_cb_miso_i.rd_data;
    clear_buffer    = 'b0;
    write_instr     = 'b0;
    ap_received     = instr_cb_miso_i.rd_addr_ready;
    next_new_pc     = new_addr_ff;

    if (requested_ff && received_data) begin
      next_requested = 'b0;
      case (fetch_st_ff)
        FETCH_CLEAR: begin
          ignore_data  = 'b1;
          next_pc_addr = new_addr_ff;
        end
        FETCH_RUN: begin
          write_instr  = 'b1;
        end
        default:  next_requested = 'b0;
      endcase
    end

    if (fetch_st_ff == FETCH_STOP) begin
      instr_cb_mosi_o.rd_addr       = cb_addr_t'({pc_addr_ff[31:2],2'd0});
      instr_cb_mosi_o.rd_addr_valid = 'b1;
      instr_cb_mosi_o.rd_size       = cb_size_t'(CB_WORD);
      next_requested = 'b1;
    end

    if (fetch_st_ff == FETCH_RUN) begin
      instr_cb_mosi_o.rd_addr       = cb_addr_t'({pc_addr_ff[31:2],2'd0});
      instr_cb_mosi_o.rd_addr_valid = 'b1;
      instr_cb_mosi_o.rd_size       = cb_size_t'(CB_WORD);
      next_requested = 'b1;
      if (ap_received) begin
        next_pc_addr = pc_addr_ff + 'd4;
      end
    end

    if (fetch_req_i) begin
      clear_buffer = 'b1;
      next_new_pc  = fetch_addr_i;
    end

    instr_cb_mosi_o.rd_ready = ~full_fifo;
  end

  always_comb begin : trap_control
    trap_info_o = s_trap_info_t'('0);
    instr_access_fault = instr_cb_miso_i.rd_valid &&
                         (instr_cb_miso_i.rd_resp != CB_OKAY);

    if (instr_access_fault) begin
      trap_info_o.active  = 'b1;
      trap_info_o.pc_addr = pc_addr_ff;
      trap_info_o.mtval   = pc_addr_ff;
    end
  end : trap_control

  always_comb begin : fetch_fsm_control
    next_fetch_sm = fetch_st_ff;

    /* verilator lint_off CASEINCOMPLETE */
    unique case (fetch_st_ff)
      IDLE:         next_fetch_sm = fetch_start_i ? FETCH_RUN   : IDLE;
      FETCH_CLEAR:  next_fetch_sm = received_data ? FETCH_RUN   : FETCH_CLEAR;
      FETCH_STOP:   next_fetch_sm = ap_received   ? FETCH_CLEAR : FETCH_STOP;
      FETCH_RUN:    next_fetch_sm = fetch_req_i   ? (ap_received ? FETCH_CLEAR : FETCH_STOP) : FETCH_RUN;
      default:      next_fetch_sm = fetch_st_ff;
    endcase
    /* verilator lint_on CASEINCOMPLETE */
  end : fetch_fsm_control

  `CLK_PROC(clk, rst) begin
    `RST_TYPE(rst) begin
      fetch_st_ff  <= fetch_fsm_t'(IDLE);
      pc_addr_ff   <= cb_addr_t'(fetch_start_addr_i);
      requested_ff <= 'b0;
      new_addr_ff  <= cb_addr_t'('0);
    end
    else begin
      fetch_st_ff  <= next_fetch_sm;
      pc_addr_ff   <= next_pc_addr;
      requested_ff <= next_requested;
      new_addr_ff  <= next_new_pc;
    end
  end

  always_comb begin : fetch_proc_if
    fetch_valid_o = 'b0;
    fetch_instr_o = 'd0;
    get_next_instr = 'b0;

    // We assert valid instr if:
    // 1 - There's no req to fetch a new addr
    // 2 - There's data inside the FIFO
    if (~fetch_req_i && (buffer_space != 'd0)) begin
      // We request to read the FIFO if:
      // 3 - The next stage is ready to receive
      fetch_valid_o = 'b1;
      fetch_instr_o = instr_buffer;
      if (fetch_ready_i) begin
        get_next_instr = 'b1;
      end
    end
  end : fetch_proc_if

  fifo #(
    .SLOTS    (L0_BUFFER_SIZE),
    .WIDTH    (32)
  ) u_fifo_l0 (
    .clk      (clk),
    .rst      (rst),
    .clear_i  (clear_buffer),
    .write_i  (write_instr),
    .read_i   (get_next_instr),
    .data_i   (instr_from_mem),
    .data_o   (instr_buffer),
    .error_o  (),
    .full_o   (full_fifo),
    .empty_o  (),
    .ocup_o   (buffer_space)
  );

`ifdef COCOTB_SIM
  `ifdef XCELIUM
    `DUMP_WAVES_XCELIUM
  `endif
`endif
endmodule
