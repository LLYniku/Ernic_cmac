



 create_clock -name CLK -period 10.0 [ get_ports aclk ] 
 


 create_clock -name CMAC_TX_CLK -period 3.105 [ get_ports cmac_tx_clk ] 
 create_clock -name CMAC_RX_CLK -period 3.105 [ get_ports cmac_rx_clk ] 
