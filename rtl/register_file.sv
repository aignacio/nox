/**
 * File              : register_file.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 05.11.2021
 * Last Modified Date: 04.12.2021
 */
module register_file
  import utils_pkg::*;
(
  input           clk,
  input           rst,
  input   raddr_t rs1_addr_i,
  input   raddr_t rs2_addr_i,
  input   raddr_t rd_addr_i,
  input   rdata_t rd_data_i,
  input           we_i,
  output  rdata_t rs1_data_o,
  output  rdata_t rs2_data_o
);
  rdata_t [31:0] reg_file_ff;
  rdata_t next_rs1, rs1_ff;
  rdata_t next_rs2, rs2_ff;

  always_comb begin
    next_rs1 = reg_file_ff[rs1_addr_i];
    next_rs2 = reg_file_ff[rs2_addr_i];

    rs1_data_o = (rs1_addr_i == raddr_t'('d0)) ? rdata_t'('d0) : rs1_ff;
    rs2_data_o = (rs2_addr_i == raddr_t'('d0)) ? rdata_t'('d0) : rs2_ff;

    if (we_i && (rd_addr_i != raddr_t'('d0))) begin
      rs1_data_o = (rs1_addr_i == rd_addr_i) ? rd_data_i : rs1_ff;
      rs2_data_o = (rs2_addr_i == rd_addr_i) ? rd_data_i : rs2_ff;
    end
  end

  `CLK_PROC(clk, rst) begin
    `RST_TYPE(rst) begin
      rs1_ff <= `OP_RST_L;
      rs2_ff <= `OP_RST_L;
    end
    else begin
      if (we_i && (rd_addr_i != 'd0)) begin
        `P_MSG("DEC","Write in the reg_file:")
        `P_VAR("DEC","reg_file[addr]",rd_addr_i)
        `P_VAR("DEC","reg_file[val]",rd_data_i)
        reg_file_ff[rd_addr_i] <= rd_data_i;
      end
      rs1_ff <= next_rs1;
      rs2_ff <= next_rs2;
    end
  end

`ifndef NO_ASSERTIONS
  `ifndef VERILATOR
    //property illegal_write_x0;
      //@`CLK_PROC(clk, rst) disable iff (rst) we_i |-> (rd_addr_i != 'd0);
    //endproperty
    //illegal_write_rf : assert property (illegal_write_x0);
  `endif
`endif

`ifdef COCOTB_SIM
  `ifdef XCELIUM
    `DUMP_WAVES_XCELIUM
  `endif
`endif
endmodule
