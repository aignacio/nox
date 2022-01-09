/**
 * File              : nox_synth.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 12.12.2021
 * Last Modified Date: 09.01.2022
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

  clock_gen u_clk_gen(
    // Clock out ports
    .clk_out (clk),
    // Status and control signals
    .reset   (rst),
    .locked  (start_fetch),
    // Clock in ports
    .clk_in  (clk_in)
  );

  axi_mem #(
    .MEM_KB(128)
  ) u_iram (
    .clk      (clk),
    .rst      (rst),
    .axi_mosi (slaves_axi_mosi[0]),
    .axi_miso (slaves_axi_miso[0])
  );

  axi_mem #(
    .MEM_KB(128)
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

