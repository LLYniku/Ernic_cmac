### -----------------------------------------------------------------------------
### CMAC example design-level XDC file
### -----------------------------------------------------------------------------
# 100 MHz
# 100 MHz
# set_property -dict {LOC BB18 IOSTANDARD LVDS} [get_ports clk_100mhz_1_p]
# set_property -dict {LOC BC18 IOSTANDARD LVDS} [get_ports clk_100mhz_1_n]
# create_clock -period 10.000 -name clk_100mhz_1 [get_ports clk_100mhz_1_p]

### For init_clk input pin assignment, if single-ended clock is not available
### on the board, user has to instantiate IBUFDS in Example Design to convert
### the differential clock to single-ended clock and make the necessary changes
# set_property PACKAGE_PIN AV33 [get_ports init_clk]
#set_property LOC BB24 [get_ports sys_reset]
#set_property LOC D21 [get_ports send_continuous_pkts]
#set_property LOC BD23 [get_ports lbus_tx_rx_restart_in]






#beizhu
# set_property IOSTANDARD LVCMOS18 [get_ports init_clk]
# set_property IOSTANDARD LVCMOS18 [get_ports clk_100mhz_1_int]




# set_property PACKAGE_PIN A10 [get_ports clk_100mhz_1_int]
# set_property PACKAGE_PIN A12 [get_ports lbus_tx_rx_restart_in]
# set_property PACKAGE_PIN A13 [get_ports send_continuous_pkts]


#----------------------------------------------1026---------------------------------------------------
set_property -dict {LOC BB18 IOSTANDARD LVDS} [get_ports init_clk_p]
set_property -dict {LOC BC18 IOSTANDARD LVDS} [get_ports init_clk_n]
create_clock -period 10.000 -name init_clk [get_ports init_clk_p]
# General configuration

set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.CONFIG.CONFIGFALLBACK ENABLE [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 85.0 [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DISABLE [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN Enable [current_design]
set_operating_conditions -design_power_budget 63


# HBM overtemp
set_property -dict {LOC J18 IOSTANDARD LVCMOS18} [get_ports hbm_cattrip]

set_false_path -to [get_ports {hbm_cattrip}]
set_output_delay 0 [get_ports {hbm_cattrip}]

#clock

# set_property -dict {LOC N36} [get_ports gt_ref_clk_p]
# set_property -dict {LOC N37} [get_ports gt_ref_clk_n]

# # 161.1328125 MHz MGT reference clock (U50 OUT0)
# create_clock -period 6.206 -name gt_ref_clk [get_ports gt_ref_clk_p]

# GT clock need getports 161MHz
set_property -dict {LOC N36} [get_ports gt_ref_clk_p]         ;# Bank 131 - MGTREFCLK0N_131 
set_property -dict {LOC N37} [get_ports gt_ref_clk_n]         ;# Bank 131 - MGTREFCLK0P_131
#create_clock -period 6.206  -name gt_ref_clk      [get_ports gt_ref_clk_p]

# init clock 100MHz
# set_property PACKAGE_PIN BC18     [get_ports "SYSCLK3_N"]            ;# Bank  64 VCCO - VCC1V8   - IO_L11N_T1U_N9_GC_64
# set_property IOSTANDARD  LVDS     [get_ports "SYSCLK3_N"]            ;# Bank  64 VCCO - VCC1V8   - IO_L11N_T1U_N9_GC_64
# set_property PACKAGE_PIN BB18     [get_ports "SYSCLK3_P"]            ;# Bank  64 VCCO - VCC1V8   - IO_L11P_T1U_N8_GC_64
# set_property IOSTANDARD  LVDS     [get_ports "SYSCLK3_P"]            ;# Bank  64 VCCO - VCC1V8   - IO_L11P_T1U_N8_GC_64
# set_property DQS_BIAS TRUE        [get_ports "SYSCLK3_P"]            ;# Bank  64 VCCO - VCC1V8   - IO_L11P_T1U_N8_GC_64
# create_clock -period 10.000 -name sysclk3        [get_ports "SYSCLK3_P"]  ;#init_clk

#led information: E18 green led, E16 green led, F17 yellow led

set_property PACKAGE_PIN E18 [get_ports tx_done_led]
set_property PACKAGE_PIN E16 [get_ports tx_busy_led]
set_property PACKAGE_PIN F17 [get_ports tx_gt_locked_led]

set_property IOSTANDARD LVCMOS18 [get_ports tx_done_led]
set_property IOSTANDARD LVCMOS18 [get_ports tx_busy_led]
set_property IOSTANDARD LVCMOS18 [get_ports tx_gt_locked_led]



# create_clock -period 10.000 [get_ports init_clk]
# set_property IOSTANDARD LVCMOS18 [get_ports init_clk]

# QSFP28 only TX Interfaces
# set_property -dict {LOC J45} [get_ports {gt_rxp_in[0]}]
# set_property -dict {LOC J46} [get_ports {gt_rxn_in[0]}]
set_property -dict {LOC D42} [get_ports {gt_txp_out[0]}]
set_property -dict {LOC D43} [get_ports {gt_txn_out[0]}]

# set_property -dict {LOC G45} [get_ports {gt_rxp_in[1]}]
# set_property -dict {LOC G46} [get_ports {gt_rxn_in[1]}]
set_property -dict {LOC C40} [get_ports {gt_txp_out[1]}]
set_property -dict {LOC C41} [get_ports {gt_txn_out[1]}]

# set_property -dict {LOC F43} [get_ports {gt_rxp_in[2]}]
# set_property -dict {LOC F44} [get_ports {gt_rxn_in[2]}]
set_property -dict {LOC B42} [get_ports {gt_txp_out[2]}]
set_property -dict {LOC B43} [get_ports {gt_txn_out[2]}]

# set_property -dict {LOC E45} [get_ports {gt_rxp_in[3]}]
# set_property -dict {LOC E46} [get_ports {gt_rxn_in[3]}]
set_property -dict {LOC A40} [get_ports {gt_txp_out[3]}]
set_property -dict {LOC A41} [get_ports {gt_txn_out[3]}]

