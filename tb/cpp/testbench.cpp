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
#include "Vnox_sim.h"
#include "Vnox_sim__Syms.h"

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
        core->rst = 0;
        this->tick();
      }
      core->rst = 1;
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
      core->clk = 0;
      core->eval();
      tick_counter++;
      if(trace) trace->dump(tick_counter);

      core->clk = 1;
      core->eval();
      tick_counter++;
      if(trace) trace->dump(tick_counter);
    }

    virtual bool done(void) {
      return (Verilated::gotFinish());
    }
};

bool loadELF(testbench<Vnox_sim> *sim, string program_path, const bool en_print){
  ELFIO::elfio program;

  program.load(program_path);

  if (program.get_class() != ELFCLASS32 ||
    program.get_machine() != 0xf3){
    cout << "\n[ERROR] Error loading ELF file, headers does not match with ELFCLASS32/RISC-V!" << endl;
    return false;
  }

  ELFIO::Elf_Half seg_num = program.segments.size();

  if (en_print){
    cout << "[ELF Loader]"    << std::endl;
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
      printf("\nSegment [%d] - LMA[0x%x] VMA[0x%x]", i,(uint32_t)lma_addr,(uint32_t)vma_addr);
      printf("\nFile size [%d] - Memory size [%d]",file_size,mem_size);
    }
    if (mem_size >= (IRAM_KB_SIZE*1024)){
      printf("\n\n[ELF Loader] ERROR:");
      printf("\nELF program: %d bytes", mem_size);
      printf("\nVerilator model memory size: %d bytes", (IRAM_KB_SIZE*1024));
      return 1;
    }
    if ((lma_addr >= IRAM_ADDR && lma_addr < (IRAM_ADDR+(IRAM_KB_SIZE*1024))) && (file_size > 0x00)){
      int init_addr = (lma_addr-IRAM_ADDR);
      // IRAM Address
      if (en_print) printf("\n> IRAM address space");
      for (uint32_t p = 0; p < mem_size; p+=4){
        uint32_t word_line = ((uint8_t)p_seg->get_data()[p+3]<<24)+((uint8_t)p_seg->get_data()[p+2]<<16)+
                             ((uint8_t)p_seg->get_data()[p+1]<<8)+(uint8_t)p_seg->get_data()[p];
        // If the whole word is zeroed, we don't write as it might overlap other regions
        if (!(word_line == 0x00)) {
          cout << "Addr[" << (p+init_addr)/4<< "] Data [" << word_line << "]" << std::endl;
          sim->core->nox_sim->writeWordIRAM((p+init_addr)/4,word_line);
        }
      }
    }
  }
  cout << std::endl;
  return 0;
}

int main(int argc, char** argv, char** env){
  auto *dut = new testbench<Vnox_sim>;
  s_sim_setup_t setup = {
    .sim_cycles = 1000,
    .waves_dump = 1,
    .waves_path = STRINGIZE_VALUE_OF(WAVEFORM_FST)
  };

  cout << "[Nox SIM]" << std::endl;
  cout << "[IRAM] " << STRINGIZE_VALUE_OF(IRAM_KB_SIZE) << "KB" << std::endl;
  cout << "[DRAM] " << STRINGIZE_VALUE_OF(DRAM_KB_SIZE) << "KB" << std::endl;
  parse_input(argc, argv, &setup);
  dut->opentrace(STRINGIZE_VALUE_OF(WAVEFORM_FST));

  if (loadELF(dut, setup.elf_path, true)) {
    cout << "\nError while processing ELF file!" << std::endl;
    exit(1);
  }

  dut->reset(2);
  while(setup.sim_cycles--) {
    dut->tick();
  }
  dut->close();
  exit(EXIT_SUCCESS);
}

double sc_time_stamp (){
    return tick_counter;
}
