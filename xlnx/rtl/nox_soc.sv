/**
 * File              : nox_soc.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 12.03.2022
 * Last Modified Date: 26.05.2022
 */

`default_nettype wire

module nox_soc import utils_pkg::*; (
`ifdef KC705_KINTEX_7_100MHz
  input               clk_in_p,
  input               clk_in_n,
`else
  input               clk_in,
`endif
  input               rst_cpu,
  input               rst_clk,
  input               bootloader_i,
  output  logic [7:0] csr_out,
  output  logic       clk_locked_o,
  output  logic       uart_tx_o,
  output  logic       uart_tx_mirror_o,
  output  logic       uart_irq_o,
  input               uart_rx_i,
  output              spi_clk_o,
  output              spi_mosi_o,
  input               spi_miso_i,
  output              spi_csn_o,
  output  logic [9:0] spi_gpio_o
);
  s_axi_mosi_t  [1:0] masters_axi_mosi;
  s_axi_miso_t  [1:0] masters_axi_miso;
  s_axi_mosi_t  [7:0] slaves_axi_mosi;
  s_axi_miso_t  [7:0] slaves_axi_miso;

  logic        clk;
  logic        rst;
  logic        bootloader_int;
  logic        uart_rx_irq;
  logic        start_fetch;
  logic [31:0] core_rst;
  logic        mtimer_irq;

  assign uart_tx_mirror_o = uart_tx_o;
  assign uart_irq_o = uart_rx_irq;

`ifdef SIMULATION
  assign clk = clk_in;
  assign rst = rst_cpu;
  assign csr_out = '0;
  assign start_fetch = '1;
`else

`ifdef KC705_KINTEX_7_100MHz
  assign bootloader_int = ~bootloader_i;
  assign rst = ~rst_cpu;
  assign clk_locked_o = start_fetch;
`endif

`ifdef QMTECH_KINTEX_7_100MHz
  assign bootloader_int = bootloader_i;
  assign rst = rst_cpu;
  assign clk_locked_o = start_fetch;
`endif

`ifdef NEXYS_VIDEO_50MHz
  assign bootloader_int = ~bootloader_i;
  assign rst = ~rst_cpu;
  assign clk_locked_o = start_fetch;
`endif

  clk_mgmt u_clk_mgmt(
`ifdef KC705_KINTEX_7_100MHz
    .clk_in_p   (clk_in_p),
    .clk_in_n   (clk_in_n),
    .rst_in     (rst_clk),
    .clk_out    (clk),
    .clk_locked (start_fetch)
`else
    .clk_in     (clk_in),
    .rst_in     (rst_clk),
    .clk_out    (clk),
    .clk_locked (start_fetch)
`endif
  );
`endif

  axi_interconnect_wrapper #(
    .N_MASTERS      (2),
    .N_SLAVES       (8),
    .M_BASE_ADDR    ({32'hF000_0000,    // MTIMER
                      32'hE000_0000,    // SPI
                      32'hD000_0000,    // GPIO
                      32'hC000_0000,    // RST Ctrl
                      32'hB000_0000,    // UART
                      32'hA000_0000,    // 128KB IMEM
                      32'h1000_0000,    // DRAM - 8KB
                      32'h0000_0000}),  // BOOTROM
    .M_ADDR_WIDTH   ({32'd17,
                      32'd17,
                      32'd17,
                      32'd17,
                      32'd17,
                      32'd17,
                      32'd17,
                      32'd17})
  ) u_axi_intcon (
    .clk              (clk),
    .arst             (rst),
    .*
  );

  nox_wrapper u_nox_wrapper (
    .clk              (clk),
    .rst              (rst),
    .irq_i            ({mtimer_irq,1'b0,uart_rx_irq}),
    .start_fetch_i    (start_fetch),
    .start_addr_i     (core_rst),
    .instr_axi_mosi_o (masters_axi_mosi[0]),
    .instr_axi_miso_i (masters_axi_miso[0]),
    .lsu_axi_mosi_o   (masters_axi_mosi[1]),
    .lsu_axi_miso_i   (masters_axi_miso[1])
  );

  /* verilator lint_off PINMISSING */
  axi_rom_wrapper u_irom_mirror (
    .clk              (clk),
    .rst              (rst),
    .axi_mosi         (slaves_axi_mosi[0]),
    .axi_miso         (slaves_axi_miso[0])
  );

  axi_mem_wrapper #(
    .MEM_KB(32)
  ) u_dram (
    .clk              (clk),
    .rst              (rst),
    .axi_mosi         (slaves_axi_mosi[1]),
    .axi_miso         (slaves_axi_miso[1])
  );

`ifdef SIMULATION
  axi_mem #(
    .MEM_KB(128)
  ) u_imem (
    .clk              (clk),
    .rst              (rst),
    .axi_mosi         (slaves_axi_mosi[2]),
    .axi_miso         (slaves_axi_miso[2])
  );
`else
  axi_mem_wrapper #(
    .MEM_KB(128)
  ) u_imem (
    .clk              (clk),
    .rst              (rst),
    .axi_mosi         (slaves_axi_mosi[2]),
    .axi_miso         (slaves_axi_miso[2])
  );
`endif

  axi_uart_wrapper u_axi_uart (
    .clk              (clk),
    .rst              (rst),
    .axi_mosi         (slaves_axi_mosi[3]),
    .axi_miso         (slaves_axi_miso[3]),
    .uart_tx_o        (uart_tx_o),
    .uart_rx_i        (uart_rx_i),
    .uart_rx_irq_o    (uart_rx_irq)
  );

  rst_ctrl u_rst_ctrl(
    .clk              (clk),
    .rst              (bootloader_int),
    .axi_mosi         (slaves_axi_mosi[4]),
    .axi_miso         (slaves_axi_miso[4]),
    .rst_addr_o       (core_rst)
  );

  axi_gpio u_axi_gpio (
    .clk              (clk),
    .rst              (rst),
    .axi_mosi         (slaves_axi_mosi[5]),
    .axi_miso         (slaves_axi_miso[5]),
    .csr_o            (csr_out)
  );

  axi_spi_master #(
    .BASE_ADDR('hE000_0000)
  ) u_axi_spi_master (
    .clk              (clk),
    .arst             (~rst),
    .axi_mosi         (slaves_axi_mosi[6]),
    .axi_miso         (slaves_axi_miso[6]),
    .sck_o            (spi_clk_o),
    .mosi_o           (spi_mosi_o),
    .miso_i           (spi_miso_i),
    .cs_n_o           (spi_csn_o),
    .spi_out_o        (spi_gpio_o)
  );

  axi_mtimer u_axi_mtimer (
    .clk              (clk),
    .rst              (rst),
    .axi_mosi         (slaves_axi_mosi[7]),
    .axi_miso         (slaves_axi_miso[7]),
    .mtimer_irq_o     (mtimer_irq)
  );
  /* verilator lint_on PINMISSING */

  //ila_0 u_ila_aignacio (
    //.clk(clk),
    //.probe0 (masters_axi_mosi[0].arvalid),                             // 1
    //.probe1 (masters_axi_mosi[0].araddr),                              // 32
    //.probe2 (masters_axi_miso[0].rvalid),                              // 1
    //.probe3 (masters_axi_miso[0].rdata),                               // 32
    //.probe4 (u_nox_wrapper.irq_i[0]),                                  // 1
    //.probe5 (u_nox_wrapper.irq_i[1]),                                  // 1
    //.probe6 (u_nox_wrapper.irq_i[2])                                   // 1
  //);

  //ila_0 u_ila_aignacio (
    //.clk(clk),
    //.probe0 (slaves_axi_mosi[0].arvalid),                              // 1
    //.probe1 (slaves_axi_mosi[0].araddr),                               // 32
    //.probe2 (slaves_axi_miso[0].rvalid),                               // 1
    //.probe3 (slaves_axi_miso[0].rdata),                                // 32
    //.probe4 (u_nox_wrapper.u_nox.u_execute.u_csr.ecall_i),             // 1
    //.probe5 (u_nox_wrapper.u_nox.u_execute.u_csr.ebreak_i),            // 1
    //.probe6 (u_nox_wrapper.u_nox.u_execute.u_csr.mret_i),              // 1
    //.probe7 (u_nox_wrapper.u_nox.u_execute.u_csr.fetch_trap_i.active), // 1
    //.probe8 (u_nox_wrapper.u_nox.u_execute.u_csr.dec_trap_i.active),   // 1
    //.probe9 (u_nox_wrapper.u_nox.u_execute.u_csr.fetch_trap_i.active), // 1
    //.probe10(u_nox_wrapper.u_nox.u_fetch.pc_addr_ff),                  // 32
    //.probe11(u_nox_wrapper.u_nox.u_fetch.fetch_req_i),                 // 1
    //.probe12(u_nox_wrapper.u_nox.u_fetch.fetch_addr_i),                // 32
    //.probe13(u_nox_wrapper.u_nox.u_execute.u_csr.trap_ff.active)       // 1
  //);

  // synthesis translate_off
  function automatic void writeWordIRAM(addr_val, word_val);
    /*verilator public*/
    logic [31:0] addr_val;
    logic [31:0] word_val;
    u_imem.mem_loading[addr_val] = word_val;
    //u_iram_mirror.mem_loading[addr_val] = word_val;
  endfunction

  function automatic void writeWordDRAM(addr_val, word_val);
    /*verilator public*/
    logic [31:0] addr_val;
    logic [31:0] word_val;
    //u_dram.mem_loading[addr_val] = word_val;
  endfunction

  function automatic void writeRstAddr(rst_addr);
    /*verilator public*/
    logic [31:0] rst_addr;
    u_rst_ctrl.rst_loading = rst_addr;
  endfunction
  // synthesis translate_on
endmodule
