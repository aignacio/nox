/**
 * File              : execute.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 21.11.2021
 * Last Modified Date: 20.03.2022
 */
module execute
  import utils_pkg::*;
#(
  parameter int SUPPORT_DEBUG     = 1,
  parameter int MTVEC_DEFAULT_VAL = 'h1000 // 4KB
)(
  input                     clk,
  input                     rst,
  // Control signals
  input   rdata_t           wb_value_i,
  input   rdata_t           wb_load_i,
  input                     lock_wb_i,
  // From DEC stg I/F
  input   s_id_ex_t         id_ex_i,
  input   rdata_t           rs1_data_i,
  input   rdata_t           rs2_data_i,
  input   valid_t           id_valid_i,
  output  ready_t           id_ready_o,
  // To MEM/WB stg I/F
  output  s_ex_mem_wb_t     ex_mem_wb_o,
  output  s_lsu_op_t        lsu_o,
  input                     lsu_bp_i,
  input   pc_t              lsu_pc_i,
  // IRQs
  input   s_irq_t           irq_i,
  // To FETCH stg
  output  logic             fetch_req_o,
  output  pc_t              fetch_addr_o,
  // Trap signals
  input   s_trap_info_t     fetch_trap_i,
  input   s_trap_lsu_info_t lsu_trap_i
);
  typedef enum logic {
    NO_FWD,
    FWD_REG
  } fwd_mux_t;

  s_ex_mem_wb_t ex_mem_wb_ff, next_ex_mem_wb;
  alu_t         op1, op2, res;
  fwd_mux_t     rs1_fwd, rs2_fwd;
  logic         fwd_wdata;
  logic         jump_or_branch;
  s_branch_t    branch_ff, next_branch;
  s_jump_t      jump_ff, next_jump;
  rdata_t       csr_rdata;
  s_trap_info_t trap_out;
  logic         will_jump_next_clk;
  logic         eval_trap;
  s_trap_info_t instr_addr_misaligned;

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

    next_ex_mem_wb = ex_mem_wb_ff;

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
    end

    if (id_ex_i.csr.op != RV_CSR_NONE) begin
      next_ex_mem_wb.result = csr_rdata;
    end

    ex_mem_wb_o = ex_mem_wb_ff;
  end : alu_proc

  always_comb begin : jump_lsu_mgmt
    instr_addr_misaligned = s_trap_info_t'('0);

    jump_or_branch = ((branch_ff.b_act && branch_ff.take_branch) || jump_ff.j_act);

    next_branch.b_act   = id_ex_i.branch && ~lsu_bp_i;
    next_branch.b_addr  = id_ex_i.pc_dec + id_ex_i.imm;
    next_branch.take_branch  = ~jump_or_branch &&
                               branch_dec(branch_t'(id_ex_i.f3), op1, op2);

    next_jump.j_act  = ~jump_or_branch && id_ex_i.jump && ~lsu_bp_i;
    next_jump.j_addr = {res[31:1], 1'b0};

    fwd_wdata = (id_ex_i.lsu == LSU_STORE) &&
                (ex_mem_wb_ff.we_rd) &&
                (ex_mem_wb_ff.rd_addr == id_ex_i.rs2_addr) &&
                (ex_mem_wb_ff.rd_addr != raddr_t'('h0));

    lsu_o.op_typ  = id_ex_i.lsu;
    lsu_o.width   = id_ex_i.lsu_w;
    lsu_o.addr    = res;
    lsu_o.wdata   = rs2_data_i;
    lsu_o.pc_addr = id_ex_i.pc_dec;
    if (fwd_wdata) begin
      // Lock means that we had a load but we had
      // to stall due to bp from the bus, thus we need
      // to use a store value of the load
      lsu_o.wdata  = (lock_wb_i) ? wb_load_i : wb_value_i;
    end
    will_jump_next_clk = next_branch.b_act || next_jump.j_act;

    if (will_jump_next_clk && next_jump.j_act) begin
      instr_addr_misaligned.active = next_jump.j_addr[1];
      instr_addr_misaligned.mtval  = next_jump.j_addr;
    end
    if (will_jump_next_clk && next_branch.b_act) begin
      instr_addr_misaligned.active = next_branch.b_addr[1] || next_branch.b_addr[0];
      instr_addr_misaligned.mtval  = next_branch.b_addr;
    end
  end : jump_lsu_mgmt

  always_comb begin : fetch_req
    fetch_req_o  = '0;
    fetch_addr_o = '0;

    fetch_req_o  = ((branch_ff.b_act && branch_ff.take_branch) || jump_ff.j_act);
    fetch_addr_o = (branch_ff.b_act) ? branch_ff.b_addr : jump_ff.j_addr;

    if (trap_out.active) begin
      fetch_req_o  = 'b1;
      fetch_addr_o = trap_out.pc_addr;
    end

    eval_trap = id_ready_o &&
                id_valid_i &&
                ~fetch_req_o &&
                (lsu_o.op_typ == NO_LSU);
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

  csr #(
    .SUPPORT_DEBUG      (SUPPORT_DEBUG),
    .MTVEC_DEFAULT_VAL  (MTVEC_DEFAULT_VAL)
  ) u_csr (
    .clk                (clk),
    .rst                (rst),
    .stall_i            (lsu_bp_i),
    .csr_i              (id_ex_i.csr),
    .rs1_data_i         (op1),
    .imm_i              (id_ex_i.imm),
    .csr_rd_o           (csr_rdata),
    .pc_addr_i          (id_ex_i.pc_dec),
    .pc_lsu_i           (lsu_pc_i),
    .irq_i              (irq_i),
    .will_jump_i        (will_jump_next_clk),
    .eval_trap_i        (eval_trap),
    .dec_trap_i         (id_ex_i.trap),
    .instr_addr_mis_i   (instr_addr_misaligned),
    .fetch_trap_i       (fetch_trap_i),
    .ecall_i            (id_ex_i.ecall),
    .ebreak_i           (id_ex_i.ebreak),
    .mret_i             (id_ex_i.mret),
    .wfi_i              (id_ex_i.wfi),
    .lsu_trap_i         (lsu_trap_i),
    .trap_o             (trap_out)
  );
endmodule
