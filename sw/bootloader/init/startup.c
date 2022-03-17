/**
 * RISC-V bootup test
 * Author: Daniele Lacamera <root@danielinux.net>
 * Modified by: Anderson Ignacio <anderson@aignacio.com>
 *
 * MIT License
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include <stdint.h>
#include <stdbool.h>
#include "riscv_csr_encoding.h"
#include "printf.h"

/*volatile uint32_t* const mtime_addr = (uint32_t*) MTIME_ADDR;*/

extern void trap_entry(void);
extern void trap_exit(void);

extern uint32_t  _start_vector;
extern uint32_t  _stored_data;
extern uint32_t  _start_data;
extern uint32_t  _end_data;
extern uint32_t  _start_bss;
extern uint32_t  _end_bss;
extern uint32_t  _end_stack;
extern uint32_t  _start_heap;
extern uint32_t  _my_global_pointer;

static int zeroed_variable_in_bss;
static int initialized_variable_in_data = 42;

extern void    irq_m_ext_callback(void);
extern void    main(void);
extern uint8_t gIdx_rx;
extern bool    gError_lsu;

void __attribute__((section(".init"),naked)) _reset(void) {
    register uint32_t *src, *dst;

    // asm volatile("la gp, _my_global_pointer");
    // asm volatile("la sp, _end_stack");
    /* Set up vectored interrupt, with starting at offset 0x100 */
    asm volatile("csrw mtvec, %0":: "r"((uint8_t *)(&_start_vector) + 1));

    src = (uint32_t *) &_stored_data;
    dst = (uint32_t *) &_start_data;

    /* Copy the .data section from flash to RAM. */
    while (dst < (uint32_t *)&_end_data) {
        *dst = *src;
        dst++;
        src++;
    }

    /* Initialize the BSS section to 0 */
    dst = &_start_bss;
    while (dst < (uint32_t *)&_end_bss) {
        *dst = 0U;
        dst++;
    }

    /* Run the program! */
    main();
}

void isr_synctrap(void)
{
  /*uint32_t mepc_return = read_csr(mepc)+0x4;*/
  uint32_t mepc_return = read_csr(mepc)+0x8;
  uint32_t mcause_csr  = read_csr(mcause);
  // If not vectored IRQ, do not add 4 to the MEPC
  write_csr(mepc, mepc_return);
  printf("\n\r[!] Sync. trap - MCAUSE = %x / MEPC = %x", mcause_csr, mepc_return);
  if (mcause_csr == 7){
    printf("\n\r[LSU] Store/AMO access fault");
    gError_lsu = true;
  }
  else if (mcause_csr == 5){
    printf("\n\r[LSU] Load access fault");
    gError_lsu = true;
  }
}

// Using the attr below it'll bkp a5 and use
// mret in the return, as we do that manually
// in asm, it's not needed to use this
/*__attribute__ ((interrupt ("machine"))) */
void __attribute__((weak)) isr_m_software(void)
{
  write_csr(mip, (0 << IRQ_M_SOFT));
  printf("\n\r[ASYNC TRAP] IRQ Software");
}

void __attribute__((weak)) isr_m_timer(void)
{
  write_csr(mip, (0 << IRQ_M_TIMER));
  printf("\n\r[ASYNC TRAP] IRQ timer");
}

void __attribute__((weak)) isr_m_external(void)
{
  /*clear_csr(mie,1<<IRQ_M_EXT);*/
  write_csr(mip, (0 << IRQ_M_EXT));
  irq_m_ext_callback();

  /*register unsigned int temp __asm__ ("t0");*/
	/*asm volatile ("add t0, zero,sp\n\t");*/
	/*unsigned int sp = temp;*/
	/*printf("[sp][%x]",sp);*/

	/*asm volatile ("add t0, zero,ra\n\t");*/
	/*unsigned int ra = temp;*/
	/*printf("[ra][%x]",ra);*/
}

