/**
 * File              : cb_to_ahb.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 23.10.2021
 * Last Modified Date: 25.02.2022
 */
module cb_to_ahb
  import utils_pkg::*;
(
  // Core bus Master I/F
  input   s_cb_mosi_t   cb_mosi_i,
  output  s_cb_miso_t   cb_miso_o,
  // AXI Master I/F
  output  s_ahb_mosi_t  ahb_mosi_o,
  input   s_ahb_miso_t  ahb_miso_i
);
  always_comb begin
    ahb_mosi_o = s_ahb_mosi_t'('0);
    cb_miso_o  = s_cb_miso_t'('0);

    // MOSI
    if (cb_mosi_i.wr_addr_valid || cb_mosi_i.rd_addr_valid) begin
      ahb_mosi_o.haddr  = cb_mosi_i.wr_addr_valid ? cb_mosi_i.wr_addr :
                                                    cb_mosi_i.rd_addr;
      ahb_mosi_o.hburst = AHB_SINGLE;
      ahb_mosi_o.hsize  = AHB_SZ_WORD;
      ahb_mosi_o.htrans = AHB_NONSEQUENTIAL;
      ahb_mosi_o.hwrite = cb_mosi_i.wr_addr_valid;
      ahb_mosi_o.hsel   = 'b1;
    end
    ahb_mosi_o.hwdata = cb_mosi_i.wr_data_valid ? cb_mosi_i.wr_data : 'h0;

    // MISO
    cb_miso_o.wr_addr_ready = ahb_miso_i.hready;
    cb_miso_o.wr_data_ready = ahb_miso_i.hready;
    cb_miso_o.wr_resp_error = cb_error_t'(ahb_miso_i.hresp);
    cb_miso_o.wr_resp_valid = 'b1;
    cb_miso_o.rd_addr_ready = ahb_miso_i.hready;
    cb_miso_o.rd_data       = ahb_miso_i.hrdata;
    cb_miso_o.rd_resp       = cb_error_t'(ahb_miso_i.hresp);
    cb_miso_o.rd_valid      = ~ahb_miso_i.hready;
  end

endmodule
