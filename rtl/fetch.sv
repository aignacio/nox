/**
 * File              : fetch.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 16.10.2021
 * Last Modified Date: 09.12.2021
 */
module fetch
  import utils_pkg::*;
#(
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
  output  logic         instr_access_fault_o,
  output  s_trap_info_t trap_info_o
);
  typedef logic [$clog2(L0_BUFFER_SIZE>1?L0_BUFFER_SIZE:2):0] buffer_t;
  typedef logic [$clog2(MAX_OT_TXN):0] cnt_ot_t;

  cnt_ot_t      ot_cnt_ff, next_ot_cnt;
  fetch_fsm_t   fetch_st_ff, next_fetch_sm;
  instr_raw_t   instr_buffer;
  buffer_t      buffer_space;
  pc_t          pc_ff, next_pc;
  instr_raw_t   instr_from_mem;
  s_trap_info_t trap_ff, next_trap;

  logic fetch_full;
  logic fetch_trig_ff, next_trig;
  logic fetch_start_ff, next_fetch_start;
  logic fetch_req_trig, fetch_start_trig;
  logic req_sent;
  logic answer_recv;
  logic get_next_instr;
  logic clear_buffer;
  logic write_instr;
  logic after_clr_valid_ff, next_after_clr_valid;

  always_comb begin : cb_fetch
    instr_cb_mosi_o = s_cb_mosi_t'('0);
    next_trig = fetch_req_i;

    // Only used during start
    next_fetch_start = fetch_start_i;
    fetch_start_trig = (next_fetch_start && ~fetch_start_ff);

    fetch_req_trig = fetch_start_trig ||
                     (next_trig && ~fetch_trig_ff);
    next_pc = pc_ff;
    fetch_full = (buffer_space == buffer_t'(L0_BUFFER_SIZE));
    clear_buffer = fetch_req_trig;
    write_instr = 'b0;
    instr_access_fault_o = 'b0;
    instr_from_mem = 'd0;
    next_after_clr_valid = after_clr_valid_ff;

    instr_cb_mosi_o.rd_ready = ~fetch_full;

    // Memory reply
    // If we received something (rd_valid) and there're no old answers
    // from previous txns due to a fetch req (fetch_st_ff != FETCH_CLEAR)
    if (instr_cb_miso_i.rd_valid && (fetch_st_ff != FETCH_CLEAR) && after_clr_valid_ff) begin
      if ((instr_cb_miso_i.rd_resp == CB_OKAY) && ~fetch_full) begin
        write_instr = 'b1;
        instr_from_mem = instr_cb_miso_i.rd_data;
      end
      else begin
        instr_access_fault_o = 'b1;
      end
    end

    // Request to mem new instr IF:
    // 1) We are not in the IDLE st and we have space left
    // 2) AND we are not in the fetch clear
    // 3) AND we didn't reach the max OT limits
    // 4) AND previous answers were cleared
      /* verilator lint_off WIDTH */
    if ((fetch_st_ff != IDLE) && ~fetch_full && ~fetch_req_trig &&
        (ot_cnt_ff < MAX_OT_TXN) && (after_clr_valid_ff)) begin
    /* verilator lint_on WIDTH */
      instr_cb_mosi_o.rd_addr_valid = 'b1;
      instr_cb_mosi_o.rd_size = cb_size_t'(CB_WORD);
      instr_cb_mosi_o.rd_addr = cb_addr_t'({next_pc[31:2],2'd0});
      instr_cb_mosi_o.rd_addr = cb_addr_t'({next_pc[31:2],2'd0});
    end

    req_sent = instr_cb_mosi_o.rd_addr_valid && instr_cb_miso_i.rd_addr_ready;
    answer_recv = instr_cb_mosi_o.rd_ready && instr_cb_miso_i.rd_valid;

    if (clear_buffer) begin
      next_pc = fetch_start_trig ? fetch_start_addr_i : {fetch_addr_i[31:2],2'd0};
      `P_MSG("FETCH","Clear L0 buffer")
    end
    else begin
      if (req_sent) begin
        next_pc = {pc_ff[31:2],2'd0} + 'd4;
      end
    end

    // This is used to discard previous OT answers
    // after we have a fetch clear
    next_ot_cnt = ot_cnt_ff + cnt_ot_t'(req_sent) - cnt_ot_t'(answer_recv);

    if (after_clr_valid_ff) begin
      if (fetch_req_trig) begin
        next_after_clr_valid = (next_ot_cnt == 'd0);
      end
    end
    else begin
      next_after_clr_valid = (next_ot_cnt == 'd0);
    end
  end : cb_fetch

  always_comb begin : trap_ctrl
    next_trap = trap_ff;
    if (instr_access_fault_o) begin
      next_trap.pc_addr = pc_ff;
      next_trap.active = 'b1;
    end
    if (fetch_req_trig) begin
      next_trap = s_trap_info_t'(0);
    end
  end : trap_ctrl

  `CLK_PROC(clk, rst) begin : pc_ctrl_seq
    `RST_TYPE(rst) begin
      pc_ff              <= pc_t'('d0);
      trap_ff            <= s_trap_info_t'('0);
      ot_cnt_ff          <= 'd0;
      after_clr_valid_ff <= 'b0;
      fetch_trig_ff      <= 'b0;
      fetch_start_ff     <= 'b0;
    end
    else begin
      pc_ff              <= next_pc;
      trap_ff            <= next_trap;
      ot_cnt_ff          <= next_ot_cnt;
      after_clr_valid_ff <= next_after_clr_valid;
      fetch_trig_ff      <= next_trig;
      fetch_start_ff     <= next_fetch_start;
    end
  end : pc_ctrl_seq

  always_comb begin : fetch_fsm_comb
    next_fetch_sm = fetch_st_ff;
    /* verilator lint_off CASEINCOMPLETE */
    unique case (fetch_st_ff)
      IDLE:         next_fetch_sm = fetch_req_trig ? FETCH_CLEAR : IDLE;
      FETCH_CLEAR:  next_fetch_sm = FETCH_RUN;
      FETCH_RUN: begin
        priority case (1)
          fetch_req_trig:  next_fetch_sm = FETCH_CLEAR;
          fetch_full:   begin
            `P_MSG("FETCH","Stall this cycle")
            next_fetch_sm = FETCH_RUN;
          end
          default:  next_fetch_sm = FETCH_RUN;
        endcase
      end
      //default:  next_fetch_sm = fetch_st_ff;
    endcase
    /* verilator lint_on CASEINCOMPLETE */
  end : fetch_fsm_comb

  `CLK_PROC(clk, rst) begin : fetch_fsm_seq
    `RST_TYPE(rst) begin
      fetch_st_ff <= fetch_fsm_t'(IDLE);
    end
    else begin
      fetch_st_ff <= next_fetch_sm;
    end
  end : fetch_fsm_seq

  always_comb begin : fetch_proc_if
    fetch_valid_o = 'b0;
    fetch_instr_o = 'd0;
    get_next_instr = 'b0;

    // We assert valid instr if:
    // 1 - There's no req to fetch a new addr
    // 2 - There's data inside the FIFO
    if (~fetch_req_trig && (buffer_space != 'd0)) begin
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
    .full_o   (),
    .empty_o  (),
    .ocup_o   (buffer_space)
  );

`ifndef NO_ASSERTIONS
  initial begin
    illegal_param_fetch : assert (L0_BUFFER_SIZE > 0)
    else $error("Illegal fetch build parameters!");
  end
`endif

`ifdef COCOTB_SIM
  `ifdef XCELIUM
    `DUMP_WAVES_XCELIUM
  `endif
`endif
endmodule
