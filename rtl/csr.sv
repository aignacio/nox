/**
 * File              : csr.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 23.01.2022
 * Last Modified Date: 13.02.2022
 */
module csr(
  input           clk,
  input           rst,
  input           stall_i,
  input   s_csr_t csr_i,
  input   rdata_t rs1_data_i,
  input   imm_t   imm_i,
  output  rdata_t csr_rd_o
);
  typedef struct packed {
    csr_t   op;
    imm_t   imm;
    rdata_t rs1;
    rdata_t csr_rd;
  } s_wr_csr_t;

  rdata_ext_t csr_minstret_ff,  next_minstret,
              csr_cycle_ff,     next_cycle,
              csr_time_ff,      next_time;

  rdata_t csr_mstatus_ff,   next_mstatus,
          csr_mie_ff,       next_mie,
          csr_mtvec_ff,     next_mtvec,
          csr_mscratch_ff,  next_mscratch,
          csr_mepc_ff,      next_mepc,
          csr_mcause_ff,    next_mcause,
          csr_mtval_ff,     next_mtval,
          csr_mip_ff,       next_mip;

  s_wr_csr_t csr_wr_arg;

  function automatic rdata_t wr_csr_val(s_wr_csr_t wr_arg);
    rdata_t wr_val;

    case (wr_arg.op)
      RV_CSR_RW:  wr_val = wr_arg.rs1;
      RV_CSR_RS:  wr_val = wr_arg.csr_rd & wr_arg.rs1;
      RV_CSR_RC:  wr_val = wr_arg.csr_rd & ~wr_arg.rs1;
      RV_CSR_RWI: wr_val = wr_arg.imm;
      RV_CSR_RSI: wr_val = wr_arg.csr_rd & wr_arg.imm;
      RV_CSR_RCI: wr_val = wr_arg.csr_rd & ~wr_arg.imm;
      default:    wr_val = wr_arg.csr_rd;
    endcase

    wr_val = stall_i ? wr_arg.csr_rd : wr_val;
    return wr_val;
  endfunction

  always_comb begin : rd_wr_csr
    // Output is combo cause there's a mux in the exe stg
    csr_rd_o = rdata_t'('0);

    next_cycle    = csr_cycle_ff + 'd1;
    next_time     = csr_time_ff;
    next_minstret = csr_minstret_ff;
    next_mstatus  = csr_mstatus_ff;
    next_mie      = csr_mie_ff;
    next_mtvec    = csr_mtvec_ff;
    next_mscratch = csr_mscratch_ff;
    next_mepc     = csr_mepc_ff;
    next_mcause   = csr_mcause_ff;
    next_mtval    = csr_mtval_ff;
    next_mip      = csr_mip_ff;

    csr_wr_arg.op     = csr_i.op;
    csr_wr_arg.imm    = imm_i;
    csr_wr_arg.rs1    = rs1_data_i;
    csr_wr_arg.csr_rd = '0;

    case(csr_i.addr)
      RV_CSR_MSTATUS: begin
        csr_rd_o           = csr_mstatus_ff;
        csr_wr_args.csr_rd = csr_rd_o;
        next_mstatus       = wr_csr_val(csr_wr_arg);
      end
      RV_CSR_MIE: begin
        csr_rd_o           = csr_mie_ff;
        csr_wr_args.csr_rd = csr_rd_o;
        next_mie           = wr_csr_val(csr_wr_arg);
      end
      RV_CSR_MTVEC: begin
        csr_rd_o           = csr_mtvec_ff;
        csr_wr_args.csr_rd = csr_rd_o;
        next_mtvec         = wr_csr_val(csr_wr_arg);
      end
      RV_CSR_MSCRATCH: begin
        csr_rd_o           = csr_mscratch_ff;
        csr_wr_args.csr_rd = csr_rd_o;
        next_mscratch      = wr_csr_val(csr_wr_arg);
      end
      RV_CSR_MEPC: begin
        csr_rd_o           = csr_mepc_ff;
        csr_wr_args.csr_rd = csr_rd_o;
        next_mepc          = wr_csr_val(csr_wr_arg);
      end
      RV_CSR_MCAUSE: begin
        csr_rd_o           = csr_mcause_ff;
        csr_wr_args.csr_rd = csr_rd_o;
        next_mcause        = wr_csr_val(csr_wr_arg);
      end
      RV_CSR_MTVAL: begin
        csr_rd_o           = csr_mtval_ff;
        csr_wr_args.csr_rd = csr_rd_o;
        next_mtval         = wr_csr_val(csr_wr_arg);
      end
      RV_CSR_MIP: begin
        csr_rd_o           = csr_mip_ff;
        csr_wr_args.csr_rd = csr_rd_o;
        next_mip           = wr_csr_val(csr_wr_arg);
      end
      RV_CSR_MCYCLE:    csr_rd_o = csr_cycle_ff[31:0];
      RV_CSR_MCYCLEH:   csr_rd_o = csr_cycle_ff[63:32];
      RV_CSR_MINSTRET:  csr_rd_o = csr_minstret_ff[31:0];
      RV_CSR_MINSTRETH: csr_rd_o = csr_minstret_ff[63:32];
      RV_CSR_CYCLE:     csr_rd_o = csr_cycle_ff[31:0];
      RV_CSR_CYCLEH:    csr_rd_o = csr_cycle_ff[63:32];
      RV_CSR_INSTRET:   csr_rd_o = csr_minstret_ff[31:0];
      RV_CSR_INSTRETH:  csr_rd_o = csr_minstret_ff[63:32];
      RV_CSR_TIME:      csr_rd_o = csr_time_ff[31:0];
      RV_CSR_TIMEH:     csr_rd_o = csr_time_ff[63:32];
      RV_CSR_MISA:      csr_rd_o = `M_ISA_ID;
      RV_CSR_MVENDORID: csr_rd_o = `M_VENDOR_ID;
      RV_CSR_MARCHID:   csr_rd_o = `M_ARCH_ID;
      RV_CSR_MIMPLID:   csr_rd_o = `M_IMPL_ID;
      RV_CSR_MHARTID:   csr_rd_o = `M_HART_ID;
    endcase
  end : rd_wr_csr

  `CLK_PROC(clk, rst) begin
    `RST_TYPE(rst) begin
      csr_mstatus_ff  <=  `OP_RST_L;
      csr_mie_ff      <=  `OP_RST_L;
      csr_mtvec_ff    <=  `OP_RST_L;
      csr_mscratch_ff <=  `OP_RST_L;
      csr_mepc_ff     <=  `OP_RST_L;
      csr_mcause_ff   <=  `OP_RST_L;
      csr_mtval_ff    <=  `OP_RST_L;
      csr_mip_ff      <=  `OP_RST_L;
      csr_cycle_ff    <=  `OP_RST_L;
      csr_time_ff     <=  `OP_RST_L;
      csr_minstret_ff <=  `OP_RST_L;
    end
    else begin
      csr_mstatus_ff  <=  next_mstatus;
      csr_mie_ff      <=  next_mie;
      csr_mtvec_ff    <=  next_mtvec;
      csr_mscratch_ff <=  next_mscratch;
      csr_mepc_ff     <=  next_mepc;
      csr_mcause_ff   <=  next_mcause;
      csr_mtval_ff    <=  next_mtval;
      csr_mip_ff      <=  next_mip;
      csr_cycle_ff    <=  next_cycle;
      csr_time_ff     <=  next_time;
      csr_minstret_ff <=  next_minstret;
    end
  end
endmodule
