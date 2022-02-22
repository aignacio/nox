#include <iostream>
#include <fstream>
#include <string>
#include <stdlib.h>
#include <signal.h>
#include <cstdlib>
#include <elfio/elfio.hpp>
#include <iomanip>
#include <ctime>
#include <queue>

#include "inc/common.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "verilated_fst_c.h"
#include "Vnox_soc.h"
#include "Vnox_soc__Syms.h"

#define STRINGIZE(x) #x
#define STRINGIZE_VALUE_OF(x) STRINGIZE(x)

using namespace std;

unsigned long tick_counter;

template<class module> class testbench {
  VerilatedFstC *trace = new VerilatedFstC;
  bool getDataNextCycle;

  public:
    module *core = new module;

    testbench() {
      Verilated::traceEverOn(true);
      tick_counter = 0l;
    }

    ~testbench(void) {
      delete core;
      core = NULL;
    }

    virtual void reset(int rst_cyc) {
      for (int i=0;i<rst_cyc;i++) {
        core->rst_cpu = 0;
        this->tick();
      }
      core->rst_cpu = 1;
      this->tick();
    }

    virtual	void opentrace(const char *name) {
      core->trace(trace, 99);
      trace->open(name);
    }

    virtual void close(void) {
      if (trace) {
        trace->close();
        trace = NULL;
      }
    }

    virtual void tick(void) {
      core->clk_in = 0;
      core->eval();
      tick_counter++;
      if(trace) trace->dump(tick_counter);

      core->clk_in = 1;
      core->eval();
      tick_counter++;
      if(trace) trace->dump(tick_counter);
    }

    virtual bool done(void) {
      return (Verilated::gotFinish());
    }
};

bool loadELF(testbench<Vnox_soc> *sim, string program_path, const bool en_print){
  ELFIO::elfio program;

  program.load(program_path);

  if (program.get_class() != ELFCLASS32 ||
    program.get_machine() != 0xf3){
    cout << "\n[ERROR] Error loading ELF file, headers does not match with ELFCLASS32/RISC-V!" << std::endl;
    return 1;
  }

  ELFIO::Elf_Half seg_num = program.segments.size();

  if (en_print){
    cout << "\n[ELF Loader]"    << std::endl;
    cout << "Program path: "  << program_path << std::endl;
    cout << "Number of segments (program headers): " << seg_num << std::endl;
  }

  for (uint8_t i = 0; i<seg_num; i++){
    const ELFIO::segment *p_seg = program.segments[i];
    const ELFIO::Elf64_Addr lma_addr = (uint32_t)p_seg->get_physical_address();
    const ELFIO::Elf64_Addr vma_addr = (uint32_t)p_seg->get_virtual_address();
    const uint32_t mem_size = (uint32_t)p_seg->get_memory_size();
    const uint32_t file_size = (uint32_t)p_seg->get_file_size();

    if (en_print){
      cout << "Segment [" << (uint32_t)i << "] - LMA [" << std::hex << lma_addr << "] VMA [" << std::hex << vma_addr << "]" << std::endl;
      cout << "File size [" << file_size << "] - Memory size [" << std::dec << mem_size << " ~ " << std::dec << mem_size/1024 << " KB]" << std::endl;
    }

    if ((lma_addr >= IRAM_ADDR && lma_addr < (IRAM_ADDR+(IRAM_KB_SIZE*1024))) && (file_size > 0x00)){
      int init_addr = (lma_addr-IRAM_ADDR);

      if (mem_size >= (IRAM_KB_SIZE*1024)){
        cout << "[ELF Loader] IRAM ERROR:" << std::endl;
        cout << "ELF program: \t" << mem_size/1024 << " KB" << std::endl;
        cout << "Verilator model memory size: \t" << IRAM_KB_SIZE << " KB" << std::endl;
        cout << "ELF File too big for emulated memory!" << std::endl;
        return 1;
      }
      // IRAM Address
      for (uint32_t p = 0; p < mem_size; p+=4){
        uint32_t word_line = ((uint8_t)p_seg->get_data()[p+3]<<24)+((uint8_t)p_seg->get_data()[p+2]<<16)+
                             ((uint8_t)p_seg->get_data()[p+1]<<8)+(uint8_t)p_seg->get_data()[p];
        // If the whole word is zeroed, we don't write as it might overlap other regions
        if (!(word_line == 0x00)) {
          //if ((p+init_addr)/4 < 10)
          //  cout << "Addr[" << std::hex << (p+init_addr)/4 << "] Data[" << std::hex << word_line << "]" << std::endl;
          sim->core->nox_soc->writeWordIRAM((p+init_addr)/4,word_line);
        }
      }
    }
    else if ((lma_addr >= DRAM_ADDR && lma_addr < (DRAM_ADDR+(DRAM_KB_SIZE*1024))) && (file_size > 0x00)) {
      int init_addr = (lma_addr-DRAM_ADDR);

      if (mem_size >= (DRAM_KB_SIZE*1024)){
        cout << "[ELF Loader] DRAM ERROR:" << std::endl;
        cout << "ELF program: \t" << mem_size/1024 << " KB" << std::endl;
        cout << "Verilator model memory size: \t" << DRAM_KB_SIZE << " KB" << std::endl;
        cout << "ELF File too big for emulated memory!" << std::endl;
        return 1;
      }
      // DRAM Address
      for (uint32_t p = 0; p < mem_size; p+=4){
        uint32_t word_line = ((uint8_t)p_seg->get_data()[p+3]<<24)+((uint8_t)p_seg->get_data()[p+2]<<16)+
                             ((uint8_t)p_seg->get_data()[p+1]<<8)+(uint8_t)p_seg->get_data()[p];
        // If the whole word is zeroed, we don't write as it might overlap other regions
        if (!(word_line == 0x00)) {
          //if ((p+init_addr)/4 < 10)
          //  cout << "Addr[" << std::hex << (p+init_addr)/4 << "] Data[" << std::hex << word_line << "]" << std::endl;
          sim->core->nox_soc->writeWordDRAM((p+init_addr)/4,word_line);
        }
      }
    }
  }
  cout << std::endl;
  return 0;
}

int main(int argc, char** argv, char** env){
  Verilated::commandArgs(argc, argv);

  auto *dut = new testbench<Vnox_soc>;
  s_sim_setup_t setup = {
    .sim_cycles = 1000,
    .waves_dump = WAVEFORM_USE,
    .waves_path = STRINGIZE_VALUE_OF(WAVEFORM_FST)
  };

  cout << "[Nox SoC]" << std::endl;
  cout << "[IRAM] " << STRINGIZE_VALUE_OF(IRAM_KB_SIZE) << "KB" << std::endl;
  cout << "[DRAM] " << STRINGIZE_VALUE_OF(DRAM_KB_SIZE) << "KB" << std::endl;
  parse_input(argc, argv, &setup);

  int sim_cycles_timeout = setup.sim_cycles;

  if (WAVEFORM_USE)
    dut->opentrace(STRINGIZE_VALUE_OF(WAVEFORM_FST));

  if (loadELF(dut, setup.elf_path, true)) {
    cout << "\nError while processing ELF file!" << std::endl;
    exit(EXIT_FAILURE);
  }

  dut->reset(2);
  while(!Verilated::gotFinish() && setup.sim_cycles--) {
    dut->tick();
  }

  cout << "\n[SIM Summary]" << std::endl;
  cout << "Clk cycles elapsed\t= " << (sim_cycles_timeout-(setup.sim_cycles+1)) << std::endl;
  cout << "Remaining clk cycles\t= " << setup.sim_cycles+1 << std::endl;
  dut->close();
  exit(EXIT_SUCCESS);
}

double sc_time_stamp (){
    return tick_counter;
}
