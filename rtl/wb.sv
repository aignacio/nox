/**
 * File              : wb.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 07.01.2022
 * Last Modified Date: 07.01.2022
 */
module wb
  import utils_pkg::*;
(
  input                 clk,
  input                 rst,
  // From EXEC
  input   s_ex_mem_wb_t ex_mem_wb_i,
  // From LSU
  input   s_lsu_op_t    wb_lsu_i,
  input   rdata_t       lsu_rd_data_i,
  input                 lsu_bp_i,
  input                 lsu_bp_data_i,
  // To DEC stg
  output  s_wb_t        wb_dec_o
);
  logic lock_wr_ff, next_lock;

  function automatic rdata_t fmt_load(s_lsu_op_t load, rdata_t rdata);
    rdata_t data;
    for (int i=0;i<`XLEN/8;i++) begin
      if (load.addr[1:0]==i[1:0]) begin
        data = rdata >> (8*i);
      end
    end

    case (load.width)
      RV_LSU_B:   return {{24{data[7]}},data[7:0]};
      RV_LSU_H:   return {{16{data[15]}},data[15:0]};
      RV_LSU_BU:  return {24'h0,data[7:0]};
      RV_LSU_HU:  return {16'h0,data[15:0]};
      default:    return data;
    endcase
  endfunction

  always_comb begin : mux_for_w_rf
    next_lock        = 'b0;
    wb_dec_o.we_rd   = ex_mem_wb_i.we_rd;
    wb_dec_o.rd_data = ex_mem_wb_i.result;
    wb_dec_o.rd_addr = ex_mem_wb_i.rd_addr;

    if (wb_lsu_i.op_typ == LSU_LOAD) begin
      // This lock is needed in case we have a pending LSU operation (load or store)
      // in the AXI Address Chn but in the Read Data Channel, we have a load that is
      // not pending and the rvalid needs to be transfered to the RF. After the load
      // is completed we need to avoid additional one write in the register due to
      // the stall generated (pending addr handshake).
      next_lock = (lsu_bp_i && ~lsu_bp_data_i) ? 'b1 : 'b0;
      // In case we haven't receive a reply from the slave, let's wait the write
      wb_dec_o.we_rd   = (lsu_bp_data_i || lock_wr_ff) ? 'b0 : ex_mem_wb_i.we_rd;
      wb_dec_o.rd_data = fmt_load(wb_lsu_i, lsu_rd_data_i);
    end
  end : mux_for_w_rf

  `CLK_PROC(clk, rst) begin
    `RST_TYPE(rst) begin
      lock_wr_ff  <= `OP_RST_L;
    end
    else begin
      lock_wr_ff  <= next_lock;
    end
  end
endmodule
