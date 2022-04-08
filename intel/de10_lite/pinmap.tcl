#============================================================
# Build by Terasic System Builder
#============================================================

set_global_assignment -name FAMILY "MAX 10"
set_global_assignment -name DEVICE 10M50DAF484C7G
set_global_assignment -name TOP_LEVEL_ENTITY "DE10_LITE_Default"
set_global_assignment -name DEVICE_FILTER_PACKAGE FBGA
set_global_assignment -name DEVICE_FILTER_PIN_COUNT 484
set_global_assignment -name DEVICE_FILTER_SPEED_GRADE 6

#============================================================
# CLOCK
#============================================================
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clk_in
set_location_assignment PIN_P11 -to clk_in

#============================================================
# LED
#============================================================
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to csr_out[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to csr_out[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to csr_out[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to csr_out[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to csr_out[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to csr_out[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to csr_out[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to csr_out[7]
set_location_assignment PIN_A8 -to  csr_out[0]
set_location_assignment PIN_A9 -to  csr_out[1]
set_location_assignment PIN_A10 -to csr_out[2]
set_location_assignment PIN_B10 -to csr_out[3]
set_location_assignment PIN_D13 -to csr_out[4]
set_location_assignment PIN_C13 -to csr_out[5]
set_location_assignment PIN_E14 -to csr_out[6]
set_location_assignment PIN_D14 -to csr_out[7]

#============================================================
# KEY
#============================================================
set_instance_assignment -name IO_STANDARD "3.3 V SCHMITT TRIGGER" -to rst_cpu
set_instance_assignment -name IO_STANDARD "3.3 V SCHMITT TRIGGER" -to bootloader_i
set_location_assignment PIN_B8 -to rst_cpu
set_location_assignment PIN_A7 -to bootloader_i

#============================================================
# Arduino
#============================================================
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clk_locked_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to uart_irq_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to uart_rx_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to uart_tx_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to uart_tx_mirror_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to rst_clk
set_location_assignment PIN_AB5 -to clk_locked_o
set_location_assignment PIN_AB6 -to uart_irq_o
set_location_assignment PIN_AB7 -to uart_rx_i
set_location_assignment PIN_AB8 -to uart_tx_o
set_location_assignment PIN_AB9 -to uart_tx_mirror_o
set_location_assignment PIN_Y10 -to rst_clk
