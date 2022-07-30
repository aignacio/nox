#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "printf.h"
#include "riscv_csr_encoding.h"
#include "eth.h"
#include "eth_csr.h"

#define FREQ_SYSTEM     50000000
#define BR_UART         115200

//#define REAL_UART

#define ERR_CFG         0xFFFF0000
#define PRINT_ADDR      0xD0000008
#define LEDS_ADDR       0xD0000000
#define RST_CFG         0xC0000000
#define UART_TX         0xB000000C
#define UART_RX         0xB0000008
#define UART_STATS      0xB0000004
#define UART_CFG        0xB0000000
#define ETH_CFG         0x20000000

#define MTIMER_LSB      0xF0000000
#define MTIMER_MSB      0xF0000004
#define MTIMER_CMP_LSB  0xF0000008
#define MTIMER_CMP_MSB  0xF000000C

volatile uint32_t* const addr_leds  = (uint32_t*) LEDS_ADDR;
volatile uint32_t* const addr_print = (uint32_t*) PRINT_ADDR;
volatile uint32_t* const uart_stats = (uint32_t*) UART_STATS;
volatile uint32_t* const uart_print = (uint32_t*) UART_TX;
volatile uint32_t* const uart_rx    = (uint32_t*) UART_RX;
volatile uint32_t* const uart_cfg   = (uint32_t*) UART_CFG;
volatile uint32_t* const rst_cfg    = (uint32_t*) RST_CFG;
volatile uint32_t* const err_cfg    = (uint32_t*) ERR_CFG;
volatile uint32_t* const eth_cfg    = (uint32_t*) ETH_CFG;

volatile uint64_t* const mtimer     = (uint64_t*) MTIMER_LSB;
volatile uint64_t* const mtimer_cmp = (uint64_t*) MTIMER_CMP_LSB;

#ifdef UART_SIM
void _putchar(char character){
  *addr_print = character;
}
#else
void _putchar(char character){
  while((*uart_stats & 0x10000) == 0);
  *uart_print = character;
}
#endif

uint8_t gLEDsAddr = 0x20;
uint64_t gCounter = 0x00;
uint8_t str[100];

void irq_timer_callback(void){
  uint64_t mtime_half_second = *mtimer;
  mtime_half_second += 50000000;
  *mtimer_cmp = mtime_half_second;
  if (gLEDsAddr == 0x2) {
    gLEDsAddr = 0x20;
    *addr_leds = ~gLEDsAddr;
  }
  else {
    gLEDsAddr = (gLEDsAddr >> 1);
    *addr_leds = ~gLEDsAddr;
  }

  uint8_t    payload[] = {"Hello from NoX!!"};
  write_eth_udp_payload(payload,16);
  set_send_pkt();
  printf("\n\r Mtimer IRQ! - RD_PTR=%d WR_PTR=%d",get_infifo_rdptr(),get_infifo_wrptr());
}

void irq_udp_callback(void){
  printf("\n\r UDP pkt received!");
  clear_send_fifo_rd_ptr();
  set_send_pkt();
}

int main(void) {
  uint8_t leds_out = 0x01;
  int i = 0;

  // 50MHz / 115200 = 434
  *uart_cfg = FREQ_SYSTEM/BR_UART;
  printf("\n\r ------> Nao trave aqui");
  printf("\n\r ------> Eth CFG = %x",*eth_cfg);
  printf("\nETH_SEND_MAC_LOW  = %x", ETH_SEND_MAC_LOW);
  printf("\nETH_SEND_MAC_HIGH = %x", ETH_SEND_MAC_HIGH);

  /*********************************************/
  /*********************************************/
  mac_addr_t mac;
  ip_t       ip   = 0xc0a80182; // 192.168.1.130
  ip_t       gateway = 0xc0a80101; // 192.168.1.1
  mac.mac_address = 0x020000000000;
  set_local_mac_addr_cfg(mac);
  set_local_gateway_cfg(gateway);
  set_local_ip_addr_cfg(ip);
  /*uint8_t    payload[] = {"Hello from NoX!"};*/
  /*write_eth_udp_payload(payload,15);*/
  /*********************************************/
  /*********************************************/
  /*********************************************/
  /*********************************************/
  ip = 0xc0a8015a; // 192.168.1.90
  mac.mac_address = 0x00e04c000752;
  set_send_mac_addr_cfg(mac);
  set_send_ip_addr_cfg(ip);
  set_send_len(15);
  set_send_src_port(1234);
  set_send_dst_port(1234);
  /*set_send_pkt();*/
  /*********************************************/
  /*********************************************/

  uint64_t mtime_half_second = *mtimer;
  mtime_half_second += 25000000;
  *mtimer_cmp = mtime_half_second;

  set_csr(mstatus,MSTATUS_MIE);
  set_csr(mie,1<<IRQ_M_TIMER);
  set_csr(mie,1<<IRQ_M_SOFT);
  while(1){
    wfi();
  }
}
