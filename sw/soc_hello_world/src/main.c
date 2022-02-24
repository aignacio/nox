#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "printf.h"
#include "riscv_csr_encoding.h"

#define LEDS_ADDR   0xA001FC00
#define PRINT_ADDR  0xA001F800

volatile uint32_t* const addr_leds = (uint32_t*) LEDS_ADDR;
volatile uint32_t* const addr_print = (uint32_t*) PRINT_ADDR;

void _putchar(char character){
  *addr_print = character;
}

int main(void) {
  int i = 0;
  int test = 0;
  int irq_type = 0;
  uint8_t leds_out = 0x01;
  int global = 0;
  int mstatus_csr   = read_csr(mstatus);
  int misa_csr      = read_csr(misa);
  int mhartid_csr   = read_csr(mhartid);
  /*int time = rdtime();*/
  //int cycle = rdcycle();

  printf("Hello_World!");
  *addr_leds = leds_out;
  /*set_csr(mstatus,MSTATUS_MIE);*/
  while(true){
    /*if (test%10 == 0){*/
      /*switch(irq_type){*/
        /*case 0:*/
          /*set_csr(mie,1<<IRQ_M_SOFT);*/
        /*break;*/
        /*case 1:*/
          /*set_csr(mie,1<<IRQ_M_TIMER);*/
        /*break;*/
        /*case 2:*/
          /*set_csr(mie,1<<IRQ_M_EXT);*/
        /*break;*/
      /*}*/
      /*[>asm volatile ("csrrsi x0,mie,8");<]*/
      /*[>asm volatile ("addi t6,t6,1");<]*/
      /*if (irq_type < 2){*/
        /*irq_type++;*/
      /*}*/
      /*else{*/
        /*irq_type = 0;*/
      /*}*/
    /*}*/
    // Illegal jump
    /*asm volatile (".word 0x02f71763");*/
    // Illegal instruction
    /*asm volatile (".word 0x0");*/

    printf("\n-->i=%d",i);
    if (i == 5){
      i = 0;

      if (leds_out == 8)
        leds_out = 1;
      else
        leds_out = leds_out << 1;

      *addr_leds = leds_out;
    }
    i++;
    test++;
  }
}
