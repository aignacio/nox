/**
 * File              : nox_sim.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 12.12.2021
 * Last Modified Date: 12.12.2021
 */
module nox_sim import utils_pkg::*; (
  input   clk,
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

  axi_mem #(
    .MEM_KB(`IRAM_KB_SIZE)
  ) u_iram (
    .clk      (clk),
    .rst      (rst),
    .axi_mosi (slaves_axi_mosi[0]),
    .axi_miso (slaves_axi_miso[0])
  );

  axi_mem #(
    .MEM_KB(`DRAM_KB_SIZE)
  ) u_dram (
    .clk      (clk),
    .rst      (rst),
    .axi_mosi (slaves_axi_mosi[1]),
    .axi_miso (slaves_axi_miso[1])
  );

  nox u_nox(
    .clk              (clk),
    .arst             (rst),
    .start_fetch_i    ('b1),
    .start_addr_i     ('h8000_0000),
    .instr_axi_mosi_o (masters_axi_mosi[0]),
    .instr_axi_miso_i (masters_axi_miso[0]),
    .lsu_axi_mosi_o   (masters_axi_mosi[1]),
    .lsu_axi_miso_i   (masters_axi_miso[1])
  );

  // synthesis translate_off
  //axi_printf_verilator u_axi_verilator (
    //.clk      (clk),
    //.arst     (arst),
    //.axi_mosi (slaves_axi_mosi[2]),
    //.axi_miso (slaves_axi_miso[2])
  //);

  //function automatic void writeWordIRAM(addr_val, word_val);
    //[> verilator public <]
    //logic [31:0] addr_val;
    //logic [31:0] word_val;
    //u_ram_instr_rv.u_ram.mem[addr_val] = word_val;
  //endfunction

  //function automatic void writeWordDRAM(addr_val, word_val);
    //[> verilator public <]
    //logic [31:0] addr_val;
    //logic [31:0] word_val;
    ////u_ram_rv.u_ram.mem[addr_val] = word_val;
  //endfunction

  //function automatic void writeRstAddr(boot_addr);
    //[> verilator public <]
    //logic [31:0] boot_addr;
    //boot_ff = boot_addr;
  //endfunction
  // synthesis translate_on
endmodule

