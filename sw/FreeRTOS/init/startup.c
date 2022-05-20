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
#include "riscv_csr_encoding.h"

/*volatile uint32_t* const mtime_addr = (uint32_t*) MTIME_ADDR;*/

extern void trap_entry(void);
extern void trap_exit(void);

extern void freertos_risc_v_trap_handler(void);

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
static int toggle = 0;

extern void irq_callback(void);
extern void main(void);

void __attribute__((section(".init"),naked)) _reset(void) {
    register uint32_t *src, *dst;

    // asm volatile("la gp, _my_global_pointer");
    // asm volatile("la sp, _end_stack");
    asm volatile("csrw mtvec, %0":: "r"((uint8_t *)(&freertos_risc_v_trap_handler)));
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

static uint32_t synctrap_cause = 0;

void isr_synctrap(void)
{
  write_csr(mip, (0 << IRQ_M_EXT));
  uint32_t mepc_return = read_csr(mepc)+0x4;
  // If not vectored IRQ, do not add 4 to the MEPC
  write_csr(mepc, mepc_return);
  /*irq_callback();*/
  /*[>asm volatile("csrr %0,mcause" : "=r"(synctrap_cause));<]*/
  /*[>asm volatile("ebreak");<]*/
  /*clear_csr(mie,1<<IRQ_M_SOFT);*/
  /*write_csr(mip, (0 << IRQ_M_SOFT));*/
  /*clear_csr(mie,1<<IRQ_M_TIMER);*/
  /*write_csr(mip, (0 << IRQ_M_TIMER));*/
  /*clear_csr(mie,1<<IRQ_M_EXT);*/
  /*write_csr(mip, (0 << IRQ_M_EXT));*/
  return;
}

// Using the attr below it'll bkp a5 and use
// mret in the return, as we do that manually
// in asm, it's not needed to use this
/*__attribute__ ((interrupt ("machine"))) */
void __attribute__((weak)) isr_m_software(void)
{
  clear_csr(mie,1<<IRQ_M_SOFT);
  write_csr(mip, (0 << IRQ_M_SOFT));
  return;
  while(1);
}

void __attribute__((weak)) isr_m_timer(void)
{
  clear_csr(mie,1<<IRQ_M_TIMER);
  write_csr(mip, (0 << IRQ_M_TIMER));
  return;
  while(1);
}

void __attribute__((weak)) isr_m_external(void)
{
  clear_csr(mie,1<<IRQ_M_EXT);
  write_csr(mip, (0 << IRQ_M_EXT));
  /*irq_callback();*/
  return;
  while(1);
}

void __attribute__((weak)) handle_trap(void)
{
  printf("\n\rHANDLE TRAP");
  return;
}

