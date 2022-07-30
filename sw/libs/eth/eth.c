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
volatile uint32_t* const eth_csr_send_rd_ptr   = (uint32_t*) ETH_SEND_RD_PTR;
volatile uint32_t* const eth_csr_send_wr_ptr   = (uint32_t*) ETH_SEND_WR_PTR;

void set_local_mac_addr_cfg(mac_addr_t mac){
  uint32_t low  = mac.mcb[2]<<16|mac.mcb[1]<<8|mac.mcb[0];
  uint32_t high = mac.mcb[5]<<16|mac.mcb[4]<<8|mac.mcb[3];
  *eth_csr_loc_mac_low  = low;
  *eth_csr_loc_mac_high = high;
}

void set_local_ip_addr_cfg(ip_t ip){
  *eth_csr_loc_ip = ip;
}

void set_local_gateway_cfg(ip_t ip){
  *eth_csr_gateway_ip = ip;
}

void set_local_mask_cfg(ip_t mask){
  *eth_csr_subnet_mask = mask;
}

void set_send_mac_addr_cfg(mac_addr_t mac){
  uint32_t low  = mac.mcb[2]<<16|mac.mcb[1]<<8|mac.mcb[0];
  uint32_t high = mac.mcb[5]<<16|mac.mcb[4]<<8|mac.mcb[3];
  *eth_csr_send_mac_low  = low;
  *eth_csr_send_mac_high = high;
}

void set_send_ip_addr_cfg(ip_t ip){
  *eth_csr_send_ip = ip;
}

void set_send_len(uint32_t len){
  *eth_csr_send_len = len;
}

void set_send_src_port(uint32_t port){
  *eth_csr_send_src_port = port;
}

void set_send_dst_port(uint32_t port){
  *eth_csr_send_dst_port = port;
}

void set_send_pkt(void){
  *eth_csr_send_pkt = 0x1;
}

void clear_send_fifo_rd_ptr(void){
  *eth_csr_send_clear = 0x1;
}

void write_eth_udp_payload(uint8_t *msg, uint16_t len){
  uint32_t val;

  for (int i=0;i<len;i+=4){
    val = (*(msg+i+3)<<24)|(*(msg+i+2)<<16)|(*(msg+i+1)<<8)|*(msg+i);
    *eth_outfifo = val;
  }
}

uint32_t get_infifo_wrptr(void){
  return *eth_csr_send_wr_ptr;
}

uint32_t get_infifo_rdptr(void){
  return *eth_csr_send_rd_ptr;
}
