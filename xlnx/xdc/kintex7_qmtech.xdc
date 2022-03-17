set_property BITSTREAM.General.UnconstrainedPins {Allow} [current_design]

## Clock Signal
create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 10} [get_ports clk_in]
set_property -dict { PACKAGE_PIN F22 IOSTANDARD LVCMOS33 } [get_ports { clk_in }];

## LEDs
set_property -dict { PACKAGE_PIN J26 IOSTANDARD LVCMOS33 } [get_ports { csr_out[0] }];
set_property -dict { PACKAGE_PIN H26 IOSTANDARD LVCMOS33 } [get_ports { csr_out[1] }];

set_property -dict { PACKAGE_PIN AF9  IOSTANDARD LVCMOS18 } [get_ports { rst_cpu }];
set_property -dict { PACKAGE_PIN AF10 IOSTANDARD LVCMOS18 } [get_ports { bootloader_i }];

## UART
set_property -dict { PACKAGE_PIN A8  IOSTANDARD LVCMOS33 } [get_ports { uart_rx_i }];
set_property -dict { PACKAGE_PIN B9  IOSTANDARD LVCMOS33 } [get_ports { uart_tx_o }];
set_property -dict { PACKAGE_PIN A10 IOSTANDARD LVCMOS33 } [get_ports { uart_tx_mirror_o }];
