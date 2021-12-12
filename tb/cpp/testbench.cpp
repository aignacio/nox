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

#include "common/common.h"
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
        core->arst = 1;
        this->tick();
      }
      core->arst = 0;
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

int main(int argc, char** argv, char** env){
  auto *dut = new testbench<Vnox_sim>;
  s_sim_setup_t setup = {
    .sim_cycles = 1000,
    .waves_dump = 0,
    .waves_path = STRINGIZE_VALUE_OF(WAVEFORM_FST)
  };
  parse_input(argc, argv, &setup);

  dut->opentrace(STRINGIZE_VALUE_OF(WAVEFORM_FST));
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
