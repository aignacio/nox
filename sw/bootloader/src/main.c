#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include "printf.h"
#include "riscv_csr_encoding.h"

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

volatile uint32_t* const addr_leds  = (uint32_t*) LEDS_ADDR;
volatile uint32_t* const addr_print = (uint32_t*) PRINT_ADDR;
volatile uint32_t* const uart_stats = (uint32_t*) UART_STATS;
volatile uint32_t* const uart_print = (uint32_t*) UART_TX;
volatile uint32_t* const uart_rx    = (uint32_t*) UART_RX;
volatile uint32_t* const uart_cfg   = (uint32_t*) UART_CFG;
volatile uint32_t* const rst_cfg    = (uint32_t*) RST_CFG;
volatile uint32_t* const err_cfg    = (uint32_t*) ERR_CFG;

uint8_t   gIdx_rx = 0;
uint8_t   gRx_chars[40];
bool      gFast_mode = false;
uint32_t  gFast_addr = 0x0;
bool      gError_lsu = false;

typedef struct {
  uint32_t addr;
  uint32_t data;
} s_req_t;

void _putchar(char character){
#ifdef REAL_UART
  while((*uart_stats & 0x10000) == 0);
  *uart_print = character;
#else
  *addr_print = character;
#endif
}

void print_help(void){
  printf("\n\r 1) Write txn fmt");
  printf("\n\r    wADDRESS/dDATA + [ENTER]");
  printf("\n\r    Example: w80001F00dDEADBEEF");
  printf("\n\r 2) Read txn fmt");
  printf("\n\r    rADDRESS + [ENTER]");
  printf("\n\r    Example: r80001F00");
  /*printf("\n\r 3) Print memory map");*/
  /*printf("\n\r    mm + [ENTER]");*/
  printf("\n\r 3) Fast mode");
  printf("\n\r    f + ADDRESS + [ENTER]");
  printf("\n\r    @DATA + [ENTER]");
  printf("\n\r    ...");
  printf("\n\r    e + [ENTER]");
  printf("\n\r [!] All addresses/data needs to be in hexadecimal");
  printf("\n\r> ");
}

void print_csrs(void){
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

void print_welcome(void){
  printf("\n\r");
  printf("\n\r  __    __            __    __         ______              ______   ");
  printf("\n\r |  \\  |  \\          |  \\  |  \\       /      \\            /      \\  ");
  printf("\n\r | $$\\ | $$  ______  | $$  | $$      |  $$$$$$\  ______  |  $$$$$$\\ ");
  printf("\n\r | $$$\\| $$ /      \\  \\$$\\/  $$      | $$___\\$$ /      \\ | $$   \\$$ ");
  printf("\n\r | $$$$\\ $$|  $$$$$$\\  >$$  $$        \\$$    \\ |  $$$$$$\\| $$       ");
  printf("\n\r | $$\\$$ $$| $$  | $$ /  $$$$\\        _\\$$$$$$\\| $$  | $$| $$   __  ");
  printf("\n\r | $$ \\$$$$| $$__/ $$|  $$ \\$$\\      |  \\__| $$| $$__/ $$| $$__/  \\ ");
  printf("\n\r | $$  \\$$$ \\$$    $$| $$  | $$       \\$$    $$ \\$$    $$ \\$$    $$ ");
  printf("\n\r  \\$$   \\$$  \\$$$$$$  \\$$   \\$$        \\$$$$$$   \\$$$$$$   \\$$$$$$  ");
  printf("\n\r");
  printf("\n\r NoX SoC UART Bootloader \n");
  print_csrs();
  printf("\n\r Freq. system:\t%d Hz",FREQ_SYSTEM);
  printf("\n\r UART Speed:\t%d bits/s",BR_UART);
  printf("\n\r Type h+[ENTER] for help!\n\r");
  printf("\n\r> ");
}

void print_cmd(void){
  printf("\n\r> UNKNOWN - Command received: ");
  for (int i=0;i<gIdx_rx;i++)
    printf("%c",gRx_chars[i]);
  printf(" -- Size[%d]",gIdx_rx);
  printf("\n\r> ");
}

// Extract address and data and convert
// from ASCII to unsigned integer
s_req_t getReq(void){
  s_req_t req;
  uint8_t addr[9], data[9];

  for (int i=0;i<8;i++){
    addr[i] = gRx_chars[i+1];
    data[i] = gRx_chars[i+10];
  }

  addr[8] = '\0';
  data[8] = '\0';

  req.addr = (uint32_t*)strtoul(addr, NULL, 16);
  req.data = (uint32_t*)strtoul(data, NULL, 16);

  return req;
}

void proc_single_write(void){
  // TODO: Need to check address boundaries first
  s_req_t write = getReq();
  volatile uint32_t *addr = write.addr;

  *(addr) = write.data;

  if (gError_lsu == true){
    printf("\n\r> Operation returned an error!");
  }
  else{
    printf("\n\r (Write) -> ADDR[%x] DATA[%x]", write.addr, write.data);
  }
  printf("\n\r> ");
}

void proc_single_read(){
  // TODO: Need to check address boundaries first
  s_req_t read = getReq();
  volatile uint32_t *addr = read.addr;

  read.data = *(addr);

  if (gError_lsu == true){
    printf("\n\r> Operation returned an error!");
  }
  else{
    printf("\n\r (Read) -> ADDR[%x] DATA[%x]", read.addr, read.data);
  }
  printf("\n\r> ");
}

void act_fast_mode(void){
  s_req_t fast_req = getReq();
  printf("\n\r> Burst Mode ON - Addr[%x]",fast_req.addr);
  printf("\n\r> ");
  gFast_mode = true;
  gFast_addr = fast_req.addr;
}

void proc_fast_mode(void){
  volatile uint32_t *addr = gFast_addr;
  uint8_t data[9];
  uint32_t buff;

  for (int i=0;i<8;i++)
    data[i] = gRx_chars[i+1];
  addr[8] = '\0';
  buff = (uint32_t*)strtoul(data, NULL, 16);
  *addr = buff;
  /*printf("\n\r (Fast Write) -> ADDR[%x] DATA[%x]", gFast_addr, buff);*/
  /*printf("\n\r> ");*/
  gFast_addr += 4;
}

void end_fast_mode(void){
  gFast_mode = false;
  printf("\n\r> Burst Mode OFF - Addr[%x]",gFast_addr);
  printf("\n\r> ");
}

bool parse_cmd(void){
  bool valid_cmd = false;

  switch(gRx_chars[0]){
    case 'h':
      if (gIdx_rx == 1){
        print_help();
        valid_cmd = true;
      }
    break;
    case 'w':
      if (gIdx_rx == 18){
        proc_single_write();
        valid_cmd = true;
      }
    break;
    case 'r':
      if (gIdx_rx == 9){
        proc_single_read();
        valid_cmd = true;
      }
    break;
    // Start fast mode
    case 'f':
      if (gIdx_rx == 9){
        act_fast_mode();
        valid_cmd = true;
      }
    break;
    case '@':
      if (gFast_mode == true){
        proc_fast_mode();
        valid_cmd = true;
      }
    break;
    // Turn off fast mode
    case 'e':
      if (gFast_mode == true){
        end_fast_mode();
        valid_cmd = true;
      }
    break;
  }
  return valid_cmd;
}

void check_input(uint8_t data){
  switch(data){
    case 13:
      if (parse_cmd() == false){
        print_cmd();
      }
      gIdx_rx = 0;
    break;
    case 127:
      if (gIdx_rx > 0) {
        gIdx_rx--;
        printf("%c", data);
      }
    break;
  }
}

void irq_m_ext_callback(void){
  uint8_t rx_data = *uart_rx;

  // If ( not an enter && not backspace)
  if ((rx_data != 13) && (rx_data != 127)){
    printf("%c", rx_data);
    gRx_chars[gIdx_rx++] = rx_data;
  }
  else {
    check_input(rx_data);
  }
}

int main(void) {
  /**err_cfg = 0x2929;*/
  // 50MHz / 115200 = 434
  *uart_cfg = FREQ_SYSTEM/BR_UART;
  print_welcome();
  set_csr(mie,1<<IRQ_M_EXT);
  set_csr(mstatus,MSTATUS_MIE);
  while(true);
}
