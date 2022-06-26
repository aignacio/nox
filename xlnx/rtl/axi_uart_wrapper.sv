module axi_uart_wrapper
  import utils_pkg::*;
#(
  parameter [30:0] INITIAL_SETUP = 31'd25,
  parameter [3:0]	 LGFLEN = 4,
  parameter [0:0]	 HARDWARE_FLOW_CONTROL_PRESENT = 1'b0
) (
  input                 clk,
  input                 rst,
  input   s_axi_mosi_t  axi_mosi,
  output  s_axi_miso_t  axi_miso,
  output  logic         uart_tx_o,
  input                 uart_rx_i,
  output                uart_rx_irq_o
);
  axi_tid_t rid_ff, next_rid;
  axi_tid_t wid_ff, next_wid;

  /* verilator lint_off PINMISSING */
  always_comb begin
    axi_miso.rlast = axi_miso.rvalid;

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
    if (~rst) begin
      rid_ff <= '0;
      wid_ff <= '0;
    end
    else begin
      rid_ff <= next_rid;
      wid_ff <= next_wid;
    end
  end

  axiluart #(
		// 4MB 8N1, when using 100MHz clock
		.INITIAL_SETUP                (INITIAL_SETUP),
		// LGFLEN: The log (based two) of our FIFOs size.  Maxes out
		// at 10, representing a FIFO length of 1024.
		.LGFLEN                       (LGFLEN),
		// HARDWARE_FLOW_CONTROL_PRESET controls whether or not we
		// ignore the RTS/CTS signaling.  If present, we only start
		// transmitting if
		.HARDWARE_FLOW_CONTROL_PRESENT(HARDWARE_FLOW_CONTROL_PRESENT)
  ) u_axi_uart (
		// AXI-lite signaling
    .S_AXI_ACLK     (clk),
    .S_AXI_ARESETN  (rst),
    .S_AXI_AWVALID  (axi_mosi.awvalid),
    .S_AXI_AWREADY  (axi_miso.awready),
    .S_AXI_AWADDR   (axi_mosi.awaddr[3:0]),
    .S_AXI_AWPROT   (axi_mosi.awprot),
    .S_AXI_WVALID   (axi_mosi.wvalid),
    .S_AXI_WREADY   (axi_miso.wready),
    .S_AXI_WDATA    (axi_mosi.wdata),
    .S_AXI_WSTRB    (axi_mosi.wstrb),
    .S_AXI_BVALID   (axi_miso.bvalid),
    .S_AXI_BREADY   (axi_mosi.bready),
    .S_AXI_BRESP    (axi_miso.bresp),
    .S_AXI_ARVALID  (axi_mosi.arvalid),
    .S_AXI_ARREADY  (axi_miso.arready),
    .S_AXI_ARADDR   (axi_mosi.araddr[3:0]),
    .S_AXI_ARPROT   (axi_mosi.arprot),
    .S_AXI_RVALID   (axi_miso.rvalid),
    .S_AXI_RREADY   (axi_mosi.rready),
    .S_AXI_RDATA    (axi_miso.rdata),
    .S_AXI_RRESP    (axi_miso.rresp),
		.i_uart_rx      (uart_rx_i),
		.o_uart_tx      (uart_tx_o),
		//
		// CTS is the "Clear-to-send" hardware flow control signal.  We
		// set it anytime our FIFO isn't full.  Feel free to ignore
		// this output if you do not wish to use flow control.
		.i_cts_n        ('1),
    .o_uart_rx_int  (uart_rx_irq_o)
  );
  /* verilator lint_on PINMISSING */

endmodule
