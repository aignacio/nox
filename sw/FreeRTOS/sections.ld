
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
OUTPUT_ARCH( "riscv" )

ENTRY( _start_reset )

MEMORY
{
  IRAM(rxai!w) : ORIGIN = 0xA0000000, LENGTH = 64K
  DRAM(wxa!ri) : ORIGIN = 0x10000000, LENGTH = 24K
}

_min_stack      = 0x200;
_stack_size     = 0x200;
SECTIONS
{
    .text :
    {
        _start_text = .;
        KEEP(*(.init))
        . = ORIGIN(IRAM) + 0x100;
        _start_vector = .;
        KEEP(*(.isr_vector))
        *(.text*)
        _edata = .;
        *(.rodata*)
        *(.srodata*)
        . = ALIGN(4);
        _end_text = .;
    } > IRAM

    /* Start of LMA address of data/bss */
    _stored_data = .;

  /* VMA of data/bss/stack/heap should be the DRAM */
  .data : AT (_stored_data) {
    __DATA_BEGIN__ = .;
    _start_data = .;
    *(.data .data.* .gnu.linkonce.d.*)
    SORT(CONSTRUCTORS)
    __SDATA_BEGIN__ = .;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata .srodata.*)
    *(.sdata .sdata.* .sdata2.* .gnu.linkonce.s.*)
    _end_data = .;
  } > DRAM

   _start_bss = .;

  .bss : AT (_stored_data) {
    __BSS_START__ = .;
    *(.dynbss)
    *(.bss .bss.* .gnu.linkonce.b.*)
    *(COMMON)
       /* Align here to ensure that the .bss section occupies space up to
           _end.  Align after .bss to ensure correct alignment even if the
           .bss section disappears because there are no input sections.
           FIXME: Why do we need it? When there is no .bss section, we do not
           pad the .data section.  */
    . = ALIGN(. != 0 ? 32 / 8 : 1);
  } > DRAM

  .sbss : AT (_stored_data) {
    *(.dynsbss)
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
    __BSS_END__ = .;
    _end = .;
    _end_bss = .;
   } > DRAM

  __global_pointer$ = MIN(__SDATA_BEGIN__ + 0x800, MAX(__DATA_BEGIN__ + 0x800, __BSS_END__ - 0x800));
}

PROVIDE(_start_stack = ORIGIN(DRAM) + LENGTH(DRAM));
PROVIDE(__freertos_irq_stack_top = ORIGIN(DRAM) + LENGTH(DRAM));
PROVIDE(_end_stack = ORIGIN(DRAM) + (LENGTH(DRAM) - _stack_size));
PROVIDE(_start_heap = __BSS_END__);
PROVIDE(_end_heap = _end_stack);
PROVIDE(end = _start_heap);

/*PROVIDE(__global_pointer$ = _global_pointer);*/
/*PROVIDE(end = _end);*/
/*PROVIDE(_start_heap = _end);*/
/*PROVIDE(_end_bss = __BSS_END__);*/
/*PROVIDE(_end_stack  = ORIGIN(DRAM) + (LENGTH(DRAM) - _min_stack) );*/
