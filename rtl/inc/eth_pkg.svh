`ifndef _ETH_PKG_
`define _ETH_PKG_
  typedef logic [47:0] mac_addr_t;
  typedef logic [31:0] ip_addr_t;
  typedef logic [15:0] udp_length_t;
  typedef logic [31:0] subnet_mask_t;
  typedef logic [15:0] port_t;
  typedef logic [$clog2(INFIFO_KB_SIZE*1024):0] ptr_t;

  typedef struct packed {
    mac_addr_t    mac;
    ip_addr_t     ip;
    ip_addr_t     gateway;
    subnet_mask_t subnet_mask;
  } s_eth_cfg_t;

  typedef struct packed {
    mac_addr_t    mac;
    ip_addr_t     ip;
    udp_length_t  length;
    port_t        src_port;
    port_t        dst_port;
  } s_eth_udp_t;

  typedef struct packed {
    ptr_t         rd_ptr;
    ptr_t         wr_ptr;
    logic         empty;
    logic         full;
    logic         done;
  } s_fifo_st_t;

  typedef struct packed {
    logic         clear;
    logic         start;
    udp_length_t  length;
  } s_fifo_cmd_t;

  typedef enum logic [1:0] {
    IDLE_PKT_ST,
    STREAMING_PKT_ST,
    DONE_PKT_ST
  } fsm_pkt_t;

  `ifndef ETH_TARGET_FPGA_ARTY
  `ifndef ETH_TARGET_FPGA_NEXYSV
  `ifndef ETH_TARGET_FPGA_KINTEX
    `define    ETH_TARGET_FPGA_NEXYSV // ARTY, NEXYSV, KINTEX
  `endif
  `endif
  `endif

  localparam INFIFO_KB_SIZE                  = 4;
  localparam OUTFIFO_KB_SIZE                 = 1;
  localparam ETH_OT_FIFO                     = 4;

  localparam ARP_CACHE_ADDR_WIDTH            = 9;
  localparam ARP_REQUEST_RETRY_COUNT         = 4;
  localparam ARP_REQUEST_RETRY_INTERVAL      = 125000000*2;
  localparam ARP_REQUEST_TIMEOUT             = 125000000*30;
  localparam UDP_CHECKSUM_GEN_ENABLE         = 1;
  localparam UDP_CHECKSUM_PAYLOAD_FIFO_DEPTH = 2048;
  localparam UDP_CHECKSUM_HEADER_FIFO_DEPTH  = 8;
`endif
