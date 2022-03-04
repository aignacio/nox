OUTPUT_ARCH("riscv")
ENTRY(rvtest_entry_point)

MEMORY {
  DRAM (rwx) : ORIGIN = 0x10000000, LENGTH = 128K
  IROM (rx)  : ORIGIN = 0x80000000, LENGTH = 2048K
}

SECTIONS
{

  .text.init ALIGN((ORIGIN(IROM) + 0x0), 64) : AT(ALIGN((ORIGIN(IROM) + 0x0), 64)) {
    PROVIDE(_ftext = .);
    *(.text.init)
    PROVIDE(_etext = .);
  }

  .text ALIGN((ADDR(.text.init) + SIZEOF(.text.init)), 64) : AT(ALIGN((LOADADDR(.text.init) + SIZEOF(.text.init)), 64)) {
    *(.text)
  }

  /*Replace by the line below if loader cannot load DRAM*/
  /*.tohost ALIGN((ORIGIN(DRAM)), 64) : AT(ALIGN((LOADADDR(.text) + SIZEOF(.text)), 64)) {*/
  .tohost ALIGN((ORIGIN(DRAM)), 64) : AT(ORIGIN(DRAM)) {
    *(.tohost)
  }

  .data ALIGN((ADDR(.tohost) + SIZEOF(.tohost)), 64) : AT(ALIGN((LOADADDR(.tohost) + SIZEOF(.tohost)), 64)) {
    *(.data)
  }

  PROVIDE(_data = ADDR(.data));
  PROVIDE(_data_lma = LOADADDR(.data));
  PROVIDE(_edata = ADDR(.data) + SIZEOF(.data));

  .data.string ALIGN((ADDR(.data) + SIZEOF(.data)), 64) : AT(ALIGN((LOADADDR(.data) + SIZEOF(.data)), 64)) {
    *(.data.string)
  }

  PROVIDE(_fstext = ADDR(.data.string));
  PROVIDE(_data_strings = LOADADDR(.data.string));
  PROVIDE(_estext = ADDR(.data.string) + SIZEOF(.data.string));

  .bss ALIGN((ADDR(.data.string) + SIZEOF(.data.string)), 64) : AT(ALIGN((LOADADDR(.data.string) + SIZEOF(.data.string)), 64)) ALIGN(8) {
    PROVIDE(_fbss = .);
    *(.bss)
    PROVIDE(_ebss = .);
  }

  PROVIDE(_end = .);

  /*signature ALIGN(ORIGIN(SIG_RAM)) : AT(ALIGN(ORIGIN(SIG_RAM))){*/
	/*begin_signature = ORIGIN(SIG_RAM)+0x10;*/
	/*end_signature = ORIGIN(SIG_RAM)+0x20;*/
  /*}*/
}
