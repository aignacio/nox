#ifndef ETH_H
#define ETH_H

#define ETH_INFIFO_ADDR       0x30000000
#define ETH_OUTFIFO_ADDR      0x40000000
#define ETH_CSR_ADDR          0x20000000

#define ETH_LOC_MAC_LOW       (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_ETH_MAC_LOW_BYTE_OFFSET)
#define ETH_LOC_MAC_HIGH      (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_ETH_MAC_HIGH_BYTE_OFFSET)
#define ETH_LOC_IP            (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_ETH_IP_BYTE_OFFSET)
#define ETH_GATEWAY_IP        (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_GATEWAY_IP_BYTE_OFFSET)
#define ETH_SUBNET_MASK       (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_SUBNET_MASK_BYTE_OFFSET)

#define ETH_SEND_MAC_LOW      (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_SEND_MAC_LOW_BYTE_OFFSET)
#define ETH_SEND_MAC_HIGH     (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_SEND_MAC_HIGH_BYTE_OFFSET)
#define ETH_SEND_IP           (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_SEND_IP_BYTE_OFFSET)
#define ETH_SEND_UDP_LEN      (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_SEND_UDP_LENGTH_BYTE_OFFSET)
#define ETH_SEND_UDP_SRC_PORT (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_SEND_SRC_PORT_BYTE_OFFSET)
#define ETH_SEND_UDP_DST_PORT (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_SEND_DST_PORT_BYTE_OFFSET)
#define ETH_SEND_PKT          (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_SEND_PKT_BYTE_OFFSET)
#define ETH_SEND_CLEAR        (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_SEND_FIFO_CLEAR_BYTE_OFFSET)
#define ETH_RECV_CLEAR        (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_RECV_FIFO_CLEAR_BYTE_OFFSET)
#define ETH_SEND_WR_PTR       (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_SEND_FIFO_WR_PTR_BYTE_OFFSET)
#define ETH_SEND_RD_PTR       (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_SEND_FIFO_RD_PTR_BYTE_OFFSET)
#define ETH_RECV_WR_PTR       (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_RECV_FIFO_WR_PTR_BYTE_OFFSET)
#define ETH_RECV_RD_PTR       (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_RECV_FIFO_RD_PTR_BYTE_OFFSET)
#define ETH_RECV_UDP_LEN      (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_RECV_UDP_LENGTH_BYTE_OFFSET)
#define ETH_CLEAR_IRQ         (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_CLEAR_IRQ_BYTE_OFFSET)

typedef uint32_t ip_t;
typedef uint32_t sbm_t;
typedef uint16_t udp_port_t;
typedef uint16_t udp_len_t;

typedef union {
  uint64_t  val;
  uint8_t   val_b[8];
} mac_addr_t;

typedef struct {
  mac_addr_t  mac_addr;
  ip_t        ip_addr;
  ip_t        ip_gateway;
  sbm_t       subnet_mask;
} eth_local_cfg_t;

typedef struct {
  mac_addr_t  mac_addr;
  ip_t        ip_addr;
  udp_port_t  src_port;
  udp_port_t  dst_port;
  udp_len_t   len;
} eth_cfg_t;

// Prototypes
void eth_set_local_cfg(eth_local_cfg_t cfg);
void eth_set_send_cfg(eth_cfg_t cfg);

void write_eth_udp_payload(uint8_t *msg, uint16_t len);
void set_send_pkt(void);
void clear_send_fifo_ptr(void);
void clear_recv_fifo_ptr(void);
uint32_t get_infifo_wrptr(void);
uint32_t get_infifo_rdptr(void);
uint32_t get_outfifo_wrptr(void);
uint32_t get_outfifo_rdptr(void);
uint32_t get_infifo_data(void);
uint32_t get_udp_length_recv(void);
void clear_irq_eth(void);
#endif
