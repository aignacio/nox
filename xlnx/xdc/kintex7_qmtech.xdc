set_property BITSTREAM.General.UnconstrainedPins {Allow} [current_design]

## Clock Signal
create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 10} [get_ports clk_in]
set_property -dict { PACKAGE_PIN F22 IOSTANDARD LVCMOS33 } [get_ports { clk_in }];

## LEDs
set_property -dict { PACKAGE_PIN J26 IOSTANDARD LVCMOS33 } [get_ports { csr_out[0] }];
set_property -dict { PACKAGE_PIN H26 IOSTANDARD LVCMOS33 } [get_ports { uart_irq_o }];

#set_property -dict { PACKAGE_PIN AF9  IOSTANDARD LVCMOS18 } [get_ports { rst_cpu }];
#set_property -dict { PACKAGE_PIN AF10 IOSTANDARD LVCMOS18 } [get_ports { bootloader_i }];

## UART
set_property -dict { PACKAGE_PIN B12 IOSTANDARD LVCMOS33 } [get_ports { uart_rx_i }];
set_property -dict { PACKAGE_PIN B11 IOSTANDARD LVCMOS33 } [get_ports { uart_tx_o }];
#set_property -dict { PACKAGE_PIN A9  IOSTANDARD LVCMOS33 } [get_ports { uart_tx_o }];
#set_property -dict { PACKAGE_PIN A9 IOSTANDARD LVCMOS33 } [get_ports { uart_tx_mirror_o }];

## Pmod Header JC
set_property -dict { PACKAGE_PIN A9   IOSTANDARD LVCMOS33 } [get_ports { spi_csn_o }]; #IO_L24P_T3_34 Sch=jb_p[3]
set_property -dict { PACKAGE_PIN C9   IOSTANDARD LVCMOS33 } [get_ports { spi_mosi_o }]; #IO_L24N_T3_34 Sch=jb_n[3]
set_property -dict { PACKAGE_PIN A10  IOSTANDARD LVCMOS33 } [get_ports { spi_gpio_o[0] }]; #IO_L19P_T3_34 Sch=jb_p[2]
set_property -dict { PACKAGE_PIN E10  IOSTANDARD LVCMOS33 } [get_ports { spi_clk_o }]; #IO_L23N_T3_34 Sch=jb_n[4]

# GPIO LEDs
set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 } [get_ports { csr_out[1] }];
set_property -dict { PACKAGE_PIN A19 IOSTANDARD LVCMOS33 } [get_ports { csr_out[2] }];
set_property -dict { PACKAGE_PIN C17 IOSTANDARD LVCMOS33 } [get_ports { csr_out[3] }];
set_property -dict { PACKAGE_PIN C18 IOSTANDARD LVCMOS33 } [get_ports { csr_out[4] }];
set_property -dict { PACKAGE_PIN E18 IOSTANDARD LVCMOS33 } [get_ports { csr_out[5] }];

# Pushbuttons
set_property -dict { PACKAGE_PIN AD21 IOSTANDARD LVCMOS33 } [get_ports { rst_cpu }];
set_property -dict { PACKAGE_PIN B20  IOSTANDARD LVCMOS33 } [get_ports { bootloader_i }];
set_property -dict { PACKAGE_PIN A20  IOSTANDARD LVCMOS33 } [get_ports { rst_clk }];
