OUTPUT_ARCH( "riscv" )

ENTRY( _start_reset )

MEMORY
{
  IRAM(rxai!w) : ORIGIN = 0xA0000000, LENGTH = 64K
  DRAM(wxa!ri) : ORIGIN = 0x10000000, LENGTH = 20K
}

SECTIONS
{
  .text :
  {
    _start_text = .;
    KEEP(*(.init))
    . = ORIGIN(IRAM) + 0x100;
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

  . = ALIGN(. != 0 ? 32 / 8 : 1);
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

  end = .;
}

__stack_size = DEFINED(__stack_size) ? __stack_size : 0x800;
PROVIDE(__stack_size = __stack_size);
__heap_size = DEFINED(__heap_size) ? __heap_size : 0x400;
PROVIDE(__heap_size = __heap_size);

PROVIDE(__freertos_irq_stack_top = ORIGIN(DRAM) + LENGTH(DRAM));
PROVIDE(_end_stack = ORIGIN(DRAM) + (LENGTH(DRAM) - _stack_size));
PROVIDE(_start_heap = end);
PROVIDE(_end_heap = _end_stack);
PROVIDE(end = _start_heap);
PROVIDE(_start_stack = __freertos_irq_stack_top);
