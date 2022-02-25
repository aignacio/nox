`ifndef _AHB_PKG_
`define _AHB_PKG_
  //package ahb_pkg;
  //endpackage
  `ifndef AHB_ADDR_WIDTH
    `define AHB_ADDR_WIDTH    32
  `endif

  `ifndef AHB_DATA_WIDTH
    `define AHB_DATA_WIDTH    32
  `endif

  `ifndef AHB_HBURST_WIDTH
    `define AHB_HBURST_WIDTH  3
  `endif

  `ifndef AHB_HPROT_WIDTH
    `define AHB_HPROT_WIDTH   7
  `endif

  `ifndef AHB_HSIZE_WIDTH
    `define AHB_HSIZE_WIDTH   3
  `endif

  `ifndef AHB_HEXC_WIDTH
    `define AHB_HEXC_WIDTH    4
  `endif

  `ifndef AHB_HTRANS_WIDTH
    `define AHB_HTRANS_WIDTH  2
  `endif

  `ifndef AHB_HMASTER_WIDTH
    `define AHB_HMASTER_WIDTH 4
  `endif

  typedef logic [`AHB_ADDR_WIDTH-1:0]     ahb_addr_t;
  typedef logic [`AHB_HPROT_WIDTH-1:0]    ahb_prot_t;
  typedef logic [`AHB_HMASTER_WIDTH-1:0]  ahb_master_t;
  typedef logic [`AHB_DATA_WIDTH-1:0]     ahb_data_t;
  //typedef logic ahb_mastlock_t;
  //typedef logic ahb_nonsec_t;
  //typedef logic ahb_excl_t;
  //typedef logic ahb_write_t;

  typedef enum logic [`AHB_HTRANS_WIDTH-1:0] {
    AHB_IDLE,
    AHB_BUSY,
    AHB_NONSEQUENTIAL,
    AHB_SEQUENTIAL
  } ahb_trans_t;

  typedef enum logic [`AHB_HBURST_WIDTH-1:0] {
    AHB_SINGLE,
    AHB_INCR,
    AHB_WRAP4,
    AHB_INCR4,
    AHB_WRAP8,
    AHB_INCR8,
    AHB_WRAP16,
    AHB_INCR16
  } ahb_burst_t;

  typedef enum logic [`AHB_HSIZE_WIDTH-1:0] {
    AHB_SZ_BYTE,
    AHB_SZ_HWORD,
    AHB_SZ_WORD,
    AHB_SZ_DWORD,
    AHB_SZ_4WORD,
    AHB_SZ_8WORD,
    AHB_SZ_512B,
    AHB_SZ_1024B
  } ahb_size_t;

  typedef struct packed {
    // Globals
    logic           hclk;
    logic           hresetn;
  } s_ahb_glb_t;

  typedef struct packed {
    ahb_data_t      hrdata;
    logic           hready;
    logic           hresp;
    logic           hexokay;
  } s_ahb_miso_t;

  typedef struct packed {
    ahb_addr_t      haddr;
    ahb_burst_t     hburst;
    logic           hmastlock;
    ahb_prot_t      hprot;
    ahb_size_t      hsize;
    logic           hnonsec;
    logic           hexcl;
    ahb_master_t    hmaster;
    ahb_trans_t     htrans;
    ahb_data_t      hwdata;
    logic           hwrite;
    logic           hsel;
  } s_ahb_mosi_t;
`endif
