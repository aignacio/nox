#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H

#define RVMODEL_DATA_SECTION \
        .pushsection .tohost,"aw",@progbits;                            \
        .align 8; .global tohost; tohost: .dword 0;                     \
        .align 8; .global fromhost; fromhost: .dword 0;                 \
        .popsection;                                                    \
        .align 8; .global begin_regstate; begin_regstate:               \
        .word 128;                                                      \
        .align 8; .global end_regstate; end_regstate:                   \
        .word 4;

#define	CONSOLE_CHAR_ADDR		0xA0000000
#define	CONSOLE_NUM_ADDR		0xB0000000
#define TESTUTIL_BASE 			0xC0000000
#define TESTUTIL_ADDR_HALT 		(TESTUTIL_BASE)
#define TESTUTIL_ADDR_BEGIN_SIGNATURE 	(TESTUTIL_BASE + 0x10)
#define TESTUTIL_ADDR_END_SIGNATURE 	(TESTUTIL_BASE + 0x20)

#define RVMODEL_HALT     	                                              \
        /* tell simulation about location of begin_signature */               \
        la t0, begin_signature;                                               \
        li t1, TESTUTIL_ADDR_BEGIN_SIGNATURE;                                 \
        sw t0, 0(t1);                                                         \
        /* tell simulation about location of end_signature */                 \
        la t0, end_signature;                                                 \
        li t1, TESTUTIL_ADDR_END_SIGNATURE;                                   \
        sw t0, 0(t1);                                                         \
        /* dump signature and terminate simulation */                         \
        li t0, 1;                                                             \
        li t1, TESTUTIL_ADDR_HALT;                                            \
        sw t0, 0(t1);

#define RVMODEL_DATA_BEGIN                                     	              \
  .align 4; .global begin_signature; begin_signature:

#define RVMODEL_DATA_END                                                      \
  .align 4; .global end_signature; end_signature:                             \
  RVMODEL_DATA_SECTION


#define RVMODEL_BOOT
//#define RVMODEL_BOOT \
	//.section .text.init; \
	  //la t0, _data_strings; \
	  //la t1, _fstext; \
	  //la t2, _estext; \
	//1: \
	  //lw t3, 0(t0); \
	  //sw t3, 0(t1); \
	  //addi t0, t0, 4; \
	  //addi t1, t1, 4; \
	  //bltu t1, t2, 1b; \
	  //la t0, _data_lma; \
	  //la t1, _data; \
	  //la t2, _edata; \
	//1: \
	  //lw t3, 0(t0); \
	  //sw t3, 0(t1); \
	  //addi t0, t0, 4; \
	  //addi t1, t1, 4; \
	  //bltu t1, t2, 1b;

// _SP = (volatile register)
//TODO: Macro to output a string to IO
#define LOCAL_IO_WRITE_STR(_STR) RVMODEL_IO_WRITE_STR(x31, _STR)
#define RVMODEL_IO_WRITE_STR(_SP, _STR)                                 \
    .section .data.string;                                              \
20001:                                                                  \
    .string _STR;                                                       \
    .section .text.init;                                                \
    la a0, 20001b;                                                      \
    jal FN_WriteStr;

#define RSIZE 4
// _SP = (volatile register)
#define LOCAL_IO_PUSH(_SP)                                              \
    la      _SP,  begin_regstate;                                       \
    sw      ra,   (1*RSIZE)(_SP);                                       \
    sw      t0,   (2*RSIZE)(_SP);                                       \
    sw      t1,   (3*RSIZE)(_SP);                                       \
    sw      t2,   (4*RSIZE)(_SP);                                       \
    sw      t3,   (5*RSIZE)(_SP);                                       \
    sw      t4,   (6*RSIZE)(_SP);                                      \
    sw      s0,   (7*RSIZE)(_SP);                                      \
    sw      a0,   (8*RSIZE)(_SP);

// _SP = (volatile register)
#define LOCAL_IO_POP(_SP)                                               \
    la      _SP,   begin_regstate;                                      \
    lw      ra,   (1*RSIZE)(_SP);                                       \
    lw      t0,   (2*RSIZE)(_SP);                                       \
    lw      t1,   (3*RSIZE)(_SP);                                       \
    lw      t2,   (4*RSIZE)(_SP);                                       \
    lw      t3,   (5*RSIZE)(_SP);                                       \
    lw      t4,   (6*RSIZE)(_SP);                                       \
    lw      s0,   (7*RSIZE)(_SP);                                       \
    lw      a0,   (8*RSIZE)(_SP);

//RVMODEL_IO_ASSERT_GPR_EQ
// _SP = (volatile register)
// _R = GPR
// _I = Immediate
// This code will check a test to see if the results
// match the expected value.
// It can also be used to tell if a set of tests is still running or has crashed
#if 0
// Spinning | =  "I am alive"
#define RVMODEL_IO_ASSERT_GPR_EQ(_SP, _R, _I) \
    LOCAL_IO_PUSH(_SP)                        \
    RVMODEL_IO_WRITE_STR2("|");               \
    RVMODEL_IO_WRITE_STR2("\b=\b");           \
    LOCAL_IO_POP(_SP)

#else

// Test to see if a specific test has passed or not.  Can assert or not.
#define RVMODEL_IO_ASSERT_GPR_EQ(_SP, _R, _I)                                 \
    LOCAL_IO_PUSH(_SP)                                                  \
    mv          s0, _R;                                                 \
    li          t5, _I;                                                 \
    beq         s0, t5, 20002f;                                         \
    LOCAL_IO_WRITE_STR("Test Failed ");                              \
    LOCAL_IO_WRITE_STR(": ");                                        \
    LOCAL_IO_WRITE_STR(# _R);                                        \
    LOCAL_IO_WRITE_STR("( ");                                        \
    mv      a0, s0;                                                     \
    jal FN_WriteNmbr;                                                   \
    LOCAL_IO_WRITE_STR(" ) != ");                                    \
    mv      a0, t5;                                                     \
    jal FN_WriteNmbr;                                                   \
    j 20003f;                                                           \
20002:                                                                  \
    LOCAL_IO_WRITE_STR("Test Passed ");                              \
20003:                                                                  \
    LOCAL_IO_WRITE_STR("\n");                                        \
    LOCAL_IO_POP(_SP)

#endif

.section .text
// FN_WriteStr: Add code here to write a string to IO
// FN_WriteNmbr: Add code here to write a number (32/64bits) to IO

#define LOCAL_IO_PUTC(_R)                                               \
    la          t3, CONSOLE_CHAR_ADDR;					\
    sw          _R, (0)(t3);

#define LOCAL_IO_PUTN(_R)                                               \
    la          t3, CONSOLE_NUM_ADDR;					\
    sw          _R, (0)(t3);


// FN_WriteStr: Uses a0, t0
FN_WriteStr:
    mv          t0, a0;
10000:
    lbu         a0, (t0);
    addi        t0, t0, 1;
    beq         a0, zero, 10000f;
    LOCAL_IO_PUTC(a0);
    j           10000b;
10000:
    ret;

FN_WriteNmbr:
    mv          t0, a0;
20000:
    lbu         a0, (t0);
    addi        t0, t0, 1;
    beq         a0, zero, 20000f;
    LOCAL_IO_PUTN(a0);
    j           20000b;
20000:
    ret;
//FN_WriteStr: \
    //ret; \
//FN_WriteNmbr: \
    //ret;

//RVTEST_IO_ASSERT_SFPR_EQ
#define RVMODEL_IO_ASSERT_SFPR_EQ(_F, _R, _I)
//RVTEST_IO_ASSERT_DFPR_EQ
#define RVMODEL_IO_ASSERT_DFPR_EQ(_D, _R, _I)

// TODO: specify the routine for setting machine software interrupt
#define RVMODEL_SET_MSW_INT

// TODO: specify the routine for clearing machine software interrupt
#define RVMODEL_CLEAR_MSW_INT

// TODO: specify the routine for clearing machine timer interrupt
#define RVMODEL_CLEAR_MTIMER_INT

// TODO: specify the routine for clearing machine external interrupt
#define RVMODEL_CLEAR_MEXT_INT

#endif // _COMPLIANCE_MODEL_H
