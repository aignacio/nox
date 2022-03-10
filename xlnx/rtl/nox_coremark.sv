/**
 * File              : nox_coremark.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 12.12.2021
 * Last Modified Date: 10.03.2022
 */

`default_nettype wire

module nox_coremark
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

  s_axi_mosi_t  [2:0] slaves_axi_mosi;
  s_axi_miso_t  [2:0] slaves_axi_miso;

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

`ifdef SIMULATION
  assign rst_int = rst_cpu;
  assign clk = clk_in;
  assign start_fetch = 'b1;
  assign uart_tx_mirror_o = uart_tx_o;
`endif

  assign slaves_axi_mosi[0]  = masters_axi_mosi[0];
  assign masters_axi_miso[0] = slaves_axi_miso[0];

  s_irq_t irq_stim;

  /* verilator lint_off PINMISSING */
  typedef enum logic [1:0] {
    IDLE,
    IRAM_MIRROR,
    DRAM
  } mux_axi_t;

  mux_axi_t switch_ff, next_switch;
  logic slave_1_sel;
  logic slave_2_sel;

  // This mux is only used for the printf to work =)
  always_comb begin : axi_mux
    masters_axi_miso[1] = s_axi_miso_t'('0);
    slaves_axi_mosi[1]  = s_axi_mosi_t'('0);
    slaves_axi_mosi[2]  = s_axi_mosi_t'('0);

    slave_2_sel = (masters_axi_mosi[1].arvalid &&
                  (masters_axi_mosi[1].araddr[31:16] == 'h8000));
    slave_1_sel = ~slave_2_sel;

    next_switch = slave_2_sel ? IRAM_MIRROR : DRAM;

    if (switch_ff == IRAM_MIRROR) begin
      masters_axi_miso[1].rid    = slaves_axi_miso[2].rid;
      masters_axi_miso[1].rdata  = slaves_axi_miso[2].rdata;
      masters_axi_miso[1].rresp  = slaves_axi_miso[2].rresp;
      masters_axi_miso[1].rlast  = slaves_axi_miso[2].rlast;
      masters_axi_miso[1].ruser  = slaves_axi_miso[2].ruser;
      masters_axi_miso[1].rvalid = slaves_axi_miso[2].rvalid;

      masters_axi_miso[1].awready = slaves_axi_miso[1].awready;
      masters_axi_miso[1].wready = slaves_axi_miso[1].wready;
      masters_axi_miso[1].arready = slaves_axi_miso[1].arready;
    end

    if (switch_ff == DRAM) begin
      masters_axi_miso[1] = slaves_axi_miso[1];
    end

    // Write channel can be always connected to the DRAM
    slaves_axi_mosi[1].wdata   = masters_axi_mosi[1].wdata;
    slaves_axi_mosi[1].wvalid  = masters_axi_mosi[1].wvalid;
    slaves_axi_mosi[1].wstrb   = masters_axi_mosi[1].wstrb;
    slaves_axi_mosi[1].wlast   = masters_axi_mosi[1].wlast;
    slaves_axi_mosi[1].wuser   = masters_axi_mosi[1].wuser;
    slaves_axi_mosi[1].bready  = masters_axi_mosi[1].bready;
    masters_axi_miso[1].bvalid = slaves_axi_miso[1].bvalid;
    masters_axi_miso[1].bresp  = slaves_axi_miso[1].bresp;

    if (slave_2_sel)
      slaves_axi_mosi[2]  = masters_axi_mosi[1];
    else
      slaves_axi_mosi[1]  = masters_axi_mosi[1];
  end

  always_ff @ (posedge clk) begin
    if (~rst_int) begin
      switch_ff <= IDLE;
    end
    else begin
      switch_ff <= next_switch;
    end
  end

`ifdef SIMULATION
  axi_mem #(
    .MEM_KB(`IRAM_KB_SIZE)
  ) u_iram_mirror (
    .clk      (clk),
    .rst      (rst_int),
    .axi_mosi (slaves_axi_mosi[2]),
    .axi_miso (slaves_axi_miso[2])
  );
`else
  axi_rom_wrapper u_irom_mirror(
    .clk              (clk),
    .rst              (rst_int),
    .axi_mosi         (slaves_axi_mosi[2]),
    .axi_miso         (slaves_axi_miso[2])
  );
`endif

`ifdef SIMULATION
  axi_mem #(
    .MEM_KB(`IRAM_KB_SIZE)
  ) u_iram (
    .clk      (clk),
    .rst      (rst_int),
    .axi_mosi (slaves_axi_mosi[0]),
    .axi_miso (slaves_axi_miso[0])
  );
`else
  axi_rom_wrapper u_irom(
    .clk              (clk),
    .rst              (rst_int),
    .axi_mosi         (slaves_axi_mosi[0]),
    .axi_miso         (slaves_axi_miso[0])
  );
`endif

  axi_mem_wrapper #(
    .MEM_KB(8)
  ) u_dram (
    .clk      (clk),
    .rst      (rst_int),
    .axi_mosi (slaves_axi_mosi[1]),
    .axi_miso (slaves_axi_miso[1]),
    .uart_tx_o(uart_tx_o),
    .csr_o    (csr_out_int)
  );
  /* verilator lint_on PINMISSING */

  nox u_nox(
    .clk              (clk),
    .arst             (rst_int),
    .start_fetch_i    (start_fetch),
    .start_addr_i     ('h8000_0000),
    .irq_i            ('0),
    .instr_axi_mosi_o (masters_axi_mosi[0]),
    .instr_axi_miso_i (masters_axi_miso[0]),
    .lsu_axi_mosi_o   (masters_axi_mosi[1]),
    .lsu_axi_miso_i   (masters_axi_miso[1])
  );

  // synthesis translate_off
  function automatic void writeWordIRAM(addr_val, word_val);
    /*verilator public*/
    logic [31:0] addr_val;
    logic [31:0] word_val;
    //u_iram.mem_loading[addr_val]        = word_val;
    //u_iram_mirror.mem_loading[addr_val] = word_val;
  endfunction

  function automatic void writeWordDRAM(addr_val, word_val);
    /*verilator public*/
    logic [31:0] addr_val;
    logic [31:0] word_val;
    u_dram.mem_loading[addr_val] = word_val;
  endfunction
  // synthesis translate_on
endmodule


