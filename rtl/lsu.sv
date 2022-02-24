/**
 * File              : lsu.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 04.12.2021
 * Last Modified Date: 24.02.2022
 */
module lsu
  import utils_pkg::*;
#(
  parameter int SUPPORT_DEBUG   = 1,
  parameter int SUPPORT_WR_RESP = 1
)(
  input                 clk,
  input                 rst,
  // From EXE stg
  input   s_lsu_op_t    lsu_i,
  // To EXE stg
  output  logic         lsu_bp_o,
  output  logic         lsu_bp_data_o,
  // To write-back datapath
  output  s_lsu_op_t    wb_lsu_o,
  output  rdata_t       lsu_data_o,
  // Core data bus I/F
  output  s_cb_mosi_t   data_cb_mosi_o,
  input   s_cb_miso_t   data_cb_miso_i,
  // Trap - MEM access fault
  output  s_trap_info_t trap_info_st_o,
  output  s_trap_info_t trap_info_ld_o
);
  s_lsu_op_t lsu_ff, next_lsu;

  logic bp_addr, bp_data;
  logic ap_txn, ap_rd_txn, ap_wr_txn;
  logic dp_txn, dp_rd_txn, dp_wr_txn;

  logic ap_done_ff, next_ap_done;
  logic dp_done_ff, next_dp_done;

  logic       lock_ff, next_lock;
  cb_addr_t   locked_addr_ff, next_locked_addr;
  cb_addr_t   lsu_req_addr;

  function automatic logic [3:0] mask_strobe(lsu_w_t size, logic [1:0] shift_left);
    cb_strb_t mask;
    case (size)
      RV_LSU_B:  mask = cb_strb_t'('b0001);
      RV_LSU_H:  mask = cb_strb_t'('b0011);
      RV_LSU_BU: mask = cb_strb_t'('b0001);
      RV_LSU_HU: mask = cb_strb_t'('b0011);
      RV_LSU_W:  mask = cb_strb_t'('b1111);
      default:   mask = cb_strb_t'('b1111);
    endcase

    for (int i=0;i<`XLEN/8;i++) begin
      if (i[1:0] == shift_left) begin
        return mask;
      end
      else begin
        mask = {mask[2:0],1'b0};
      end
    end

    return mask;
  endfunction

  always_comb begin
    next_ap_done = ap_done_ff;
    next_dp_done = dp_done_ff;

    // Default values transfer nothing
    data_cb_mosi_o = s_cb_mosi_t'('0);
    data_cb_mosi_o.rd_ready      = 'b1;
    data_cb_mosi_o.wr_resp_ready = 'b1;

    lsu_bp_o    = 'b0;

    ap_txn     = (lsu_i.op_typ  != NO_LSU);
    ap_rd_txn  = (lsu_i.op_typ  == LSU_LOAD);
    ap_wr_txn  = (lsu_i.op_typ  == LSU_STORE);

    dp_txn     = (lsu_ff.op_typ  != NO_LSU);
    dp_rd_txn  = (lsu_ff.op_typ  == LSU_LOAD);
    dp_wr_txn  = (lsu_ff.op_typ  == LSU_STORE);

    // Data phase
    bp_data = 'b0;
    if (dp_txn) begin
      if (~dp_done_ff)
        bp_data = dp_rd_txn ? ~data_cb_miso_i.rd_valid : ~data_cb_miso_i.wr_data_ready;
      if (dp_wr_txn) begin
        data_cb_mosi_o.wr_strobe = mask_strobe(lsu_ff.width, lsu_ff.addr[1:0]);
        for (int i=0;i<`XLEN/8;i++) begin
          if (lsu_ff.addr[1:0]==i[1:0]) begin
            data_cb_mosi_o.wr_data = lsu_ff.wdata << (8*i);
          end
          data_cb_mosi_o.wr_data[(i*8)+:8] = data_cb_mosi_o.wr_strobe[i] ?
                                             data_cb_mosi_o.wr_data[(i*8)+:8] : 8'h0;
        end
        data_cb_mosi_o.wr_data_valid = ~dp_done_ff;
      end
      next_dp_done = ~bp_data;
    end

    // Address phase
    if (lock_ff) begin
      lsu_req_addr = locked_addr_ff;
    end
    else begin
      lsu_req_addr = lsu_i.addr;
    end

    bp_addr = 'b0;
    if (ap_txn) begin
      if (~ap_done_ff)
        bp_addr = ap_rd_txn ? ~data_cb_miso_i.rd_addr_ready : ~data_cb_miso_i.wr_addr_ready;
      if (ap_wr_txn) begin
        data_cb_mosi_o.wr_addr       = {lsu_req_addr[31:2],2'b0};
        data_cb_mosi_o.wr_size       = CB_WORD;
        data_cb_mosi_o.wr_addr_valid = ~ap_done_ff && ~bp_data;
      end
      else begin
        data_cb_mosi_o.rd_addr       = {lsu_req_addr[31:2],2'b0};
        data_cb_mosi_o.rd_size       = CB_WORD;
        data_cb_mosi_o.rd_addr_valid = ~ap_done_ff && ~bp_data;
      end
      next_ap_done = ~bp_addr;
    end

    next_lock = lock_ff;
    next_locked_addr = locked_addr_ff;

    if (ap_txn) begin
      next_lock = ap_rd_txn ? (data_cb_mosi_o.rd_addr_valid && ~data_cb_miso_i.rd_addr_ready) :
                              (data_cb_mosi_o.wr_addr_valid && ~data_cb_miso_i.wr_addr_ready);
    end

    next_locked_addr = lock_ff ? locked_addr_ff : lsu_req_addr;

    lsu_bp_o = bp_addr || bp_data;
    lsu_bp_data_o = bp_data;

    next_lsu = lsu_ff;

    if (~lsu_bp_o) begin
      next_lsu = lsu_i;
      next_lsu.addr = lock_ff ? locked_addr_ff : lsu_i.addr;
      next_ap_done = 'b0;
      next_dp_done = 'b0;
    end

    wb_lsu_o = lsu_ff;
    lsu_data_o = data_cb_miso_i.rd_data;
  end

  always_comb begin : trap_lsu
    trap_info_st_o = s_trap_info_t'('0);
    trap_info_ld_o = s_trap_info_t'('0);

    if ((SUPPORT_WR_RESP == 1) && data_cb_miso_i.wr_resp_valid && (data_cb_miso_i.wr_resp_error != CB_OKAY)) begin
      trap_info_st_o.active = 'b1;
    end

    if (data_cb_miso_i.rd_valid && (data_cb_miso_i.rd_resp != CB_OKAY)) begin
      trap_info_ld_o.active = 'b1;
    end
  end : trap_lsu

  `CLK_PROC(clk, rst) begin
    `RST_TYPE(rst) begin
      lsu_ff          <= s_lsu_op_t'('0);
      ap_done_ff      <= 'b0;
      dp_done_ff      <= 'b0;
      lock_ff         <= 'b0;
      locked_addr_ff  <= '0;
    end
    else begin
      lsu_ff          <= next_lsu;
      ap_done_ff      <= next_ap_done;
      dp_done_ff      <= next_dp_done;
      lock_ff         <= next_lock;
      locked_addr_ff  <= next_locked_addr;
    end
  end
endmodule
