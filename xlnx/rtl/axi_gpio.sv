module axi_gpio
  import amba_axi_pkg::*;
  import amba_ahb_pkg::*;
  import nox_utils_pkg::*;
(
  input                 clk,
  input                 rst,
  input   s_axi_mosi_t  axi_mosi,
  output  s_axi_miso_t  axi_miso,
  output  logic [7:0]   csr_o
);
`ifdef SIMULATION
  function [7:0] getbufferReq;
    /* verilator public */
    begin
      getbufferReq = (axi_mosi.wdata[7:0]);
    end
  endfunction

  function printfbufferReq;
    /* verilator public */
    begin
      printfbufferReq = print_ff && axi_mosi.wvalid;
    end
  endfunction
`endif

  /* verilator lint_off WIDTH */
  logic [7:0] csr_output_ff, next_csr;
  logic print_ff, next_print;
  logic csr_decode_ff, next_dec_csr;
  logic bvalid_ff, next_bvalid;
  logic rd_gpio_ff, next_rd_gpio;
  axi_tid_t rid_ff, next_rid;
  axi_tid_t wid_ff, next_wid;

  always_comb begin
    axi_miso = s_axi_miso_t'('0);
    axi_miso.bvalid = bvalid_ff;
    axi_miso.awready = 'b1;
    axi_miso.arready = 'b1;

    csr_o = csr_output_ff;
    next_dec_csr = csr_decode_ff;
    next_csr = csr_output_ff;
    next_bvalid = bvalid_ff;
    next_print = print_ff;
    next_rd_gpio = rd_gpio_ff;

    if ((axi_mosi.awaddr[15:0] == 'h0000) && axi_mosi.awvalid) begin
      next_dec_csr = 'b1;
    end

    if ((axi_mosi.awaddr[15:0] == 'h0008) && axi_mosi.awvalid) begin
      next_print = 'b1;
    end

    if (axi_mosi.wvalid && print_ff) begin
      axi_miso.wready = 'b1;
      next_print = 'b0;
      next_bvalid = 'b1;
    end

    if (axi_mosi.wvalid && csr_decode_ff) begin
      axi_miso.wready = 'b1;
      next_dec_csr = 'b0;
      next_csr = axi_mosi.wdata[8:0];
      next_bvalid = 'b1;
    end

    if (axi_mosi.bready && bvalid_ff) begin
      next_bvalid = 'b0;
    end

    if (axi_mosi.arvalid && (axi_mosi.araddr[15:0] == 'h0000)) begin
      next_rd_gpio = 'b1;
    end

    if (rd_gpio_ff) begin
      axi_miso.rvalid = 'b1;
      axi_miso.rlast  = 'b1;
      axi_miso.rdata  = csr_output_ff;
      if (axi_mosi.rready) begin
        next_rd_gpio = 'b0;
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

  always_ff @ (posedge clk) begin
    if (rst == 0) begin
      rid_ff <= '0;
      wid_ff <= '0;
    end
    else begin
      rid_ff <= next_rid;
      wid_ff <= next_wid;
    end
  end

  always_ff @(posedge clk) begin
    if (rst == 0) begin
      csr_decode_ff <= '0;
      csr_output_ff <= '0;
      bvalid_ff     <= '0;
      print_ff      <= '0;
      rd_gpio_ff    <= '0;
    end
    else begin
      csr_decode_ff <= next_dec_csr;
      csr_output_ff <= next_csr;
      bvalid_ff     <= next_bvalid;
      print_ff      <= next_print;
      rd_gpio_ff    <= next_rd_gpio;
    end
  end
endmodule
/* verilator lint_on WIDTH */
