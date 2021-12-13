module axi_mem import utils_pkg::*; #(
  parameter MEM_KB = 4
)(
  input                 clk,
  input                 rst,
  input   s_axi_mosi_t  axi_mosi,
  output  s_axi_miso_t  axi_miso
);
  localparam ADDR_RAM  = $clog2((MEM_KB*1024)/4);
  localparam NUM_WORDS = (MEM_KB*1024)/4;
  logic [NUM_WORDS-1:0][31:0] mem_ff;
  logic [NUM_WORDS-1:0][31:0] mem_loading;
  logic [ADDR_RAM-1:0] rd_addr;
  logic [ADDR_RAM-1:0] wr_addr;
  logic [31:0] next_wdata;
  logic [1:0] byte_sel_rd;
  logic [1:0] byte_sel_wr;
  logic we_mem;
  logic bvalid_ff, next_bvalid;
  logic axi_rd_vld_ff, next_axi_rd;
  logic axi_wr_vld_ff, next_axi_wr;
  axi_addr_t  rd_addr_ff, next_rd_addr;
  axi_addr_t  wr_addr_ff, next_wr_addr;
  axi_size_t  size_rd_ff, next_rd_size;
  axi_size_t  size_wr_ff, next_wr_size;
  axi_data_t  rd_data_ff, next_rd_data;

  function automatic axi_data_t mask_axi_w(axi_data_t    data,
                                           logic [1:0]   byte_sel,
                                           axi_wr_strb_t wstrb);
    axi_data_t data_o;
    for (int i=0;i<4;i++) begin
      data_o[i*8+:8] = (wstrb[i]) ? data[i*8+:8] : 'h0;
    end
    data_o = data_o << ('h8*byte_sel);

    return data_o;
  endfunction

  function automatic axi_data_t mask_axi(axi_data_t  data,
                                         logic [1:0] byte_sel,
                                         axi_size_t  sz);
    axi_data_t data_o;
    logic [31:0] mask_val;
    case (sz)
      AXI_BYTE:       mask_val = 'hFF;
      AXI_HALF_WORD:  mask_val = 'hFFFF;
      default:        mask_val = 'hFFFF_FFFF;
    endcase

    data_o = data & (mask_val << ('h8*byte_sel));
    return data_o;
  endfunction

  always_comb begin : axi_wr_datapath
    next_wr_addr = axi_addr_t'('0);
    next_axi_wr  = axi_wr_vld_ff;
    next_wr_size = axi_size_t'('h0);
    wr_addr      = wr_addr_ff[2+:ADDR_RAM];
    byte_sel_wr  = 'h0;
    we_mem       = 'b0;
    next_bvalid  = bvalid_ff;
    next_rd_size = axi_size_t'('h0);
    next_wdata   = 'h0;

    axi_miso.awready = 'b1;
    axi_miso.wready  = axi_wr_vld_ff;
    axi_miso.bid     = 'b0;
    axi_miso.bresp   = AXI_OKAY;
    axi_miso.buser   = 'h0;
    axi_miso.bvalid  = 'b0;

    if (axi_mosi.awvalid && axi_miso.awready) begin
      next_wr_addr = axi_mosi.awaddr;
      next_axi_wr  = 'b1;
      next_rd_size = axi_mosi.awsize;
    end

    if (axi_mosi.wvalid && axi_wr_vld_ff) begin
      byte_sel_wr = wr_addr_ff[1:0];
      next_wdata  = mask_axi_w(axi_mosi.wdata, byte_sel_wr, axi_mosi.wstrb);
      we_mem      = 'b1;
      next_bvalid = 'b1;
    end

    if (bvalid_ff) begin
      next_bvalid = ~axi_mosi.bready;
    end

    if (axi_wr_vld_ff) begin
      next_axi_wr = ~(axi_mosi.wvalid && axi_mosi.wlast);
    end

    axi_miso.bvalid = bvalid_ff;
  end : axi_wr_datapath

  always_comb begin : axi_rd_datapath
    next_rd_addr = axi_addr_t'('0);
    next_rd_data = 'd0;
    next_axi_rd  = 'b0;
    next_rd_size = axi_size_t'('h0);
    rd_addr      = rd_addr_ff[2+:ADDR_RAM];
    byte_sel_rd  = 'h0;
    axi_miso.arready = 'b1;

    if (axi_mosi.arvalid && axi_miso.arready) begin
      next_rd_addr = axi_mosi.araddr;
      next_axi_rd  = 'b1;
      next_rd_size = axi_mosi.arsize;
    end

    if (axi_rd_vld_ff) begin
      byte_sel_rd  = rd_addr_ff[1:0];
      next_rd_data = mask_axi(mem_ff[rd_addr], byte_sel_rd, size_rd_ff);
    end

    axi_miso.rid    = 1'b0;
    axi_miso.rresp  = AXI_OKAY;
    axi_miso.ruser  = axi_user_req_t'('h0);
    axi_miso.rdata  = axi_data_t'(rd_data_ff);
    axi_miso.rvalid = axi_rd_vld_ff;
    axi_miso.rlast  = axi_rd_vld_ff;
  end : axi_rd_datapath

  `CLK_PROC(clk, rst) begin
    `RST_TYPE(rst) begin
      rd_data_ff    <= `OP_RST_L;
      rd_addr_ff    <= `OP_RST_L;
      wr_addr_ff    <= `OP_RST_L;
      axi_rd_vld_ff <= `OP_RST_L;
      axi_wr_vld_ff <= `OP_RST_L;
      size_rd_ff    <= `OP_RST_L;
      size_wr_ff    <= `OP_RST_L;
      bvalid_ff     <= `OP_RST_L;
    end
    else begin
      rd_data_ff    <= next_rd_data;
      rd_addr_ff    <= next_rd_addr;
      wr_addr_ff    <= next_wr_addr;
      axi_rd_vld_ff <= next_axi_rd;
      axi_wr_vld_ff <= next_axi_wr;
      size_rd_ff    <= next_rd_size;
      size_wr_ff    <= next_wr_size;
      bvalid_ff     <= next_bvalid;
      if (we_mem) begin
        mem_ff[wr_addr] <= next_wdata;
      end
    end
  end

  initial begin
    `ifdef ACT_H_RESET
    if (rst) begin
    `else
    if (~rst) begin
    `endif
      mem_ff = mem_loading;
    end
  end
endmodule
