AXI_IF				?=	1

# Design files
_SRC_VERILOG	?=	rtl/inc/axi_pkg.svh
_SRC_VERILOG	?=	rtl/inc/ahb_pkg.svh
_SRC_VERILOG	+=	rtl/inc/nox_pkg.svh
_SRC_VERILOG 	+=	rtl/inc/core_bus_pkg.svh
_SRC_VERILOG 	+=	rtl/inc/riscv_pkg.svh
_SRC_VERILOG 	+=	rtl/inc/utils_pkg.sv
_SRC_VERILOG 	+=	$(shell find rtl/ -type f -iname *.sv)
_CORE_VERILOG :=	$(_SRC_VERILOG)
_SRC_VERILOG 	+=	$(shell find tb/  -type f -iname *.sv)
_SRC_VERILOG 	+=	$(shell find xlnx/rtl/verilog-axi/rtl -type f -iname *.v)
_SRC_VERILOG 	+=	xlnx/rtl/axi_mem_wrapper.sv
_SRC_VERILOG 	+=	xlnx/rtl/axi_rom_wrapper.sv
_SRC_VERILOG 	+=	sw/hello_world/output/boot_rom.sv
SRC_VERILOG 	?=	$(_SRC_VERILOG)

# SoC design files
_SOC_VERILOG	?=	rtl/inc/axi_pkg.svh
_SOC_VERILOG	?=	rtl/inc/ahb_pkg.svh
_SOC_VERILOG	+=	rtl/inc/nox_pkg.svh
_SOC_VERILOG 	+=	rtl/inc/core_bus_pkg.svh
_SOC_VERILOG 	+=	rtl/inc/riscv_pkg.svh
_SOC_VERILOG 	+=	rtl/inc/utils_pkg.sv
_SOC_VERILOG 	+=	tb/axi_mem.sv
_SOC_VERILOG 	+=	$(_CORE_VERILOG)
_SOC_VERILOG 	+=	$(shell find xlnx/rtl/verilog-axi/rtl -type f -iname *.v)
_SOC_VERILOG 	+=	xlnx/rtl/wbuart32/rtl/axiluart.v
_SOC_VERILOG 	+=	xlnx/rtl/wbuart32/rtl/rxuart.v
_SOC_VERILOG 	+=	xlnx/rtl/wbuart32/rtl/rxuartlite.v
_SOC_VERILOG 	+=	xlnx/rtl/wbuart32/rtl/skidbuffer.v
_SOC_VERILOG 	+=	xlnx/rtl/wbuart32/rtl/txuart.v
_SOC_VERILOG 	+=	xlnx/rtl/wbuart32/rtl/txuartlite.v
_SOC_VERILOG 	+=	xlnx/rtl/wbuart32/rtl/ufifo.v
_SOC_VERILOG 	+=	xlnx/rtl/axi_interconnect_wrapper.sv
_SOC_VERILOG 	+=	xlnx/rtl/axi_mem_wrapper.sv
_SOC_VERILOG 	+=	xlnx/rtl/axi_rom_wrapper.sv
_SOC_VERILOG 	+=	xlnx/rtl/axi_uart_wrapper.sv
_SOC_VERILOG 	+=	xlnx/rtl/axi_crossbar_wrapper.sv
ifeq ($(AXI_IF),0)
_SOC_VERILOG 	+=	xlnx/rtl/nox_soc_ahb.sv
else
_SOC_VERILOG 	+=	xlnx/rtl/nox_soc.sv
endif
SOC_VERILOG		:=	$(_SOC_VERILOG)

# Design include files
_INCS_VLOG		?=	rtl/inc
INCS_VLOG			:=	$(addprefix -I,$(_INCS_VLOG))

# Parameters of simulation
#IRAM_KB_SIZE	?=	2*1024 #2MB due to J-Tests on RV Compliance tests
IRAM_KB_SIZE	?=	16
DRAM_KB_SIZE	?=	8
ENTRY_ADDR		?=	\'h8000_0000
IRAM_ADDR			?=	0x80000000
DRAM_ADDR			?=	0x10000000
DISPLAY_TEST	?=	0 # Enable $display in axi_mem.sv [compliance test]
WAVEFORM_USE	?=	1 # Use 0 to not generate waves [compliance test]
BP_ADDRS_CHN	?=	0 # Insert bp on address chn - aw/raddr [MISO]
BP_WRDTA_CHN	?=	0 # Insert bp on data chn - wready/rvalid [MISO]
BP_BWRES_CHN	?=	0 # Insert bp on write resp chn - bvalid [MISO]

# Verilator info
VERILATOR_TB	:=	tb
WAVEFORM_FST	?=	nox_waves.fst
OUT_VERILATOR	:=	output_verilator
ROOT_MOD_VERI	:=	nox_sim
ROOT_MOD_SOC	:=	nox_soc
VERILATOR_EXE	:=	$(OUT_VERILATOR)/$(ROOT_MOD_VERI)
VERI_EXE_SOC	:=	$(OUT_VERILATOR)/$(ROOT_MOD_SOC)

# Testbench files
SRC_CPP				:=	$(wildcard $(VERILATOR_TB)/cpp/testbench.cpp)
SRC_CPP_SOC		:=	$(wildcard $(VERILATOR_TB)/cpp/testbench_soc.cpp)
_INC_CPPS			:=	../tb/cpp/elfio
_INC_CPPS			+=	../tb/cpp/inc
INCS_CPP			:=	$(addprefix -I,$(_INC_CPPS))

# Verilog Macros
_MACROS_VLOG	?=	IRAM_KB_SIZE=$(IRAM_KB_SIZE)
_MACROS_VLOG	+=	DRAM_KB_SIZE=$(DRAM_KB_SIZE)
_MACROS_VLOG	+=	ENTRY_ADDR=$(ENTRY_ADDR)
_MACROS_VLOG	+=	DISPLAY_TEST=$(DISPLAY_TEST)
_MACROS_VLOG	+=	BP_ADDRS_CHN=$(BP_ADDRS_CHN)
_MACROS_VLOG	+=	BP_WRDTA_CHN=$(BP_WRDTA_CHN)
_MACROS_VLOG	+=	BP_BWRES_CHN=$(BP_BWRES_CHN)
_MACROS_VLOG	+=	SIMULATION
ifeq ($(RV_COMPLIANCE),1)
_MACROS_VLOG	+=	RV_COMPLIANCE
else
_MACROS_VLOG	+=	EN_PRINTF
endif

ifeq ($(AXI_IF),0)
_MACROS_VLOG	+=	TARGET_IF_AHB
else
_MACROS_VLOG	+=	TARGET_IF_AXI
endif
MACROS_VLOG		?=	$(addprefix +define+,$(_MACROS_VLOG))

# Be sure to set up correctly the number of
# resources like memory/cpu for docker to run
# in case you don't, docker will killed
# the container and you'll not be able to build
# the executable nox_sim
RUN_CMD				:=	docker run --rm --name ship_nox	\
									-v $(abspath .):/nox_files -w		\
									/nox_files aignacio/nox
RUN_CMD_2			:=	docker run --rm --name ship_nox	\
									-v $(abspath .):/nox_files -w		\
									/opt/riscv-arch-test aignacio/nox

RUN_SW				:=	sw/hello_world/output/hello_world.elf
RUN_SW_SOC		:=	sw/soc_hello_world/output/soc_hello_world.elf

CPPFLAGS_VERI	:=	"$(INCS_CPP) -O0 -g3 -Wall						\
									-Werror																\
									-DIRAM_KB_SIZE=\"$(IRAM_KB_SIZE)\"		\
									-DDRAM_KB_SIZE=\"$(DRAM_KB_SIZE)\"		\
									-DIRAM_ADDR=\"$(IRAM_ADDR)\"					\
									-DDRAM_ADDR=\"$(DRAM_ADDR)\"					\
									-DWAVEFORM_USE=\"$(WAVEFORM_USE)\"	  \
									-DWAVEFORM_FST=\"$(WAVEFORM_FST)\""
									#-Wunknown-warning-option"

CPPFLAGS_SOC	:=	"$(INCS_CPP) -O0 -g3 -Wall						\
									-DIRAM_KB_SIZE=\"$(IRAM_KB_SIZE)\"		\
									-DDRAM_KB_SIZE=\"$(DRAM_KB_SIZE)\"		\
									-DIRAM_ADDR=\"$(IRAM_ADDR)\"					\
									-DDRAM_ADDR=\"$(DRAM_ADDR)\"					\
									-DWAVEFORM_USE=\"$(WAVEFORM_USE)\"	  \
									-DWAVEFORM_FST=\"$(WAVEFORM_FST)\""
									#-Wunknown-warning-option"

VERIL_ARGS		:=	-CFLAGS $(CPPFLAGS_VERI) 			\
									--top-module $(ROOT_MOD_VERI)	\
									--Mdir $(OUT_VERILATOR)				\
									-f verilator.flags			  		\
									$(INCS_VLOG)									\
									$(MACROS_VLOG)							 	\
									$(SRC_VERILOG) 								\
									$(SRC_CPP) 										\
									-o 														\
									$(ROOT_MOD_VERI)

VERIL_ARGS_SOC	:=	-CFLAGS $(CPPFLAGS_SOC) 			\
										--top-module $(ROOT_MOD_SOC)	\
										--Mdir $(OUT_VERILATOR)				\
										-f verilator.flags			  		\
										$(INCS_VLOG)									\
										$(MACROS_VLOG)							 	\
										$(SOC_VERILOG) 								\
										$(SRC_CPP_SOC)								\
										-o 														\
										$(ROOT_MOD_SOC)

.PHONY: verilator clean help
help:
	@echo "Targets:"
	@echo "all	- build design and sim through verilator"
	@echo "run	- run sw/hello_world app through nox_sim"
	@echo "build	- build docker image used by nox project"
	@echo "wave	- calls gtkwave"
	@echo "lint	- calls verible for sv linting"

conv_verilog:
	$(RUN_CMD) sv2v						 \
		$(INCS_VLOG)						 \
		$(_CORE_VERILOG) > design.v

wave: $(WAVEFORM_FST)
	/Applications/gtkwave.app/Contents/Resources/bin/gtkwave $(WAVEFORM_FST) waves.gtkw

lint:
	verible-verilog-lint --lint_fatal --parse_fatal $(_CORE_VERILOG)
	ec $(_CORE_VERILOG)

clean:
	rm -rf $(OUT_VERILATOR)

all: clean $(VERILATOR_EXE)
	@echo "\n"
	@echo "Design build done, run as follow:"
	@echo "$(VERILATOR_EXE) -h"
	@echo "\n"

build:
	docker build -f Dockerfile.nox . -t nox:latest . --progress tty

$(RUN_SW):
	make -C sw/hello_world all

run: $(RUN_SW)
	$(RUN_CMD) ./$(VERILATOR_EXE) -s 50000 -e $<

$(VERILATOR_EXE): $(OUT_VERILATOR)/V$(ROOT_MOD_VERI).mk
	$(RUN_CMD) make -C $(OUT_VERILATOR)	\
		-f V$(ROOT_MOD_VERI).mk

$(OUT_VERILATOR)/V$(ROOT_MOD_VERI).mk: $(SRC_VERILOG) $(SRC_CPP) $(TB_VERILATOR)
	$(RUN_CMD) verilator $(VERIL_ARGS)

##########################
#				 Coremark			   #
##########################
nox_coremark:
	make all IRAM_KB_SIZE=24

sw/coremark/coremark.elf:
	make -C sw/coremark/ PORT_DIR=nox ITERATIONS=10

run_coremark: sw/coremark/coremark.elf
	$(RUN_CMD) ./$(VERILATOR_EXE) -s 52835000 -e $< -w 1000000000000000

##########################
#				 SoC test			   #
##########################
wave_soc: $(WAVEFORM_FST)
	/Applications/gtkwave.app/Contents/Resources/bin/gtkwave $(WAVEFORM_FST) waves_soc.gtkw

$(VERI_EXE_SOC): $(OUT_VERILATOR)/V$(ROOT_MOD_SOC).mk
	$(RUN_CMD) make -C $(OUT_VERILATOR)	\
		-f V$(ROOT_MOD_SOC).mk

$(OUT_VERILATOR)/V$(ROOT_MOD_SOC).mk: $(SOC_VERILOG) $(SRC_CPP_SOC) $(TB_VERILATOR)
	$(RUN_CMD) verilator $(VERIL_ARGS_SOC)


soc: clean $(VERI_EXE_SOC)
	@echo "\n"
	@echo "Design build done, run as follow:"
	@echo "$(VERI_EXE_SOC) -h"
	@echo "\n"

$(RUN_SW_SOC):
	make -C sw/soc_hello_world all

run_soc: $(RUN_SW_SOC)
	$(RUN_CMD) ./$(VERI_EXE_SOC) -s 100000 -e $<

##########################
#	RISC-V Compliance test #
##########################
sim_comp:
	make all RV_COMPLIANCE=1 IRAM_KB_SIZE=2048 DRAM_KB_SIZE=128 WAVEFORM_USE=0

compliance:
	$(RUN_CMD_2) make verify RISCV_PREFIX=riscv-none-embed-	\
		RISCV_TARGET=nox RISCV_DEVICE=I		 										\
		TARGET_SIM=/nox_files/$(VERILATOR_EXE) -j8

	#$(RUN_CMD_2) make all_variant RISCV_PREFIX=riscv-none-embed-	\
		#RISCV_TARGET=nox																						\
		#TARGET_SIM=/nox_files/$(VERILATOR_EXE) -j8

