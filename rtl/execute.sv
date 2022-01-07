/**
 * File              : execute.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 21.11.2021
 * Last Modified Date: 07.01.2022
 */
module execute
  import utils_pkg::*;
#(
  parameter int SUPPORT_DEBUG = 1
)(
  input                 clk,
  input                 rst,
  // Control signals
  input   rdata_t       wb_value_i,
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
  // To FETCH stg
  output  logic         fetch_req_o,
  output  pc_t          fetch_addr_o,
  // Trap - Instruction access fault
  output  logic         illegal_ex_o,
  output  s_trap_info_t trap_info_o
);
  s_ex_mem_wb_t ex_mem_wb_ff, next_ex_mem_wb;
  alu_t         op1, op2, res;
  fwd_mux_t     rs1_fwd, rs2_fwd;
  logic         fwd_wdata;
  logic         jump_or_branch;
  s_branch_t    branch_ff, next_branch;
  s_jump_t      jump_ff, next_jump;

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

  always_comb begin : fwd_mux
    rs1_fwd = NO_FWD;
    rs2_fwd = NO_FWD;

    if ((ex_mem_wb_ff.rd_addr != 'h0) && (ex_mem_wb_ff.we_rd)) begin
      if ((id_ex_i.rs1_op == REG_RF) && (id_ex_i.rs1_addr == ex_mem_wb_ff.rd_addr)) begin
        rs1_fwd = FWD_REG;
      end

      if ((id_ex_i.rs2_op == REG_RF) && (id_ex_i.rs2_addr == ex_mem_wb_ff.rd_addr)) begin
        rs2_fwd = FWD_REG;
      end
    end
  end : fwd_mux

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

    op1 = (rs1_fwd == FWD_REG) ? wb_value_i : op1;

    // Mux Src B
    case (id_ex_i.rs2_op)
      REG_RF:   op2 = alu_t'(rs2_data_i);
      IMM:      op2 = alu_t'(id_ex_i.imm);
      ZERO:     op2 = alu_t'('0);
      PC:       op2 = alu_t'(id_ex_i.pc_dec);
      default:  op2 = alu_t'('0);
    endcase

    op2 = (rs2_fwd == FWD_REG) ? wb_value_i : op2;

    // ALU compute
    case (id_ex_i.f3)
      RV_F3_ADD_SUB:  res = (id_ex_i.f7 == RV_F7_1) ? op1 - op2 : op1 + op2;
      RV_F3_SLT:      res = (signed'(op1) < signed'(op2)) ? 'd1 : 'd0;
      RV_F3_SLTU:     res = (op1 < op2) ? 'd1 : 'd0;
      RV_F3_XOR:      res = (op1 ^ op2);
      RV_F3_OR:       res = (op1 | op2);
      RV_F3_AND:      res = (op1 & op2);
      RV_F3_SLL:      res = (id_ex_i.rs2_op == IMM) ? (op1 << op2[4:0]) : (op1 << op2[4:0]);
      RV_F3_SRL_SRA:  res = (id_ex_i.rshift == RV_SRA) ? signed'((signed'(op1) >>> op2[4:0])) : (op1 >> op2[4:0]);
      default:        res = 'd0;
    endcase

    next_ex_mem_wb.result  = (id_ex_i.jump) ? alu_t'(id_ex_i.pc_dec+'d4) : res;
    next_ex_mem_wb.rd_addr = id_ex_i.rd_addr;
    next_ex_mem_wb.we_rd   = id_ex_i.we_rd;

    if (lsu_bp_i) begin
      next_ex_mem_wb = ex_mem_wb_ff;
      id_ready_o = 'b0;
    end

    if (jump_or_branch) begin
      next_ex_mem_wb.we_rd = 'b0;
      illegal_ex_o = 'b0;
      trap_info_o = s_trap_info_t'('0);
    end

    illegal_ex_o = 'b0;
    trap_info_o = s_trap_info_t'('0);

    ex_mem_wb_o = ex_mem_wb_ff;
  end : alu_proc

  always_comb begin : jump_lsu_mgmt
    jump_or_branch = ((branch_ff.b_act && branch_ff.take_branch) || jump_ff.j_act);

    next_branch.b_act   = id_ex_i.branch && ~lsu_bp_i;
    next_branch.b_addr  = id_ex_i.pc_dec + id_ex_i.imm;
    next_branch.take_branch  = ~jump_or_branch &&
                               branch_dec(branch_t'(id_ex_i.f3),
                                         (rs1_fwd == NO_FWD) ? rs1_data_i : wb_value_i,
                                         (rs2_fwd == NO_FWD) ? rs2_data_i : wb_value_i);

    next_jump.j_act  = ~jump_or_branch && id_ex_i.jump && ~lsu_bp_i;
    next_jump.j_addr = {res[31:1], 1'b0};

    fwd_wdata = (id_ex_i.lsu == LSU_STORE) &&
                (ex_mem_wb_ff.we_rd) &&
                (ex_mem_wb_ff.rd_addr == id_ex_i.rs2_addr) &&
                (ex_mem_wb_ff.rd_addr != raddr_t'('h0));

    lsu_o.op_typ = id_ex_i.lsu;
    lsu_o.width  = id_ex_i.lsu_w;
    lsu_o.addr   = res;
    lsu_o.wdata  = (fwd_wdata) ? wb_value_i : rs2_data_i;
  end : jump_lsu_mgmt

  always_comb begin : fetch_req
    // To FETCH / DEC (flush_i)
    fetch_req_o  = ((branch_ff.b_act && branch_ff.take_branch) || jump_ff.j_act);
    // To FETCH / DEC (pc_jump_i)
    fetch_addr_o = (branch_ff.b_act) ? branch_ff.b_addr : jump_ff.j_addr;
  end : fetch_req

  `CLK_PROC(clk, rst) begin
    `RST_TYPE(rst) begin
      ex_mem_wb_ff <= `OP_RST_L;
      branch_ff    <= s_branch_t'('h0);
      jump_ff      <= s_jump_t'('h0);
    end
    else begin
      ex_mem_wb_ff <= next_ex_mem_wb;
      branch_ff    <= next_branch;
      jump_ff      <= next_jump;
    end
  end
endmodule
