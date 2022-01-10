/**
 * File              : nox_synth.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 12.12.2021
 * Last Modified Date: 10.01.2022
 */
module nox_synth import utils_pkg::*; (
  input   clk_in,
  input   rst
);
  s_axi_mosi_t  [1:0] masters_axi_mosi;
  s_axi_miso_t  [1:0] masters_axi_miso;

  s_axi_mosi_t  [1:0] slaves_axi_mosi;
  s_axi_miso_t  [1:0] slaves_axi_miso;

  assign slaves_axi_mosi[0]  = masters_axi_mosi[0];
  assign slaves_axi_mosi[1]  = masters_axi_mosi[1];
  assign masters_axi_miso[0] = slaves_axi_miso[0];
  assign masters_axi_miso[1] = slaves_axi_miso[1];

  logic start_fetch;
  logic clk_out_clock_gen;
  logic clk_in_clock_gen;
  logic reset_clk = ~rst;

  MMCME2_ADV#(
    .BANDWIDTH            ("OPTIMIZED"),
    .CLKOUT4_CASCADE      ("FALSE"),
    .COMPENSATION         ("ZHOLD"),
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (1),
    .CLKFBOUT_MULT_F      (10.000),
    .CLKFBOUT_PHASE       (0.000),
    .CLKFBOUT_USE_FINE_PS ("FALSE"),
    .CLKOUT0_DIVIDE_F     (5.000),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT0_USE_FINE_PS  ("FALSE"),
    .CLKIN1_PERIOD        (10.000))
  u_mmcm_adv_inst
    // Output clocks
  (
    .CLKOUT0             (clk_out_clock_gen),
    // Input clock control
    .CLKIN1              (clk_in_clock_gen),
    .CLKIN2              (1'b0),
    // Tied to always select the primary input clock
    .CLKINSEL            (1'b1),
    // Ports for dynamic reconfiguration
    .DADDR               (7'h0),
    .DCLK                (1'b0),
    .DEN                 (1'b0),
    .DI                  (16'h0),
    .DWE                 (1'b0),
    // Ports for dynamic phase shift
    .PSCLK               (1'b0),
    .PSEN                (1'b0),
    .PSINCDEC            (1'b0),
    // Other control and status signals
    .LOCKED              (start_fetch),
    .PWRDWN              (1'b0),
    .RST                 (reset_clk)
  );

  IBUF u_clk_ibufg(
    .O(clk_in_clock_gen),
    .I(clk_in)
  );

  BUFG u_clk_buf(
    .O(clk),
    .I(clk_out_clock_gen)
  );

  axi_mem #(
    .MEM_KB(64)
  ) u_iram (
    .clk      (clk),
    .rst      (rst),
    .axi_mosi (slaves_axi_mosi[0]),
    .axi_miso (slaves_axi_miso[0])
  );

  axi_mem #(
    .MEM_KB(64)
  ) u_dram (
    .clk      (clk),
    .rst      (rst),
    .axi_mosi (slaves_axi_mosi[1]),
    .axi_miso (slaves_axi_miso[1])
  );

  nox u_nox(
    .clk              (clk),
    .arst             (rst),
    .start_fetch_i    (start_fetch),
    .start_addr_i     ('h8000_0000),
    .instr_axi_mosi_o (masters_axi_mosi[0]),
    .instr_axi_miso_i (masters_axi_miso[0]),
    .lsu_axi_mosi_o   (masters_axi_mosi[1]),
    .lsu_axi_miso_i   (masters_axi_miso[1])
  );
endmodule

