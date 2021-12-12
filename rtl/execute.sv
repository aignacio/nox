/**
 * File              : execute.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 21.11.2021
 * Last Modified Date: 10.12.2021
 */
module execute
  import utils_pkg::*;
#(
  parameter int SUPPORT_DEBUG = 1
)(
  input                 clk,
  input                 rst,
  // Control signals
  output  s_branch_t    branch_o,
  output  s_jump_t      jump_o,
  output  raddr_t       rd_addr_ex_o,
  // From DEC stg I/F
  input   s_id_ex_t     id_ex_i,
  input   rdata_t       rs1_data_i,
  input   rdata_t       rs2_data_i,
  input   valid_t       id_valid_i,
  output  ready_t       id_ready_o,
  // To MEM/WB stg I/F
  output  s_ex_mem_wb_t ex_mem_wb_o,
  output  s_lsu_op_t    lsu_o,
  input                 lsu_bp_i,
  // Trap - Instruction access fault
  output  logic         illegal_ex_o,
  output  s_trap_info_t trap_info_o
);
  s_ex_mem_wb_t ex_mem_wb_ff, next_ex_mem_wb;
  alu_t         op1, op2, res;

  function automatic branch_dec(branch_t op, rdata_t rs1, rdata_t rs2);
    logic         take_branch;
    case (op)
      RV_B_BEQ:   take_branch = (rs1 == rs2);
      RV_B_BNE:   take_branch = (rs1 != rs2);
      RV_B_BLT:   take_branch = (signed'(rs1) < signed'(rs2));
      RV_B_BGE:   take_branch = (signed'(rs1) >= signed'(rs2));
      RV_B_BLTU:  take_branch = (rs1 < rs2);
      RV_B_BGEU:  take_branch = (rs1 >= rs2);
      default:    take_branch = 'b0;
    endcase
    return take_branch;
  endfunction

  always_comb begin : alu_proc
    op1 = alu_t'('0);
    op2 = alu_t'('0);
    res = alu_t'('0);
    id_ready_o = 'b1;

    // Mux Src A
    case (id_ex_i.rs1_op)
      REG_RF:   op1 = alu_t'(rs1_data_i);
      IMM:      op1 = alu_t'(id_ex_i.imm);
      ZERO:     op1 = alu_t'('0);
      PC:       op1 = alu_t'(id_ex_i.pc_dec);
      default:  op1 = alu_t'('0);
    endcase

    // Mux Src B
    case (id_ex_i.rs2_op)
      REG_RF:   op2 = alu_t'(rs2_data_i);
      IMM:      op2 = alu_t'(id_ex_i.imm);
      ZERO:     op2 = alu_t'('0);
      PC:       op2 = alu_t'(id_ex_i.pc_dec);
      default:  op2 = alu_t'('0);
    endcase

    // ALU compute
    case (id_ex_i.f3)
      RV_F3_ADD_SUB: begin
        op2 = id_ex_i.f7 ? (~op2+'d1) : op2;
        res = op1 + op2;
        if (id_ex_i.jump) begin
          // For JALR set LSB[0] == 'b0
          res[0] = (id_ex_i.rs1_op == REG_RF) ? 1'b0 : res[0];
        end
      end
      RV_F3_SLT:      res = (signed'(op1 < op2)) ? alu_t'('d1) : alu_t'('d0);
      RV_F3_SLTU:     res = (op1 < op2) ? alu_t'('d1) : alu_t'('d0);
      RV_F3_XOR:      res = (op1 ^ op2);
      RV_F3_OR:       res = (op1 | op2);
      RV_F3_AND:      res = (op1 & op2);
      RV_F3_SLL:      res = (id_ex_i.rs2_op == IMM) ? (op1 << id_ex_i.shamt) :
                                                      (op1 << op2);
      RV_F3_SRL_SRA: begin
        if (id_ex_i.rs2_op == IMM) begin
          res = (id_ex_i.rshift == RV_SRA) ? (op1 >>> id_ex_i.shamt) :
                                             (op1 >>  id_ex_i.shamt);
        end
        else begin
          res = (id_ex_i.rshift == RV_SRA) ? (op1 >>> op2) :
                                             (op1 >>  op2);
        end
      end
      default:        res = alu_t'('0);
    endcase

    branch_o.b_act   = id_ex_i.branch && ~lsu_bp_i;
    branch_o.b_addr  = id_ex_i.imm;
    branch_o.take_branch  = branch_dec(branch_t'(id_ex_i.f3),
                                       rs1_data_i,
                                       rs2_data_i);

    jump_o.j_act  = id_ex_i.jump && ~lsu_bp_i;
    jump_o.j_addr = res;

    lsu_o.op_typ = id_ex_i.lsu;
    lsu_o.width  = lsu_w_t'(id_ex_i.f3);
    lsu_o.addr   = res;
    lsu_o.wdata  = rs2_data_i;

    next_ex_mem_wb.result  = (id_ex_i.jump) ? alu_t'(id_ex_i.pc_dec+'d4) : res;
    next_ex_mem_wb.rd_addr = id_ex_i.rd_addr;
    next_ex_mem_wb.we_rd   = id_ex_i.we_rd;

    if (lsu_bp_i) begin
      next_ex_mem_wb = ex_mem_wb_ff;
      id_ready_o = 'b0;
    end

    illegal_ex_o = 'b0;
    trap_info_o = s_trap_info_t'('0);

    ex_mem_wb_o = ex_mem_wb_ff;
    rd_addr_ex_o = id_ex_i.rd_addr;
  end : alu_proc

  `CLK_PROC(clk, rst) begin
    `RST_TYPE(rst) begin
      ex_mem_wb_ff <= `OP_RST_L;
    end
    else begin
      ex_mem_wb_ff <= next_ex_mem_wb;
    end
  end
endmodule
