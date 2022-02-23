module axi_interconnect_wrapper
  import utils_pkg::*;
#(
  parameter N_MASTERS     = 1,
  parameter N_SLAVES      = 1,
  parameter M_BASE_ADDR   = 0,
  parameter M_ADDR_WIDTH  = 0
)(
  input                                 clk,
  input                                 arst,
  // From Master I/Fs
  input   s_axi_mosi_t  [N_MASTERS-1:0] masters_axi_mosi,
  output  s_axi_miso_t  [N_MASTERS-1:0] masters_axi_miso,
  // To Slave I/Fs
  output  s_axi_mosi_t  [N_SLAVES-1:0]  slaves_axi_mosi,
  input   s_axi_miso_t  [N_SLAVES-1:0]  slaves_axi_miso
);
  /* verilator lint_off WIDTH */
  logic [N_MASTERS*ID_WIDTH-1:0]     from_m_axi_awid;
  logic [N_MASTERS*ADDR_WIDTH-1:0]   from_m_axi_awaddr;
  logic [N_MASTERS*ALEN_WIDTH:0]     from_m_axi_awlen;
  logic [N_MASTERS*3-1:0]            from_m_axi_awsize;
  logic [N_MASTERS*2-1:0]            from_m_axi_awburst;
  logic [N_MASTERS-1:0]              from_m_axi_awlock;
  logic [N_MASTERS*4-1:0]            from_m_axi_awcache;
  logic [N_MASTERS*3-1:0]            from_m_axi_awprot;
  logic [N_MASTERS*4-1:0]            from_m_axi_awqos;
  logic [N_MASTERS*AWUSER_WIDTH-1:0] from_m_axi_awuser;
  logic [N_MASTERS-1:0]              from_m_axi_awvalid;
  logic [N_MASTERS-1:0]              from_m_axi_awready;
  logic [N_MASTERS*DATA_WIDTH-1:0]   from_m_axi_wdata;
  logic [N_MASTERS*STRB_WIDTH-1:0]   from_m_axi_wstrb;
  logic [N_MASTERS-1:0]              from_m_axi_wlast;
  logic [N_MASTERS*WUSER_WIDTH-1:0]  from_m_axi_wuser;
  logic [N_MASTERS-1:0]              from_m_axi_wvalid;
  logic [N_MASTERS-1:0]              from_m_axi_wready;
  logic [N_MASTERS*ID_WIDTH-1:0]     from_m_axi_bid;
  logic [N_MASTERS*2-1:0]            from_m_axi_bresp;
  logic [N_MASTERS*BUSER_WIDTH-1:0]  from_m_axi_buser;
  logic [N_MASTERS-1:0]              from_m_axi_bvalid;
  logic [N_MASTERS-1:0]              from_m_axi_bready;
  logic [N_MASTERS*ID_WIDTH-1:0]     from_m_axi_arid;
  logic [N_MASTERS*ADDR_WIDTH-1:0]   from_m_axi_araddr;
  logic [N_MASTERS*ALEN_WIDTH:0]     from_m_axi_arlen;
  logic [N_MASTERS*3-1:0]            from_m_axi_arsize;
  logic [N_MASTERS*2-1:0]            from_m_axi_arburst;
  logic [N_MASTERS-1:0]              from_m_axi_arlock;
  logic [N_MASTERS*4-1:0]            from_m_axi_arcache;
  logic [N_MASTERS*3-1:0]            from_m_axi_arprot;
  logic [N_MASTERS*4-1:0]            from_m_axi_arqos;
  logic [N_MASTERS*ARUSER_WIDTH-1:0] from_m_axi_aruser;
  logic [N_MASTERS-1:0]              from_m_axi_arvalid;
  logic [N_MASTERS-1:0]              from_m_axi_arready;
  logic [N_MASTERS*ID_WIDTH-1:0]     from_m_axi_rid;
  logic [N_MASTERS*DATA_WIDTH-1:0]   from_m_axi_rdata;
  logic [N_MASTERS*2-1:0]            from_m_axi_rresp;
  logic [N_MASTERS*2-1:0]            from_m_axi_rlast;
  logic [N_MASTERS*2-1:0]            from_m_axi_ruser;
  logic [N_MASTERS*2-1:0]            from_m_axi_rvalid;
  logic [N_MASTERS*2-1:0]            from_m_axi_rready;

  logic [N_SLAVES*ID_WIDTH-1:0]      to_s_axi_awid;
  logic [N_SLAVES*ADDR_WIDTH-1:0]    to_s_axi_awaddr;
  logic [N_SLAVES*ALEN_WIDTH:0]      to_s_axi_awlen;
  logic [N_SLAVES*3-1:0]             to_s_axi_awsize;
  logic [N_SLAVES*2-1:0]             to_s_axi_awburst;
  logic [N_SLAVES-1:0]               to_s_axi_awlock;
  logic [N_SLAVES*4-1:0]             to_s_axi_awcache;
  logic [N_SLAVES*3-1:0]             to_s_axi_awprot;
  logic [N_SLAVES*4-1:0]             to_s_axi_awqos;
  logic [N_SLAVES*AWUSER_WIDTH-1:0]  to_s_axi_awuser;
  logic [N_SLAVES-1:0]               to_s_axi_awvalid;
  logic [N_SLAVES-1:0]               to_s_axi_awready;
  logic [N_SLAVES*DATA_WIDTH-1:0]    to_s_axi_wdata;
  logic [N_SLAVES*STRB_WIDTH-1:0]    to_s_axi_wstrb;
  logic [N_SLAVES-1:0]               to_s_axi_wlast;
  logic [N_SLAVES*WUSER_WIDTH-1:0]   to_s_axi_wuser;
  logic [N_SLAVES-1:0]               to_s_axi_wvalid;
  logic [N_SLAVES-1:0]               to_s_axi_wready;
  logic [N_SLAVES*ID_WIDTH-1:0]      to_s_axi_bid;
  logic [N_SLAVES*2-1:0]             to_s_axi_bresp;
  logic [N_SLAVES*BUSER_WIDTH-1:0]   to_s_axi_buser;
  logic [N_SLAVES-1:0]               to_s_axi_bvalid;
  logic [N_SLAVES-1:0]               to_s_axi_bready;
  logic [N_SLAVES*ID_WIDTH-1:0]      to_s_axi_arid;
  logic [N_SLAVES*ADDR_WIDTH-1:0]    to_s_axi_araddr;
  logic [N_SLAVES*ALEN_WIDTH:0]      to_s_axi_arlen;
  logic [N_SLAVES*3-1:0]             to_s_axi_arsize;
  logic [N_SLAVES*2-1:0]             to_s_axi_arburst;
  logic [N_SLAVES-1:0]               to_s_axi_arlock;
  logic [N_SLAVES*4-1:0]             to_s_axi_arcache;
  logic [N_SLAVES*3-1:0]             to_s_axi_arprot;
  logic [N_SLAVES*4-1:0]             to_s_axi_arqos;
  logic [N_SLAVES*ARUSER_WIDTH-1:0]  to_s_axi_aruser;
  logic [N_SLAVES-1:0]               to_s_axi_arvalid;
  logic [N_SLAVES-1:0]               to_s_axi_arready;
  logic [N_SLAVES*ID_WIDTH-1:0]      to_s_axi_rid;
  logic [N_SLAVES*DATA_WIDTH-1:0]    to_s_axi_rdata;
  logic [N_SLAVES*2-1:0]             to_s_axi_rresp;
  logic [N_SLAVES*2-1:0]             to_s_axi_rlast;
  logic [N_SLAVES*2-1:0]             to_s_axi_ruser;
  logic [N_SLAVES*2-1:0]             to_s_axi_rvalid;
  logic [N_SLAVES*2-1:0]             to_s_axi_rready;

  localparam ID_WIDTH     = 1;
  localparam DATA_WIDTH   = 32;
  localparam ADDR_WIDTH   = 32;
  localparam AWUSER_WIDTH = 1;
  localparam ARUSER_WIDTH = 1;
  localparam WUSER_WIDTH  = 1;
  localparam BUSER_WIDTH  = 1;
  localparam STRB_WIDTH   = 4;
  localparam ALEN_WIDTH   = 8;

  always_comb begin
    for (int m_idx=0;m_idx<N_MASTERS;m_idx++) begin
      // Masters
      from_m_axi_awid    [m_idx*ID_WIDTH     +: ID_WIDTH]     = masters_axi_mosi[m_idx].awid;
      from_m_axi_awaddr  [m_idx*ADDR_WIDTH   +: ADDR_WIDTH]   = masters_axi_mosi[m_idx].awaddr;
      from_m_axi_awlen   [m_idx*ALEN_WIDTH   +: ALEN_WIDTH]   = masters_axi_mosi[m_idx].awlen;
      from_m_axi_awsize  [m_idx*3            +: 3]            = masters_axi_mosi[m_idx].awsize;
      from_m_axi_awburst [m_idx*2            +: 2]            = masters_axi_mosi[m_idx].awburst;
      from_m_axi_awlock  [m_idx*1            +: 1]            = masters_axi_mosi[m_idx].awlock;
      from_m_axi_awcache [m_idx*4            +: 4]            = masters_axi_mosi[m_idx].awcache;
      from_m_axi_awprot  [m_idx*3            +: 3]            = masters_axi_mosi[m_idx].awprot;
      from_m_axi_awqos   [m_idx*4            +: 4]            = masters_axi_mosi[m_idx].awqos;
      from_m_axi_awuser  [m_idx*AWUSER_WIDTH +: AWUSER_WIDTH] = masters_axi_mosi[m_idx].awuser;
      from_m_axi_awvalid [m_idx*1            +: 1]            = masters_axi_mosi[m_idx].awvalid;
      masters_axi_miso[m_idx].awready  = from_m_axi_awready[m_idx*1+:1];
      from_m_axi_wdata   [m_idx*DATA_WIDTH   +: DATA_WIDTH]   = masters_axi_mosi[m_idx].wdata;
      from_m_axi_wstrb   [m_idx*STRB_WIDTH   +: STRB_WIDTH]   = masters_axi_mosi[m_idx].wstrb;
      from_m_axi_wlast   [m_idx*1            +: 1]            = masters_axi_mosi[m_idx].wlast;
      from_m_axi_wuser   [m_idx*WUSER_WIDTH  +: WUSER_WIDTH]  = masters_axi_mosi[m_idx].wuser;
      from_m_axi_wvalid  [m_idx*1            +: 1]            = masters_axi_mosi[m_idx].wvalid;
      masters_axi_miso[m_idx].wready   = from_m_axi_wready[m_idx*1+:1];
      masters_axi_miso[m_idx].bid      = from_m_axi_bid   [m_idx*ID_WIDTH+:ID_WIDTH];
      masters_axi_miso[m_idx].bresp    = axi_error_t'(from_m_axi_bresp [m_idx*2+:2]);
      masters_axi_miso[m_idx].buser    = from_m_axi_buser [m_idx*BUSER_WIDTH+:BUSER_WIDTH];
      masters_axi_miso[m_idx].bvalid   = from_m_axi_bvalid[m_idx*1+:1];
      from_m_axi_bready  [m_idx*1            +: 1]            = masters_axi_mosi[m_idx].bready;
      from_m_axi_arid    [m_idx*ID_WIDTH     +: ID_WIDTH]     = masters_axi_mosi[m_idx].arid;
      from_m_axi_araddr  [m_idx*ADDR_WIDTH   +: ADDR_WIDTH]   = masters_axi_mosi[m_idx].araddr;
      from_m_axi_arlen   [m_idx*ALEN_WIDTH   +: ALEN_WIDTH]   = masters_axi_mosi[m_idx].arlen;
      from_m_axi_arsize  [m_idx*3            +: 3]            = masters_axi_mosi[m_idx].arsize;
      from_m_axi_arburst [m_idx*2            +: 2]            = masters_axi_mosi[m_idx].arburst;
      from_m_axi_arlock  [m_idx*1            +: 1]            = masters_axi_mosi[m_idx].arlock;
      from_m_axi_arcache [m_idx*4            +: 4]            = masters_axi_mosi[m_idx].arcache;
      from_m_axi_arprot  [m_idx*3            +: 3]            = masters_axi_mosi[m_idx].arprot;
      from_m_axi_arqos   [m_idx*4            +: 4]            = masters_axi_mosi[m_idx].arqos;
      from_m_axi_aruser  [m_idx*ARUSER_WIDTH +: ARUSER_WIDTH] = masters_axi_mosi[m_idx].aruser;
      from_m_axi_arvalid [m_idx*1            +: 1]            = masters_axi_mosi[m_idx].arvalid;
      masters_axi_miso[m_idx].arready = from_m_axi_arready[m_idx*1+:1];
      masters_axi_miso[m_idx].rid     = from_m_axi_rid    [m_idx*ID_WIDTH+:ID_WIDTH];
      masters_axi_miso[m_idx].rdata   = from_m_axi_rdata  [m_idx*DATA_WIDTH+:DATA_WIDTH];
      masters_axi_miso[m_idx].rresp   = axi_error_t'(from_m_axi_rresp  [m_idx*2+:2]);
      masters_axi_miso[m_idx].rlast   = from_m_axi_rlast  [m_idx*1+:1];
      masters_axi_miso[m_idx].ruser   = from_m_axi_ruser  [m_idx*1+:1];
      masters_axi_miso[m_idx].rvalid  = from_m_axi_rvalid [m_idx*1+:1];
      from_m_axi_rready [m_idx*1            +: 1]            = masters_axi_mosi[m_idx].rready;
    end

    for (int s_idx=0;s_idx<N_SLAVES;s_idx++) begin
      // Slaves
      slaves_axi_mosi[s_idx].awid    = to_s_axi_awid    [s_idx*ID_WIDTH     +: ID_WIDTH];
      slaves_axi_mosi[s_idx].awaddr  = to_s_axi_awaddr  [s_idx*ADDR_WIDTH   +: ADDR_WIDTH];
      slaves_axi_mosi[s_idx].awlen   = to_s_axi_awlen   [s_idx*ALEN_WIDTH   +: ALEN_WIDTH];
      slaves_axi_mosi[s_idx].awsize  = axi_size_t'(to_s_axi_awsize  [s_idx*3            +: 3]);
      slaves_axi_mosi[s_idx].awburst = axi_burst_t'(to_s_axi_awburst [s_idx*2            +: 2]);
      slaves_axi_mosi[s_idx].awlock  = to_s_axi_awlock  [s_idx*1            +: 1];
      slaves_axi_mosi[s_idx].awcache = to_s_axi_awcache [s_idx*4            +: 4];
      slaves_axi_mosi[s_idx].awprot  = axi_prot_t'(to_s_axi_awprot  [s_idx*3            +: 3]);
      slaves_axi_mosi[s_idx].awqos   = to_s_axi_awqos   [s_idx*4            +: 4];
      slaves_axi_mosi[s_idx].awuser  = to_s_axi_awuser  [s_idx*AWUSER_WIDTH +: AWUSER_WIDTH];
      slaves_axi_mosi[s_idx].awvalid = to_s_axi_awvalid [s_idx*1            +: 1];
      to_s_axi_awready[s_idx*1+:1] = slaves_axi_miso[s_idx].awready;
      slaves_axi_mosi[s_idx].wdata   = to_s_axi_wdata   [s_idx*DATA_WIDTH   +: DATA_WIDTH];
      slaves_axi_mosi[s_idx].wstrb   = to_s_axi_wstrb   [s_idx*STRB_WIDTH   +: STRB_WIDTH];
      slaves_axi_mosi[s_idx].wlast   = to_s_axi_wlast   [s_idx*1            +: 1];
      slaves_axi_mosi[s_idx].wuser   = to_s_axi_wuser   [s_idx*WUSER_WIDTH  +: WUSER_WIDTH];
      slaves_axi_mosi[s_idx].wvalid  = to_s_axi_wvalid  [s_idx*1            +: 1];
      to_s_axi_wready[s_idx*1+:1]                     = slaves_axi_miso[s_idx].wready;
      to_s_axi_bid   [s_idx*ID_WIDTH+:ID_WIDTH]       = slaves_axi_miso[s_idx].bid;
      to_s_axi_bresp [s_idx*2+:2]                     = slaves_axi_miso[s_idx].bresp;
      to_s_axi_buser [s_idx*BUSER_WIDTH+:BUSER_WIDTH] = slaves_axi_miso[s_idx].buser;
      to_s_axi_bvalid[s_idx*1+:1]                     = slaves_axi_miso[s_idx].bvalid;
      slaves_axi_mosi[s_idx].bready   = to_s_axi_bready  [s_idx*1            +: 1];
      slaves_axi_mosi[s_idx].arid     = to_s_axi_arid    [s_idx*ID_WIDTH     +: ID_WIDTH];
      slaves_axi_mosi[s_idx].araddr   = to_s_axi_araddr  [s_idx*ADDR_WIDTH   +: ADDR_WIDTH];
      slaves_axi_mosi[s_idx].arlen    = to_s_axi_arlen   [s_idx*ALEN_WIDTH   +: ALEN_WIDTH];
      slaves_axi_mosi[s_idx].arsize   = axi_size_t'(to_s_axi_arsize  [s_idx*3            +: 3]);
      slaves_axi_mosi[s_idx].arburst  = axi_burst_t'(to_s_axi_arburst [s_idx*2            +: 2]);
      slaves_axi_mosi[s_idx].arlock   = to_s_axi_arlock  [s_idx*1            +: 1];
      slaves_axi_mosi[s_idx].arcache  = to_s_axi_arcache [s_idx*4            +: 4];
      slaves_axi_mosi[s_idx].arprot   = axi_prot_t'(to_s_axi_arprot  [s_idx*3            +: 3]);
      slaves_axi_mosi[s_idx].arqos    = to_s_axi_arqos   [s_idx*4            +: 4];
      slaves_axi_mosi[s_idx].aruser   = to_s_axi_aruser  [s_idx*ARUSER_WIDTH +: ARUSER_WIDTH];
      slaves_axi_mosi[s_idx].arvalid  = to_s_axi_arvalid [s_idx*1            +: 1];
      to_s_axi_arready[s_idx*1+:1]                    = slaves_axi_miso[s_idx].arready;
      to_s_axi_rid    [s_idx*ID_WIDTH+:ID_WIDTH]      = slaves_axi_miso[s_idx].rid;
      to_s_axi_rdata  [s_idx*DATA_WIDTH+:DATA_WIDTH]  = slaves_axi_miso[s_idx].rdata;
      to_s_axi_rresp  [s_idx*2+:2]                    = slaves_axi_miso[s_idx].rresp;
      to_s_axi_rlast  [s_idx*1+:1]                    = slaves_axi_miso[s_idx].rlast;
      to_s_axi_ruser  [s_idx*1+:1]                    = slaves_axi_miso[s_idx].ruser;
      to_s_axi_rvalid [s_idx*1+:1]                    = slaves_axi_miso[s_idx].rvalid;
      slaves_axi_mosi[s_idx].rready =  to_s_axi_rready [s_idx*1            +: 1];
    end
  end

  // Configuration:
  // M_BASE_ADDR = Configures the base address of the AXI slaves
  // M_ADDR_WIDTH = Configures the length of the addressing of the slaves based on multiples of 4KB
  // for instance, if we consider 5x slave with MM below + 2x Masters:
  //    _______________________________
  //  | 0x2000-0x3FFF | slave # 0 - 8KB |
  //  | 0x4000-0x5FFF | slave # 1 - 8KB |
  //  | 0x6000-0x6FFF | slave # 2 - 4KB |
  //    ⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻
  // .S_COUNT(2),
  // .M_COUNT(3),
  // .ADDR_WIDTH(16),
  // .M_REGIONS(1),
  // .M_BASE_ADDR({16'h6000, 16'h4000, 16'h2000}),
  // .M_ADDR_WIDTH({32'd12, 32'd13, 32'd13})
  //
  // More info:
  // https://github.com/alexforencich/verilog-axi/issues/16
  axi_interconnect #(
    .S_COUNT      (N_MASTERS),
    // Number of AXI outputs (master interfaces)
    .M_COUNT      (N_SLAVES),
    // Width of ID signal
    .ID_WIDTH     (1),
    // Number of regions per master interface
    .M_REGIONS    (1),
    // Width of address bus in bits
    .ADDR_WIDTH   (32),
    // Master interface base addresses
    // M_COUNT concatenated fields of M_REGIONS concatenated fields of ADDR_WIDTH bits
    // set to zero for default addressing based on M_ADDR_WIDTH
    .M_BASE_ADDR  (M_BASE_ADDR),
    // Master interface address widths
    // M_COUNT concatenated fields of M_REGIONS concatenated fields of 32 bits
    .M_ADDR_WIDTH (M_ADDR_WIDTH)
  ) u_axi_intcon (
    .clk          (clk),
    .rst          (~arst),
    // Masters
    .s_axi_awid     (from_m_axi_awid),
    .s_axi_awaddr   (from_m_axi_awaddr),
    .s_axi_awlen    (from_m_axi_awlen),
    .s_axi_awsize   (from_m_axi_awsize),
    .s_axi_awburst  (from_m_axi_awburst),
    .s_axi_awlock   (from_m_axi_awlock),
    .s_axi_awcache  (from_m_axi_awcache),
    .s_axi_awprot   (from_m_axi_awprot),
    .s_axi_awqos    (from_m_axi_awqos),
    .s_axi_awuser   (from_m_axi_awuser),
    .s_axi_awvalid  (from_m_axi_awvalid),
    .s_axi_awready  (from_m_axi_awready),
    .s_axi_wdata    (from_m_axi_wdata),
    .s_axi_wstrb    (from_m_axi_wstrb),
    .s_axi_wlast    (from_m_axi_wlast),
    .s_axi_wuser    (from_m_axi_wuser),
    .s_axi_wvalid   (from_m_axi_wvalid),
    .s_axi_wready   (from_m_axi_wready),
    .s_axi_bid      (from_m_axi_bid),
    .s_axi_bresp    (from_m_axi_bresp),
    .s_axi_buser    (from_m_axi_buser),
    .s_axi_bvalid   (from_m_axi_bvalid),
    .s_axi_bready   (from_m_axi_bready),
    .s_axi_arid     (from_m_axi_arid),
    .s_axi_araddr   (from_m_axi_araddr),
    .s_axi_arlen    (from_m_axi_arlen),
    .s_axi_arsize   (from_m_axi_arsize),
    .s_axi_arburst  (from_m_axi_arburst),
    .s_axi_arlock   (from_m_axi_arlock),
    .s_axi_arcache  (from_m_axi_arcache),
    .s_axi_arprot   (from_m_axi_arprot),
    .s_axi_arqos    (from_m_axi_arqos),
    .s_axi_aruser   (from_m_axi_aruser),
    .s_axi_arvalid  (from_m_axi_arvalid),
    .s_axi_arready  (from_m_axi_arready),
    .s_axi_rid      (from_m_axi_rid),
    .s_axi_rdata    (from_m_axi_rdata),
    .s_axi_rresp    (from_m_axi_rresp),
    .s_axi_rlast    (from_m_axi_rlast),
    .s_axi_ruser    (from_m_axi_ruser),
    .s_axi_rvalid   (from_m_axi_rvalid),
    .s_axi_rready   (from_m_axi_rready),
    // Slaves
    .m_axi_awid     (to_s_axi_awid),
    .m_axi_awaddr   (to_s_axi_awaddr),
    .m_axi_awlen    (to_s_axi_awlen),
    .m_axi_awsize   (to_s_axi_awsize),
    .m_axi_awburst  (to_s_axi_awburst),
    .m_axi_awlock   (to_s_axi_awlock),
    .m_axi_awcache  (to_s_axi_awcache),
    .m_axi_awprot   (to_s_axi_awprot),
    .m_axi_awqos    (to_s_axi_awqos),
    .m_axi_awregion (),
    .m_axi_awuser   (to_s_axi_awuser),
    .m_axi_awvalid  (to_s_axi_awvalid),
    .m_axi_awready  (to_s_axi_awready),
    .m_axi_wdata    (to_s_axi_wdata),
    .m_axi_wstrb    (to_s_axi_wstrb),
    .m_axi_wlast    (to_s_axi_wlast),
    .m_axi_wuser    (to_s_axi_wuser),
    .m_axi_wvalid   (to_s_axi_wvalid),
    .m_axi_wready   (to_s_axi_wready),
    .m_axi_bid      (to_s_axi_bid),
    .m_axi_bresp    (to_s_axi_bresp),
    .m_axi_buser    (to_s_axi_buser),
    .m_axi_bvalid   (to_s_axi_bvalid),
    .m_axi_bready   (to_s_axi_bready),
    .m_axi_arid     (to_s_axi_arid),
    .m_axi_araddr   (to_s_axi_araddr),
    .m_axi_arlen    (to_s_axi_arlen),
    .m_axi_arsize   (to_s_axi_arsize),
    .m_axi_arburst  (to_s_axi_arburst),
    .m_axi_arlock   (to_s_axi_arlock),
    .m_axi_arcache  (to_s_axi_arcache),
    .m_axi_arprot   (to_s_axi_arprot),
    .m_axi_arqos    (to_s_axi_arqos),
    .m_axi_arregion (),
    .m_axi_aruser   (to_s_axi_aruser),
    .m_axi_arvalid  (to_s_axi_arvalid),
    .m_axi_arready  (to_s_axi_arready),
    .m_axi_rid      (to_s_axi_rid),
    .m_axi_rdata    (to_s_axi_rdata),
    .m_axi_rresp    (to_s_axi_rresp),
    .m_axi_rlast    (to_s_axi_rlast),
    .m_axi_ruser    (to_s_axi_ruser),
    .m_axi_rvalid   (to_s_axi_rvalid),
    .m_axi_rready   (to_s_axi_rready)
  );

  /* verilator lint_on WIDTH */
endmodule
