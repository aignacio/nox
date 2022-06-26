/**
 * File              : rst_ctrl.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 13.03.2022
 * Last Modified Date: 26.06.2022
 */
module rst_ctrl import utils_pkg::*; (
  input                 clk,
  input                 rst,
  input   s_axi_mosi_t  axi_mosi,
  output  s_axi_miso_t  axi_miso,
  output  logic [31:0]  rst_addr_o
);
  s_axi_mosi_t  axi_mosi_int;
  s_axi_miso_t  axi_miso_int;
  axi_tid_t     rid_ff, next_rid;
  axi_tid_t     wid_ff, next_wid;

  logic [31:0] rst_addr_ff, next_rst;
  logic        wr_rst_ff,   next_wr_rst;
  logic        rd_rst_ff,   next_rd_rst;
  logic        bvalid_ff,   next_bvalid;
  logic [31:0] rst_loading;

  /* verilator lint_off WIDTH */
  always_comb begin
    next_rst    = rst_addr_ff;
    next_wr_rst = wr_rst_ff;
    next_rd_rst = rd_rst_ff;
    axi_miso    = s_axi_miso_t'('0);
    next_bvalid = bvalid_ff;
    rst_addr_o  = rst_addr_ff;

    axi_miso.awready = 1'b1;
    axi_miso.wready  = wr_rst_ff;
    axi_miso.arready = 1'b1;
    axi_miso.bvalid  = bvalid_ff;

    if (axi_mosi.awvalid && (axi_mosi.awaddr[15:0] == '0)) begin
      next_wr_rst = 1'b1;
    end

    if (axi_mosi.wvalid && wr_rst_ff) begin
      next_wr_rst = 1'b0;
      next_rst    = axi_mosi.wdata;
      next_bvalid = 'b1;
    end

    if (bvalid_ff) begin
      next_bvalid = axi_mosi.bready ? 'b0 : 'b1;
    end

    if (axi_mosi.arvalid && (axi_mosi.araddr[15:0] == '0)) begin
      next_rd_rst = 'b1;
    end

    if (rd_rst_ff) begin
      axi_miso.rvalid = 'b1;
      axi_miso.rlast  = 'b1;
      axi_miso.rdata  = rst_addr_ff;
      if (axi_mosi.rready) begin
        next_rd_rst = 'b0;
      end
    end

    next_rid = rid_ff;
    next_wid = wid_ff;
    axi_miso.rid = rid_ff;
    axi_miso.bid = wid_ff;

    if (axi_mosi.arvalid && axi_miso.arready) begin
      next_rid = axi_mosi.arid;
    end

    if (axi_mosi.awvalid && axi_miso.awready) begin
      next_wid = axi_mosi.awid;
    end
  end
  /* verilator lint_on WIDTH */

  always_ff @ (posedge clk) begin
    if (~rst) begin
      rid_ff <= '0;
      wid_ff <= '0;
    end
    else begin
      rid_ff <= next_rid;
      wid_ff <= next_wid;
    end
  end

  always_ff @(posedge clk) begin
    if (~rst) begin
    `ifdef SIMULATION
      rst_addr_ff <= rst_loading;
    `else
      rst_addr_ff <= '0;
    `endif
      wr_rst_ff   <= '0;
      bvalid_ff   <= '0;
      rd_rst_ff   <= '0;
    end
    else begin
      rst_addr_ff <= next_rst;
      wr_rst_ff   <= next_wr_rst;
      bvalid_ff   <= next_bvalid;
      rd_rst_ff   <= next_rd_rst;
    end
  end
endmodule
