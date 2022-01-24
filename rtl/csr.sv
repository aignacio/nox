/**
 * File              : csr.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 23.01.2022
 * Last Modified Date: 24.01.2022
 */
module csr(
  input   s_csr_t csr_i,
  input   rdata_t rs1_data_i,
  input   imm_t   imm_i,
  output  rdata_t csr_rd_o
);

  rdata_t csr_cycle_ff,     next_cycle,
          csr_time_ff,      next_time,
          csr_minstret_ff,  next_minstret,
          csr_mstatus_ff,   next_mstatus,
          csr_mie_ff,       next_mie,
          csr_mtvec_ff,     next_mtvec,
          csr_mscratch_ff,  next_mscratch,
          csr_mepc_ff,      next_mepc,
          csr_mcause_ff,    next_mcause;

  always_comb begin : wr_csr
    case (csr_i.op) begin
      RV_CSR_NONE:
      RV_CSR_RW:
      RV_CSR_RS:
      RV_CSR_RC:
      RV_CSR_RWI:
      RV_CSR_RSI:
      RV_CSR_RCI:
      default:
    endcase
  end : wr_csr

  always_comb begin : rd_csr
    csr_rd_o = rdata_t'('0);

    if (csr_i.op == RV_CSR_NONE) begin
      case(csr_i.addr) begin
        RV_CSR_MCYCLE     csr_rd_o = csr_cycle_ff[31:0];
        RV_CSR_MCYCLEH    csr_rd_o = csr_cycle_ff[63:32];
        RV_CSR_CYCLE      csr_rd_o = csr_cycle_ff[31:0];
        RV_CSR_CYCLEH     csr_rd_o = csr_cycle_ff[63:32];
        RV_CSR_MINSTRET   csr_rd_o = csr_minstret_ff[31:0];
        RV_CSR_MINSTRETH  csr_rd_o = csr_minstret_ff[63:32];
        RV_CSR_INSTRET    csr_rd_o = csr_minstret_ff[31:0];
        RV_CSR_INSTRETH   csr_rd_o = csr_minstret_ff[63:32];
        RV_CSR_TIME       csr_rd_o = csr_time_ff[31:0];
        RV_CSR_TIME       csr_rd_o = csr_time_ff[63:32];
        RV_CSR_MVENDORID
        RV_CSR_MARCHID
        RV_CSR_MIMPLID
        RV_CSR_MHARTID
        RV_CSR_MSTATUS
        RV_CSR_MISA
        RV_CSR_MIE
        RV_CSR_MTVEC
        RV_CSR_MSCRATCH
        RV_CSR_MEPC
        RV_CSR_MCAUSE
        RV_CSR_MTVAL
        RV_CSR_MIP



      endcase
    end
  end : rd_csr

  `CLK_PROC(clk, rst) begin
    `RST_TYPE(rst) begin

    end
    else begin

    end
  end
endmodule
