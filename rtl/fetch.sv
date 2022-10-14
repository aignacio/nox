/**
* File              : fetch.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 16.10.2021
 * Last Modified Date: 03.07.2022
 */
module fetch
  import amba_axi_pkg::*;
  import amba_ahb_pkg::*;
  import nox_utils_pkg::*;
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
  typedef logic [$clog2(L0_BUFFER_SIZE):0] buffer_t;

  logic         get_next_instr;
  logic         write_instr;
  buffer_t      buffer_space;
  instr_raw_t   instr_buffer;
  logic         full_fifo;
  logic         data_valid;
  logic         data_ready;
  logic         jump;
  logic         clear_fifo;
  logic         valid_addr;
  logic         read_ot_fifo;
  logic         ot_empty;

  cb_addr_t     pc_addr_ff, next_pc_addr;
  cb_addr_t     pc_buff_ff, next_pc_buff;
  logic         req_ff, next_req;
  logic         valid_txn_i, valid_txn_o;
  logic         addr_ready;
  logic         instr_access_fault;

  typedef enum logic [1:0] {
    F_STP,
    F_REQ,
    F_CLR
  } fetch_st_t;

  fetch_st_t st_ff, next_st;
  buffer_t   ot_cnt_ff, next_ot;

  always_comb begin : addr_chn_req
    instr_cb_mosi_o.wr_addr       = cb_addr_t'('0);
    instr_cb_mosi_o.wr_size       = cb_size_t'('0);
    instr_cb_mosi_o.wr_addr_valid = 1'b0;
    instr_cb_mosi_o.wr_data       = cb_data_t'('0);
    instr_cb_mosi_o.wr_strobe     = cb_strb_t'('0);
    instr_cb_mosi_o.wr_data_valid = 1'b0;
    instr_cb_mosi_o.wr_resp_ready = 1'b0;

    data_valid   = instr_cb_miso_i.rd_valid;
    addr_ready   = instr_cb_miso_i.rd_addr_ready;
    clear_fifo   = (fetch_req_i || (~fetch_start_i));
    valid_addr   = 1'b0;
    next_pc_addr = pc_addr_ff;
    next_pc_buff = pc_buff_ff;
    next_st      = st_ff;
    jump         = fetch_req_i;
    valid_txn_i  = 1'b0;

    next_ot = ot_cnt_ff + (req_ff && addr_ready) - (data_valid && data_ready);

    case (st_ff)
      F_STP: begin
        next_st = fetch_start_i ? F_REQ : F_STP;

        if (req_ff && ~addr_ready) begin
          valid_addr  = 1'b1; // Keep driving high to complete txn
          valid_txn_i = 1'b0;
        end
      end
      F_REQ: begin
        if (req_ff && ~addr_ready) begin
          valid_addr  = 1'b1; // Keep driving high to complete txn
          valid_txn_i = 1'b1;
        end

        if (req_ff && addr_ready) begin
          valid_txn_i = 1'b1;
          next_pc_addr = pc_addr_ff + 'd4;
        end

        if ((req_ff && addr_ready) || ~req_ff) begin
          // Next txn
          if (next_ot < (buffer_t'(L0_BUFFER_SIZE))) begin
            valid_addr  = ~full_fifo;
          end
        end

        if (jump) begin
          next_pc_addr = fetch_addr_i;
          next_pc_buff = pc_addr_ff;
          valid_txn_i  = 1'b0;

          if ((req_ff && ~addr_ready) || (next_ot > 'd0)) begin
            next_st    = F_CLR;
          end

          if (req_ff && addr_ready) begin
            valid_addr = 1'b0;
          end
        end

        if (~fetch_start_i) begin
          next_st = F_STP;
        end
      end
      F_CLR: begin
        // After a jump request:
        //  - Finish ongoing txn
        valid_txn_i = 1'b0;
        if (req_ff && ~addr_ready) begin
          valid_addr  = 1'b1;
        end
        else if (next_ot == '0) begin
          next_st    = F_REQ;
          valid_addr = 1'b1; // Next txn is the jump
        end
      end
      default: valid_addr = 1'b0;
    endcase

    next_req = valid_addr;
    instr_cb_mosi_o.rd_addr_valid = req_ff;
    instr_cb_mosi_o.rd_addr       = req_ff ? ((st_ff == F_CLR) ? pc_buff_ff : pc_addr_ff) : '0;
    instr_cb_mosi_o.rd_size       = req_ff ? cb_size_t'(CB_WORD) : cb_size_t'('0);
  end : addr_chn_req

  always_comb begin : rd_chn
    write_instr = 'b0;
    data_ready = (st_ff == F_REQ) ? ~full_fifo : 'b1;
    instr_cb_mosi_o.rd_ready = data_ready;
    read_ot_fifo = ot_empty ? 1'b0 : (data_valid && data_ready);
    // Only write in the FIFO if
    // 1 - When there's no jump req
    // 2 - When there's vld data phase (opposite means discarding)
    // 3 - There valid data in the bus
    // 4 - We don't have a full fifo
    if (~fetch_req_i && ~ot_empty && valid_txn_o && data_valid && ~full_fifo) begin
      write_instr = 'b1;
    end
  end : rd_chn

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
      pc_buff_ff   <= cb_addr_t'(fetch_start_addr_i);
      st_ff        <= F_STP;
      req_ff       <= 1'b0;
      ot_cnt_ff    <= buffer_t'('0);
    end
    else begin
      pc_addr_ff   <= next_pc_addr;
      pc_buff_ff   <= next_pc_buff;
      st_ff        <= next_st;
      req_ff       <= next_req;
      ot_cnt_ff    <= next_ot;
    end
  end

  always_comb begin : fetch_proc_if
    fetch_valid_o = 'b0;
    fetch_instr_o = 'd0;
    get_next_instr = 'b0;

    // We assert valid instr if:
    // 1 - There's no req to fetch a new addr
    // 2 - There's data inside the FIFO
    if (fetch_start_i && ~fetch_req_i && (buffer_space != 'd0)) begin
      // We request to read the FIFO if:
      // 3 - The next stage is ready to receive
      fetch_valid_o  = 'b1;
      fetch_instr_o  = instr_buffer;
      get_next_instr = fetch_ready_i;
    end
  end : fetch_proc_if

  fifo_nox #(
    .SLOTS    (L0_BUFFER_SIZE),
    .WIDTH    (1)
  ) u_fifo_ot_rd (
    .clk      (clk),
    .rst      (rst),
    .clear_i  (clear_fifo),
    .write_i  ((req_ff && addr_ready)),
    .read_i   (read_ot_fifo),
    .data_i   (valid_txn_i),
    .data_o   (valid_txn_o),
    .error_o  (),
    .full_o   (),
    .empty_o  (ot_empty),
    .ocup_o   ()
  );

  fifo_nox #(
    .SLOTS    (L0_BUFFER_SIZE),
    .WIDTH    (32)
  ) u_fifo_l0 (
    .clk      (clk),
    .rst      (rst),
    .clear_i  (clear_fifo),
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
