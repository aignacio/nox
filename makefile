# Design files
_SRC_VERILOG	?=	rtl/inc/axi_pkg.svh
_SRC_VERILOG	+=	rtl/inc/nox_pkg.svh
_SRC_VERILOG 	+=	rtl/inc/core_bus_pkg.svh
_SRC_VERILOG 	+=	rtl/inc/riscv_pkg.svh
_SRC_VERILOG 	+=	rtl/inc/utils_pkg.svh
_SRC_VERILOG 	+=	$(shell find rtl/ -type f -iname *.sv)
_CORE_VERILOG :=	$(_SRC_VERILOG)
_SRC_VERILOG 	+=	$(shell find tb/  -type f -iname *.sv)
SRC_VERILOG 	?=	$(_SRC_VERILOG)

# Design include files
_INCS_VLOG		?=	rtl/inc
INCS_VLOG			:=	$(addprefix -I,$(_INCS_VLOG))

# Parameters of simulation
#IRAM_KB_SIZE	?=	256
IRAM_KB_SIZE	?=	2*1024
DRAM_KB_SIZE	?=	128
IRAM_ADDR			?=	0x80000000
DRAM_ADDR			?=	0x10000000
DISPLAY_TEST	?=	0 # Display or not $display under axi_mem.sv [compliance test]
WAVEFORM_USE	?=	0 # Use 0 to not generate waves [compliance test]
BP_ADDRS_CHN	?=	0 # Insert bp on aw/raddr chn
BP_RDATA_CHN	?=	0 # Insert bp on rdata chn
BP_BWRES_CHN	?=	0 # Insert bp on b chn

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
_MACROS_VLOG	+=	DISPLAY_TEST=$(DISPLAY_TEST)
_MACROS_VLOG	+=	BP_ADDRS_CHN=$(BP_ADDRS_CHN)
_MACROS_VLOG	+=	BP_RDATA_CHN=$(BP_RDATA_CHN)
_MACROS_VLOG	+=	BP_BWRES_CHN=$(BP_BWRES_CHN)
_MACROS_VLOG	+=	SIMULATION
MACROS_VLOG		?=	$(addprefix +define+,$(_MACROS_VLOG))

CPPFLAGS_VERI	:=	"$(INCS_CPP) -O0 -g3 -Wall -std=c++11 \
									-Werror																\
									-DIRAM_KB_SIZE=\"$(IRAM_KB_SIZE)\"		\
									-DDRAM_KB_SIZE=\"$(DRAM_KB_SIZE)\"		\
									-DIRAM_ADDR=\"$(IRAM_ADDR)\"					\
									-DDRAM_ADDR=\"$(DRAM_ADDR)\"					\
									-DWAVEFORM_USE=\"$(WAVEFORM_USE)\"	  \
									-DWAVEFORM_FST=\"$(WAVEFORM_FST)\""
									#-Wunknown-warning-option"

VERIL_ARGS		:=	-CFLAGS $(CPPFLAGS_VERI) 			\
									--top-module $(ROOT_MOD_VERI) \
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
	@echo "all					- run verilator"
	@echo "design				- build design and sim through verilator"
	@echo "wave					- calls gtkwave"
	@echo "lint					- calls verible for sv linting"

conv_verilog:
	sv2v	$(INCS_VLOG)						\
				-DIRAM_KB_SIZE="128"		\
				-DDRAM_KB_SIZE="128"		\
				$(SRC_VERILOG) > design.v

wave: $(WAVEFORM_FST)
	/Applications/gtkwave.app/Contents/Resources/bin/gtkwave $(WAVEFORM_FST) w_tmplt.gtkw

lint:
	verible-verilog-lint --lint_fatal --parse_fatal $(_CORE_VERILOG)
	ec $(_CORE_VERILOG)

clean:
	rm -rf $(OUT_VERILATOR) run_dir

all: clean $(OUT_VERILATOR)/V$(ROOT_MOD_VERI).mk
	@echo "Verilator build done!"

design: $(VERILATOR_EXE)
	@echo "\n"
	@echo "Design build done, run as follow:"
	@echo "$(VERILATOR_EXE) -h"
	@echo "\n"

$(VERILATOR_EXE): $(OUT_VERILATOR)/V$(ROOT_MOD_VERI).mk
	+@make -C $(OUT_VERILATOR) -f V$(ROOT_MOD_VERI).mk VM_PARALLEL_BUILDS=1

$(OUT_VERILATOR)/V$(ROOT_MOD_VERI).mk: $(SRC_VERILOG) $(SRC_CPP) $(TB_VERILATOR)
	verilator $(VERIL_ARGS)
