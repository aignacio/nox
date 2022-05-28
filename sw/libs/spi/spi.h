#ifndef SPI_UTILS_H
#define SPI_UTILS_H

#define SPI_BASE_ADDR     0xE0000000
#define SPI_CFG_ADDR      SPI_BASE_ADDR
#define SPI_GPIO_ADDR     (SPI_BASE_ADDR+(1*4))
#define SPI_VERSION_ADDR  (SPI_BASE_ADDR+(2*4))
#define SPI_FIFO_IN_ADDR  (SPI_BASE_ADDR+(3*4))
#define SPI_FIFO_OUT_ADDR (SPI_BASE_ADDR+(4*4))

#define SPI_CPOL_MASK     (0x1<<0)
#define SPI_CPHA_MASK     (0x1<<1)
#define SPI_CLKDIV_MASK   (0xF<<2)
#define SPI_SLV_SEL_MASK  (0xF<<6)

#define formatSPIcfg(cfg) ((SPI_SLV_SEL_MASK & (cfg.slv_sel << 6)) | \
                           (SPI_CLKDIV_MASK  & (cfg.clk_div << 2)) | \
                           (SPI_CPHA_MASK    & (cfg.cpha    << 1)) | \
                           (SPI_CPOL_MASK    & (cfg.cpol    << 0)))

typedef union {
  uint32_t  read;
  char      string[5];
} spi_ver_t;

typedef struct {
  bool cpol;
  bool cpha;
  uint8_t clk_div;
  uint8_t slv_sel;
} spi_cfg_t;

spi_ver_t get_spi_version(void);
void      set_spi_cfg(spi_cfg_t cfg);
void      set_spi_gpio(uint32_t gpio_val);
uint32_t  get_spi_gpio(void);
void      send_spi_byte(uint8_t val);
uint8_t   get_spi_byte(void);
bool      empty_rd_byte(void);
uint8_t   get_spi_mode(uint8_t mode);
bool      set_spi_mode(uint8_t mode);
spi_cfg_t get_spi_cfg(void);
void      set_spi_clk(uint8_t clk_div);
void      set_spi_slv(uint8_t slv);

#endif
