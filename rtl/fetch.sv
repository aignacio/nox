/**
* File              : fetch.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 16.10.2021
 * Last Modified Date: 27.06.2022
 */
module fetch
  import utils_pkg::*;
#(
  parameter int SUPPORT_DEBUG  = 1,
  parameter int L0_BUFFER_SIZE = 2  // Max instrs locally stored
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

  logic         clear_buffer;
  logic         get_next_instr;
  logic         write_instr;
  buffer_t      buffer_space;
  instr_raw_t   instr_buffer;
  logic         full_fifo;

  cb_addr_t     pc_addr_ff, next_pc_addr;
  logic         req_ff, next_req;
  logic         ready_txn;
  logic         skip_incr_pc;
  logic         vld_instr_ff, next_vld;
  logic         instr_access_fault;
  cb_addr_t     pc_buf_ff, next_pc_buf;
  logic         fetch_ff, next_fetch;

  always_comb begin : addr_chn_req
    next_req = 'b0;
    clear_buffer = 'b0;
    next_pc_addr = pc_addr_ff;
    skip_incr_pc = 'b0;
    next_vld = vld_instr_ff;
    next_fetch = fetch_ff;
    next_pc_buf = pc_buf_ff;

    instr_cb_mosi_o = s_cb_mosi_t'('0);
    instr_cb_mosi_o.rd_addr_valid = req_ff;
    instr_cb_mosi_o.rd_addr  = pc_addr_ff;
    instr_cb_mosi_o.rd_size  = cb_size_t'(CB_WORD);
    instr_cb_mosi_o.rd_ready = vld_instr_ff ? ~full_fifo : 'b1;
    ready_txn = instr_cb_miso_i.rd_addr_ready;

    if (req_ff) begin : act_req
      if (ready_txn) begin
        if (fetch_start_i && fetch_ff) begin
          next_pc_addr = cb_addr_t'({pc_buf_ff[31:2],2'd0});
          next_req     = 'b1;
          next_fetch   = 'b0;
          skip_incr_pc = 'b1;
          next_vld     = 'b0;
        end
        else begin
          if (fetch_start_i && ~fetch_req_i) begin
            if (~full_fifo) begin
              next_req = 'b1;
            end
          end
          else if (fetch_start_i && fetch_req_i) begin
            next_pc_addr = cb_addr_t'({fetch_addr_i[31:2],2'd0});
            next_req     = 'b1;
            clear_buffer = 'b1;
            skip_incr_pc = 'b1;
            next_vld     = 'b0;
          end
        end
      end
      else begin
        next_req = 'b1; // Once we started, we keep H till recv
        if (fetch_start_i && fetch_req_i) begin
          next_pc_buf = cb_addr_t'({fetch_addr_i[31:2],2'd0});
          next_fetch  = 'b1;
          next_vld    = 'b0;
          clear_buffer = 'b1;
        end
      end
    end : act_req
    else begin : no_req_ongoing
      if (fetch_start_i && ~fetch_req_i) begin
        if (~full_fifo) begin
          next_req = 'b1;
        end
      end
      else if (fetch_start_i && fetch_req_i) begin
        next_pc_addr = fetch_addr_i;
        next_req     = 'b1;
        clear_buffer = 'b1;
        next_vld     = 'b0;
      end
    end : no_req_ongoing

    if (~skip_incr_pc && req_ff && ready_txn) begin
      next_pc_addr = pc_addr_ff + 'd4;
      next_vld = 'b1;
    end
  end : addr_chn_req

  always_comb begin
    write_instr = 'b0;

    // Only write in the FIFO if
    // 1 - When there's no jump req
    // 2 - When there's vld data phase (opposite means discarding)
    // 3 - There valid data in the bus
    // 4 - We don't have a full fifo
    if (~fetch_req_i && vld_instr_ff && instr_cb_miso_i.rd_valid && ~full_fifo) begin
      write_instr = 'b1;
    end
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

  `CLK_PROC(clk, rst) begin
    `RST_TYPE(rst) begin
      pc_addr_ff   <= cb_addr_t'(fetch_start_addr_i);
      req_ff       <= 'b0;
      vld_instr_ff <= 'b0;
      pc_buf_ff    <= '0;
      fetch_ff     <= '0;
    end
    else begin
      pc_addr_ff   <= next_pc_addr;
      req_ff       <= next_req;
      vld_instr_ff <= next_vld;
      pc_buf_ff    <= next_pc_buf;
      fetch_ff     <= next_fetch;
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
      get_next_instr = fetch_ready_i;
    end
  end : fetch_proc_if

  fifo_nox #(
    .SLOTS    (L0_BUFFER_SIZE),
    .WIDTH    (32)
  ) u_fifo_l0 (
    .clk      (clk),
    .rst      (rst),
    .clear_i  (clear_buffer),
    .write_i  (write_instr),
    .read_i   (get_next_instr),
    .data_i   (instr_cb_miso_i.rd_data),
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
