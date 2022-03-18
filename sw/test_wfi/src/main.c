#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "printf.h"
#include "riscv_csr_encoding.h"

#define LEDS_ADDR   0xD0000000
#define PRINT_ADDR  0xA0000000

volatile uint32_t* const addr_leds = (uint32_t*) LEDS_ADDR;
volatile uint32_t* const addr_print = (uint32_t*) PRINT_ADDR;

void _putchar(char character){
  *addr_print = character;
}

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
  printf("\n\r Test WFI\n");
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
  int i = 0;
  int test = 0;
  int irq_type = 0;
  uint8_t leds_out = 0x01;
  int global = 0;

  /*int time = rdtime();*/

  /*printf("Hello_World Nox!");*/
  *addr_leds = leds_out;
  print_logo();
  /*set_csr(mie,1<<IRQ_M_EXT);*/
  /*set_csr(mie,1<<IRQ_M_SOFT);*/
  set_csr(mie,1<<IRQ_M_TIMER);
  set_csr(mstatus,MSTATUS_MIE);
  while(true){
    wfi();
  }
}
