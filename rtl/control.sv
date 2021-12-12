/**
 * File              : control.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 09.12.2021
 * Last Modified Date: 10.12.2021
 */
module control
  import utils_pkg::*;
(
  input                 clk,
  input                 rst,
  // To FETCH stg
  output  logic         fetch_req_o,
  output  pc_t          fetch_addr_o,
  // From EXEC/WB
  input   s_ex_mem_wb_t ex_mem_wb_i,
  input   s_branch_t    branch_i,
  input   s_jump_t      jump_i,
  input   raddr_t       rd_addr_ex_i,
  // From LSU
  input   s_lsu_op_t    wb_lsu_i,
  input   rdata_t       lsu_rd_data_i,
  // To DEC stg
  output  s_wb_t        wb_dec_o,
  output  logic         stall_o,
  // From DEC
  input s_stall_id_t    id_regs_i
);
  logic stall_rs1, stall_rs2;

  always_comb begin : hdu_check
    // Hazard Detection Unit:
    // Stall when... - (rs1 != x0 && rs2 != x0 && rd != x0)
    // > rs1 / opcodes = OP/_IMM, JALR, BRANCH, LOAD, STORE
    // > rs2 / opcodes = OP, BRANCH, STORE
    // rs1 || rs2 [ID] == rd [EX]
    //
    // The core also bp when there's a pending LOAD/STORE
    // and when there's a jump/branch taken
    stall_rs1 = 'b0;
    stall_rs2 = 'b0;

    stall_o = 'b0;

    if (rd_addr_ex_i != 'h0) begin
      if (id_regs_i.rs1_sel) begin
        stall_rs1 = (id_regs_i.rs1_addr == rd_addr_ex_i);
      end

      if (id_regs_i.rs2_sel) begin
        stall_rs2 = (id_regs_i.rs2_addr == rd_addr_ex_i);
      end
    end

    stall_o = (stall_rs1 || stall_rs2);
  end : hdu_check

  always_comb begin
    // To FETCH / DEC (flush_i)
    fetch_req_o  = (branch_i.b_act || jump_i.j_act);
    // To FETCH / DEC (pc_jump_i)
    fetch_addr_o = (branch_i.b_act) ? branch_i.b_addr :
                                      jump_i.j_addr;
  end

  always_comb begin : mux_for_w_rf
    wb_dec_o.we_rd   = ex_mem_wb_i.we_rd;
    wb_dec_o.rd_addr = ex_mem_wb_i.rd_addr;
    wb_dec_o.rd_data = (wb_lsu_i.op_typ == LSU_LOAD) ? lsu_rd_data_i :
                                                       ex_mem_wb_i.result;
  end : mux_for_w_rf

endmodule
