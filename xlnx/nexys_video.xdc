## Clock Signal
set_property -dict { PACKAGE_PIN R4   IOSTANDARD LVCMOS33 } [get_ports { clk_in }]; #IO_L13P_T2_MRCC_34 Sch=sysclk
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_in]
set_property -dict { PACKAGE_PIN E22  IOSTANDARD LVCMOS12 } [get_ports { rst }]; #IO_L22P_T3_16 Sch=sw[0]

## Configuration options, can be used for all designs
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
