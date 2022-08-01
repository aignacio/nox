#include <stdbool.h>
#include <stdint.h>
#include "eth_csr.h"
#include "eth.h"

volatile uint32_t* const eth_infifo            = (uint32_t*) ETH_INFIFO_ADDR;
volatile uint32_t* const eth_outfifo           = (uint32_t*) ETH_OUTFIFO_ADDR;

volatile uint32_t* const eth_csr_loc_mac_low   = (uint32_t*) ETH_LOC_MAC_LOW;
volatile uint32_t* const eth_csr_loc_mac_high  = (uint32_t*) ETH_LOC_MAC_HIGH;
volatile uint32_t* const eth_csr_loc_ip        = (uint32_t*) ETH_LOC_IP;
volatile uint32_t* const eth_csr_gateway_ip    = (uint32_t*) ETH_GATEWAY_IP;
volatile uint32_t* const eth_csr_subnet_mask   = (uint32_t*) ETH_SUBNET_MASK;

volatile uint32_t* const eth_csr_send_mac_low  = (uint32_t*) ETH_SEND_MAC_LOW;
volatile uint32_t* const eth_csr_send_mac_high = (uint32_t*) ETH_SEND_MAC_HIGH;
volatile uint32_t* const eth_csr_send_ip       = (uint32_t*) ETH_SEND_IP;
volatile uint32_t* const eth_csr_send_len      = (uint32_t*) ETH_SEND_UDP_LEN;
volatile uint32_t* const eth_csr_send_src_port = (uint32_t*) ETH_SEND_UDP_SRC_PORT;
volatile uint32_t* const eth_csr_send_dst_port = (uint32_t*) ETH_SEND_UDP_DST_PORT;
volatile uint32_t* const eth_csr_send_pkt      = (uint32_t*) ETH_SEND_PKT;
volatile uint32_t* const eth_csr_send_clear    = (uint32_t*) ETH_SEND_CLEAR;
volatile uint32_t* const eth_csr_recv_clear    = (uint32_t*) ETH_RECV_CLEAR;
volatile uint32_t* const eth_csr_send_rd_ptr   = (uint32_t*) ETH_SEND_RD_PTR;
volatile uint32_t* const eth_csr_send_wr_ptr   = (uint32_t*) ETH_SEND_WR_PTR;
volatile uint32_t* const eth_csr_recv_rd_ptr   = (uint32_t*) ETH_RECV_RD_PTR;
volatile uint32_t* const eth_csr_recv_wr_ptr   = (uint32_t*) ETH_RECV_WR_PTR;
volatile uint32_t* const eth_csr_udp_len       = (uint32_t*) ETH_RECV_UDP_LEN;
volatile uint32_t* const eth_csr_clear_irq     = (uint32_t*) ETH_CLEAR_IRQ;
volatile uint32_t* const eth_csr_enable_filter = (uint32_t*) ETH_FILTER_EN;
volatile uint32_t* const eth_csr_filter_port   = (uint32_t*) ETH_FILTER_PORT;
volatile uint32_t* const eth_csr_filter_ip     = (uint32_t*) ETH_FILTER_IP;

void eth_set_local_cfg(eth_local_cfg_t cfg){
  // MAC address
  uint32_t low  = cfg.mac_addr.val_b[2]<<16|cfg.mac_addr.val_b[1]<<8|cfg.mac_addr.val_b[0];
  uint32_t high = cfg.mac_addr.val_b[5]<<16|cfg.mac_addr.val_b[4]<<8|cfg.mac_addr.val_b[3];
  *eth_csr_loc_mac_low  = low;
  *eth_csr_loc_mac_high = high;
  // IPv4 addr.
  *eth_csr_loc_ip = cfg.ip_addr;
  // IPv4 addr. gateway
  *eth_csr_gateway_ip = cfg.ip_gateway;
  // Subnet Mask
  *eth_csr_subnet_mask = cfg.subnet_mask;
}

void eth_set_send_cfg(eth_cfg_t cfg){
  // MAC address
  uint32_t low  = cfg.mac_addr.val_b[2]<<16|cfg.mac_addr.val_b[1]<<8|cfg.mac_addr.val_b[0];
  uint32_t high = cfg.mac_addr.val_b[5]<<16|cfg.mac_addr.val_b[4]<<8|cfg.mac_addr.val_b[3];
  *eth_csr_send_mac_low  = low;
  *eth_csr_send_mac_high = high;
  // IPv4 addr.
  *eth_csr_send_ip = cfg.ip_addr;
  // UDP src port
  *eth_csr_send_src_port = cfg.src_port;
  // UDP dst port
  *eth_csr_send_dst_port = cfg.dst_port;
  // UDP pkt len
  *eth_csr_send_len = cfg.len;
}

void eth_set_filter(eth_filter_cfg_t cfg){
  *eth_csr_enable_filter = cfg.filter_en;
  *eth_csr_filter_port = cfg.udp_port;
  *eth_csr_filter_ip = cfg.ip_addr;
}

void eth_send_pkt(void){
  *eth_csr_send_pkt = 0x1;
}

void eth_clr_outfifo_ptr(void){
  *eth_csr_send_clear = 0x1;
}

void eth_clr_infifo_ptr(void){
  *eth_csr_recv_clear = 0x1;
}

void eth_write_infifo_data(uint8_t *msg, uint16_t len){
  uint32_t val;

  for (int i=0;i<len;i+=4){
    val = (*(msg+i+3)<<24)|(*(msg+i+2)<<16)|(*(msg+i+1)<<8)|*(msg+i);
    *eth_outfifo = val;
  }
}

fifo_ptr_t eth_outfifo_ptr(void){
  fifo_ptr_t fifo;
  fifo.wr_ptr = *eth_csr_send_wr_ptr;
  fifo.rd_ptr = *eth_csr_send_rd_ptr;
  return fifo;
}

fifo_ptr_t eth_infifo_ptr(void){
  fifo_ptr_t fifo;
  fifo.wr_ptr = *eth_csr_recv_wr_ptr;
  fifo.rd_ptr = *eth_csr_recv_rd_ptr;
  return fifo;
}

uint32_t eth_get_recv_len(void){
  return *eth_csr_udp_len;
}

uint32_t eth_recv_data(void){
  return *eth_infifo;
}

void eth_clr_irqs(void){
  *eth_csr_clear_irq = 0x1;
}
