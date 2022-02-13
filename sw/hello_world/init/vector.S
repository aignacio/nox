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

.macro trap_entry
    # Allocate space on the stack, we need to save the
    # context of 16*32-bit registers what's equals to
    # 16*(4 bytes) = 64 bytes
    addi sp, sp, -64
    # Start saving the "Caller" registers in the stack
    sw ra, 0(sp)
    sw t0, 4(sp)
    sw t1, 8(sp)
    sw t2, 12(sp)
    sw a0, 16(sp)
    sw a1, 20(sp)
    sw a2, 24(sp)
    sw a3, 28(sp)
    sw a4, 32(sp)
    sw a5, 36(sp)
    sw a6, 40(sp)
    sw a7, 44(sp)
    sw t3, 48(sp)
    sw t4, 52(sp)
    sw t5, 56(sp)
    sw t6, 60(sp)
.endm

.macro trap_exit
    # We'll return from the trap entry, so we restore
    # the context stored in the stack...
    lw ra, 0(sp)
    lw t0, 4(sp)
    lw t1, 8(sp)
    lw t2, 12(sp)
    lw a0, 16(sp)
    lw a1, 20(sp)
    lw a2, 24(sp)
    lw a3, 28(sp)
    lw a4, 32(sp)
    lw a5, 36(sp)
    lw a6, 40(sp)
    lw a7, 44(sp)
    lw t3, 48(sp)
    lw t4, 52(sp)
    lw t5, 56(sp)
    lw t6, 60(sp)
    # ...and we deallocate space on the stack return
    addi sp, sp, 64
    # ing from the trap with mret
    mret
.endm

.option norvc
.section .isr_vector
    # In this section we're going to list all PC addresses that the hardware
    # will go to jump on trap execution, in the code below we consider that
    # vectored interrupt are actived (i.e MTVEC[1:0] = 1)
    # synchronous trap = exceptions
    # asynchronous trap = interrupts
.align 8 # Align to the next 2^8=256 bytes, or 0x100 offset address
trap_vectors:
    j _synctrap # Base trap address (also sync trap address)
    nop
    nop
    j trap_machine_software_int # MTVEC = [Trap base] + 0x4*3 = 0x0C
    nop
    nop
    nop
    j trap_machine_timer_int # MTVEC = [Trap base] + 0x4*7 = 0x1C
    nop
    nop
    nop
    j trap_machine_external_int # MTVEC = [Trap base] + 0x4*11 = 0x2C
    .align 2

_synctrap:
    trap_entry
    jal isr_synctrap
    trap_exit
trap_machine_software_int:
    trap_entry
    jal isr_m_software
    trap_exit
trap_machine_timer_int:
    trap_entry
    jal isr_m_timer
    trap_exit
trap_machine_external_int:
    trap_entry
    jal isr_m_external
    trap_exit
