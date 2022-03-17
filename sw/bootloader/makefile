#PREFIX	?=	/opt/riscv/bin/riscv64-unknown-elf-
PREFIX	?=	docker run --rm --name sw_nox					\
						-v $(abspath ../..):/files -w					\
						/files/sw/$(notdir $(shell pwd))			\
						aignacio/nox riscv-none-embed-
RUN_PY	?=	docker run --rm --name sw_nox					\
						-v $(abspath ../..):/files -w					\
						/files/sw/$(notdir $(shell pwd))			\
						aignacio/nox python3
CC			:=	$(PREFIX)gcc
OBJDUMP	:=	$(PREFIX)objdump
OBJCOPY	:=	$(PREFIX)objcopy
GDB			:=	$(PREFIX)gdb
SIZE		:=	$(PREFIX)size

CFLAGS	:=	-march=rv32i	    	\
						-mabi=ilp32					\
						-Wall								\
						-Wno-unused					\
						-ffreestanding			\
						-O0 -g							\
						--specs=nano.specs	\
						-Wall -Wno-main			\
						-DPRINTF_DISABLE_SUPPORT_FLOAT			 \
						-DPRINTF_DISABLE_SUPPORT_EXPONENTIAL
LDFLAGS	:=	-g									\
						-Wl,-gc-sections		\
						-Wl,-Map=output/image.map,--print-memory-usage \
						-march=rv32i				\
						-mabi=ilp32					\
						-nostartfiles 			\
						-lgcc

#-nostdlib

TARGET_NAME	:= $(notdir $(shell pwd))
ODIR				:=	output
TEMP				:=	output_temp
TARGET			:=	$(ODIR)/$(TARGET_NAME)
LD					:=	sections.ld
_INC				:=	../common
_INC				+=	printf
INC					:=	$(addprefix -I,$(_INC))
_OBJ    		:=	$(patsubst printf/%,%.o,$(basename $(wildcard printf/*.c)))
_OBJ    		+=	$(patsubst init/%,%.o,$(basename $(wildcard init/*.S)))
_OBJ    		+=	$(patsubst init/%,%.o,$(basename $(wildcard init/*.c)))
_OBJ    		+=	$(patsubst src/%,%.o,$(basename $(wildcard src/*.c)))
OBJ					:=	$(patsubst %,$(TEMP)/%,$(_OBJ))

$(shell   mkdir -p $(ODIR)_temp)
$(shell   mkdir -p $(ODIR))

.PHONY: all clean default

default: all

all: $(ODIR)/boot_rom.sv $(TARGET).asm
	@echo	"$(TARGET_NAME) builded"
	#$(SIZE) -t $(TARGET).elf

$(ODIR)/boot_rom.sv: $(TARGET).data
	@echo "Generating behavioral ROM in verilog with hex file"
	$(RUN_PY) scripts/gen_rom.py --in_hex $< --out_v $@

$(TARGET).data: $(TARGET).bin
	@echo "Generating hex format from elf to run in digital simulations..."
	$(RUN_PY) scripts/freedom-bin2hex.py --bit-width 32 $< $@

$(TARGET).asm:	$(TARGET).elf
	@echo "Generating disassembly of the code..."
	$(OBJDUMP) -S -t -D -h $< > $@

$(TARGET).bin:	$(TARGET).elf
	@echo "Generating binary format of the elf executable..."
	$(OBJCOPY) -O binary $< $@

$(TARGET).elf:	$(OBJ) $(LD)
	@echo "Linking $@"
	$(CC) -T$(LD) $(INC) $(OBJ) -o $@ $(LDFLAGS)

$(TEMP)/%.o:	init/%.S
	@echo "Building $@"
	$(CC) $(CFLAGS) -save-temps=obj $(INC) -c $< -o $@

$(TEMP)/%.o:	printf/%.c
	@echo "Building $@"
	$(CC) $(CFLAGS) -save-temps=obj $(INC) -c $< -o $@

$(TEMP)/%.o:	init/%.c
	@echo "Building $@"
	$(CC) $(CFLAGS) -save-temps=obj $(INC) -c $< -o $@

$(TEMP)/%.o:  src/%.c
	@echo "Building $@"
	$(CC) $(CFLAGS) -save-temps=obj $(INC) -c $< -o $@

$(TEMP)/%.o:
	@echo "Building $@"
	$(CC) $(CFLAGS) -save-temps=obj $(INC) -c $< -o $@

dbg:
	@echo "Use disass /m name_of_the_function to search for a function in assembly/c\n"
	$(GDB) $(TARGET).elf -ex "target remote localhost:3333" -ex "load"

clean:
	@echo "Cleaning all..."
	rm -rf $(ODIR)
	rm -rf $(TEMP)
