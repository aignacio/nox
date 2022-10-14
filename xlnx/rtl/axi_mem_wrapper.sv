module axi_mem_wrapper
  import amba_axi_pkg::*;
  import amba_ahb_pkg::*;
  import nox_utils_pkg::*;
#(
  parameter MEM_KB   = 4,
  parameter ID_WIDTH = 8
)(
  input                 clk,
  input                 rst,
  input   s_axi_mosi_t  axi_mosi,
  output  s_axi_miso_t  axi_miso
);
  s_axi_mosi_t  axi_mosi_int;
  s_axi_miso_t  axi_miso_int;

  localparam ADDR_RAM = $clog2(MEM_KB*1024);

  /* verilator lint_off WIDTH */
  always_comb begin
    axi_miso = axi_miso_int;
    axi_mosi_int = axi_mosi;
  end

  axi_ram #(
    // Width of data bus in bits
    .DATA_WIDTH(32),
    // Width of address bus in bits
    .ADDR_WIDTH(ADDR_RAM),
    // Width of ID signal
    .ID_WIDTH(ID_WIDTH),
    // Extra pipeline register on output
    .PIPELINE_OUTPUT(0)
  ) u_ram (
    .clk          (clk),
    .rst          (~rst),
    .s_axi_awid   (axi_mosi_int.awid),
    .s_axi_awaddr (axi_mosi_int.awaddr),
    .s_axi_awlen  (axi_mosi_int.awlen),
    .s_axi_awsize (axi_mosi_int.awsize),
    .s_axi_awburst(axi_mosi_int.awburst),
    .s_axi_awlock (axi_mosi_int.awlock),
    .s_axi_awcache(axi_mosi_int.awcache),
    .s_axi_awprot (axi_mosi_int.awprot),
    .s_axi_awvalid(axi_mosi_int.awvalid),
    .s_axi_awready(axi_miso_int.awready),
    .s_axi_wdata  (axi_mosi_int.wdata),
    .s_axi_wstrb  (axi_mosi_int.wstrb),
    .s_axi_wlast  (axi_mosi_int.wlast),
    .s_axi_wvalid (axi_mosi_int.wvalid),
    .s_axi_wready (axi_miso_int.wready),
    .s_axi_bid    (axi_miso_int.bid),
    .s_axi_bresp  (axi_miso_int.bresp),
    .s_axi_bvalid (axi_miso_int.bvalid),
    .s_axi_bready (axi_mosi_int.bready),
    .s_axi_arid   (axi_mosi_int.arid),
    .s_axi_araddr (axi_mosi_int.araddr),
    .s_axi_arlen  (axi_mosi_int.arlen),
    .s_axi_arsize (axi_mosi_int.arsize),
    .s_axi_arburst(axi_mosi_int.arburst),
    .s_axi_arlock (axi_mosi_int.arlock),
    .s_axi_arcache(axi_mosi_int.arcache),
    .s_axi_arprot (axi_mosi_int.arprot),
    .s_axi_arvalid(axi_mosi_int.arvalid),
    .s_axi_arready(axi_miso_int.arready),
    .s_axi_rid    (axi_miso_int.rid),
    .s_axi_rdata  (axi_miso_int.rdata),
    .s_axi_rresp  (axi_miso_int.rresp),
    .s_axi_rlast  (axi_miso_int.rlast),
    .s_axi_rvalid (axi_miso_int.rvalid),
    .s_axi_rready (axi_mosi_int.rready)
  );

endmodule
/* verilator lint_on WIDTH */
