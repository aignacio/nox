# Design files
_SRC_VERILOG	?=	rtl/inc/axi_pkg.svh
_SRC_VERILOG	+=	rtl/inc/nox_pkg.svh
_SRC_VERILOG 	+=	rtl/inc/core_bus_pkg.svh
_SRC_VERILOG 	+=	rtl/inc/riscv_pkg.svh
_SRC_VERILOG 	+=	rtl/inc/utils_pkg.sv
_SRC_VERILOG 	+=	$(shell find rtl/ -type f -iname *.sv)
_CORE_VERILOG :=	$(_SRC_VERILOG)
_SRC_VERILOG 	+=	$(shell find tb/  -type f -iname *.sv)
SRC_VERILOG 	?=	$(_SRC_VERILOG)

# Design include files
_INCS_VLOG		?=	rtl/inc
INCS_VLOG			:=	$(addprefix -I,$(_INCS_VLOG))

# Parameters of simulation
#IRAM_KB_SIZE	?=	2*1024 #2MB due to J-Tests on RV Compliance tests
IRAM_KB_SIZE	?=	8
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
VERILATOR_EXE	:=	$(OUT_VERILATOR)/$(ROOT_MOD_VERI)

# Testbench files
SRC_CPP				:=	$(wildcard $(VERILATOR_TB)/cpp/*.cpp)
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
_MACROS_VLOG	+=	RV_COMPLIANCE
MACROS_VLOG		?=	$(addprefix +define+,$(_MACROS_VLOG))

# Be sure to set up correctly the number of
# resources like memory/cpu for docker to run
# in case you don't, docker will killed
# the container and you'll not be able to build
# the executable nox_sim
RUN_CMD				:=	docker run --rm --name ship_nox	\
									-v $(abspath .):/nox_files -w		\
									/nox_files nox
RUN_CMD_2			:=	docker run --rm --name ship_nox	\
									-v $(abspath .):/nox_files -w		\
									/opt/riscv-arch-test nox

RUN_SW				:=	sw/hello_world/output/hello_world.elf

CPPFLAGS_VERI	:=	"$(INCS_CPP) -O0 -g3 -Wall						\
									-Werror																\
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

.PHONY: verilator clean help
help:
	@echo "Targets:"
	@echo "run	- run verilator"
	@echo "build	- build docker image used by nox project"
	@echo "all	- build design and sim through verilator"
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
	docker build -t nox:latest . --progress tty

$(RUN_SW):
	make -C sw/hello_world all

run: $(VERILATOR_EXE) $(RUN_SW)
	$(RUN_CMD) ./$(VERILATOR_EXE) -s 10000 -e $(RUN_SW)

$(VERILATOR_EXE): $(OUT_VERILATOR)/V$(ROOT_MOD_VERI).mk
	$(RUN_CMD) make -C $(OUT_VERILATOR)	\
		-f V$(ROOT_MOD_VERI).mk

$(OUT_VERILATOR)/V$(ROOT_MOD_VERI).mk: $(SRC_VERILOG) $(SRC_CPP) $(TB_VERILATOR)
	$(RUN_CMD) verilator $(VERIL_ARGS)

##########################
#	RISC-V Compliance test #
##########################
sim_comp:
	make all IRAM_KB_SIZE=2048 DRAM_KB_SIZE=128 WAVEFORM_USE=0

compliance:
	$(RUN_CMD_2) make verify RISCV_PREFIX=riscv-none-embed-	\
		RISCV_TARGET=nox																			\
		RISCV_DEVICE=privilege  															\
		TARGET_SIM=/nox_files/$(VERILATOR_EXE) -j8


