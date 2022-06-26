module axi_mtimer import utils_pkg::*; (
  input                 clk,
  input                 rst,
  input   s_axi_mosi_t  axi_mosi,
  output  s_axi_miso_t  axi_miso,
  // SPI Pins
  output  logic         mtimer_irq_o
);
  typedef struct packed {
    logic         vld;
    logic [15:0]  addr;
  } s_axi_req_t;

  logic [63:0]  mtimer_ff, next_mtimer;
  logic [63:0]  mtimercmp_ff, next_mtimercmp;
  s_axi_req_t   wr_req_ff, next_wr_req;
  s_axi_req_t   rd_req_ff, next_rd_req;
  logic         bvalid_ff, next_bvalid;
  axi_tid_t rid_ff, next_rid;
  axi_tid_t wid_ff, next_wid;

  always_comb begin
    axi_miso = s_axi_miso_t'('0);

    mtimer_irq_o = (mtimer_ff >= mtimercmp_ff);

    axi_miso.awready  = 'b1;
    axi_miso.wready   = wr_req_ff.vld;
    axi_miso.bvalid   = bvalid_ff;
    axi_miso.arready  = 'b1;

    next_bvalid     = bvalid_ff;
    next_mtimercmp  = mtimercmp_ff;
    next_mtimer     = mtimer_ff + 'd1;
    next_wr_req     = wr_req_ff;
    next_rd_req     = rd_req_ff;

    // Write address phase
    if (axi_mosi.awvalid) begin
      if ((axi_mosi.awaddr[15:0] == 'h0008) ||
          (axi_mosi.awaddr[15:0] == 'h000C)) begin
        next_wr_req.vld   = 'b1;
        next_wr_req.addr  = axi_mosi.awaddr[15:0];
      end
    end

    // Write data phase
    if (wr_req_ff.vld && axi_mosi.wvalid) begin
      case (wr_req_ff.addr)
        'h0008: next_mtimercmp[31:0]  = axi_mosi.wdata;
        'h000C: next_mtimercmp[63:32] = axi_mosi.wdata;
        //default:
          //$error("Unexpected decoding!");
      endcase
      next_wr_req.vld = 'b0;
      next_bvalid     = 'b1;
    end

    // Write response
    if (bvalid_ff) begin
      axi_miso.bvalid = 'b1;
      next_bvalid     = ~axi_mosi.bready;
    end

    // Read address channel
    if (axi_mosi.arvalid) begin
      if ((axi_mosi.araddr[15:0] == 'h0000) ||
          (axi_mosi.araddr[15:0] == 'h0004) ||
          (axi_mosi.araddr[15:0] == 'h0008) ||
          (axi_mosi.araddr[15:0] == 'h000C)) begin
        next_rd_req.vld   = 'b1;
        next_rd_req.addr  = axi_mosi.araddr[15:0];
      end
    end

    // Read data phase
    if (rd_req_ff.vld) begin
      case (rd_req_ff.addr)
        'h0000: axi_miso.rdata = mtimer_ff[31:0];
        'h0004: axi_miso.rdata = mtimer_ff[63:32];
        'h0008: axi_miso.rdata = mtimercmp_ff[31:0];
        'h000C: axi_miso.rdata = mtimercmp_ff[63:32];
        default:  axi_miso.rdata = '0;
      endcase
      axi_miso.rvalid = 'b1;
      axi_miso.rlast  = 'b1;
      next_rd_req.vld = ~axi_mosi.rready;
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
    if (~rst) begin
      mtimer_ff     <= '0;
      mtimercmp_ff  <= '1; // We don't want IRQ at #t0 so we set to the max val
      wr_req_ff     <= '0;
      rd_req_ff     <= '0;
      bvalid_ff     <= '0;
      rid_ff        <= '0;
      wid_ff        <= '0;
    end
    else begin
      mtimer_ff     <= next_mtimer;
      mtimercmp_ff  <= next_mtimercmp;
      wr_req_ff     <= next_wr_req;
      rd_req_ff     <= next_rd_req;
      bvalid_ff     <= next_bvalid;
      rid_ff        <= next_rid;
      wid_ff        <= next_wid;
    end
  end
endmodule
