/**
 * File              : lsu.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 04.12.2021
 * Last Modified Date: 21.03.2022
 */
module lsu
  import utils_pkg::*;
#(
  parameter int SUPPORT_DEBUG         = 1,
  parameter int TRAP_ON_MIS_LSU_ADDR  = 0,
  parameter int TRAP_ON_LSU_ERROR     = 0
)(
  input                     clk,
  input                     rst,
  // From EXE stg
  input   s_lsu_op_t        lsu_i,
  // To EXE stg
  output  logic             lsu_bp_o,
  output  pc_t              lsu_pc_o,
  // To write-back datap    ath
  output  logic             lsu_bp_data_o,
  output  s_lsu_op_t        wb_lsu_o,
  output  rdata_t           lsu_data_o,
  // Core data bus I/F
  output  s_cb_mosi_t       data_cb_mosi_o,
  input   s_cb_miso_t       data_cb_miso_i,
  output  s_trap_lsu_info_t lsu_trap_o
);
  s_lsu_op_t lsu_ff, next_lsu;

  logic       bp_addr, bp_data;
  logic       ap_txn, ap_rd_txn, ap_wr_txn;
  logic       dp_txn, dp_rd_txn, dp_wr_txn;
  logic       dp_done_ff, next_dp_done;
  logic       lock_ff, next_lock;
  logic       unaligned_lsu;

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
    // obs.: Due to the fact that the core is fully bypassed/fwd,
    // we only dispatch the address phase request if there's
    // no data phase back pressure, once this read/write data
    // might be used for the address phase.
    if (lock_ff) begin
      lsu_req_addr = locked_addr_ff;
    end
    else begin
      lsu_req_addr = lsu_i.addr;
    end

    bp_addr = 'b0;
    if (ap_txn) begin
        bp_addr = ap_rd_txn ? ~data_cb_miso_i.rd_addr_ready : ~data_cb_miso_i.wr_addr_ready;
      if (ap_wr_txn) begin
        data_cb_mosi_o.wr_addr       = {lsu_req_addr[31:2],2'b0};
        data_cb_mosi_o.wr_size       = CB_WORD;
        data_cb_mosi_o.wr_addr_valid = ~bp_data;
      end
      else begin
        data_cb_mosi_o.rd_addr       = {lsu_req_addr[31:2],2'b0};
        data_cb_mosi_o.rd_size       = CB_WORD;
        data_cb_mosi_o.rd_addr_valid = ~bp_data;
      end
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
      next_dp_done = 'b0;
    end

    wb_lsu_o = lsu_ff;
    lsu_data_o = data_cb_miso_i.rd_data;
    lsu_pc_o = lsu_ff.pc_addr;
  end

  always_comb begin : trap_lsu
    lsu_trap_o = s_trap_lsu_info_t'('0);

    // Check if we have an unaligned xfer
    unaligned_lsu = 'b0;

    // Some signals are stable during AP:
    // -lsu_i.width
    // -lsu_i.op_typ
    // Other signals we have to take from the lsu
    // bus once bp can happen, that's why we use
    // lsu_req_addr / data_cb_mosi_o.XX_addr_valid
    case (lsu_i.width)
      RV_LSU_B:  unaligned_lsu = 'b0;
      RV_LSU_H:  unaligned_lsu = (lsu_req_addr[1:0] == 'd3);
      RV_LSU_BU: unaligned_lsu = 'b0;
      RV_LSU_HU: unaligned_lsu = (lsu_req_addr[1:0] == 'd3);
      RV_LSU_W:  unaligned_lsu = (lsu_req_addr[1:0] != 'd0);
      default:   unaligned_lsu = 'b0;
    endcase

    // We only evaluate unaligned xfer if we're not stalling due to bus bp
    if ((lsu_i.op_typ != NO_LSU) && unaligned_lsu) begin
      if ((lsu_i.op_typ == LSU_LOAD) && data_cb_mosi_o.rd_addr_valid)
        lsu_trap_o.ld_mis.active = (TRAP_ON_MIS_LSU_ADDR == 'b1);

      if ((lsu_i.op_typ == LSU_STORE) && data_cb_mosi_o.wr_addr_valid)
        lsu_trap_o.st_mis.active = (TRAP_ON_MIS_LSU_ADDR == 'b1);
    end

    if (data_cb_miso_i.wr_resp_valid && (data_cb_miso_i.wr_resp_error != CB_OKAY)) begin
      lsu_trap_o.st.active = (TRAP_ON_LSU_ERROR == 'b1);
    end

    if (data_cb_miso_i.rd_valid && (data_cb_miso_i.rd_resp != CB_OKAY)) begin
      lsu_trap_o.ld.active = (TRAP_ON_LSU_ERROR == 'b1);
    end
  end : trap_lsu

  `CLK_PROC(clk, rst) begin
    `RST_TYPE(rst) begin
      lsu_ff          <= s_lsu_op_t'('0);
      dp_done_ff      <= 'b0;
      lock_ff         <= 'b0;
      locked_addr_ff  <= '0;
    end
    else begin
      lsu_ff          <= next_lsu;
      dp_done_ff      <= next_dp_done;
      lock_ff         <= next_lock;
      locked_addr_ff  <= next_locked_addr;
    end
  end
endmodule
