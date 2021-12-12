/**
 * File              : cb_to_axi.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 23.10.2021
 * Last Modified Date: 04.12.2021
 */
module cb_to_axi
  import utils_pkg::*;
#(
  parameter logic [2:0] PROT = 'b010 // INSTRUCTION - 100 / NONSECURE - 010 / PRIV - 001
)(
  // Core bus Master I/F
  input   s_cb_mosi_t   cb_mosi_i,
  output  s_cb_miso_t   cb_miso_o,
  // AXI Master I/F
  output  s_axi_mosi_t  axi_mosi_o,
  input   s_axi_miso_t  axi_miso_i
);
  always_comb begin
    axi_mosi_o = s_axi_mosi_t'('0);
    cb_miso_o  = s_cb_miso_t'('0);

    // MOSI
    axi_mosi_o.awaddr   = axi_addr_t'(cb_mosi_i.wr_addr);
    axi_mosi_o.awsize   = axi_size_t'(cb_mosi_i.wr_size);
    axi_mosi_o.awvalid  = cb_mosi_i.wr_addr_valid;
    axi_mosi_o.wdata    = axi_data_t'(cb_mosi_i.wr_data);
    axi_mosi_o.wvalid   = cb_mosi_i.wr_data_valid;
    axi_mosi_o.wstrb    = axi_wr_strb_t'(cb_mosi_i.wr_strobe);
    axi_mosi_o.bready   = cb_mosi_i.wr_resp_ready;
    axi_mosi_o.araddr   = axi_addr_t'(cb_mosi_i.rd_addr);
    axi_mosi_o.arsize   = axi_size_t'(cb_mosi_i.rd_size);
    axi_mosi_o.arvalid  = cb_mosi_i.rd_addr_valid;
    axi_mosi_o.rready   = cb_mosi_i.rd_ready;
    axi_mosi_o.arprot   = PROT;
    axi_mosi_o.awprot   = PROT;

    // MISO
    cb_miso_o.wr_addr_ready = axi_miso_i.awready;
    cb_miso_o.wr_data_ready = axi_miso_i.wready;
    cb_miso_o.wr_resp_error = cb_error_t'(axi_miso_i.bresp);
    cb_miso_o.wr_resp_valid = axi_miso_i.bvalid;
    cb_miso_o.rd_addr_ready = axi_miso_i.arready;
    cb_miso_o.rd_data       = cb_data_t'(axi_miso_i.rdata);
    cb_miso_o.rd_resp       = cb_error_t'(axi_miso_i.rresp);
    cb_miso_o.rd_valid      = axi_miso_i.rvalid;
  end

endmodule
