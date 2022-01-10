/**
 * File              : lsu.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 04.12.2021
 * Last Modified Date: 10.01.2022
 */
module lsu
  import utils_pkg::*;
#(
  parameter int SUPPORT_DEBUG = 1
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
  output  logic         txn_error_o,
  output  s_trap_info_t trap_info_o
);
  s_lsu_op_t lsu_ff, next_lsu;
  logic req_ff, next_req;
  logic wr_resp_ff, next_wresp;
  logic bp_addr, bp_data, bp_wr_resp;
  logic new_txn;
  logic rd_txn;
  logic wr_txn;
  logic wr_txn_dp;

  function automatic cb_size_t size_txn(lsu_w_t size);
    cb_size_t sz;
    case (size)
      RV_LSU_B:  sz = CB_BYTE;
      RV_LSU_H:  sz = CB_HALF_WORD;
      RV_LSU_BU: sz = CB_BYTE;
      RV_LSU_HU: sz = CB_HALF_WORD;
      //RV_LSU_W:  sz = CB_WORD;
      default:   sz = CB_WORD;
    endcase
    return sz;
  endfunction

  function automatic logic [3:0] mask_strobe(lsu_w_t size, logic [1:0] shift_left);
    cb_strb_t mask;
    case (size)
      RV_LSU_B:  mask = cb_strb_t'('b0001);
      RV_LSU_H:  mask = cb_strb_t'('b0011);
      RV_LSU_BU: mask = cb_strb_t'('b0001);
      RV_LSU_HU: mask = cb_strb_t'('b0011);
      //RV_LSU_W:  mask = cb_strb_t'('b1111);
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
    new_txn   = (lsu_i.op_typ  != NO_LSU);
    rd_txn    = (lsu_i.op_typ  == LSU_LOAD);
    wr_txn    = (lsu_i.op_typ  == LSU_STORE);
    wr_txn_dp = (lsu_ff.op_typ == LSU_STORE);
    lsu_bp_o  = 'b0;
    next_req  = req_ff;
    next_lsu = lsu_ff;
    next_wresp = wr_resp_ff ? ~data_cb_miso_i.wr_resp_valid : (wr_txn_dp && data_cb_miso_i.wr_data_ready);

    // Default values transfer nothing
    data_cb_mosi_o = s_cb_mosi_t'('0);
    data_cb_mosi_o.rd_ready      = 'b1;
    data_cb_mosi_o.wr_resp_ready = 'b1;

    // Backpressure check
    bp_addr = new_txn && (rd_txn ? ~data_cb_miso_i.rd_addr_ready :
                                   ~data_cb_miso_i.wr_addr_ready);
    bp_data = req_ff && (wr_txn_dp ? ~data_cb_miso_i.wr_data_ready :
                                     ~data_cb_miso_i.rd_valid);
    bp_wr_resp = wr_resp_ff ? ~data_cb_miso_i.wr_resp_valid : 'b0;

    lsu_bp_o = bp_addr || bp_data || bp_wr_resp;

    lsu_bp_data_o = bp_data;

    if (new_txn) begin : addr_ph
      // 1 - stall execute stg
      // 0 - don't stall
      if (wr_txn) begin
        data_cb_mosi_o.wr_addr       = {lsu_i.addr[31:2],2'b0};
        data_cb_mosi_o.wr_size       = CB_WORD; //size_txn(lsu_i.width);
        data_cb_mosi_o.wr_addr_valid = ~bp_data;
      end
      else begin
        data_cb_mosi_o.rd_addr       = {lsu_i.addr[31:2],2'b0};
        data_cb_mosi_o.rd_size       = CB_WORD; //size_txn(lsu_i.width);
        data_cb_mosi_o.rd_addr_valid = ~bp_data;
      end
    end : addr_ph

    if (req_ff) begin : data_ph
      if (wr_txn_dp) begin
        data_cb_mosi_o.wr_strobe = mask_strobe(lsu_ff.width, lsu_ff.addr[1:0]);
        for (int i=0;i<`XLEN/8;i++) begin
          if (lsu_ff.addr[1:0]==i[1:0]) begin
            data_cb_mosi_o.wr_data = lsu_ff.wdata << (8*i);
          end
          data_cb_mosi_o.wr_data[(i*8)+:8] = data_cb_mosi_o.wr_strobe[i] ? data_cb_mosi_o.wr_data[(i*8)+:8] : 8'h0;
        end
        data_cb_mosi_o.wr_data_valid = 'b1;
      end
    end : data_ph

    // Moves to data ph. in case we have a txn
    // and no bp on execute stage OR back to no txn
    if (~lsu_bp_o) begin
      next_lsu = lsu_i;
      next_req = new_txn;
    end

    txn_error_o = req_ff ? ((data_cb_miso_i.wr_resp_error != CB_OKAY) ||
                            (data_cb_miso_i.rd_resp != CB_OKAY)) : 'b0;
    trap_info_o = s_trap_info_t'('0);
    wb_lsu_o = lsu_ff;

    lsu_data_o = data_cb_miso_i.rd_data;
  end

  `CLK_PROC(clk, rst) begin
    `RST_TYPE(rst) begin
      lsu_ff      <= s_lsu_op_t'('0);
      req_ff      <= 'b0;
      wr_resp_ff  <= `OP_RST_L;
    end
    else begin
      lsu_ff      <= next_lsu;
      req_ff      <= next_req;
      wr_resp_ff  <= next_wresp;
    end
  end
endmodule
