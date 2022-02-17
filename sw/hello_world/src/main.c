#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "riscv_csr_encoding.h"

#define LEDS_ADDR 0xD0000000

volatile uint32_t* const addr_leds = (uint32_t*) LEDS_ADDR;

uint32_t read_mbox(uint32_t addr, uint8_t hsize){
  uint32_t val_mbox = 0;
  uint32_t mbox_aligned_addr = addr & 0xFFFFFFFC;
  uint8_t  offset = addr & 0x3;

  if (hsize){
    switch(offset){
      case 0:
        asm volatile("la t1,0"); // Clear t1
        asm volatile("lw t0, 0(%[mbx])"::[mbx]"r"(&mbox_aligned_addr));
        asm volatile("lh t1, 0(t0)");
        asm volatile("sw t1, 0(%[val])"::[val]"r"(&val_mbox));
        break;
      case 2:
        asm volatile("la t1,0"); // Clear t1
        asm volatile("lw t0, 0(%[mbx])"::[mbx]"r"(&mbox_aligned_addr));
        asm volatile("lh t1, 1(t0)");
        asm volatile("sw t1, 0(%[val])"::[val]"r"(&val_mbox));
        break;
      default:
        return 0;
        break;
    }
  }
  else {
    switch(offset){
      case 0:
        asm volatile("la t1,0"); // Clear t1
        asm volatile("lw t0, 0(%[mbx])"::[mbx]"r"(&mbox_aligned_addr));
        asm volatile("lb t1, 0(t0)");
        asm volatile("sw t1, 0(%[val])"::[val]"r"(&val_mbox));
        break;
      case 1:
        asm volatile("la t1,0"); // Clear t1
        asm volatile("lw t0, 0(%[mbx])"::[mbx]"r"(&mbox_aligned_addr));
        asm volatile("lb t1, 1(t0)");
        asm volatile("sw t1, 0(%[val])"::[val]"r"(&val_mbox));
        break;
      case 2:
        asm volatile("la t1,0"); // Clear t1
        asm volatile("lw t0, 0(%[mbx])"::[mbx]"r"(&mbox_aligned_addr));
        asm volatile("lb t1, 2(t0)");
        asm volatile("sw t1, 0(%[val])"::[val]"r"(&val_mbox));
        break;
      case 3:
        asm volatile("la t1,0"); // Clear t1
        asm volatile("lw t0, 0(%[mbx])"::[mbx]"r"(&mbox_aligned_addr));
        asm volatile("lb t1, 3(t0)");
        asm volatile("sw t1, 0(%[val])"::[val]"r"(&val_mbox));
        break;
      default:
        return 0;
        break;
    }
  }

  return val_mbox;
}

int main(void) {
  int i = 0;
  int test = 0;
  uint8_t leds_out = 0x0F;

  /*uint32_t read_byte_0 = read_mbox(0x20000000, 0);*/
  /*uint32_t read_byte_1 = read_mbox(0x20000001, 0);*/
  /*uint32_t read_byte_2 = read_mbox(0x20000002, 0);*/
  /*uint32_t read_byte_3 = read_mbox(0x20000003, 0);*/
  /*uint32_t read_hword_0 = read_mbox(0x20000000, 1);*/
  /*uint32_t read_hword_1 = read_mbox(0x20000004, 1);*/

  int mstatus_csr   = read_csr(mstatus);
  int misa_csr      = read_csr(misa);
  int mhartid_csr   = read_csr(mhartid);
  //write_csr(mstatus, "TEST");
  //int tmp = swap_csr(mstatus, "OLA!");
  /*int time = rdtime();*/
  //int cycle = rdcycle();

  *addr_leds = leds_out;
  while(true){
//    if (test == 3){
//      test++;
//      asm volatile("ebreak");
//    }
    asm volatile (".word 0x2f71763");
    if (i == 10){
      test++;
      i = 0;
      *addr_leds = leds_out;
      leds_out = ~leds_out;
    }
    i++;
  }
}
