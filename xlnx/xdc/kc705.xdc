##############################################################################
## Clock Signal
set_property -dict { PACKAGE_PIN AD12 IOSTANDARD LVDS } [get_ports clk_in_p];
set_property -dict { PACKAGE_PIN AD11 IOSTANDARD LVDS } [get_ports clk_in_n];
create_clock -add -name sys_clk_pin -period 5 [get_nets clk_in_p];

## LEDs
set_property PACKAGE_PIN AA8 [get_ports GPIO_LED_1_LS]
set_property IOSTANDARD LVCMOS15 [get_ports GPIO_LED_1_LS]
set_property PACKAGE_PIN AB8 [get_ports GPIO_LED_0_LS]
set_property IOSTANDARD LVCMOS15 [get_ports GPIO_LED_0_LS]
set_property PACKAGE_PIN AB9 [get_ports GPIO_LED_3_LS]
set_property IOSTANDARD LVCMOS15 [get_ports GPIO_LED_3_LS]
set_property PACKAGE_PIN AC9 [get_ports GPIO_LED_2_LS]
set_property IOSTANDARD LVCMOS15 [get_ports GPIO_LED_2_LS]

set_property -dict { PACKAGE_PIN AA8  IOSTANDARD LVCMOS15 } [get_ports { csr_out[0] }];
set_property -dict { PACKAGE_PIN AB8  IOSTANDARD LVCMOS15 } [get_ports { csr_out[1] }];
set_property -dict { PACKAGE_PIN AB9  IOSTANDARD LVCMOS15 } [get_ports { csr_out[2] }];
set_property -dict { PACKAGE_PIN AC9  IOSTANDARD LVCMOS15 } [get_ports { csr_out[3] }];
set_property -dict { PACKAGE_PIN AE26 IOSTANDARD LVCMOS25 } [get_ports { csr_out[4] }];

set_property -dict { PACKAGE_PIN AA12 IOSTANDARD LVCMOS15 } [get_ports { rst_cpu }]; # North
set_property -dict { PACKAGE_PIN AC6  IOSTANDARD LVCMOS15 } [get_ports { rst_clk }]; # West
set_property -dict { PACKAGE_PIN AB12 IOSTANDARD LVCMOS15 } [get_ports { bootloader_i }]; # South

## UART
set_property -dict { PACKAGE_PIN K24 IOSTANDARD LVCMOS25 } [get_ports { uart_rx_i }];
set_property -dict { PACKAGE_PIN M19 IOSTANDARD LVCMOS25 } [get_ports { uart_tx_o }];
set_property -dict { PACKAGE_PIN G19 IOSTANDARD LVCMOS25 } [get_ports { uart_tx_mirror_o }];
