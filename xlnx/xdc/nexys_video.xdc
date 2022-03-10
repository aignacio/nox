## Clock Signal
set_property -dict { PACKAGE_PIN R4   IOSTANDARD LVCMOS33 } [get_ports { clk_in }]; #IO_L13P_T2_MRCC_34 Sch=sysclk
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_in]

set_property -dict { PACKAGE_PIN F15 IOSTANDARD LVCMOS12 } [get_ports { rst_cpu }]; #IO_0_16 Sch=btnu
set_property -dict { PACKAGE_PIN D22 IOSTANDARD LVCMOS12 } [get_ports { rst_clk }]; #IO_L22N_T3_16 Sch=btnd

## Configuration options, can be used for all designs
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## LEDs
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS25 } [get_ports { csr_out[0] }]; #IO_L15P_T2_DQS_13 Sch=led[0]
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS25 } [get_ports { csr_out[1] }]; #IO_L15N_T2_DQS_13 Sch=led[1]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS25 } [get_ports { csr_out[2] }]; #IO_L17P_T2_13 Sch=led[2]
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS25 } [get_ports { csr_out[3] }]; #IO_L17N_T2_13 Sch=led[3]

set_property -dict { PACKAGE_PIN AA19  IOSTANDARD LVCMOS33 } [get_ports { uart_tx_o }]; #IO_L15P_T2_DQS_RDWR_B_14 Sch=uart_rx_out
set_property -dict { PACKAGE_PIN AB22  IOSTANDARD LVCMOS33 } [get_ports { uart_tx_mirror_o }]; #IO_L10N_T1_D15_14 Sch=ja[1]
