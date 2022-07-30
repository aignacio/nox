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
#define ETH_SEND_WR_PTR       (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_SEND_FIFO_WR_PTR_BYTE_OFFSET)
#define ETH_SEND_RD_PTR       (uint32_t*)(ETH_CSR_ADDR+ETH_CSR_SEND_FIFO_RD_PTR_BYTE_OFFSET)

typedef union {
  uint64_t  mac_address;
  uint8_t   mcb[8];
} mac_addr_t;

typedef uint32_t ip_t;

void set_send_mac_addr_cfg(mac_addr_t mac);
void set_send_ip_addr_cfg(ip_t ip);
void set_send_len(uint32_t len);
void set_send_src_port(uint32_t port);
void set_send_dst_port(uint32_t port);
void write_eth_udp_payload(uint8_t *msg, uint16_t len);
void set_send_pkt(void);
void clear_send_fifo_rd_ptr(void);
void set_local_ip_addr_cfg(ip_t ip);
void set_local_mac_addr_cfg(mac_addr_t mac);
void set_local_mask_cfg(ip_t mask);
void set_local_gateway_cfg(ip_t ip);
uint32_t get_infifo_wrptr(void);
uint32_t get_infifo_rdptr(void);

#endif
