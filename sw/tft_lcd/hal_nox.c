#include <stdint.h>
#include <stdbool.h>
#include "spi.h"
#include "hal_nox.h"

void HAL_GPIO_WritePin(uint8_t port, uint8_t pin, uint8_t val){
  switch(pin){
    case LCD_CS_PIN:  set_spi_slv(~val);
    case LCD_DC_PIN:  set_spi_gpio(val);
  }
}

void HAL_Delay(uint32_t ammount){
  for (uint32_t i=0;i<ammount;i++)
    asm volatile("nop");
}


void HAL_SPI_Transmit(uint8_t spi, uint8_t *data, uint8_t size, uint8_t timeout){
  for(uint8_t i=0;i<size;i++)
    send_spi_byte(*(data++));
}
