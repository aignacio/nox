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
  // From EXEC
  input   s_ex_mem_wb_t ex_mem_wb_i,
  // From LSU
  input   s_lsu_op_t    wb_lsu_i,
  input   rdata_t       lsu_rd_data_i,
  input                 lsu_bp_i,
  // To DEC stg
  output  s_wb_t        wb_dec_o
);
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
    wb_dec_o.we_rd   = ex_mem_wb_i.we_rd;
    wb_dec_o.rd_data = ex_mem_wb_i.result;

    if (wb_lsu_i.op_typ == LSU_LOAD) begin
      wb_dec_o.we_rd   = lsu_bp_i ? 1'b0 : ex_mem_wb_i.we_rd;
      wb_dec_o.rd_data = fmt_load(wb_lsu_i, lsu_rd_data_i);
    end
    wb_dec_o.rd_addr = ex_mem_wb_i.rd_addr;
  end : mux_for_w_rf
endmodule
