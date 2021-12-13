#include <iostream>
#include <string>

using namespace std;

typedef struct{
  int sim_cycles;
  int waves_dump;
  string waves_path;
  string elf_path;
} s_sim_setup_t;

void show_usage(void) {
  cerr  << "Usage: "
        << "\t-h,--help\tShow this help message\n"
        << "\t-s,--sim\tSimulation cycles\n"
        << "\t-e,--elf\tELF file to be loaded\n"
        << std::endl;
}

void show_summary(s_sim_setup_t *setup) {
  cout  << "=================================================" << std::endl;
  cout  << "Running simulation: \n"
        << "\n\tClock cycles: " << setup->sim_cycles
        << "\n\tWaves enable: " << setup->waves_dump
        << "\n\tWaves path: "   << setup->waves_path
        << "\n\tELF file: "     << setup->elf_path
        << "\n"
        << std::endl;
  cout  << "=================================================" << std::endl;

}

void parse_input (int argc, char** argv, s_sim_setup_t *setup){
  if (argc == 1) {
    show_usage();
    exit(EXIT_FAILURE);
  }

  for (int i=1; i < argc; ++i) {
    string arg = argv[i];
    if ((arg == "-h") || (arg == "--help")) {
      show_usage();
      exit(EXIT_SUCCESS);
    } else if ((arg == "-s") || (arg == "--sim")) {
      setup->sim_cycles = atoi(argv[i+1]);
    } else if ((arg == "-e") || (arg == "--elf")) {
      setup->elf_path = argv[i+1];
    }
  }
  show_summary(setup);
}


