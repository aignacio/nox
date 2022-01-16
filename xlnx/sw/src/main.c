#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#define LEDS_ADDR 0xD0000000

volatile uint32_t* const addr_leds = (uint32_t*) LEDS_ADDR;

int main(void) {
  int i = 0;
  uint8_t leds_out = 0x0F;

  while(true){
    if (i == 500000){
      i = 0;
      *addr_leds = leds_out;
      leds_out = ~leds_out;
    }
    i++;
  }
}
