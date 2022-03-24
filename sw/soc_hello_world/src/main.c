#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "printf.h"
#include "riscv_csr_encoding.h"

#define FREQ_SYSTEM 50000000
#define BR_UART     115200

/*#define FREQ_SYSTEM 100000000*/
/*#define BR_UART     230400*/
#define REAL_UART

#define ERR_CFG     0xFFFF0000
#define PRINT_ADDR  0xD0000008
#define LEDS_ADDR   0xD0000000
#define RST_CFG     0xC0000000
#define UART_TX     0xB000000C
#define UART_RX     0xB0000008
#define UART_STATS  0xB0000004
#define UART_CFG    0xB0000000

volatile uint32_t* const addr_leds  = (uint32_t*) LEDS_ADDR;
volatile uint32_t* const addr_print = (uint32_t*) PRINT_ADDR;
volatile uint32_t* const uart_stats = (uint32_t*) UART_STATS;
volatile uint32_t* const uart_print = (uint32_t*) UART_TX;
volatile uint32_t* const uart_rx    = (uint32_t*) UART_RX;
volatile uint32_t* const uart_cfg   = (uint32_t*) UART_CFG;
volatile uint32_t* const rst_cfg    = (uint32_t*) RST_CFG;
volatile uint32_t* const err_cfg    = (uint32_t*) ERR_CFG;

#if 0
void _putchar(char character){
  *addr_print = character;
}
#else
void _putchar(char character){
  while((*uart_stats & 0x10000) == 0);
  *uart_print = character;
}

#endif
void print_logo(void){
  int mstatus_csr  = read_csr(mstatus);
  int misa_csr     = read_csr(misa);
  int mhartid_csr  = read_csr(mhartid);
  int mie_csr      = read_csr(mie);
  int mtvec_csr    = read_csr(mtvec);
  int mepc_csr     = read_csr(mepc);
  int mscratch_csr = read_csr(mscratch);
  int mtval_csr    = read_csr(mtval);
  int mcause_csr   = read_csr(mcause);
  int mip_csr      = read_csr(mip);
  int cycle = rdcycle();

  printf("\n\r  _   _       __  __  ");
  printf("\n\r | \\ | |  ___ \\ \\/ /  ");
  printf("\n\r |  \\| | / _ \\ \\  /   ");
  printf("\n\r | |\\  || (_) |/  \\   ");
  printf("\n\r |_| \\_| \\___//_/\\_\\  ");
  printf("\n\r NoX RISC-V Core RV32I \n");
  printf("\n\r CSRs:");
  printf("\n\r mstatus \t0x%x",mstatus_csr);
  printf("\n\r misa    \t0x%x",misa_csr);
  printf("\n\r mhartid \t0x%x",mhartid_csr);
  printf("\n\r mie     \t0x%x",mie_csr);
  printf("\n\r mip     \t0x%x",mip_csr);
  printf("\n\r mtvec   \t0x%x",mtvec_csr);
  printf("\n\r mepc    \t0x%x",mepc_csr);
  printf("\n\r mscratch\t0x%x",mscratch_csr);
  printf("\n\r mtval   \t0x%x",mtval_csr);
  printf("\n\r mcause  \t0x%x",mcause_csr);
  printf("\n\r cycle   \t%d",cycle);
  printf("\n\r");
}

int main(void) {
  uint8_t leds_out = 0x01;
  int i = 0;

  /**addr_leds = leds_out;*/
  // 50MHz / 115200 = 434
  *uart_cfg = FREQ_SYSTEM/BR_UART;
  print_logo();

  while(true);
  /*{*/
    /*if (i == 60000){*/
      /*i = 0;*/
      /*if (leds_out == 8)*/
        /*leds_out = 1;*/
      /*else*/
        /*leds_out = leds_out << 1;*/
      /**addr_leds = leds_out;*/

      /*print_logo();*/
    /*}*/
    /*i++;*/
  /*}*/
}
