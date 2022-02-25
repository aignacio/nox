/**
 * File              : nox_soc_ahb.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 12.12.2021
 * Last Modified Date: 25.02.2022
 */
module nox_soc
  import utils_pkg::*;
(
  input               clk_in,
  input               rst_cpu,
  input               rst_clk,
  output  logic [3:0] csr_out
);
  s_ahb_mosi_t  [1:0] masters_ahb_mosi;
  s_ahb_miso_t  [1:0] masters_ahb_miso;

  s_ahb_mosi_t  [3:0] slaves_ahb_mosi;
  s_ahb_miso_t  [3:0] slaves_ahb_miso;

  logic start_fetch;
  logic clk;
  logic rst_int;
  logic [7:0] csr_out_int;

  assign csr_out[3:0] = csr_out_int[3:0];

  /* verilator lint_off PINMISSING */
  nox u_nox (
    .clk              (clk),
    .arst             (rst_int),
    .irq_i            ('0),
    .start_fetch_i    (rst_int),
    .start_addr_i     ('h8000_0000),
    .instr_ahb_mosi_o (masters_ahb_mosi[0]),
    .instr_ahb_miso_i (masters_ahb_miso[0]),
    .lsu_ahb_mosi_o   (masters_ahb_mosi[1]),
    .lsu_ahb_miso_i   (masters_ahb_miso[1])
  );
  /* verilator lint_on PINMISSING */

`ifdef SIMULATION
  // synthesis translate_off
  function automatic void writeWordIRAM(addr_val, word_val);
    /*verilator public*/
    logic [31:0] addr_val;
    logic [31:0] word_val;
    //u_iram.mem_loading[addr_val] = word_val;
  endfunction

  function automatic void writeWordDRAM(addr_val, word_val);
    /*verilator public*/
    logic [31:0] addr_val;
    logic [31:0] word_val;
    //u_dram.mem_loading[addr_val] = word_val;
  endfunction
  // synthesis translate_on
`endif
endmodule
