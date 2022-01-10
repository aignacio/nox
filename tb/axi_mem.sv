module axi_mem import utils_pkg::*; #(
  parameter MEM_KB = 4,
  parameter DISPLAY_TEST = `DISPLAY_TEST
)(
  input                 clk,
  input                 rst,
`ifndef SIMULATION
  output  logic [7:0]   csr_o,
`endif
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

`ifndef SIMULATION
  logic csr_decode_ff, next_dec_csr;
  logic [7:0] csr_output_ff, next_csr;
`endif

  axi_addr_t  wr_addr_ff, next_wr_addr;
  axi_size_t  size_wr_ff, next_wr_size;
  axi_data_t  rd_data_ff, next_rd_data;
`ifdef SIMULATION
  logic [7:0] char_wr;
  logic next_char, char_ff;
  logic next_num, num_ff;
  typedef struct packed {
    logic [31:0]     start_addr;
    logic [31:0]     end_addr;
  } s_signature_t;

  s_signature_t sig_ff, next_sig;
  logic start_sig_ff, next_start_sig;
  logic end_sig_ff, next_end_sig;
  logic fin_sig_ff, next_fin;
`endif

  function automatic void dump_signature();
    automatic string sig_file;
    automatic integer sig_fd;
    automatic integer errno;
    automatic string error_str;
    automatic bit use_sig_file;

    $value$plusargs("signature=%s", sig_file);
    if ($value$plusargs("signature=%s", sig_file)) begin
      if (DISPLAY_TEST) begin
        $display("@Dumping signature:");
        $display(" ---- Start Address [DRAM] = %x", sig_ff.start_addr);
        $display(" ---- End Address [DRAM] = %x", sig_ff.end_addr);
        $display("@Sig:");
      end
      sig_fd = $fopen(sig_file, "w");
      if (sig_fd == 0) begin
        errno = $ferror(sig_fd, error_str);
        $error(error_str);
        use_sig_file = 1'b0;
      end else begin
        use_sig_file = 1'b1;
      end

      for (logic [31:0] addr = sig_ff.start_addr; addr < sig_ff.end_addr; addr +=4) begin
        if (DISPLAY_TEST)
          $display("[0x%x] - %x",addr,mem_ff[addr>>2]);
        if (use_sig_file) begin
          $fdisplay(sig_fd, "%x", mem_ff[addr>>2]);
        end
      end
    end
  endfunction

  function automatic logic [7:0] find_byte(logic [31:0] data_in);
    logic [7:0] data;
    data = data_in[7:0];

    for (int i=0;i<4;i++) begin
      if (data == 'h0) begin
        data = data_in[(i*8)+:8];
      end
      else begin
        return data;
      end
    end
    return data;
  endfunction

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
    next_wr_size = axi_size_t'('h0);
    next_wdata   = 'h0;

    axi_miso.awready = 'b1;
    axi_miso.wready  = 'b1;
    axi_miso.bid     = 'b0;
    axi_miso.bresp   = AXI_OKAY;
    axi_miso.buser   = 'h0;
    axi_miso.bvalid  = 'b0;

`ifndef SIMULATION
    csr_o = csr_output_ff;
    next_csr = csr_output_ff;
    next_dec_csr = csr_decode_ff;

    if (axi_mosi.awvalid && axi_miso.awready) begin
      next_wr_addr = axi_mosi.awaddr;
      next_axi_wr  = 'b1;
      next_wr_size = axi_mosi.awsize;
      if (axi_mosi.awaddr == 'hD000_0000) begin
        next_dec_csr = 'b1;
      end
    end
    if (axi_mosi.wvalid && axi_wr_vld_ff) begin
      byte_sel_wr = wr_addr_ff[1:0];
      next_wdata  = mask_axi_w(axi_mosi.wdata, byte_sel_wr, axi_mosi.wstrb);
      we_mem      = 'b1;
      next_bvalid = 'b1;
      if (csr_decode_ff) begin
        next_csr = axi_mosi.wdata[7:0];
        we_mem = 'b0;
      end
    end
`else
    next_char = 'b0;
    next_num  = 'b0;
    char_wr   = 'b0;
    next_start_sig = 'b0;
    next_end_sig   = 'b0;
    next_fin       = 'b0;
    next_sig       = sig_ff;

    // Address phase
    if (axi_mosi.awvalid && axi_miso.awready) begin
      if (axi_mosi.awaddr == 'hA000_0000) begin
        next_char = 'b1;
      end
      else if (axi_mosi.awaddr == 'hB000_0000) begin
        next_num = 'b1;
      end
      else if (axi_mosi.awaddr == 'hC000_0010) begin
        next_start_sig = 'b1;
      end
      else if (axi_mosi.awaddr == 'hC000_0020) begin
        next_end_sig = 'b1;
      end
      else if (axi_mosi.awaddr == 'hC000_0000) begin
        next_fin = 'b1;
      end
      else begin
        next_wr_addr = axi_mosi.awaddr;
        next_axi_wr  = 'b1;
        next_wr_size = axi_mosi.awsize;
      end
    end
    /* verilator lint_off UNOPTTHREADS */
    // Data phase
    if (axi_mosi.wvalid && axi_wr_vld_ff) begin
      next_bvalid = 'b1;
      if (fin_sig_ff) begin
        dump_signature();
        $finish;
      end
      else if (start_sig_ff) begin
        next_sig.start_addr = axi_mosi.wdata;
      end
      else if (end_sig_ff) begin
        next_sig.end_addr = axi_mosi.wdata;
      end
      /* verilator lint_on UNOPTTHREADS */
      else if (~char_ff && ~num_ff) begin
        byte_sel_wr = wr_addr_ff[1:0];
        next_wdata  = mask_axi_w(axi_mosi.wdata, byte_sel_wr, axi_mosi.wstrb);
        we_mem      = 'b1;
      end
    end
`endif

    if (bvalid_ff) begin
      next_bvalid = ~axi_mosi.bready;
    end

    if (axi_wr_vld_ff) begin
      next_axi_wr = ~(axi_mosi.wvalid && axi_mosi.wlast);
    end

    axi_miso.bvalid = bvalid_ff;
  end : axi_wr_datapath

  always_comb begin : axi_rd_datapath
    next_rd_data = rd_data_ff;
    next_axi_rd  = 'b0;
    byte_sel_rd  = 'h0;
    rd_addr      = axi_mosi.araddr[2+:ADDR_RAM];
    axi_miso.arready = 'b1;

    if (axi_rd_vld_ff) begin
      next_axi_rd  = ~axi_mosi.rready;
    end

    if (axi_mosi.arvalid && axi_miso.arready) begin
      next_axi_rd  = 'b1;
      byte_sel_rd  = axi_mosi.araddr[1:0];
      next_rd_data = mask_axi(mem_ff[rd_addr], byte_sel_rd, axi_mosi.arsize);
    end

    axi_miso.rid    = 1'b0;
    axi_miso.rresp  = AXI_OKAY;
    axi_miso.ruser  = axi_user_req_t'('h0);
    axi_miso.rvalid = axi_rd_vld_ff;
    axi_miso.rlast  = axi_rd_vld_ff;
    axi_miso.rdata  = axi_miso.rvalid ? axi_data_t'(rd_data_ff) : axi_data_t'('h0);
  end : axi_rd_datapath

  `CLK_PROC(clk, rst) begin
    `RST_TYPE(rst) begin
      rd_data_ff    <= axi_data_t'(`OP_RST_L);
      wr_addr_ff    <= axi_addr_t'(`OP_RST_L);
      axi_rd_vld_ff <= `OP_RST_L;
      axi_wr_vld_ff <= `OP_RST_L;
      size_wr_ff    <= axi_size_t'(`OP_RST_L);
      bvalid_ff     <= `OP_RST_L;
`ifdef SIMULATION
      char_ff       <= 'b0;
      num_ff        <= 'b0;
      sig_ff        <= s_signature_t'('h0);
      start_sig_ff  <= 'b0;
      end_sig_ff    <= 'b0;
      fin_sig_ff    <= 'b0;
`else
      csr_output_ff <= `OP_RST_L;
      csr_decode_ff <= `OP_RST_L;
`endif
    end
    else begin
      rd_data_ff    <= next_rd_data;
      wr_addr_ff    <= next_wr_addr;
      axi_rd_vld_ff <= next_axi_rd;
      axi_wr_vld_ff <= next_axi_wr;
      size_wr_ff    <= next_wr_size;
      bvalid_ff     <= next_bvalid;
`ifdef SIMULATION
      char_ff       <= next_char;
      num_ff        <= next_num;
      sig_ff        <= next_sig;
      start_sig_ff  <= next_start_sig;
      end_sig_ff    <= next_end_sig;
      fin_sig_ff    <= next_fin;
      if (char_ff) begin
        if (DISPLAY_TEST)
          $write("%c",find_byte(axi_mosi.wdata));
      end
      else if (num_ff) begin
        if (DISPLAY_TEST)
          $write("%d",find_byte(axi_mosi.wdata));
      end
`else
      csr_output_ff <= next_csr;
      csr_decode_ff <= next_dec_csr;
`endif
      if (we_mem) begin
        for (int i=0;i<4;i++) begin
          if (axi_mosi.wstrb[i])
            mem_ff[wr_addr][i*8+:8] <= axi_mosi.wdata[i*8+:8];
        end
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
