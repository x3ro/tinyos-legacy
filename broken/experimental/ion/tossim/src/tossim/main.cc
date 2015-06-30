#include <tossim/util/CommandLine.hh>

int main(int argc, char ** argv)
{
  CommandLine command_line(argv, argc);
  CommandLine::Arguments& arguments = command_line.arguments();
  CommandLine::Options& options = command_line.options();

  Simulator tossim;

  tossim.power_profiling = options.has_option(Simulator::POWER_PROFILING);
  tossim.cpu_profiling = options.has_option(Simulator::CPU_PROFILING);
  tossim.adc_type;
  tossim.radio_type;
  tossim.eeprom_name;

  tossim.setup_debug();

  tossim.setup_power();

  tossim.setup_signals();


  
}
