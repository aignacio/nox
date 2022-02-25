/**
 * File              : ahb_interconnect_wrapper.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 25.02.2022
 * Last Modified Date: 25.02.2022
 */
module ahb_interconnect_wrapper
  import utils_pkg::*;
#(
  parameter N_MASTERS     = 1,
  parameter N_SLAVES      = 1,
  parameter M_BASE_ADDR   = 0,
  parameter M_ADDR_WIDTH  = 0
)(
  input                                 clk,
  input                                 arst,
  // From Master I/Fs
  input   s_axi_mosi_t  [N_MASTERS-1:0] masters_ahb_mosi,
  output  s_axi_miso_t  [N_MASTERS-1:0] masters_ahb_miso,
  // To Slave I/Fs
  output  s_axi_mosi_t  [N_SLAVES-1:0]  slaves_ahb_mosi,
  input   s_axi_miso_t  [N_SLAVES-1:0]  slaves_ahb_miso
);
  amba_ahb_m2s4 #(
    .P_NUMM(2), // num of masters
    .P_NUMS(4), // num of slaves
    .P_HSEL0_START(32'h00000000),
    .P_HSEL0_SIZE (32'h00010000),
    .P_HSEL1_START(32'h10000000),
    .P_HSEL1_SIZE (32'h00010000),
    .P_HSEL2_START(32'h20000000),
    .P_HSEL2_SIZE (32'h00010000),
    .P_HSEL3_START(32'h30000000),
    .P_HSEL3_SIZE (32'h00010000)
  ) u_amba_ahb_m2s4 (
    .HRESETn      (),
    .HCLK         (),
    .M0_HBUSREQ   (),
    .M0_HGRANT    (),
    .M0_HADDR     (),
    .M0_HTRANS    (),
    .M0_HSIZE     (),
    .M0_HBURST    (),
    .M0_HPROT     (),
    .M0_HLOCK     (),
    .M0_HWRITE    (),
    .M0_HWDATA    (),
    .M1_HBUSREQ   (),
    .M1_HGRANT    (),
    .M1_HADDR     (),
    .M1_HTRANS    (),
    .M1_HSIZE     (),
    .M1_HBURST    (),
    .M1_HPROT     (),
    .M1_HLOCK     (),
    .M1_HWRITE    (),
    .M1_HWDATA    (),
    .M_HRDATA     (),
    .M_HRESP      (),
    .M_HREADY     (),
    .S_HADDR      (),
    .S_HWRITE     (),
    .S_HTRANS     (),
    .S_HSIZE      (),
    .S_HBURST     (),
    .S_HWDATA     (),
    .S_HPROT      (),
    .S_HREADY     (),
    .S_HMASTER    (),
    .S_HMASTLOCK  (),
    .S0_HSEL      (),
    .S0_HREADY    (),
    .S0_HRESP     (),
    .S0_HRDATA    (),
    .S0_HSPLIT    (),
    .S1_HSEL      (),
    .S1_HREADY    (),
    .S1_HRESP     (),
    .S1_HRDATA    (),
    .S1_HSPLIT    (),
    .S2_HSEL      (),
    .S2_HREADY    (),
    .S2_HRESP     (),
    .S2_HRDATA    (),
    .S2_HSPLIT    (),
    .S3_HSEL      (),
    .S3_HREADY    (),
    .S3_HRESP     (),
    .S3_HRDATA    (),
    .S3_HSPLIT    (),
    .REMAP        ()
  );
endmodule
