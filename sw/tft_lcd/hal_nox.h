#ifndef _HAL_NOX_H_
#define _HAL_NOX_H_

#include <stdint.h>
#include "spi.h"

#define LCD_CS_PIN      0x99
#define LCD_DC_PIN      0xAA
#define LCD_RST_PIN     2
#define LCD_CS_PORT     3
#define LCD_DC_PORT     4
#define LCD_RST_PORT    5

#define GPIO_PIN_RESET  0x0
#define GPIO_PIN_SET    0x1
#define GPIOB           8

void HAL_GPIO_WritePin(uint8_t port, uint8_t pin, uint8_t val);
void HAL_SPI_Transmit(uint8_t spi, uint8_t *data, uint8_t size, uint8_t ign2);
void HAL_Delay(uint32_t ammount);

#endif
