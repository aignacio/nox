`ifndef _CORE_BUS_PKG_
`define _CORE_BUS_PKG_
  //package core_bus_pkg;

  `ifndef CB_ADDR_WIDTH
    `define CB_ADDR_WIDTH         32
  `endif

  `ifndef CB_DATA_WIDTH
    `define CB_DATA_WIDTH         32
  `endif

  typedef logic [`CB_ADDR_WIDTH-1:0] cb_addr_t;
  typedef logic [`CB_DATA_WIDTH-1:0] cb_data_t;
  typedef logic [(`CB_DATA_WIDTH/8)-1:0] cb_strb_t;

  typedef enum logic [1:0] {
    CB_BYTE,
    CB_HALF_WORD,
    CB_WORD
  } cb_size_t;

  typedef enum logic [1:0] {
    CB_OKAY,
    CB_EXOKAY,
    CB_SLVERR,
    CB_DECERR
  } cb_error_t;

  typedef struct packed {
    // Write Addr channel
    logic       wr_addr_ready;
    // Write Data channel
    logic       wr_data_ready;
    // Write Response channel
    cb_error_t  wr_resp_error;
    logic       wr_resp_valid;
    // Read addr channel
    logic       rd_addr_ready;
    // Read data channel
    cb_data_t   rd_data;
    cb_error_t  rd_resp;
    logic       rd_valid;
  } s_cb_miso_t;

  typedef struct packed {
    // Write Address channel
    cb_addr_t   wr_addr;
    cb_size_t   wr_size;
    logic       wr_addr_valid;
    // Write Data channel
    cb_data_t   wr_data;
    cb_strb_t   wr_strobe;
    logic       wr_data_valid;
    // Write Response channel
    logic       wr_resp_ready;
    // Read Address channel
    cb_addr_t   rd_addr;
    cb_size_t   rd_size;
    logic       rd_addr_valid;
    // Read Data channel
    logic       rd_ready;
  } s_cb_mosi_t;

  //endpackage
`endif

