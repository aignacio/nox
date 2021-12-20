`ifndef _RISCV_PKG_
`define _RISCV_PKG_
  `define PC_WIDTH      32
  `define XLEN          32

  typedef logic [`XLEN-1:0]         instr_raw_t;
  typedef logic [`PC_WIDTH-1:0]     pc_t;
  typedef logic [`XLEN-1:0]         lsu_addr_t;
  typedef logic [`XLEN-1:0]         b_addr_t;
  typedef logic [`XLEN-1:0]         j_addr_t;

  typedef logic [$clog2(`XLEN)-1:0] raddr_t;
  typedef logic [`XLEN-1:0]         rdata_t;
  typedef logic [`XLEN-1:0]         imm_t;
  typedef logic [4:0]               shamt_t;
  typedef logic [`XLEN-1:0]         alu_t;

  typedef enum logic [1:0] {
    REG_RF,
    IMM,
    ZERO,
    PC
  } oper_mux_t;

  typedef enum logic [2:0] {
    RV_LSU_B  = 3'b000,
    RV_LSU_H  = 3'b001,
    RV_LSU_W  = 3'b010,
    RV_LSU_BU = 3'b100,
    RV_LSU_HU = 3'b101
  } lsu_w_t;

  typedef enum logic [1:0] {
    NO_LSU,
    LSU_LOAD,
    LSU_STORE
  } lsu_t;

  typedef enum logic {
    RV_SRL = 1'b0,
    RV_SRA = 1'b1
  } rshift_t;

  typedef enum logic [6:0]{
    RV_F7_SRL = 7'b0000000,
    RV_F7_SRA = 7'b0100000
  } funct7_t;

  typedef enum logic {
    RV_F7_0,
    RV_F7_1
  } sfunct7_t;

  typedef enum logic {
    RV_TYPE_JAL,
    RV_TYPE_JALR
  } j_type_t;

  typedef enum logic [2:0]{
    RV_B_BEQ   = 3'b000,
    RV_B_BNE   = 3'b001,
    RV_B_BLT   = 3'b100,
    RV_B_BGE   = 3'b101,
    RV_B_BLTU  = 3'b110,
    RV_B_BGEU  = 3'b111
  } branch_t;

  typedef enum logic [2:0]{
    RV_F3_ADD_SUB   = 3'b000,
    RV_F3_SLT       = 3'b010,
    RV_F3_SLTU      = 3'b011,
    RV_F3_XOR       = 3'b100,
    RV_F3_OR        = 3'b110,
    RV_F3_AND       = 3'b111,
    RV_F3_SLL       = 3'b001,
    RV_F3_SRL_SRA   = 3'b101
  } funct3_t;

  typedef enum logic [6:0]{
    RV_LOAD       = 'b00_000_11,
    RV_custom_0   = 'b00_010_11,
    RV_MISC_MEM   = 'b00_011_11,
    RV_OP_IMM     = 'b00_100_11,
    RV_AUIPC      = 'b00_101_11,
    RV_OP_IMM_32  = 'b00_110_11,
    RV_STORE      = 'b01_000_11,
    RV_custom_1   = 'b01_010_11,
    RV_OP         = 'b01_100_11,
    RV_LUI        = 'b01_101_11,
    RV_OP_32      = 'b01_110_11,
    RV_custom_2   = 'b10_110_11,
    RV_BRANCH     = 'b11_000_11,
    RV_JALR       = 'b11_001_11,
    RV_JAL        = 'b11_011_11,
    RV_SYSTEM     = 'b11_100_11,
    RV_custom_3   = 'b11_110_11
  } op_t;

  typedef enum logic [2:0]{
    I_IMM,
    S_IMM,
    B_IMM,
    U_IMM,
    J_IMM
  } imm_type_t;

  typedef struct packed {
    funct7_t  f7;
    raddr_t   rs2;
    raddr_t   rs1;
    funct3_t  f3;
    raddr_t   rd;
    op_t      op;
  } s_instr_t;

  typedef struct packed {
    pc_t        pc_addr;
    instr_raw_t instr;
    bool_t      active;
  } s_trap_info_t;

  typedef struct packed {
    logic        we_rd;
    pc_t         pc_dec;
    oper_mux_t   rs1_op;
    oper_mux_t   rs2_op;
    lsu_t        lsu;
    lsu_w_t      lsu_w;
    logic        branch;
    logic        jump;
    sfunct7_t    f7;
    raddr_t      rd_addr;
    funct3_t     f3;
    rshift_t     rshift;
    imm_t        imm;
    raddr_t      rs1_addr;
    raddr_t      rs2_addr;
  } s_id_ex_t;

  typedef struct packed {
    lsu_t       lsu;
    logic       we_rd;
    raddr_t     rd_addr;
    alu_t       result;
  } s_ex_mem_wb_t;

  typedef struct packed {
    logic       take_branch;
    logic       b_act;
    b_addr_t    b_addr;
  } s_branch_t;

  typedef struct packed {
    logic       j_act;
    j_addr_t    j_addr;
  } s_jump_t;

  typedef struct packed {
    lsu_t       op_typ;
    lsu_w_t     width;
    lsu_addr_t  addr;
    rdata_t     wdata;
  } s_lsu_op_t;

  typedef struct packed {
    rdata_t     rd_data;
    raddr_t     rd_addr;
    logic       we_rd;
  } s_wb_t;

  typedef struct packed {
    raddr_t     rs1_addr;
    raddr_t     rs2_addr;
    logic       rs1_sel;
    logic       rs2_sel;
  } s_stall_id_t;

  function automatic imm_t gen_imm(instr_raw_t instr, imm_type_t imm_type);
    imm_t imm_res;

    unique case(imm_type)
      I_IMM:  imm_res = {{21{instr[31]}},instr[30:25],instr[24:21],instr[20]};
      S_IMM:  imm_res = {{21{instr[31]}},instr[30:25],instr[11:8],instr[7]};
      B_IMM:  imm_res = {{20{instr[31]}},instr[7],instr[30:25],instr[11:8],1'b0};
      U_IMM:  imm_res = {instr[31],instr[30:20],instr[19:12],12'd0};
      J_IMM:  imm_res = {{12{instr[31]}},instr[19:12],instr[20],instr[30:25],instr[24:21],1'b0};
      default:  `ERROR("Immediate encoding not valid!",imm_type)
    endcase
    return  imm_res;
  endfunction
`endif
