module axil_to_axi
  import utils_pkg::*;
(
  input   s_axi_mosi_t  axi_mosi_i,
  output  s_axi_miso_t  axi_miso_o,

  output  s_axil_mosi_t axil_mosi_o,
  input   s_axil_miso_t axil_miso_i
);
  always_comb begin
    axil_mosi_o = s_axil_mosi_t'('0);
    axi_miso_o  = s_axi_miso_t'('0);

    axil_mosi_o.awid    = axi_mosi_i.awid;
    axil_mosi_o.awaddr  = axi_mosi_i.awaddr;
    axil_mosi_o.awprot  = axi_mosi_i.awprot;
    axil_mosi_o.awvalid = axi_mosi_i.awvalid;
    axil_mosi_o.wdata   = axi_mosi_i.wdata;
    axil_mosi_o.wstrb   = axi_mosi_i.wstrb;
    axil_mosi_o.wvalid  = axi_mosi_i.wvalid;
    axil_mosi_o.bready  = axi_mosi_i.bready;
    axil_mosi_o.arid    = axi_mosi_i.arid;
    axil_mosi_o.araddr  = axi_mosi_i.araddr;
    axil_mosi_o.arprot  = axi_mosi_i.arprot;
    axil_mosi_o.arvalid = axi_mosi_i.arvalid;
    axil_mosi_o.rready  = axi_mosi_i.rready;

    axi_miso_o.awready  = axil_miso_i.awready;
    axi_miso_o.wready   = axil_miso_i.wready;
    axi_miso_o.bid      = axil_miso_i.bid;
    axi_miso_o.bresp    = axil_miso_i.bresp;
    axi_miso_o.buser    = '0;
    axi_miso_o.bvalid   = axil_miso_i.bvalid;
    axi_miso_o.arready  = axil_miso_i.arready;
    axi_miso_o.rid      = axil_miso_i.rid;
    axi_miso_o.rdata    = axil_miso_i.rdata;
    axi_miso_o.rresp    = axil_miso_i.rresp;
    axi_miso_o.rlast    = axil_miso_i.rvalid;
    axi_miso_o.ruser    = '0;
    axi_miso_o.rvalid   = axil_miso_i.rvalid;
  end
endmodule
