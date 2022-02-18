/**
 * File              : nox_synth.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 12.12.2021
 * Last Modified Date: 18.02.2022
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

`ifdef NEXYS_VIDEO_70MHz
  PLLE2_ADV #(
    .BANDWIDTH           ("OPTIMIZED"),
    .COMPENSATION        ("ZHOLD"),
    .STARTUP_WAIT        ("FALSE"),
    .DIVCLK_DIVIDE       (5),
    .CLKFBOUT_MULT       (42),
    .CLKFBOUT_PHASE      (0.000),
    .CLKOUT0_DIVIDE      (12),
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
`endif

`ifdef QMTECH_KINTEX_7_100MHz
  clk_mmcm u_mmcm(
    .clk_out  (clk_out_clk_gen),
    .reset    (rst_clk),
    .locked   (start_fetch),
    .clk_in   (clk_in_clk_gen)
  );
`endif

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
    .MEM_KB(8)
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
    .irq_i            ('0),
    .start_fetch_i    (start_fetch),
    .start_addr_i     ('h8000_0000),
    .instr_axi_mosi_o (masters_axi_mosi[0]),
    .instr_axi_miso_i (masters_axi_miso[0]),
    .lsu_axi_mosi_o   (masters_axi_mosi[1]),
    .lsu_axi_miso_i   (masters_axi_miso[1])
  );

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

module clk_mmcm(
  clk_out,
  reset,
  locked,
  clk_in
);
  output  clk_out;
  input   reset;
  output  locked;
  input   clk_in;

  (* IBUF_LOW_PWR *) wire clk_in;
  wire clk_out;
  wire locked;
  wire reset;

  clk_mmcm_clk_mmcm_clk_wiz
  inst(
    .clk_in(clk_in),
    .clk_out(clk_out),
    .locked(locked),
    .reset(reset)
  );
endmodule

(* ORIG_REF_NAME = "clk_mmcm_clk_wiz" *)
module clk_mmcm_clk_mmcm_clk_wiz(
  clk_out,
  reset,
  locked,
  clk_in
);
  output clk_out;
  input reset;
  output locked;
  input clk_in;

  wire clk_in;
  wire clk_in_clk_mmcm;
  wire clk_out;
  wire clk_out_clk_mmcm;
  wire clkfbout_buf_clk_mmcm;
  wire clkfbout_clk_mmcm;
  wire locked;
  wire reset;
  wire NLW_mmcm_adv_inst_CLKFBOUTB_UNCONNECTED;
  wire NLW_mmcm_adv_inst_CLKFBSTOPPED_UNCONNECTED;
  wire NLW_mmcm_adv_inst_CLKINSTOPPED_UNCONNECTED;
  wire NLW_mmcm_adv_inst_CLKOUT0B_UNCONNECTED;
  wire NLW_mmcm_adv_inst_CLKOUT1_UNCONNECTED;
  wire NLW_mmcm_adv_inst_CLKOUT1B_UNCONNECTED;
  wire NLW_mmcm_adv_inst_CLKOUT2_UNCONNECTED;
  wire NLW_mmcm_adv_inst_CLKOUT2B_UNCONNECTED;
  wire NLW_mmcm_adv_inst_CLKOUT3_UNCONNECTED;
  wire NLW_mmcm_adv_inst_CLKOUT3B_UNCONNECTED;
  wire NLW_mmcm_adv_inst_CLKOUT4_UNCONNECTED;
  wire NLW_mmcm_adv_inst_CLKOUT5_UNCONNECTED;
  wire NLW_mmcm_adv_inst_CLKOUT6_UNCONNECTED;
  wire NLW_mmcm_adv_inst_DRDY_UNCONNECTED;
  wire NLW_mmcm_adv_inst_PSDONE_UNCONNECTED;
  wire [15:0]NLW_mmcm_adv_inst_DO_UNCONNECTED;

  (* BOX_TYPE = "PRIMITIVE" *)
  BUFG clkf_buf
       (.I(clkfbout_clk_mmcm),
        .O(clkfbout_buf_clk_mmcm));
  (* BOX_TYPE = "PRIMITIVE" *)
  (* CAPACITANCE = "DONT_CARE" *)
  (* IBUF_DELAY_VALUE = "0" *)
  (* IFD_DELAY_VALUE = "AUTO" *)
  IBUF #(
    .IOSTANDARD("DEFAULT"))
    clkin1_ibufg
       (.I(clk_in),
        .O(clk_in_clk_mmcm));
  (* BOX_TYPE = "PRIMITIVE" *)
  BUFG clkout1_buf
       (.I(clk_out_clk_mmcm),
        .O(clk_out));
  (* BOX_TYPE = "PRIMITIVE" *)
  MMCME2_ADV #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKFBOUT_MULT_F(20.000000),
    .CLKFBOUT_PHASE(0.000000),
    .CLKFBOUT_USE_FINE_PS("FALSE"),
    .CLKIN1_PERIOD(20.000000),
    .CLKIN2_PERIOD(0.000000),
    .CLKOUT0_DIVIDE_F(10.000000),
    .CLKOUT0_DUTY_CYCLE(0.500000),
    .CLKOUT0_PHASE(0.000000),
    .CLKOUT0_USE_FINE_PS("FALSE"),
    .CLKOUT1_DIVIDE(1),
    .CLKOUT1_DUTY_CYCLE(0.500000),
    .CLKOUT1_PHASE(0.000000),
    .CLKOUT1_USE_FINE_PS("FALSE"),
    .CLKOUT2_DIVIDE(1),
    .CLKOUT2_DUTY_CYCLE(0.500000),
    .CLKOUT2_PHASE(0.000000),
    .CLKOUT2_USE_FINE_PS("FALSE"),
    .CLKOUT3_DIVIDE(1),
    .CLKOUT3_DUTY_CYCLE(0.500000),
    .CLKOUT3_PHASE(0.000000),
    .CLKOUT3_USE_FINE_PS("FALSE"),
    .CLKOUT4_CASCADE("FALSE"),
    .CLKOUT4_DIVIDE(1),
    .CLKOUT4_DUTY_CYCLE(0.500000),
    .CLKOUT4_PHASE(0.000000),
    .CLKOUT4_USE_FINE_PS("FALSE"),
    .CLKOUT5_DIVIDE(1),
    .CLKOUT5_DUTY_CYCLE(0.500000),
    .CLKOUT5_PHASE(0.000000),
    .CLKOUT5_USE_FINE_PS("FALSE"),
    .CLKOUT6_DIVIDE(1),
    .CLKOUT6_DUTY_CYCLE(0.500000),
    .CLKOUT6_PHASE(0.000000),
    .CLKOUT6_USE_FINE_PS("FALSE"),
    .COMPENSATION("ZHOLD"),
    .DIVCLK_DIVIDE(1),
    .IS_CLKINSEL_INVERTED(1'b0),
    .IS_PSEN_INVERTED(1'b0),
    .IS_PSINCDEC_INVERTED(1'b0),
    .IS_PWRDWN_INVERTED(1'b0),
    .IS_RST_INVERTED(1'b0),
    .REF_JITTER1(0.010000),
    .REF_JITTER2(0.010000),
    .SS_EN("FALSE"),
    .SS_MODE("CENTER_HIGH"),
    .SS_MOD_PERIOD(10000),
    .STARTUP_WAIT("FALSE"))
    mmcm_adv_inst
       (.CLKFBIN(clkfbout_buf_clk_mmcm),
        .CLKFBOUT(clkfbout_clk_mmcm),
        .CLKFBOUTB(NLW_mmcm_adv_inst_CLKFBOUTB_UNCONNECTED),
        .CLKFBSTOPPED(NLW_mmcm_adv_inst_CLKFBSTOPPED_UNCONNECTED),
        .CLKIN1(clk_in_clk_mmcm),
        .CLKIN2(1'b0),
        .CLKINSEL(1'b1),
        .CLKINSTOPPED(NLW_mmcm_adv_inst_CLKINSTOPPED_UNCONNECTED),
        .CLKOUT0(clk_out_clk_mmcm),
        .CLKOUT0B(NLW_mmcm_adv_inst_CLKOUT0B_UNCONNECTED),
        .CLKOUT1(NLW_mmcm_adv_inst_CLKOUT1_UNCONNECTED),
        .CLKOUT1B(NLW_mmcm_adv_inst_CLKOUT1B_UNCONNECTED),
        .CLKOUT2(NLW_mmcm_adv_inst_CLKOUT2_UNCONNECTED),
        .CLKOUT2B(NLW_mmcm_adv_inst_CLKOUT2B_UNCONNECTED),
        .CLKOUT3(NLW_mmcm_adv_inst_CLKOUT3_UNCONNECTED),
        .CLKOUT3B(NLW_mmcm_adv_inst_CLKOUT3B_UNCONNECTED),
        .CLKOUT4(NLW_mmcm_adv_inst_CLKOUT4_UNCONNECTED),
        .CLKOUT5(NLW_mmcm_adv_inst_CLKOUT5_UNCONNECTED),
        .CLKOUT6(NLW_mmcm_adv_inst_CLKOUT6_UNCONNECTED),
        .DADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .DCLK(1'b0),
        .DEN(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .DO(NLW_mmcm_adv_inst_DO_UNCONNECTED[15:0]),
        .DRDY(NLW_mmcm_adv_inst_DRDY_UNCONNECTED),
        .DWE(1'b0),
        .LOCKED(locked),
        .PSCLK(1'b0),
        .PSDONE(NLW_mmcm_adv_inst_PSDONE_UNCONNECTED),
        .PSEN(1'b0),
        .PSINCDEC(1'b0),
        .PWRDWN(1'b0),
        .RST(reset));
endmodule
