/**
 * File              : clk_mgmt.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 17.03.2022
 * Last Modified Date: 08.04.2022
 */

`default_nettype wire

module clk_mgmt(
  input   clk_in,
  input   rst_in,
  output  clk_out,
  output  clk_locked
);

`ifdef ARTY_A7_50MHz
  `define NEXYS_VIDEO_50MHz
`endif

`ifdef NEXYS_VIDEO_50MHz
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
    .LOCKED              (clk_locked),
    .PWRDWN              (1'b0),
    .RST                 (rst_in)
  );

  IBUF clkin1_ibufg(
    .O (clk_in_clk_wiz_2),
    .I (clk_in)
  );

  BUFG clkf_buf(
    .O (clkfbout_buf_clk_wiz_2),
    .I (clkfbout_clk_wiz_2)
  );

  BUFG clkout1_buf(
    .O (clk_out),
    .I (clk_out_clk_wiz_2)
  );

`endif

`ifdef QMTECH_KINTEX_7_100MHz
  logic        clkfbout_clk_wiz_2;
  logic        clkfbout_buf_clk_wiz_2;
  logic        clk_out_clk_wiz_2;

  PLLE2_ADV#(
    .BANDWIDTH            ("OPTIMIZED"),
    .COMPENSATION         ("ZHOLD"),
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (1),
    .CLKFBOUT_MULT        (18),
    .CLKFBOUT_PHASE       (0.000),
    .CLKOUT0_DIVIDE       (9),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKIN1_PERIOD        (20.000)
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
    .LOCKED              (clk_locked),
    .PWRDWN              (1'b0),
    .RST                 ('b0)
    //.RST                 (rst_in)
  );

  IBUF clkin1_ibufg(
    .O (clk_in_clk_wiz_2),
    .I (clk_in)
  );

  BUFG clkf_buf(
    .O (clkfbout_buf_clk_wiz_2),
    .I (clkfbout_clk_wiz_2)
  );

  BUFG clkout1_buf(
    .O (clk_out),
    .I (clk_out_clk_wiz_2)
  );
`endif

`ifdef DE10_LITE_50MHz
  assign clk_out = clk_in;
  assign clk_locked = 'b1;
`endif

endmodule
