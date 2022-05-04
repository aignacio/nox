#include <stdbool.h>
#include <stdint.h>
#include "spi.h"

volatile uint32_t* const spi_cfg      = (uint32_t*) SPI_CFG_ADDR;
volatile uint32_t* const spi_gpio     = (uint32_t*) SPI_GPIO_ADDR;
volatile uint32_t* const spi_version  = (uint32_t*) SPI_VERSION_ADDR;
volatile uint32_t* const spi_fifo_in  = (uint32_t*) SPI_FIFO_IN_ADDR;
volatile uint32_t* const spi_fifo_out = (uint32_t*) SPI_FIFO_OUT_ADDR;

spi_cfg_t gSPIcfg = {.cpol = 0,
                     .cpha = 0,
                     .clk_div = 15,
                     .slv_sel = 0
};

uint8_t   gSPImode;

spi_ver_t get_spi_version(void){
  spi_ver_t version_val;
  version_val.read = *spi_version;
  version_val.string[4] = '\0';
  return version_val;
}

spi_cfg_t get_spi_cfg(void){
  return gSPIcfg;
}

void set_spi_cfg(spi_cfg_t cfg){
  *spi_cfg = formatSPIcfg(cfg);
}

void set_spi_clk(uint8_t clk_div){
  gSPIcfg.clk_div = clk_div;
  *spi_cfg = formatSPIcfg(gSPIcfg);
}

void set_spi_slv(uint8_t slv){
  gSPIcfg.slv_sel = slv;
  *spi_cfg = formatSPIcfg(gSPIcfg);
}

uint8_t get_spi_mode(uint8_t mode){
  return gSPImode;
}

bool set_spi_mode(uint8_t mode){
  switch(mode){
    case 0:
      gSPIcfg.cpol = 0;
      gSPIcfg.cpha = 0;
			break;
    case 1:
      gSPIcfg.cpol = 0;
      gSPIcfg.cpha = 1;
			break;
    case 2:
      gSPIcfg.cpol = 1;
      gSPIcfg.cpha = 0;
			break;
    case 3:
      gSPIcfg.cpol = 1;
      gSPIcfg.cpha = 1;
			break;
  	default:
      return false;
  }
  gSPImode = mode;
  *spi_cfg = formatSPIcfg(gSPIcfg);
  return true;
}

void set_spi_gpio(uint32_t gpio_val){
  *spi_gpio = gpio_val;
}

uint32_t get_spi_gpio(void){
  return *spi_gpio;
}

void send_spi_byte(uint8_t val){
  *spi_fifo_in = val;
}

//uint8_t get_spi_byte(uint8_t val){
//  send_spi_byte(val);
//  return *spi_fifo_out;
//}

uint8_t get_spi_byte(void){
  return *spi_fifo_out;
}

bool empty_rd_byte(void){
  uint8_t buff;
  for (int i=0;i<2;i++)
    buff = *spi_fifo_out;
  return true;
}
