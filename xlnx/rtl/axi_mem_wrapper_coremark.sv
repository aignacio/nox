module axi_mem_wrapper_coremark
  import amba_axi_pkg::*;
  import amba_ahb_pkg::*;
  import nox_utils_pkg::*;
#(
  parameter MEM_KB = 4
)(
  input                 clk,
  input                 rst,
  input   s_axi_mosi_t  axi_mosi,
  output  s_axi_miso_t  axi_miso,
  output  logic [7:0]   csr_o,
  output  logic         uart_tx_o
);
  s_axi_mosi_t  axi_mosi_int;
  s_axi_miso_t  axi_miso_int;

  logic uart_busy;
  logic write_uart;

`ifdef SIMULATION
  localparam NUM_WORDS = (MEM_KB*1024)/4;
  logic [NUM_WORDS-1:0][31:0] mem_loading;

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
  localparam ADDR_RAM = $clog2(MEM_KB*1024);

  /* verilator lint_off WIDTH */
  logic [7:0] csr_output_ff, next_csr;
  logic print_ff, next_print;
  logic busy_ff, next_busy;
  logic csr_decode_ff, next_dec_csr;
  logic bvalid_ff, next_bvalid;

  always_comb begin
    axi_miso = axi_miso_int;
    axi_miso.bvalid = axi_miso_int.bvalid || bvalid_ff;

    csr_o = csr_output_ff;
    axi_mosi_int = axi_mosi;
    next_dec_csr = csr_decode_ff;
    next_csr = csr_output_ff;
    next_bvalid = 'b0;
    next_print = print_ff;
    write_uart = 'b0;
    next_busy = 'b0;

    if ((axi_mosi.awaddr == 'hA000_0008) && axi_mosi.awvalid) begin
      axi_mosi_int.awvalid = '0;
      next_dec_csr = 'b1;
    end

    if ((axi_mosi.awaddr == 'hA000_0000) && axi_mosi.awvalid) begin
      axi_mosi_int.awvalid = '0;
      next_print = 'b1;
    end

    if ((axi_mosi.araddr == 'hA000_0004) && axi_mosi.arvalid) begin
      axi_mosi_int.arvalid = '0;
      next_busy = 'b1;
    end

    if (busy_ff) begin
      axi_miso.rvalid = '1;
      axi_miso.rdata  = {31'h0,uart_busy};
      next_busy = 'b0;
    end


    if (axi_mosi.wvalid && print_ff) begin
      axi_mosi_int.wvalid = '0;
      axi_miso.wready = 'b1;
      next_print = 'b0;
      next_bvalid = 'b1;
      write_uart = 'b1;
    end

    if (axi_mosi.wvalid && csr_decode_ff) begin
      axi_mosi_int.wvalid = '0;
      axi_miso.wready = 'b1;
      next_dec_csr = 'b0;
      next_csr = axi_mosi.wdata[7:0];
      next_bvalid = 'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst == 0) begin
      csr_decode_ff <= '0;
      csr_output_ff <= '0;
      bvalid_ff     <= '0;
      print_ff      <= '0;
      busy_ff       <= '0;
    end
    else begin
      csr_decode_ff <= next_dec_csr;
      csr_output_ff <= next_csr;
      bvalid_ff     <= next_bvalid;
      print_ff      <= next_print;
      busy_ff       <= next_busy;
    end
  end

  axi_ram #(
    // Width of data bus in bits
    .DATA_WIDTH(32),
    // Width of address bus in bits
    .ADDR_WIDTH(ADDR_RAM),
    // Width of ID signal
    .ID_WIDTH(1),
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

  txuartlite #(
	  .CLOCKS_PER_BAUD(434)
	) u_uart (
	  .i_clk      (clk),
		.i_wr       (write_uart),
		.i_data     (axi_mosi.wdata[7:0]),
		.o_uart_tx  (uart_tx_o),
		.o_busy     (uart_busy)
  );

`ifdef SIMULATION
  initial begin
    `ifdef ACT_H_RESET
    if (rst) begin
    `else
    if (~rst) begin
    `endif
      for (int i=0;i<NUM_WORDS;i++) begin
        u_ram.mem[i][31:0] = mem_loading[i][31:0];
      end
    end
  end
`endif
endmodule
/* verilator lint_on WIDTH */
