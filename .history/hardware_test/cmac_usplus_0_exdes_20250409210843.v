`timescale 1ps/1ps

(* DowngradeIPIdentifiedWarnings="yes" *)
module cmac_usplus_0_exdes
(
    output [3 :0]   gt_txp_out,
    output [3 :0]   gt_txn_out,

    // input  wire     send_continuous_pkts,
    // input  wire     lbus_tx_rx_restart_in,
    // input  wire     simplex_mode_rx_aligned,
    output wire     tx_gt_locked_led,
    output wire     tx_done_led,
    output wire     tx_busy_led,
    output wire     hbm_cattrip,
    input  wire     gt_ref_clk_p,
    input  wire     gt_ref_clk_n,


    // input  wire     sys_reset,
    // input  wire     init_clk
    input  wire     init_clk_p,         //100GHz
    input  wire     init_clk_n
);

  parameter PKT_NUM      = 1000;    //// 1 to 65535 (Number of packets)
  parameter PKT_SIZE     = 522;     //// Min pkt size 64 Bytes; Max pkt size 16000 Bytes
                                    //// Above Min value is >= GUI configured Min pkt value
                                    //// and Max value is <= GUI configured Max pkt value
  
  wire [11 :0]    gt_loopback_in;

  //// For other GT loopback options please change the value appropriately
  //// For example, for Near End PMA loopback for 4 Lanes update the gt_loopback_in = {4{3'b010}};
  //// For more information and settings on loopback, refer GT Transceivers user guide

  assign gt_loopback_in  = {4{3'b000}};

  wire            gt_ref_clk_out;
  wire [3 :0]     gt_rxrecclkout;
  wire [3 :0]     gt_powergoodout;
  wire            gtwiz_reset_tx_datapath;
  wire            gtwiz_reset_rx_datapath;
  wire            txusrclk2;
  wire            tx_axis_tready;
  wire            tx_axis_tvalid;
  wire [511:0]    tx_axis_tdata;
  wire            tx_axis_tlast;
  wire [63:0]     tx_axis_tkeep;
  wire            tx_axis_tuser;
  wire            tx_rdyout;
  wire [128-1:0]  tx_datain0;
  wire            tx_enain0;
  wire            tx_sopin0;
  wire            tx_eopin0;
  wire            tx_errin0;
  wire [4-1:0]    tx_mtyin0;
  wire [128-1:0]  tx_datain1;
  wire            tx_enain1;
  wire            tx_sopin1;
  wire            tx_eopin1;
  wire            tx_errin1;
  wire [4-1:0]    tx_mtyin1;
  wire [128-1:0]  tx_datain2;
  wire            tx_enain2;
  wire            tx_sopin2;
  wire            tx_eopin2;
  wire            tx_errin2;
  wire [4-1:0]    tx_mtyin2;
  wire [128-1:0]  tx_datain3;
  wire            tx_enain3;
  wire            tx_sopin3;
  wire            tx_eopin3;
  wire            tx_errin3;
  wire [4-1:0]    tx_mtyin3;
  wire            tx_ovfout;
  wire            tx_unfout;
  wire [55:0]     tx_preamblein;
  wire            usr_tx_reset;
//   wire            stat_tx_bad_fcs;
//   wire            stat_tx_broadcast;
//   wire            stat_tx_frame_error;
//   wire            stat_tx_local_fault;
//   wire            stat_tx_multicast;
//   wire            stat_tx_packet_1024_1518_bytes;
//   wire            stat_tx_packet_128_255_bytes;
//   wire            stat_tx_packet_1519_1522_bytes;
//   wire            stat_tx_packet_1523_1548_bytes;
//   wire            stat_tx_packet_1549_2047_bytes;
//   wire            stat_tx_packet_2048_4095_bytes;
//   wire            stat_tx_packet_256_511_bytes;
//   wire            stat_tx_packet_4096_8191_bytes;
//   wire            stat_tx_packet_512_1023_bytes;
//   wire            stat_tx_packet_64_bytes;
//   wire            stat_tx_packet_65_127_bytes;
//   wire            stat_tx_packet_8192_9215_bytes;
//   wire            stat_tx_packet_large;
//   wire            stat_tx_packet_small;
//   wire [5:0]      stat_tx_total_bytes;
//   wire [13:0]     stat_tx_total_good_bytes;
//   wire            stat_tx_total_good_packets;
//   wire            stat_tx_total_packets;
//   wire            stat_tx_unicast;
//   wire            stat_tx_vlan;


  wire            ctl_tx_enable;
  wire            ctl_tx_test_pattern;
  wire            ctl_tx_send_idle;
  wire            ctl_tx_send_rfi;
  wire            ctl_tx_send_lfi;
  wire            tx_reset;
  wire     sys_reset;
  wire     init_clk_ibufg;
  wire     init_clk;

  assign gtwiz_reset_tx_datapath    = 1'b0;
  assign gtwiz_reset_rx_datapath    = 1'b0;

  wire aclk       = txusrclk2;
  wire aresetn    = ~usr_tx_reset;
  wire     simplex_mode_rx_aligned;

  assign simplex_mode_rx_aligned    = 1'b1;
  assign sys_reset = 0;

  wire     [511:0]  ernic_m_axis_tdata ;
  wire     [63:0]   ernic_m_axis_tkeep ;
  wire              ernic_m_axis_tvalid;
  wire              ernic_m_axis_tlast ;
  wire     [511:0]  ernic_m_axis_send_tdata ;
  wire     send_continuous_pkts;
  wire     lbus_tx_rx_restart_in;
  wire [3 :0]      tx_prestate;
wire [511 : 0] tx_m_axis_tdata_send_test;
wire [63:0] tx_m_axis_tkeep_send_test;
wire tx_m_axis_tvalid_send_test;
wire tx_m_axis_tlast_send_test;


IBUFGDS clk_init_ibufg_inst (
   .O   (init_clk_ibufg),
   .I   (init_clk_p),
   .IB  (init_clk_n)
);

BUFG
clk_100mhz_1_bufg_inst (
    .I(init_clk_ibufg),
    .O(init_clk)
);


cmac_usplus_0 DUT
(
    .gt_txp_out                           (gt_txp_out),
    .gt_txn_out                           (gt_txn_out),
    .gt_txusrclk2                         (txusrclk2),
    .gt_loopback_in                       (gt_loopback_in),
    .gt_rxrecclkout                       (gt_rxrecclkout),
    .gt_powergoodout                      (gt_powergoodout),
    .gtwiz_reset_tx_datapath              (gtwiz_reset_tx_datapath),
    .gtwiz_reset_rx_datapath              (gtwiz_reset_rx_datapath),
    .sys_reset                            (sys_reset),
    .gt_ref_clk_p                         (gt_ref_clk_p),
    .gt_ref_clk_n                         (gt_ref_clk_n),
    .init_clk                             (init_clk),
    .gt_ref_clk_out                       (gt_ref_clk_out),

    // .stat_tx_bad_fcs                      (stat_tx_bad_fcs),
    // .stat_tx_broadcast                    (stat_tx_broadcast),
    // .stat_tx_frame_error                  (stat_tx_frame_error),
    // .stat_tx_local_fault                  (stat_tx_local_fault),
    // .stat_tx_multicast                    (stat_tx_multicast),
    // .stat_tx_packet_1024_1518_bytes       (stat_tx_packet_1024_1518_bytes),
    // .stat_tx_packet_128_255_bytes         (stat_tx_packet_128_255_bytes),
    // .stat_tx_packet_1519_1522_bytes       (stat_tx_packet_1519_1522_bytes),
    // .stat_tx_packet_1523_1548_bytes       (stat_tx_packet_1523_1548_bytes),
    // .stat_tx_packet_1549_2047_bytes       (stat_tx_packet_1549_2047_bytes),
    // .stat_tx_packet_2048_4095_bytes       (stat_tx_packet_2048_4095_bytes),
    // .stat_tx_packet_256_511_bytes         (stat_tx_packet_256_511_bytes),
    // .stat_tx_packet_4096_8191_bytes       (stat_tx_packet_4096_8191_bytes),
    // .stat_tx_packet_512_1023_bytes        (stat_tx_packet_512_1023_bytes),
    // .stat_tx_packet_64_bytes              (stat_tx_packet_64_bytes),
    // .stat_tx_packet_65_127_bytes          (stat_tx_packet_65_127_bytes),
    // .stat_tx_packet_8192_9215_bytes       (stat_tx_packet_8192_9215_bytes),
    // .stat_tx_packet_large                 (stat_tx_packet_large),
    // .stat_tx_packet_small                 (stat_tx_packet_small),
    // .stat_tx_total_bytes                  (stat_tx_total_bytes),
    // .stat_tx_total_good_bytes             (stat_tx_total_good_bytes),
    // .stat_tx_total_good_packets           (stat_tx_total_good_packets),
    // .stat_tx_total_packets                (stat_tx_total_packets),
    // .stat_tx_unicast                      (stat_tx_unicast),
    // .stat_tx_vlan                         (stat_tx_vlan),


    .ctl_tx_enable                        (ctl_tx_enable),
    .ctl_tx_test_pattern                  (ctl_tx_test_pattern),
    .ctl_tx_send_idle                     (ctl_tx_send_idle),
    .ctl_tx_send_rfi                      (ctl_tx_send_rfi),
    .ctl_tx_send_lfi                      (ctl_tx_send_lfi),
    .core_tx_reset                        (1'b0),
    .tx_axis_tready                       (tx_axis_tready),
    .tx_axis_tvalid                       (tx_m_axis_tvalid_send_test),
    .tx_axis_tdata                        (tx_m_axis_tdata_send_test),   //
    .tx_axis_tkeep                        (tx_m_axis_tkeep_send_test),
    .tx_axis_tlast                        (tx_m_axis_tlast_send_test),
    .tx_axis_tuser                        (tx_axis_tuser),
    .tx_ovfout                            (tx_ovfout),
    .tx_unfout                            (tx_unfout),
    .tx_preamblein                        (tx_preamblein),
    .usr_tx_reset                         (usr_tx_reset),
    .core_drp_reset                       (1'b0),
    .drp_clk                              (1'b0),
    .drp_addr                             (10'b0),
    .drp_di                               (16'b0),
    .drp_en                               (1'b0),
    .drp_do                               (),
    .drp_rdy                              (),
    .drp_we                               (1'b0)
);

cmac_usplus_0_axis_pkt_gen
#(
    .PKT_NUM                              (PKT_NUM),
    .PKT_SIZE                             (PKT_SIZE)
) i_cmac_usplus_0_axis_pkt_gen  
(
    .clk                                  (txusrclk2),
    .reset                                (usr_tx_reset),
    .sys_reset                            (sys_reset),
    .send_continuous_pkts                 (1),
    .lbus_tx_rx_restart_in                (1),
    .ctl_tx_enable                        (ctl_tx_enable),
    .ctl_tx_test_pattern                  (ctl_tx_test_pattern),
    .ctl_tx_send_idle                     (ctl_tx_send_idle),
    .ctl_tx_send_rfi                      (ctl_tx_send_rfi),
    .ctl_tx_send_lfi                      (ctl_tx_send_lfi),
    .tx_reset                             (tx_reset),
    .gt_rxrecclkout                       (gt_rxrecclkout),
    .tx_gt_locked_led                     (tx_gt_locked_led),
    .simplex_mode_rx_aligned              (simplex_mode_rx_aligned),
    .tx_done_led                          (tx_done_led),
    .tx_busy_led                          (tx_busy_led),
    // .stat_tx_bad_fcs                      (stat_tx_bad_fcs),
    // .stat_tx_broadcast                    (stat_tx_broadcast),
    // .stat_tx_frame_error                  (stat_tx_frame_error),
    // .stat_tx_local_fault                  (stat_tx_local_fault),
    // .stat_tx_multicast                    (stat_tx_multicast),
    // .stat_tx_packet_1024_1518_bytes       (stat_tx_packet_1024_1518_bytes),
    // .stat_tx_packet_128_255_bytes         (stat_tx_packet_128_255_bytes),
    // .stat_tx_packet_1519_1522_bytes       (stat_tx_packet_1519_1522_bytes),
    // .stat_tx_packet_1523_1548_bytes       (stat_tx_packet_1523_1548_bytes),
    // .stat_tx_packet_1549_2047_bytes       (stat_tx_packet_1549_2047_bytes),
    // .stat_tx_packet_2048_4095_bytes       (stat_tx_packet_2048_4095_bytes),
    // .stat_tx_packet_256_511_bytes         (stat_tx_packet_256_511_bytes),
    // .stat_tx_packet_4096_8191_bytes       (stat_tx_packet_4096_8191_bytes),
    // .stat_tx_packet_512_1023_bytes        (stat_tx_packet_512_1023_bytes),
    // .stat_tx_packet_64_bytes              (stat_tx_packet_64_bytes),
    // .stat_tx_packet_65_127_bytes          (stat_tx_packet_65_127_bytes),
    // .stat_tx_packet_8192_9215_bytes       (stat_tx_packet_8192_9215_bytes),
    // .stat_tx_packet_large                 (stat_tx_packet_large),
    // .stat_tx_packet_small                 (stat_tx_packet_small),
    // .stat_tx_total_bytes                  (stat_tx_total_bytes),
    // .stat_tx_total_good_bytes             (stat_tx_total_good_bytes),
    // .stat_tx_total_good_packets           (stat_tx_total_good_packets),
    // .stat_tx_total_packets                (stat_tx_total_packets),
    // .stat_tx_unicast                      (stat_tx_unicast),
    // .stat_tx_vlan                         (stat_tx_vlan), 
    .tx_preamblein                        (tx_preamblein),
    .tx_axis_tready                       (tx_axis_tready),
    .tx_axis_tvalid                       (tx_axis_tvalid),
    .tx_axis_tdata                        (tx_axis_tdata),
    .tx_axis_tkeep                        (tx_axis_tkeep),
    .tx_axis_tlast                        (tx_axis_tlast),
    .tx_axis_tuser                        (tx_axis_tuser),
    .tx_ovfout                            (tx_ovfout),
    .tx_unfout                            (tx_unfout),


    .tx_prestate                          (tx_prestate),


    .cmac_m_axis_tdata        (ernic_m_axis_send_tdata)  ,//send模式
    .cmac_m_axis_tkeep         (ernic_m_axis_tkeep) ,
    .cmac_m_axis_tvalid         (ernic_m_axis_tvalid),
    .cmac_m_axis_tlast         (ernic_m_axis_tlast) 
);


exdes_top ernic_top_inst (
    .aclk                   (aclk),
    .aresetn_1              (aresetn),
    .cmac_rx_clk            (txusrclk2),
    .cmac_tx_clk            (txusrclk2),
    .cmac_rst               (usr_tx_reset),
    .num_send_pkt_rcvd      (), // 可根据需要连接监控信号
    .num_rd_resp_pkt_rcvd   (),
    .num_rdma_rd_wr_wqe     (),
    .num_ack_rcvd           (),
    .rdma_write_payload_chk_pass_cnt(), 
    .send_capsule_matched   (),
    .rd_rsp_payload_matched (),
    .final_reg_read_done    (),
    .rqci_completions_written_out(),
    // 内部exdes_top模块会产生输出流信号（例如通过FIFO输出的wqe_proc_top_m_axis_tdata等）
    .cmac_m_axis_tdata        (ernic_m_axis_tdata)  ,
    .cmac_m_axis_tkeep         (ernic_m_axis_tkeep) ,
    .cmac_m_axis_tvalid         (ernic_m_axis_tvalid),
    .cmac_m_axis_tlast         (ernic_m_axis_tlast) ,


    .tx_m_axis_tdata_int   (tx_m_axis_tdata_send_test),
    .tx_m_axis_tkeep_int   (tx_m_axis_tkeep_send_test),
    .tx_m_axis_tvalid_int  (tx_m_axis_tvalid_send_test),
    .tx_m_axis_tlast_int   (tx_m_axis_tlast_send_test)
    // .simplex_mode_rx_aligned
  );




//exdes_top（数据源） → cmac_usplus_0_axis_pkt_gen（发送器） → CMAC IP（发包）

ila_0 mark (
	.clk(txusrclk2), // input wire clk


	.probe0(init_clk), // input wire [0:0]  probe0  
	.probe1(tx_axis_tdata), // input wire [511:0]  probe1 
	.probe2(tx_prestate), // input wire [3:0]  probe2 
	.probe3(tx_axis_tready), // input wire [0:0]  probe3 
	.probe4(tx_axis_tlast), // input wire [0:0]  probe4
	.probe5(ctl_tx_enable), // input wire [0:0]  probe5 
	.probe6(gt_ref_clk_out), // input wire [0:0]  probe6 
	.probe7(tx_gt_locked_led), // input wire [0:0]  probe7 
	.probe8(sys_reset), // input wire [0:0]  probe8 
	.probe9(usr_tx_reset) // input wire [0:0]  probe9
);

endmodule

