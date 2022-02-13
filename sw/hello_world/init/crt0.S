.option norvc
.section .init
.global _start_reset

_start_reset:
  # Initialize global pointer
.option push
.option norelax
1:
    auipc gp, %pcrel_hi(__global_pointer$)
    addi  gp, gp, %pcrel_lo(1b)
.option pop
    la sp, _start_stack
    call _reset
