## Clock Signal
# 100 MHz clock
set_property -dict {LOC R4 IOSTANDARD LVCMOS33} [get_ports clk_in]
create_clock -period 10.000 -name clk [get_ports clk_in]

set_property -dict { PACKAGE_PIN F15 IOSTANDARD LVCMOS12 } [get_ports { rst_cpu }]; #IO_0_16 Sch=btnu
set_property -dict { PACKAGE_PIN D22 IOSTANDARD LVCMOS12 } [get_ports { rst_clk }]; #IO_L22N_T3_16 Sch=btnd

# General configuration
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true [current_design]

## LEDs
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS25 } [get_ports { csr_out[0] }]; #IO_L15P_T2_DQS_13 Sch=led[0]
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS25 } [get_ports { csr_out[1] }]; #IO_L15N_T2_DQS_13 Sch=led[1]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS25 } [get_ports { csr_out[2] }]; #IO_L17P_T2_13 Sch=led[2]
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS25 } [get_ports { csr_out[3] }]; #IO_L17N_T2_13 Sch=led[3]
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS25 } [get_ports { csr_out[4] }]; #IO_L14N_T2_SRCC_13 Sch=led[4]
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS25 } [get_ports { csr_out[5] }]; #IO_L16N_T2_13 Sch=led[5]
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS25 } [get_ports { csr_out[6] }]; #IO_L16P_T2_13 Sch=led[6]
set_property -dict { PACKAGE_PIN Y13   IOSTANDARD LVCMOS25 } [get_ports { csr_out[7] }]; #IO_L5P_T0_13 Sch=led[7]

## UART
set_property -dict { PACKAGE_PIN AA19  IOSTANDARD LVCMOS33 } [get_ports { uart_tx_o }]; #IO_L15P_T2_DQS_RDWR_B_14 Sch=uart_rx_out
set_property -dict { PACKAGE_PIN V18   IOSTANDARD LVCMOS33 } [get_ports { uart_rx_i }]; #IO_L14P_T2_SRCC_14 Sch=uart_tx_in
set_property -dict { PACKAGE_PIN B22   IOSTANDARD LVCMOS12 } [get_ports { bootloader_i }]; #IO_L20N_T3_16 Sch=btnc

set_false_path -from [get_ports {rst_cpu}]
set_input_delay 0 [get_ports {rst_cpu}]
set_false_path -from [get_ports {rst_clk}]
set_input_delay 0 [get_ports {rst_clk}]

# Gigabit Ethernet RGMII PHY
set_property -dict {LOC V13 IOSTANDARD LVCMOS25} [get_ports phy_rx_clk]
set_property -dict {LOC AB16 IOSTANDARD LVCMOS25} [get_ports {phy_rxd[0]}]
set_property -dict {LOC AA15 IOSTANDARD LVCMOS25} [get_ports {phy_rxd[1]}]
set_property -dict {LOC AB15 IOSTANDARD LVCMOS25} [get_ports {phy_rxd[2]}]
set_property -dict {LOC AB11 IOSTANDARD LVCMOS25} [get_ports {phy_rxd[3]}]
set_property -dict {LOC W10 IOSTANDARD LVCMOS25} [get_ports phy_rx_ctl]
set_property -dict {LOC AA14 IOSTANDARD LVCMOS25 SLEW FAST DRIVE 16} [get_ports phy_tx_clk]
set_property -dict {LOC Y12 IOSTANDARD LVCMOS25 SLEW FAST DRIVE 16} [get_ports {phy_txd[0]}]
set_property -dict {LOC W12 IOSTANDARD LVCMOS25 SLEW FAST DRIVE 16} [get_ports {phy_txd[1]}]
set_property -dict {LOC W11 IOSTANDARD LVCMOS25 SLEW FAST DRIVE 16} [get_ports {phy_txd[2]}]
set_property -dict {LOC Y11 IOSTANDARD LVCMOS25 SLEW FAST DRIVE 16} [get_ports {phy_txd[3]}]
set_property -dict {LOC V10 IOSTANDARD LVCMOS25 SLEW FAST DRIVE 16} [get_ports phy_tx_ctl]
set_property -dict {LOC U7 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports phy_reset_n]
set_property -dict {LOC Y14 IOSTANDARD LVCMOS25} [get_ports phy_int_n]
set_property -dict {LOC W14 IOSTANDARD LVCMOS25} [get_ports phy_pme_n]

create_clock -period 8.000 -name phy_rx_clk [get_ports phy_rx_clk]

set_false_path -to [get_ports {phy_reset_n}]
set_output_delay 0 [get_ports {phy_reset_n}]
set_false_path -from [get_ports {phy_int_n phy_pme_n}]
set_input_delay 0 [get_ports {phy_int_n phy_pme_n}]

set_property IDELAY_VALUE 0 [get_cells {phy_rx_ctl_idelay phy_rxd_idelay_*}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks clk]
set_clock_groups -asynchronous -group [get_clocks  clk_mmcm_out_125MHz] -group [get_clocks clk_out_50MHz]

#set_false_path -from [get_clocks  clk_mmcm_out_125MHz] -to [get_clocks clk_out_clk_wiz_2]
#set async_fifos [get_cells -hier -filter {(ORIG_REF_NAME == axis_async_fifo || REF_NAME == axis_async_fifo || ORIG_REF_NAME == axis_async_frame_fifo || REF_NAME == axis_async_frame_fifo)}]
#foreach fifo $async_fifos {
    #puts $fifo
    ## ASYNC_REG property on the reset synchronizer flip-flops
    #set reset_ffs [get_cells -hier -regexp {.*/(s|m)_rst_sync[123]_reg_reg} -filter "PARENT == $fifo"]
    #set_property ASYNC_REG TRUE $reset_ffs

    ## false path to reset pins on the reset synchronizer flip-flops
    #set_false_path -to [get_pins -of_objects $reset_ffs -filter {IS_PRESET || IS_RESET}]

    ## false path to the second stage reset synchronizer flip-flops data
    #set_false_path -to [get_pins $fifo/s_rst_sync2_reg_reg/D]
    #set_false_path -to [get_pins $fifo/m_rst_sync2_reg_reg/D]

    ## max delayto 2ns to maximize metastability settle time
    #set_max_delay -from [get_cells $fifo/s_rst_sync2_reg_reg] -to [get_cells $fifo/s_rst_sync3_reg_reg] 2
    #set_max_delay -from [get_cells $fifo/m_rst_sync2_reg_reg] -to [get_cells $fifo/m_rst_sync3_reg_reg] 2

    ## set ASYNC_REG property for all registers in the grey code synchronizer chain
    #set_property ASYNC_REG TRUE [get_cells -hier -regexp {.*/(wr|rd)_ptr_gray_sync[12]_reg_reg\[\d+\]} -filter "PARENT == $fifo"]

    ## extract write/read clocks from the grey code registers
    #set read_clk [get_clocks -of_objects [get_pins $fifo/rd_ptr_reg_reg[0]/C]]
    #set write_clk [get_clocks -of_objects [get_pins $fifo/wr_ptr_reg_reg[0]/C]]

    ## rd_ptr_gray_sync is synchronized from the read clock to the write clock so
    ## we use the read clock (launch clock) period to constrain the max_delay
    #set_max_delay -from [get_cells $fifo/rd_ptr_gray_reg_reg[*]] -to [get_cells $fifo/rd_ptr_gray_sync1_reg_reg[*]] -datapath_only [get_property -min PERIOD $read_clk]
    ## similarly we uuse the write clock period to constrain the max_delay for the wr_ptr_gray_sync
    #set_max_delay -from [get_cells $fifo/wr_ptr_gray_reg_reg[*]] -to [get_cells $fifo/wr_ptr_gray_sync1_reg_reg[*]] -datapath_only [get_property -min PERIOD $write_clk]

    ## for async_frame_fifos there are a few more status synchronization registers
    #if {[string match [get_property ORIG_REF_NAME [get_cells $fifo]] axis_async_frame_fifo] || [string match [get_property REF_NAME [get_cells $fifo]] axis_async_frame_fifo]} {
        #set status_sync_regs [get_cells -quiet -hier -regexp {.*/(?:overflow|bad_frame|good_frame)_sync[1234]_reg_reg} -filter "PARENT == $fifo"]
        #foreach reg $status_sync_regs {
            #set_property ASYNC_REG TRUE $reg
        #}
    #}
#}
