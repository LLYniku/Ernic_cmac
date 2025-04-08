`timescale 1ps/1ps

module cmac_usplus_0_exdes_tb
(
);

  parameter       OPERATION = 1;
  `define         PKT_GEN  0
  `define         PKT_MON  1
  `define         GT_LOCK  2
  `define         RX_ALIGN 3

    task  display_result;
        input [1:0] module_name;
        input test_result, timeout;
        begin
            if (timeout== 1'b1)
            begin
                if (module_name == 2'd0)
                    $display("ERROR : Packet Generator failed - Time Out Error");
                else if  (module_name == 2'd1)
                    $display("ERROR : Packet Monitor failed - Time Out Error");
                else if  (module_name == 2'd2)
                    $display("ERROR : GT LOCK failed - Time Out Error");
                else if  (module_name == 2'd3)
                    $display("ERROR : Rx_Aligned failed - Time Out Error");
                
            $display("ERROR : Time Out Error");
            $finish;
            end
            else if (test_result == 1'b1)
            begin 
                if (module_name == 2'd0)
                    $display("WARNING : Packets generation stopped due to tx_ovfout / tx_unfout");
                else
                    $display("ERROR : ALL PACKETS RECEIVED, WITH ERRORS");
            end
            else 
            begin 
                if (module_name == 2'd0)
                    $display("INFO : ALL PACKETS SENT, NO ERRORS");
                else if (module_name == 2'd1)
                    $display("INFO : ALL PACKETS RECEIVED, NO ERRORS");
                else if (module_name == 2'd2)
                    $display("INFO : GT LOCKED");
                else if (module_name == 2'd3)
                    $display("INFO : RX-ALIGNED");
            end
        end
   endtask

    reg             init_clk;

    
    reg             gt_ref_clk_p;
    reg             gt_ref_clk_n;
    reg             sys_reset;
    reg             send_continuous_pkts;
    reg             test_fail;
    reg             timed_out;
    reg             time_out_cntr_en;
    reg  [23 :0]    time_out_cntr;

    wire [3 :0]     gt_p_loopback;
    wire [3 :0]     gt_n_loopback;

    reg             lbus_tx_rx_restart_in;
    reg             simplex_mode_rx_aligned;
             
    wire            tx_gt_locked_led;
             
    wire            tx_done_led;
    wire            tx_busy_led;

    wire            rx_gt_locked_led;
    wire            rx_aligned_led;
    wire            rx_done_led;
    wire            rx_data_fail_led;
    wire            rx_busy_led;



cmac_usplus_0_exdes EXDES
(
.gt_ref_clk_p                    (gt_ref_clk_p),
.gt_ref_clk_n                    (gt_ref_clk_n),
.sys_reset                       (sys_reset),
.send_continuous_pkts            (send_continuous_pkts),
.lbus_tx_rx_restart_in           (lbus_tx_rx_restart_in),
.simplex_mode_rx_aligned         (simplex_mode_rx_aligned),
.tx_gt_locked_led                (tx_gt_locked_led),
.tx_done_led                     (tx_done_led),
.tx_busy_led                     (tx_busy_led),
.gt_txp_out                      (gt_p_loopback),
.gt_txn_out                      (gt_n_loopback),
.init_clk                        (init_clk)
);

cmac_usplus_0_partner_exdes PARTNER
(
.gt_ref_clk_p                    (gt_ref_clk_p),
.gt_ref_clk_n                    (gt_ref_clk_n),
.sys_reset                       (sys_reset),
.send_continuous_pkts            (send_continuous_pkts),
.lbus_tx_rx_restart_in           (lbus_tx_rx_restart_in),
.rx_gt_locked_led                (rx_gt_locked_led),
.rx_aligned_led                  (rx_aligned_led),
.rx_done_led                     (rx_done_led),
.rx_data_fail_led                (rx_data_fail_led),
.rx_busy_led                     (rx_busy_led),
.gt_rxp_in                       (gt_p_loopback),
.gt_rxn_in                       (gt_n_loopback),
.init_clk                        (init_clk)
);

    initial
    begin
      sys_reset  = 1;
      send_continuous_pkts  = 0;
      lbus_tx_rx_restart_in = 0;
      simplex_mode_rx_aligned = 0;

      repeat (100) @(posedge init_clk);
      sys_reset = 0;
      $display("INFO : SYS_RESET RELEASED TO CMAC IP");

      $display("INFO : WAITING FOR THE GT LOCK..........");
      time_out_cntr_en = 1;
      if (OPERATION == 0)
      begin
          $display("ERROR : Invalid Operation");
          $display("INFO  : Test FAILED");
          $finish;
      end

      wait(tx_gt_locked_led || timed_out);
      display_result(`GT_LOCK, 1'b0, timed_out);
      $display("           Core_Version  =  3.1");

      time_out_cntr_en = 0;


      $display("INFO : WAITING FOR CMAC RX_ALIGNED..........");
      repeat (1) @(posedge init_clk);
      time_out_cntr_en = 1;

    //   wait (rx_aligned_led || timed_out);
      display_result(`RX_ALIGN, 1'b0, timed_out);
      simplex_mode_rx_aligned = 1;
      time_out_cntr_en = 0;

      repeat (1) @(posedge init_clk);
      lbus_tx_rx_restart_in = 0;
      send_continuous_pkts  = 0;  //// 0 : For fixed number of packet transmission
                                  //// 1 : For streaming continuous packets

      $display("INFO : Packet Generator and Monitor (SANITY Testing) STARTED");
      wait(tx_done_led);
      display_result(`PKT_GEN, 1'b0, 1'b0);
      wait(rx_done_led);
      display_result(`PKT_MON, rx_data_fail_led, 1'b0);
      wait((!tx_busy_led) && (!rx_busy_led));

      repeat (5) @(posedge init_clk);

      $display(" ");
      $display("INFO : ***** PACKET GENERATION RESTARTED *****");
      $display(" ");
      $display("INFO : Packet Generator and Monitor (SANITY Testing) STARTED");
      lbus_tx_rx_restart_in = 1;
      repeat (4) @(posedge init_clk);
      lbus_tx_rx_restart_in = 0;

      wait((!tx_done_led) && (!rx_done_led));
      wait(tx_done_led);
      display_result(`PKT_GEN, 1'b0, 1'b0);
      wait(rx_done_led);
      display_result(`PKT_MON, rx_data_fail_led, 1'b0);
      wait((!tx_busy_led) && (!rx_busy_led));


      repeat (20) @(posedge init_clk);

      if (test_fail == 1'b1)
           $display("ERROR : All the Test Cases Completed but Failed with Errors/Warnings");
      else
           $display("INFO : Test Completed Successfully");

      $finish;
    end

    //////////////////////////////////////////////////
    ////time_out_cntr signal generation Max 26ms
    //////////////////////////////////////////////////
    always @( posedge init_clk or negedge sys_reset )
    begin
        if ( sys_reset == 1'b1 )
        begin
            timed_out     <= 1'b0;
            time_out_cntr <= 24'd0;
        end
        else
        begin
            timed_out <= time_out_cntr[20];
            if (time_out_cntr_en == 1'b1)
                time_out_cntr <= time_out_cntr + 24'd1;
            else
                time_out_cntr <= 24'd0;
        end
    end

    //////////////////////////////////////////////////
    ////test_fail signal generation
    //////////////////////////////////////////////////
    always @( posedge init_clk or posedge sys_reset )
    begin
        if ( sys_reset == 1'b1 )
        begin
            test_fail     <= 1'b0;
        end
        else
        begin
            if (rx_data_fail_led == 1'b1)
                test_fail <= 1'b1;
        end
    end

    initial
    begin
        gt_ref_clk_p =1;
        forever #3103.030   gt_ref_clk_p = ~ gt_ref_clk_p;
    end

    initial
    begin
        gt_ref_clk_n =0;
        forever #3103.030   gt_ref_clk_n = ~ gt_ref_clk_n;
    end

    initial
    begin
        init_clk =1;
        forever #5000.000 init_clk = ~init_clk;
    end

endmodule

