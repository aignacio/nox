/**
 * File              : nox_wrapper.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 12.03.2022
 * Last Modified Date: 17.03.2022
 */
module nox_wrapper import utils_pkg::*; (
  input                 clk,
  input                 rst,
  input   [2:0]         irq_i,
  input                 start_fetch_i,
  input   [31:0]        start_addr_i,
  output  s_axi_mosi_t  instr_axi_mosi_o,
  input   s_axi_miso_t  instr_axi_miso_i,
  output  s_axi_mosi_t  lsu_axi_mosi_o,
  input   s_axi_miso_t  lsu_axi_miso_i
);
  s_irq_t     irq_core;
  logic [2:0] irq_sync;

  genvar i;
  generate
    for(i=0;i<3;i++) begin : sync_irq
      cdc_2ff_sync u_irq_sync(
        .arst_master  (~rst),
        .clk_sync     (clk),
        .async_i      (irq_i[i]),
        .sync_o       (irq_sync[i])
      );
    end
  endgenerate

  always_comb begin
    irq_core.timer_irq  = irq_sync[2];
    irq_core.sw_irq     = irq_sync[1];
    irq_core.ext_irq    = irq_sync[0];
  end

  nox u_nox (
    .clk              (clk),
    .arst             (rst),
    .irq_i            (irq_core),
    .start_fetch_i    (start_fetch_i),
    .start_addr_i     (start_addr_i),
    .instr_axi_mosi_o (instr_axi_mosi_o),
    .instr_axi_miso_i (instr_axi_miso_i),
    .lsu_axi_mosi_o   (lsu_axi_mosi_o),
    .lsu_axi_miso_i   (lsu_axi_miso_i)
  );
endmodule
