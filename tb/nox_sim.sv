/**
 * File              : nox_sim.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 12.12.2021
 * Last Modified Date: 19.02.2022
 */
module nox_sim import utils_pkg::*; (
  input               clk,
  input               rst
);
  s_axi_mosi_t  [1:0] masters_axi_mosi;
  s_axi_miso_t  [1:0] masters_axi_miso;

  s_axi_mosi_t  [1:0] slaves_axi_mosi;
  s_axi_miso_t  [1:0] slaves_axi_miso;

  assign slaves_axi_mosi[0]  = masters_axi_mosi[0];
  assign slaves_axi_mosi[1]  = masters_axi_mosi[1];
  assign masters_axi_miso[0] = slaves_axi_miso[0];
  assign masters_axi_miso[1] = slaves_axi_miso[1];

  s_irq_t irq_stim;

  /* verilator lint_off PINMISSING */
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
  /* verilator lint_on PINMISSING */

  nox u_nox(
    .clk              (clk),
    .arst             (rst),
    .start_fetch_i    ('b1),
    .start_addr_i     (`ENTRY_ADDR),
    .irq_i            (irq_stim),
    .instr_axi_mosi_o (masters_axi_mosi[0]),
    .instr_axi_miso_i (masters_axi_miso[0]),
    .lsu_axi_mosi_o   (masters_axi_mosi[1]),
    .lsu_axi_miso_i   (masters_axi_miso[1])
  );

  irq_stim u_irq_stim(
    .clk    (clk),
    .rst    (rst),
    .irq_o  (irq_stim)
  );

  // synthesis translate_off
  function automatic void writeWordIRAM(addr_val, word_val);
    /*verilator public*/
    logic [31:0] addr_val;
    logic [31:0] word_val;
    u_iram.mem_loading[addr_val] = word_val;
  endfunction

  function automatic void writeWordDRAM(addr_val, word_val);
    /*verilator public*/
    logic [31:0] addr_val;
    logic [31:0] word_val;
    u_dram.mem_loading[addr_val] = word_val;
  endfunction
  // synthesis translate_on
endmodule

module irq_stim(
  input           clk,
  input           rst,
  output s_irq_t  irq_o
);
  logic [7:0] msoft_cnt_ff, next_msoft;
  logic [7:0] mtime_cnt_ff, next_mtime;
  logic [7:0] mext_cnt_ff, next_mext;

  always_comb begin
    next_msoft =  msoft_cnt_ff+'d1; //msoft_cnt_ff[5] ? '0 : msoft_cnt_ff+'d1;
    next_mtime =  mtime_cnt_ff+'d1; //mtime_cnt_ff[6] ? '0 : mtime_cnt_ff+'d1;
    next_mext  =  mext_cnt_ff+'d1;  //mext_cnt_ff[7]  ? '0 : mext_cnt_ff+'d1;

    irq_o.sw_irq    = msoft_cnt_ff[5];
    irq_o.timer_irq = mtime_cnt_ff[6];
    irq_o.ext_irq   = mext_cnt_ff[7];
  end

  always_ff @ (posedge clk) begin
    if (~rst) begin
      msoft_cnt_ff <= '0;
      mtime_cnt_ff <= '0;
      mext_cnt_ff  <= '0;
    end
    else begin
      msoft_cnt_ff <= next_msoft;
      mtime_cnt_ff <= next_mtime;
      mext_cnt_ff  <= next_mext;
    end
  end
endmodule
