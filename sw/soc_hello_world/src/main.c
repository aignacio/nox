#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "printf.h"
#include "riscv_csr_encoding.h"
#include "tft_lcd.h"

#define FREQ_SYSTEM 50000000
#define BR_UART     115200
#define REAL_UART

#define ERR_CFG     0xFFFF0000
#define PRINT_ADDR  0xD0000008
#define LEDS_ADDR   0xD0000000
#define RST_CFG     0xC0000000
#define UART_TX     0xB000000C
#define UART_RX     0xB0000008
#define UART_STATS  0xB0000004
#define UART_CFG    0xB0000000

#define MTIMER_LSB      0xF0000000
#define MTIMER_MSB      0xF0000004
#define MTIMER_CMP_LSB  0xF0000008
#define MTIMER_CMP_MSB  0xF000000C

volatile uint32_t* const addr_leds  = (uint32_t*) LEDS_ADDR;
volatile uint32_t* const addr_print = (uint32_t*) PRINT_ADDR;
volatile uint32_t* const uart_stats = (uint32_t*) UART_STATS;
volatile uint32_t* const uart_print = (uint32_t*) UART_TX;
volatile uint32_t* const uart_rx    = (uint32_t*) UART_RX;
volatile uint32_t* const uart_cfg   = (uint32_t*) UART_CFG;
volatile uint32_t* const rst_cfg    = (uint32_t*) RST_CFG;
volatile uint32_t* const err_cfg    = (uint32_t*) ERR_CFG;

volatile uint64_t* const mtimer     = (uint64_t*) MTIMER_LSB;
volatile uint64_t* const mtimer_cmp = (uint64_t*) MTIMER_CMP_LSB;

#define LCD_EN

#ifndef REAL_UART
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
  printf("\n\r NoX SoC RISC-V Core RV32I \n");
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

uint8_t gLEDsAddr = 0x00;
uint64_t gCounter = 0x00;
uint8_t str[100];

void irq_timer_callback(void){
  printf("\n\r ------> MTIMER IRQ!");
  uint64_t mtime_half_second = *mtimer;
  mtime_half_second += 2500000;
  *mtimer_cmp = mtime_half_second;
  gLEDsAddr ^= 0xff;
  *addr_leds = gLEDsAddr;
  sprintf(str, "%u", gCounter++);
  ILI9341_Draw_Text(str, 10, 110, WHITE, 2, BLACK);
}

int main(void) {
  uint8_t leds_out = 0x01;
  int i = 0;

  // 50MHz / 115200 = 434
  *uart_cfg = FREQ_SYSTEM/BR_UART;
  /*print_logo();*/
  printf("\n\r Hello....");
  set_csr(mstatus,MSTATUS_MIE);
#ifndef LCD_EN
  uint64_t mtime_half_second = *mtimer;
  mtime_half_second += 25000000;
  *mtimer_cmp = mtime_half_second;

  while(1){
    /*printf("\n\rMtimer: %d",*mtimer);*/
    wfi();
  }
#else
  uint64_t mtime_half_second = *mtimer;
  mtime_half_second += 25000000;
  *mtimer_cmp = mtime_half_second;

  ILI9341_Init();
  ILI9341_Set_Rotation(SCREEN_HORIZONTAL_1);
  ILI9341_Fill_Screen(ORANGE);
  ILI9341_Draw_Text("NoX SoC", 10, 20, WHITE, 3, BLACK);
  ILI9341_Draw_Text("-> mcycle:", 10, 80, WHITE, 2, BLACK);
  set_csr(mie,1<<IRQ_M_TIMER);
  while(1){
    wfi();
  }
#endif
}
