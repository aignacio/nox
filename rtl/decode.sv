/**
 * File              : decode.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 28.10.2021
 * Last Modified Date: 29.12.2021
 */
module decode
  import utils_pkg::*;
#(
  parameter int SUPPORT_DEBUG = 1
)(
  input                 clk,
  input                 rst,
  // Control signals
  input                 jump_i,
  input                 stall_i,
  input   pc_t          pc_reset_i,
  input   pc_t          pc_jump_i,
  //output  s_stall_id_t  id_regs_o,
  // From FETCH stg I/F
  input   valid_t       fetch_valid_i,
  output  ready_t       fetch_ready_o,
  input   instr_raw_t   fetch_instr_i,
  // From MEM/WB stg I/F
  input   s_wb_t        wb_dec_i,
  // To EXEC stg I/F
  output  s_id_ex_t     id_ex_o,
  output  rdata_t       rs1_data_o,
  output  rdata_t       rs2_data_o,
  output  valid_t       id_valid_o,
  input   ready_t       id_ready_i,
  // Trap - Instruction access fault
  output  logic         illegal_instr_fault_o,
  output  s_trap_info_t trap_info_o
);
  valid_t     dec_valid_ff, next_vld_dec;
  s_instr_t   instr_dec;
  logic       wait_inst_ff, next_wait_inst;

  s_trap_info_t trap_info_ff, next_trap;
  s_id_ex_t id_ex_ff, next_id_ex;

  always_comb begin
    next_vld_dec  = fetch_valid_i;
    fetch_ready_o = (id_ready_i && ~stall_i);
    id_valid_o    = dec_valid_ff;
  end

  always_comb begin : dec_op
    if (jump_i || stall_i) begin
      // ..Insert a NOP
      id_ex_o          = s_id_ex_t'('0);
      id_ex_o.we_rd    = 'b0;
      id_ex_o.rs1_op   = REG_RF;
      id_ex_o.rs2_op   = IMM;
      id_ex_o.lsu      = NO_LSU;
      id_ex_o.branch   = 'b0;
      id_ex_o.jump     = 'b0;
      id_ex_o.f7       = sfunct7_t'('h0);
      id_ex_o.rd_addr  = raddr_t'('h0);
      id_ex_o.f3       = RV_F3_ADD_SUB;
      id_ex_o.rshift   = rshift_t'('h0);
      id_ex_o.imm      = imm_t'('h0);
      id_ex_o.rs1_addr = raddr_t'('h0);
      id_ex_o.rs2_addr = raddr_t'('h0);
    end
    else begin
      id_ex_o = id_ex_ff;
    end

    instr_dec  = fetch_instr_i;
    next_trap  = trap_info_ff;
    next_id_ex = id_ex_ff;

    // Defaults
    next_id_ex          = s_id_ex_t'('0);
    next_id_ex.rd_addr  = instr_dec.rd;
    next_id_ex.rs1_addr = instr_dec.rs1;
    next_id_ex.rs2_addr = instr_dec.rs2;

    case(instr_dec.op)
      RV_OP_IMM: begin
        next_id_ex.f3     = instr_dec.f3;
        next_id_ex.rs1_op = REG_RF;
        next_id_ex.rs2_op = IMM;
        next_id_ex.imm    = gen_imm(fetch_instr_i, I_IMM);
        next_id_ex.rshift = instr_dec[30] ? RV_SRA : RV_SRL;
        next_id_ex.we_rd  = 1'b1;
      end
      RV_LUI: begin
        next_id_ex.f3     = RV_F3_ADD_SUB;
        next_id_ex.rs1_op = ZERO;
        next_id_ex.rs2_op = IMM;
        next_id_ex.imm    = gen_imm(fetch_instr_i, U_IMM);
        next_id_ex.we_rd  = 1'b1;
      end
      RV_AUIPC: begin
        next_id_ex.f3     = RV_F3_ADD_SUB;
        next_id_ex.rs1_op = PC;
        next_id_ex.rs2_op = IMM;
        next_id_ex.imm    = gen_imm(fetch_instr_i, U_IMM);
        next_id_ex.we_rd  = 1'b1;
      end
      RV_OP: begin
        next_id_ex.f3     = instr_dec.f3;
        next_id_ex.rs1_op = REG_RF;
        next_id_ex.rs2_op = REG_RF;
        next_id_ex.f7     = instr_dec[30] ? RV_F7_1 : RV_F7_0;
        next_id_ex.we_rd  = 1'b1;
      end
      RV_JAL: begin
        next_id_ex.jump   = 1'b1;
        next_id_ex.f3     = RV_F3_ADD_SUB;
        next_id_ex.rs1_op = PC;
        next_id_ex.rs2_op = IMM;
        next_id_ex.imm    = gen_imm(fetch_instr_i, J_IMM);
        next_id_ex.we_rd  = 1'b1;
      end
      RV_JALR: begin
        next_id_ex.jump   = 1'b1;
        next_id_ex.f3     = RV_F3_ADD_SUB;
        next_id_ex.rs1_op = REG_RF;
        next_id_ex.rs2_op = IMM;
        next_id_ex.imm    = gen_imm(fetch_instr_i, I_IMM);
        next_id_ex.we_rd  = 1'b1;
      end
      RV_BRANCH: begin
        next_id_ex.branch = 1'b1;
        next_id_ex.f3     = instr_dec.f3;
        next_id_ex.rs1_op = REG_RF;
        next_id_ex.rs2_op = REG_RF;
        next_id_ex.imm    = gen_imm(fetch_instr_i, B_IMM);
      end
      RV_LOAD: begin
        next_id_ex.lsu    = LSU_LOAD;
        next_id_ex.f3     = RV_F3_ADD_SUB;
        next_id_ex.rs1_op = REG_RF;
        next_id_ex.rs2_op = IMM;
        next_id_ex.we_rd  = 1'b1;
        next_id_ex.lsu_w  = lsu_w_t'(instr_dec.f3);
        next_id_ex.imm    = gen_imm(fetch_instr_i, I_IMM);
      end
      RV_STORE: begin
        next_id_ex.lsu     = LSU_STORE;
        next_id_ex.f3      = RV_F3_ADD_SUB;
        next_id_ex.rs1_op  = REG_RF;
        next_id_ex.rs2_op  = IMM;
        next_id_ex.lsu_w   = lsu_w_t'(instr_dec.f3);
        next_id_ex.imm     = gen_imm(fetch_instr_i, S_IMM);
      end
      RV_MISC_MEM: begin
        next_id_ex.f3     = RV_F3_ADD_SUB;
        next_id_ex.rs1_op = ZERO;
        next_id_ex.rs2_op = ZERO;
      end
      RV_SYSTEM: begin // TODO: Create logic for ecall/ebreak
        next_id_ex.f3     = RV_F3_ADD_SUB;
        next_id_ex.rs1_op = ZERO;
        next_id_ex.rs2_op = ZERO;
      end
      default: begin
        next_trap.active = 1'b1;
        `P_MSG ("DEC", "Instruction non-supported")
      end
    endcase

    if (fetch_valid_i && id_ready_i && wait_inst_ff && ~stall_i) begin
      next_id_ex.pc_dec  = id_ex_ff.pc_dec + 'd4;
    end
    else begin
      next_id_ex.pc_dec  = id_ex_ff.pc_dec;
    end

    if (jump_i) begin
      next_id_ex.pc_dec  = pc_jump_i;
    end

    next_wait_inst = wait_inst_ff;
    if (~wait_inst_ff) begin
      next_wait_inst = (fetch_valid_i && id_ready_i && ~stall_i);
    end
    else if (jump_i) begin
      next_wait_inst = 'b0;
    end

    //id_regs_o.rs1_addr = instr_dec.rs1;
    //id_regs_o.rs2_addr = instr_dec.rs2;
    //id_regs_o.rs1_sel  = (next_id_ex.rs1_op == REG_RF);
    //id_regs_o.rs2_sel  = (next_id_ex.rs2_op == REG_RF);
  end : dec_op

  `CLK_PROC(clk, rst) begin
    `RST_TYPE(rst) begin
      dec_valid_ff    <= 'b0;
      id_ex_ff        <= `OP_RST_L;
      id_ex_ff.pc_dec <= pc_reset_i;
      wait_inst_ff    <= 'b0;
    end
    else begin
      dec_valid_ff    <= next_vld_dec;
      id_ex_ff        <= next_id_ex;
      wait_inst_ff    <= next_wait_inst;
    end
  end

  register_file u_register_file(
    .clk       (clk),
    .rst       (rst),
    .rs1_addr_i(instr_dec.rs1),
    .rs2_addr_i(instr_dec.rs2),
    .rd_addr_i (wb_dec_i.rd_addr),
    .rd_data_i (wb_dec_i.rd_data),
    .we_i      (wb_dec_i.we_rd),
    .rs1_data_o(rs1_data_o),
    .rs2_data_o(rs2_data_o)
  );

`ifdef COCOTB_SIM
  `ifdef XCELIUM
    `DUMP_WAVES_XCELIUM
  `endif
`endif
endmodule
