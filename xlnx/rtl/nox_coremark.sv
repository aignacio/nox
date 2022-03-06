/**
 * File              : nox_coremark.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 12.12.2021
 * Last Modified Date: 06.03.2022
 */

`default_nettype wire

module nox_coremark
  import utils_pkg::*;
(
  input               clk,
  input               rst
);
  s_axi_mosi_t  [1:0] masters_axi_mosi;
  s_axi_miso_t  [1:0] masters_axi_miso;

  s_axi_mosi_t  [3:0] slaves_axi_mosi;
  s_axi_miso_t  [3:0] slaves_axi_miso;

  logic start_fetch;
  logic clk_int;
  logic rst_int;
  logic [7:0] csr_out_int;

  assign csr_out[3:0] = csr_out_int[3:0];
  assign slaves_axi_mosi[0]  = masters_axi_mosi[0];
  assign masters_axi_miso[0] = slaves_axi_miso[0];

`ifdef ARTY_A7_70MHz
  `define NEXYS_VIDEO_70MHz
`endif

`ifdef NEXYS_VIDEO_70MHz
  assign rst_int = ~rst;
  assign uart_tx_mirror_o = uart_tx_o;

  logic  clkfbout_clk_wiz_2;
  logic  clkfbout_buf_clk_wiz_2;
  logic  clk_out_clk_wiz_2;

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
    .RST                 (rst));

  IBUF clkin1_ibufg(
    .O (clk_in_clk_wiz_2),
    .I (clk)
  );

  BUFG clkf_buf(
    .O (clkfbout_buf_clk_wiz_2),
    .I (clkfbout_clk_wiz_2)
  );

  BUFG clkout1_buf(
    .O   (clk_int),
    .I   (clk_out_clk_wiz_2)
  );
`else
  assign start_fetch = 'b1;
  assign rst_int = rst;
`endif

  nox u_nox (
    .clk              (clk_int),
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
    .clk              (clk_int),
    .rst              (rst_int),
    .axi_mosi         (slaves_axi_mosi[1]),
    .axi_miso         (slaves_axi_miso[1]),
    .csr_o            ()
  );

`ifndef SIMULATION
  axi_rom_wrapper u_irom(
    .clk              (clk_int),
    .rst              (rst_int),
    .axi_mosi         (slaves_axi_mosi[0]),
    .axi_miso         (slaves_axi_miso[0])
  );

  axi_rom_wrapper u_irom_mirror(
    .clk              (clk_int),
    .rst              (rst_int),
    .axi_mosi         (slaves_axi_mosi[2]),
    .axi_miso         (slaves_axi_miso[2])
  );
`else
  axi_mem #(
    .MEM_KB(`IRAM_KB_SIZE)
  ) u_iram (
    .clk              (clk_int),
    .rst              (rst_int),
    .axi_mosi         (slaves_axi_mosi[0]),
    .axi_miso         (slaves_axi_miso[0])
  );

  axi_mem #(
    .MEM_KB(`IRAM_KB_SIZE)
  ) u_iram_mirror (
    .clk              (clk_int),
    .rst              (rst_int),
    .axi_mosi         (slaves_axi_mosi[2]),
    .axi_miso         (slaves_axi_miso[2])
  );
`endif

  axi_uart_wrapper u_axi_uart (
    .clk              (clk_int),
    .rst              (rst_int),
    .axi_mosi         (slaves_axi_mosi[3]),
    .axi_miso         (slaves_axi_miso[3]),
    .uart_tx_o        (uart_tx_o),
    .uart_rx_i        ('1)
  );

  typedef enum logic [2:0] {
    IDLE,
    IRAM_MIRROR,
    UART,
    DRAM
  } mux_axi_t;

  mux_axi_t switch_ff, next_switch;

  logic slave_1_sel;
  logic slave_2_sel;
  logic slave_3_sel;

  // This mux is only used for the printf to work =)
  always_comb begin : axi_mux
    masters_axi_miso[1] = s_axi_miso_t'('0);
    slaves_axi_mosi[1]  = s_axi_mosi_t'('0);
    slaves_axi_mosi[2]  = s_axi_mosi_t'('0);
    slaves_axi_mosi[3]  = s_axi_mosi_t'('0);

    slave_1_sel = ~slave_2_sel && ~slave_3_sel;
    slave_2_sel = (masters_axi_mosi[1].arvalid &&
                  (masters_axi_mosi[1].araddr[31:16] == 'h8000));
    slave_3_sel = (masters_axi_mosi[1].arvalid &&
                  (masters_axi_mosi[1].araddr[31:16] == 'hB000));

    case ({slave_3_sel,slave_2_sel,slave_1_sel})
      'b001:  begin
        next_switch = DRAM;
        slaves_axi_mosi[1]  = masters_axi_mosi[1];
      end
      'b010:  begin
        next_switch = IRAM_MIRROR;
        slaves_axi_mosi[2]  = masters_axi_mosi[1];
      end
      'b100:  begin
        next_switch = UART;
        slaves_axi_mosi[3]  = masters_axi_mosi[1];
      end
      default: begin
        next_switch = DRAM;
        slaves_axi_mosi[1]  = masters_axi_mosi[1];
      end
    endcase

    case (switch_ff)
      UART: begin
        masters_axi_miso[1] = slaves_axi_miso[3];

        slaves_axi_mosi[3].wdata   = masters_axi_mosi[1].wdata;
        slaves_axi_mosi[3].wvalid  = masters_axi_mosi[1].wvalid;
        slaves_axi_mosi[3].wstrb   = masters_axi_mosi[1].wstrb;
        slaves_axi_mosi[3].wlast   = masters_axi_mosi[1].wlast;
        slaves_axi_mosi[3].wuser   = masters_axi_mosi[1].wuser;
        slaves_axi_mosi[3].bready  = masters_axi_mosi[1].bready;
      end
      IRAM_MIRROR:  begin
        masters_axi_miso[1] = slaves_axi_miso[2];
      end
      DRAM: begin
        masters_axi_miso[1] = slaves_axi_miso[1];

        slaves_axi_mosi[1].wdata   = masters_axi_mosi[1].wdata;
        slaves_axi_mosi[1].wvalid  = masters_axi_mosi[1].wvalid;
        slaves_axi_mosi[1].wstrb   = masters_axi_mosi[1].wstrb;
        slaves_axi_mosi[1].wlast   = masters_axi_mosi[1].wlast;
        slaves_axi_mosi[1].wuser   = masters_axi_mosi[1].wuser;
        slaves_axi_mosi[1].bready  = masters_axi_mosi[1].bready;
      end
      default: begin
        masters_axi_miso[1] = slaves_axi_miso[1];
        slaves_axi_mosi[1]  = masters_axi_mosi[1];
      end
    endcase
  end

  always_ff @ (posedge clk_int) begin
    if (~rst_int) begin
      switch_ff <= IDLE;
    end
    else begin
      switch_ff <= next_switch;
    end
  end
endmodule
