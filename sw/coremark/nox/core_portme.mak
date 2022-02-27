# Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Original Author: Shay Gal-on

#File : core_portme.mak

# Flag : OUTFLAG
#	Use this flag to define how to to get an executable (e.g -o)
OUTFLAG= -o

RUN_CMD	?=	docker run --rm --name ship_nox	  \
		    -v $(abspath .):/nox_files -w     \
		    /nox_files nox riscv-none-embed-
# Flag : CC
#	Use this flag to define compiler to use
CC 		 = $(RUN_CMD)gcc
# Flag : LD
#	Use this flag to define compiler to use
LD		 = $(RUN_CMD)gcc
# Flag : AS
#	Use this flag to define compiler to use
AS		= $(RUN_CMD)gcc
# Added by Anderson to get the asm
OBJDUMP	= $(RUN_CMD)objdump

# Flag : CFLAGS
#	Use this flag to define compiler options. Note, you can add compiler options from the command line using XCFLAGS="other flags"
PORT_CFLAGS = -O0 -g              \
          	  -march=rv32i	      \
			  -mabi=ilp32		  \
			  -Wall				  \
			  -Wno-unused		  \
			  -ffreestanding	  \
			  --specs=nano.specs  \
			  -DPRINTF_DISABLE_SUPPORT_FLOAT		\
			  -DPRINTF_DISABLE_SUPPORT_EXPONENTIAL	\
			  -DPRINTF_DISABLE_SUPPORT_LONG_LONG	\
			  -Wall -Wno-main
FLAGS_STR = "$(PORT_CFLAGS) $(XCFLAGS) $(XLFLAGS) $(LFLAGS_END)"
CFLAGS = $(PORT_CFLAGS) -I$(PORT_DIR) -I. -DFLAGS_STR=\"$(FLAGS_STR)\"
#Flag : LFLAGS_END
#	Define any libraries needed for linking or other flags that should come at the end of the link line (e.g. linker scripts).
#	Note : On certain platforms, the default clock_gettime implementation is supported but requires linking of librt.
SEPARATE_COMPILE=0
# Flag : SEPARATE_COMPILE
# You must also define below how to create an object file, and how to link.
OBJOUT 	= -o
LFLAGS 	= -Tsections.ld       \
          -g				  \
		  -Wl,-gc-sections	  \
		  -Wl,-Map=image.map,--print-memory-usage \
		  -march=rv32i		  \
		  -mabi=ilp32		  \
		  -nostartfiles 	  \
		  -lgcc -lm -lc
ASFLAGS =
OFLAG 	= -o
COUT 	= -c

LFLAGS_END =
# Flag : PORT_SRCS
# 	Port specific source files can be added here
#	You may also need cvt.c if the fcvt functions are not provided as intrinsics by your compiler!
PORT_OBJS =	$(PORT_DIR)/printf.o		\
			$(PORT_DIR)/core_portme.o	\
			$(PORT_DIR)/crt0.o			\
			$(PORT_DIR)/startup.o
			#$(PORT_DIR)/ee_printf.o \
            #$(PORT_DIR)/cvt.o
PORT_SRCS =	$(PORT_DIR)/printf.c		\
			$(PORT_DIR)/core_portme.c	\
			$(PORT_DIR)/crt0.s			\
			$(PORT_DIR)/startup.c
						#$(PORT_DIR)/ee_printf.c \
            #$(PORT_DIR)/cvt.c
vpath %.c $(PORT_DIR)
vpath %.s $(PORT_DIR)

# Flag : LOAD
#	For a simple port, we assume self hosted compile and run, no load needed.

# Flag : RUN
#	For a simple port, we assume self hosted compile and run, simple invocation of the executable

LOAD = echo "Please set LOAD to the process of loading the executable to the flash"
RUN = echo "Please set LOAD to the process of running the executable (e.g. via jtag, or board reset)"

OEXT = .o
EXE = .elf

$(OPATH)$(PORT_DIR)/%$(OEXT) : %.c
	$(CC) $(CFLAGS) $(XCFLAGS) $(COUT) $< $(OBJOUT) $@

$(OPATH)%$(OEXT) : %.c
	$(CC) $(CFLAGS) $(XCFLAGS) $(COUT) $< $(OBJOUT) $@

$(OPATH)%$(OEXT) : %.s
	$(CC) $(CFLAGS) $(XCFLAGS) $(COUT) $< $(OBJOUT) $@

#$(OPATH)$(PORT_DIR)/%$(OEXT) : %.s
	#$(AS) $(ASFLAGS) $< $(OBJOUT) $@

port_postbuild:
	$(OBJDUMP) -S -t -D -h coremark.elf > coremark.asm
# Target : port_pre% and port_post%
# For the purpose of this simple port, no pre or post steps needed.

port_prebuild:
	@echo "Additional sources $(PORT_SRCS)"

.PHONY : port_prebuild port_postbuild port_prerun port_postrun port_preload port_postload
port_pre% port_post% :

# FLAG : OPATH
# Path to the output folder. Default - current folder.
OPATH = ./
MKDIR = mkdir -p

