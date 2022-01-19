/**
 * File              : nox_synth.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 12.12.2021
 * Last Modified Date: 19.01.2022
 */
module nox_synth
  import utils_pkg::*;
(
  input               clk_in,
  input               rst_cpu,
  input               rst_clk,
  output  logic [7:0] csr_out,
  output  logic       test_act
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
  logic reset_clk;
  logic [7:0] csr_out_int;

  assign csr_out[0]   = start_fetch;
  assign csr_out[1]   = rst_cpu;
  assign csr_out[7:2] = csr_out_int[6:1];
  assign test_act     = 'b0;

  // 100MHz (in) -> 80MHz (clk out)
  logic clk_in_clk_gen;
  logic clkfbout_buf_clk_gen;
  logic clkfbout_clk_gen;

  IBUF clkin_ibufg(
    .O (clk_in_clk_gen),
    .I (clk_in)
  );

  PLLE2_ADV #(
    .BANDWIDTH           ("OPTIMIZED"),
    .COMPENSATION        ("ZHOLD"),
    .STARTUP_WAIT        ("FALSE"),
    .DIVCLK_DIVIDE       (5),
    .CLKFBOUT_MULT       (44),
    .CLKFBOUT_PHASE      (0.000),
    .CLKOUT0_DIVIDE      (11),
    .CLKOUT0_PHASE       (0.000),
    .CLKOUT0_DUTY_CYCLE  (0.500),
    .CLKIN1_PERIOD       (10.000)
  ) u_plle2_adv_inst (
    // Output clocks
    .CLKFBOUT            (clkfbout_clk_gen),
    .CLKOUT0             (clk_out_clk_gen),
    .CLKOUT1             (),
    .CLKOUT2             (),
    .CLKOUT3             (),
    .CLKOUT4             (),
    .CLKOUT5             (),
     // Input clock control
    .CLKFBIN             (clkfbout_buf_clk_gen),
    .CLKIN1              (clk_in_clk_gen),
    .CLKIN2              (1'b0),
     // Tied to always select the primary input clock
    .CLKINSEL            (1'b1),
    // Ports for dynamic reconfiguration
    .DADDR               (7'h0),
    .DCLK                (1'b0),
    .DEN                 (1'b0),
    .DI                  (16'h0),
    .DO                  (),
    .DRDY                (),
    .DWE                 (1'b0),
    // Other control and status signals
    .LOCKED              (start_fetch),
    .PWRDWN              (1'b0),
    .RST                 (rst_clk)
  );

  BUFG u_clkf_buf(
    .O (clkfbout_buf_clk_gen),
    .I (clkfbout_clk_gen)
  );

  BUFG u_clkout_buf(
    .O   (clk),
    .I   (clk_out_clk_gen)
  );

  axi_rom_wrapper u_irom(
    .clk      (clk),
    .rst      (rst_cpu),
    .axi_mosi (slaves_axi_mosi[0]),
    .axi_miso (slaves_axi_miso[0])
  );

  axi_mem_wrapper #(
    .MEM_KB(4)
  ) u_dram (
    .clk      (clk),
    .rst      (rst_cpu),
    .axi_mosi (slaves_axi_mosi[1]),
    .axi_miso (slaves_axi_miso[1]),
    .csr_o    (csr_out_int)
  );

  nox u_nox(
    .clk              (clk),
    .arst             (rst_cpu),
    .start_fetch_i    (start_fetch),
    .start_addr_i     ('h8000_0000),
    .instr_axi_mosi_o (masters_axi_mosi[0]),
    .instr_axi_miso_i (masters_axi_miso[0]),
    .lsu_axi_mosi_o   (masters_axi_mosi[1]),
    .lsu_axi_miso_i   (masters_axi_miso[1])
  );
endmodule