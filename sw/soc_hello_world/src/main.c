#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "printf.h"
#include "riscv_csr_encoding.h"

#define LEDS_ADDR   0xA001FC00
#define PRINT_ADDR  0xA001F800
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

#if 0
void _putchar(char character){
  *addr_print = character;
}
#else
void _putchar(char character){
  while((*uart_stats & 0x10000) == 0);
  *uart_print = character;
  /**addr_print = character;*/
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

  printf("\n  _   _       __  __  ");
  printf("\n | \\ | |  ___ \\ \\/ /  ");
  printf("\n |  \\| | / _ \\ \\  /   ");
  printf("\n | |\\  || (_) |/  \\   ");
  printf("\n |_| \\_| \\___//_/\\_\\  ");
  printf("\n NoX RISC-V Core RV32I \n");
  printf("\n CSRs:");
  printf("\n mstatus \t0x%x",mstatus_csr);
  printf("\n misa    \t0x%x",misa_csr);
  printf("\n mhartid \t0x%x",mhartid_csr);
  printf("\n mie     \t0x%x",mie_csr);
  printf("\n mip     \t0x%x",mip_csr);
  printf("\n mtvec   \t0x%x",mtvec_csr);
  printf("\n mepc    \t0x%x",mepc_csr);
  printf("\n mscratch\t0x%x",mscratch_csr);
  printf("\n mtval   \t0x%x",mtval_csr);
  printf("\n mcause  \t0x%x",mcause_csr);
  printf("\n cycle   \t%d",cycle);
  printf("\n");
}

int main(void) {
  uint8_t leds_out = 0x01;
  int i = 0;

  *addr_leds = leds_out;
  // 50MHz -> 115200
  /**uart_cfg = 49;*/
  /*print_logo();*/

  *uart_cfg = 434;
  print_logo();

  /**uart_cfg = 848;*/
  /*print_logo();*/

  /**uart_cfg = 654;*/
  /*print_logo();*/

  /**uart_cfg = 848;*/
  /*print_logo();*/

  while(true){
    if (i == 60000){
      i = 0;
      if (leds_out == 8)
        leds_out = 1;
      else
        leds_out = leds_out << 1;
      *addr_leds = leds_out;

      print_logo();
    }
    i++;
  }
}
