/**
 * File              : nox_soc.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 12.12.2021
 * Last Modified Date: 06.03.2022
 */

`default_nettype wire

module nox_soc
  import utils_pkg::*;
(
  input               clk_in,
  input               rst_cpu,
  input               rst_clk,
  output  logic [3:0] csr_out,
  output  logic       uart_tx_o,
  output  logic       uart_tx_mirror_o
);
  s_axi_mosi_t  [1:0] masters_axi_mosi;
  s_axi_miso_t  [1:0] masters_axi_miso;

  s_axi_mosi_t  [3:0] slaves_axi_mosi;
  s_axi_miso_t  [3:0] slaves_axi_miso;

  logic start_fetch;
  logic clk;
  logic rst_int;
  logic [7:0] csr_out_int;

  assign csr_out[3:0] = csr_out_int[3:0];

`ifdef ARTY_A7_70MHz
  `define NEXYS_VIDEO_70MHz
`endif

`ifdef NEXYS_VIDEO_70MHz
  assign rst_int = ~rst_cpu;
  assign uart_tx_mirror_o = uart_tx_o;

  logic        clkfbout_clk_wiz_2;
  logic        clkfbout_buf_clk_wiz_2;
  logic        clk_out_clk_wiz_2;

  PLLE2_ADV#(
    .BANDWIDTH            ("OPTIMIZED"),
    .COMPENSATION         ("ZHOLD"),
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (2),
    .CLKFBOUT_MULT        (17),
    .CLKFBOUT_PHASE       (0.000),
    .CLKOUT0_DIVIDE       (17),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKIN1_PERIOD        (10.000)
  ) plle2_adv_inst (
    .CLKFBOUT            (clkfbout_clk_wiz_2),
    .CLKOUT0             (clk_out_clk_wiz_2),
    .CLKOUT1             (),
    .CLKOUT2             (),
    .CLKOUT3             (),
    .CLKOUT4             (),
    .CLKOUT5             (),
     // Input clock control
    .CLKFBIN             (clkfbout_buf_clk_wiz_2),
    .CLKIN1              (clk_in_clk_wiz_2),
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
    .RST                 (rst_clk));

  IBUF clkin1_ibufg(
    .O (clk_in_clk_wiz_2),
    .I (clk_in)
  );

  BUFG clkf_buf(
    .O (clkfbout_buf_clk_wiz_2),
    .I (clkfbout_clk_wiz_2)
  );

  BUFG clkout1_buf(
    .O   (clk),
    .I   (clk_out_clk_wiz_2)
  );

`endif

`ifdef QMTECH_KINTEX_7_100MHz
  assign rst_int = rst_cpu;
  //clk_mmcm u_mmcm(
    //.clk_out  (clk_out_clk_gen),
    //.reset    (rst_clk),
    //.locked   (start_fetch),
    //.clk_in   (clk_in_clk_gen)
  //);
`endif

`ifdef SIMULATION
  assign rst_int = rst_cpu;
  assign clk = clk_in;
  assign start_fetch = 'b1;
`endif

  nox u_nox (
    .clk              (clk),
    .arst             (rst_int),
    .irq_i            ('0),
    .start_fetch_i    (start_fetch),
    .start_addr_i     ('h8000_0000),
    .instr_axi_mosi_o (masters_axi_mosi[0]),
    .instr_axi_miso_i (masters_axi_miso[0]),
    .lsu_axi_mosi_o   (masters_axi_mosi[1]),
    .lsu_axi_miso_i   (masters_axi_miso[1])
  );

  axi_mem_wrapper #(
    .MEM_KB           (8)
  ) u_dram (
    .clk              (clk),
    .rst              (rst_int),
    .axi_mosi         (slaves_axi_mosi[0]),
    .axi_miso         (slaves_axi_miso[0]),
    .csr_o            ()
  );

`ifdef SIMULATION
  axi_mem #(
    .MEM_KB           (16)
  ) u_iram (
    .clk              (clk),
    .rst              (rst_int),
    .axi_mosi         (slaves_axi_mosi[1]),
    .axi_miso         (slaves_axi_miso[1]),
    .csr_o            ()
  );
`else
  axi_rom_wrapper u_irom(
    .clk              (clk),
    .rst              (rst_int),
    .axi_mosi         (slaves_axi_mosi[1]),
    .axi_miso         (slaves_axi_miso[1])
  );
`endif

  axi_mem_wrapper #(
    .MEM_KB           (1)
  ) u_slave_1_mem (
    .clk              (clk),
    .rst              (rst_int),
    .axi_mosi         (slaves_axi_mosi[2]),
    .axi_miso         (slaves_axi_miso[2]),
    .csr_o            (csr_out_int)
  );

  axi_interconnect_wrapper #(
    .N_MASTERS        (2),
    .N_SLAVES         (4),
    .M_BASE_ADDR      ({32'hB000_0000, 32'hA000_0000, 32'h8000_0000, 32'h1000_0000}),
    .M_ADDR_WIDTH     ({32'd17, 32'd17, 32'd17, 32'd17})
  ) u_axi_intcon (
    .clk              (clk),
    .arst             (rst_int),
    .*
  );

  axi_uart_wrapper u_axi_uart (
    .clk              (clk),
    .rst              (rst_int),
    .axi_mosi         (slaves_axi_mosi[3]),
    .axi_miso         (slaves_axi_miso[3]),
    .uart_tx_o        (uart_tx_o),
    .uart_rx_i        ('1)
  );

`ifdef SIMULATION
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
    //u_dram.mem_loading[addr_val] = word_val;
  endfunction
  // synthesis translate_on
`endif

  //ila_nox u_ila (
    //.clk(clk),
    //.probe0(slaves_axi_mosi[0].arvalid),                // 1
    //.probe1(slaves_axi_mosi[0].araddr),                 // 32
    //.probe2(slaves_axi_miso[0].rvalid),                 // 1
    //.probe3(slaves_axi_miso[0].rdata),                  // 32
    //.probe4(u_nox.u_execute.u_csr.ecall_i),             // 1
    //.probe5(u_nox.u_execute.u_csr.ebreak_i),            // 1
    //.probe6(u_nox.u_execute.u_csr.mret_i),              // 1
    //.probe7(u_nox.u_execute.u_csr.fetch_trap_i.active), // 1
    //.probe8(u_nox.u_execute.u_csr.dec_trap_i.active),   // 1
    //.probe9(u_nox.u_execute.u_csr.fetch_trap_i.active), // 1
    //.probe10(u_nox.u_execute.u_csr.csr_mcause_ff),      // 32
    //.probe11(u_nox.u_fetch.fetch_req_i),                // 1
    //.probe12(u_nox.u_fetch.fetch_addr_i),               // 32
    //.probe13(u_nox.u_execute.u_csr.trap_ff.active)      // 1
  //);
endmodule
