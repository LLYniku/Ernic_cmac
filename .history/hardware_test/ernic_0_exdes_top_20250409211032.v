
`timescale 1ns/1ns
module exdes_top 
(
input aclk,
input aresetn_1,
input cmac_rx_clk,
input cmac_tx_clk,
input cmac_rst,
output [15:0] num_send_pkt_rcvd,
output [15:0] num_rd_resp_pkt_rcvd,
output [15:0] num_rdma_rd_wr_wqe,
output [15:0] num_ack_rcvd,
output [4:0]  rdma_write_payload_chk_pass_cnt,
output wire   send_capsule_matched,
output wire   rd_rsp_payload_matched,
output wire   final_reg_read_done,
output wire rqci_completions_written_out,
// exdes_top 顶层添加端口
output [511:0] cmac_m_axis_tdata,
output [63:0]  cmac_m_axis_tkeep,
output         cmac_m_axis_tvalid,
output         cmac_m_axis_tlast,
// output [511:0] tx_m_axis_tdata_int,

output  [511:0]  tx_m_axis_tdata_int,
output  [63:0] tx_m_axis_tkeep_int,
output  tx_m_axis_tvalid_int,
output  tx_m_axis_tlast_int

);




localparam C_AXI_ADDR_WIDTH = 32; 
localparam C_AXI_DATA_WIDTH = 32;
localparam C_AXI_LITE_DATA_WIDTH = 32;
localparam C_AXIS_DATA_WIDTH = 512;
localparam C_M_AXI_ID_WIDTH =1;
`include "XRNIC_Reg_Config.vh"
 wire   [32-1:0]           s_axi_lite_awaddr;
 wire                                    s_axi_lite_awready;
 wire                                    s_axi_lite_awvalid;

 wire   [32-1:0]           s_axi_lite_araddr;
 wire                                    s_axi_lite_arready;
 wire                                    s_axi_lite_arvalid;

 wire   [32-1:0]      s_axi_lite_wdata;
 wire   [32/8 -1:0]   s_axi_lite_wstrb;
 wire                                    s_axi_lite_wready;
 wire                                    s_axi_lite_wvalid;

 wire  [32-1:0]       s_axi_lite_rdata;
 wire  [1:0]                             s_axi_lite_rresp;
 wire                                    s_axi_lite_rready;
 wire                                    s_axi_lite_rvalid;

 wire  [1:0]                             s_axi_lite_bresp;
 wire                                    s_axi_lite_bready;
 wire                                    s_axi_lite_bvalid;

 wire                                    i_gen_txns;
 wire [32-1:0]             i_addr;
 wire  [32-1:0]            i_data;
 wire                                    o_txns_done;
 wire                                    conf_of_reg_done;
 wire [C_AXIS_DATA_WIDTH-1 : 0]          tx_m_axis_tdata_int;   //need
 wire [C_AXIS_DATA_WIDTH/8-1:0]          tx_m_axis_tkeep_int;
 wire                                    tx_m_axis_tvalid_int;
 wire                                    tx_m_axis_tready_int;
 wire                                    tx_m_axis_tlast_int;

 reg                                     rx_pkt_hndler_ddr_m_axi_bvalid_1;
 reg                                     rx_pkt_hndler_ddr_m_axi_bvalid_2;
 reg                                     rx_pkt_hndler_ddr_m_axi_bvalid_3;

 wire  [32-1:0]    qp_mgr_m_axi_araddr; 
 wire                                    qp_mgr_m_axi_arvalid;
 wire                                     qp_mgr_m_axi_arready;
 wire   [C_AXIS_DATA_WIDTH-1:0]           qp_mgr_m_axi_rdata;
 wire  [1:0]                             qp_mgr_m_axi_rresp ;
 wire                                     qp_mgr_m_axi_rlast ;
 wire                                     qp_mgr_m_axi_rvalid ;
 wire                                    qp_mgr_m_axi_rready ;

 wire                                    qp_mgr_m_axi_arready_rd_resp;
 wire   [C_AXIS_DATA_WIDTH-1:0]          qp_mgr_m_axi_rdata_rd_resp;
 wire                                    qp_mgr_m_axi_rlast_rd_resp;
 wire                                    qp_mgr_m_axi_rvalid_rd_resp;

 wire                                    qp_mgr_m_axi_arready_rdmawr;
 wire   [C_AXIS_DATA_WIDTH-1:0]          qp_mgr_m_axi_rdata_rdmawr;
 wire                                    qp_mgr_m_axi_rlast_rdmawr;
 wire                                    qp_mgr_m_axi_rvalid_rdmawr;


wire [1:0] rx_pkt_hndler_ddr_m_axi_rresp;

wire [C_M_AXI_ID_WIDTH-1:0]         rx_pkt_hndler_ddr_m_axi_awid;
wire [32-1:0]         rx_pkt_hndler_ddr_m_axi_awaddr;
wire [7:0]                          rx_pkt_hndler_ddr_m_axi_awlen;
wire [2:0]                          rx_pkt_hndler_ddr_m_axi_awsize;
wire [1:0]                          rx_pkt_hndler_ddr_m_axi_awburst;
wire [3:0]                          rx_pkt_hndler_ddr_m_axi_awcache;
wire [2:0]                          rx_pkt_hndler_ddr_m_axi_awprot;
wire                                rx_pkt_hndler_ddr_m_axi_awvalid;
wire                                rx_pkt_hndler_ddr_m_axi_awready;
wire [511:0]                        rx_pkt_hndler_ddr_m_axi_wdata;
wire [ 63:0]                        rx_pkt_hndler_ddr_m_axi_wstrb;
wire                                rx_pkt_hndler_ddr_m_axi_wlast;
wire                                rx_pkt_hndler_ddr_m_axi_wvalid;
wire                                rx_pkt_hndler_ddr_m_axi_wready;
wire                                rx_pkt_hndler_ddr_m_axi_awlock;
wire [C_M_AXI_ID_WIDTH-1 :0]        rx_pkt_hndler_ddr_m_axi_bid;
wire [1:0]                          rx_pkt_hndler_ddr_m_axi_bresp;
wire                                rx_pkt_hndler_ddr_m_axi_bvalid;
wire                                rx_pkt_hndler_ddr_m_axi_bready;

wire [C_M_AXI_ID_WIDTH-1:0]         rx_pkt_hndler_rdrsp_m_axi_awid;
wire [32-1:0]         rx_pkt_hndler_rdrsp_m_axi_awaddr;
wire [7:0]                          rx_pkt_hndler_rdrsp_m_axi_awlen;
wire [2:0]                          rx_pkt_hndler_rdrsp_m_axi_awsize;
wire [1:0]                          rx_pkt_hndler_rdrsp_m_axi_awburst;
wire [3:0]                          rx_pkt_hndler_rdrsp_m_axi_awcache;
wire [2:0]                          rx_pkt_hndler_rdrsp_m_axi_awprot;
wire                                rx_pkt_hndler_rdrsp_m_axi_awvalid;
wire                                rx_pkt_hndler_rdrsp_m_axi_awready;
wire [511:0]                        rx_pkt_hndler_rdrsp_m_axi_wdata;
wire [ 63:0]                        rx_pkt_hndler_rdrsp_m_axi_wstrb;
wire                                rx_pkt_hndler_rdrsp_m_axi_wlast;
wire                                rx_pkt_hndler_rdrsp_m_axi_wvalid;
wire                                rx_pkt_hndler_rdrsp_m_axi_wready;
wire                                rx_pkt_hndler_rdrsp_m_axi_awlock;
wire [C_M_AXI_ID_WIDTH-1 :0]        rx_pkt_hndler_rdrsp_m_axi_bid;
wire [1:0]                          rx_pkt_hndler_rdrsp_m_axi_bresp;
wire                                rx_pkt_hndler_rdrsp_m_axi_bvalid;
wire                                rx_pkt_hndler_rdrsp_m_axi_bready;

wire [31:0]                         MAC_SRC_ADDR_LSB;
wire [31:0]                         MAC_SRC_ADDR_MSB;
wire [31:0]                         QP3_MAC_DEST_ADDR_LSB;
wire [31:0]                         QP3_MAC_DEST_ADDR_MSB;
wire [31:0]                         IP4H_QP3_DEST_ADDR_1;
wire [31:0]                         IP4H_QP3_SRC_ADDR_1;
wire [31:0]                         QP3_PSN;
wire [31:0]                         QP2_MAC_DEST_ADDR_LSB;
wire [31:0]                         QP2_MAC_DEST_ADDR_MSB;
wire [31:0]                         IP4H_QP2_DEST_ADDR_1;
wire [31:0]                         IP4H_QP2_SRC_ADDR_1;
wire [31:0]                         QP2_PSN;

wire [31:0]                         QP4_MAC_DEST_ADDR_LSB;
wire [31:0]                         QP4_MAC_DEST_ADDR_MSB;
wire [31:0]                         IP4H_QP4_DEST_ADDR_1;
wire [31:0]                         QP4_PSN;

wire [31:0]                         QP5_MAC_DEST_ADDR_LSB;
wire [31:0]                         QP5_MAC_DEST_ADDR_MSB;
wire [31:0]                         IP4H_QP5_DEST_ADDR_1;
wire [31:0]                         QP5_PSN;

wire [31:0]                         QP6_MAC_DEST_ADDR_LSB;
wire [31:0]                         QP6_MAC_DEST_ADDR_MSB;
wire [31:0]                         IP4H_QP6_DEST_ADDR_1;
wire [31:0]                         QP6_PSN;

wire [31:0]                         QP7_MAC_DEST_ADDR_LSB;
wire [31:0]                         QP7_MAC_DEST_ADDR_MSB;
wire [31:0]                         IP4H_QP7_DEST_ADDR_1;
wire [31:0]                         QP7_PSN;


wire [15:0]                         o_qp_sq_pidb_hndshk;
wire [31:0]                         o_qp_sq_pidb_wr_addr_hndshk;
wire                                o_qp_sq_pidb_wr_valid_hndshk;

wire [15:0]                         o_qp_sq_pidb_hndshk_rd_resp;
wire [31:0]                         o_qp_sq_pidb_wr_addr_hndshk_rd_resp;
wire                                o_qp_sq_pidb_wr_valid_hndshk_rd_resp;

wire [15:0]                         o_qp_sq_pidb_hndshk_rdmawr;
wire [31:0]                         o_qp_sq_pidb_wr_addr_hndshk_rdmawr;
wire                                o_qp_sq_pidb_wr_valid_hndshk_rdmawr;

wire                                i_qp_sq_pidb_wr_rdy;
wire  [C_AXIS_DATA_WIDTH-1:0]       wqe_proc_top_m_axis_tdata;
wire  [C_AXIS_DATA_WIDTH/8-1:0]     wqe_proc_top_m_axis_tkeep;
wire                                wqe_proc_top_m_axis_tvalid;
wire                                wqe_proc_top_m_axis_tlast;

wire [C_AXIS_DATA_WIDTH-1:0]        wqe_proc_top_m_axi_rdata;                     
wire                                wqe_proc_top_m_axi_rlast;                     
wire                                wqe_proc_top_m_axi_rvalid;
wire                                wqe_proc_top_m_axi_arvalid;
wire                                wqe_proc_top_m_axi_arready;
wire[31:0]                          cnt_reg_sqpidb;
wire [C_AXIS_DATA_WIDTH-1 : 0] tx_m_axis_tdata_rd_resp_test;
wire [C_AXIS_DATA_WIDTH/8-1:0] tx_m_axis_tkeep_rd_resp_test;
wire tx_m_axis_tvalid_rd_resp_test;
wire tx_m_axis_tlast_rd_resp_test;

wire [C_AXIS_DATA_WIDTH-1 : 0] tx_m_axis_tdata_send_test;
wire [C_AXIS_DATA_WIDTH/8-1:0] tx_m_axis_tkeep_send_test;
wire tx_m_axis_tvalid_send_test;
wire tx_m_axis_tlast_send_test;

reg [C_AXIS_DATA_WIDTH-1 : 0] tx_m_axis_tdata_to_crc;
wire [C_AXIS_DATA_WIDTH-1 : 0] tx_m_axis_tdata_filter;
reg [C_AXIS_DATA_WIDTH/8-1:0] tx_m_axis_tkeep_to_crc;
wire [C_AXIS_DATA_WIDTH/8-1:0] tx_m_axis_tkeep_filter;

wire [C_AXIS_DATA_WIDTH -1:0] cmac_m_axis_tdata;
wire [C_AXIS_DATA_WIDTH/8 -1 :0] cmac_m_axis_tkeep;
wire cmac_m_axis_tvalid;
wire cmac_m_axis_tlast;
reg tx_m_axis_tvalid_to_crc;
wire tx_m_axis_tvalid_filter;
reg tx_m_axis_tlast_to_crc;
wire tx_m_axis_tlast_filter;
wire [7:0] wqe_proc_top_m_axi_arlen;
wire RDMA_SND_TST_DONE;
wire rdma_read_path_done;

wire [31:0]   rx_pkt_hndler_o_rq_db_data;
wire [9:0]    rx_pkt_hndler_o_rq_db_addr;      
wire          rx_pkt_hndler_o_rq_db_data_valid;
wire          resp_hndler_o_send_cq_db_cnt_valid;
wire [9:0 ]   resp_hndler_o_send_cq_db_addr;
wire [31:0]   resp_hndler_o_send_cq_db_cnt;

wire  [15:0] qp_rq_cidb_hndshk;
wire  [31:0] qp_rq_cidb_wr_addr_hndshk;
wire     qp_rq_cidb_wr_valid_hndshk;
wire     qp_rq_cidb_wr_rdy;
wire [23:0]  write_pkt_psn;
reg aresetn_2;
reg aresetn;




// XRNIC Module Instantiation
// Needs to be parameterized based on the model parameters

always @(posedge aclk) begin
       aresetn_2 <= aresetn_1;
       aresetn   <= aresetn_2;
end

  ernic_0 xrnic_inst (
          .s_axi_lite_aclk       (aclk),
          .s_axi_lite_aresetn    (aresetn),
          .m_axi_aclk            (aclk),
          .m_axi_aresetn         (aresetn),
          .cmac_rx_clk           (cmac_rx_clk),                                             
          .cmac_rx_rst           (cmac_rst),                                             
          .cmac_tx_clk           (cmac_tx_clk), 

          .cmac_tx_rst           (cmac_rst),                                             

         .s_axi_lite_awaddr      (s_axi_lite_awaddr),
         .s_axi_lite_awready     (s_axi_lite_awready),
         .s_axi_lite_awvalid     (s_axi_lite_awvalid),
         .s_axi_lite_araddr      (s_axi_lite_araddr),
         .s_axi_lite_arready     (s_axi_lite_arready),
         .s_axi_lite_arvalid     (s_axi_lite_arvalid),
         .s_axi_lite_wdata       (s_axi_lite_wdata),
         .s_axi_lite_wstrb       (s_axi_lite_wstrb),
         .s_axi_lite_wready      (s_axi_lite_wready),
         .s_axi_lite_wvalid      (s_axi_lite_wvalid),
         .s_axi_lite_rdata       (s_axi_lite_rdata),
         .s_axi_lite_rresp       (s_axi_lite_rresp),
         .s_axi_lite_rready      (s_axi_lite_rready),
         .s_axi_lite_rvalid      (s_axi_lite_rvalid),
         .s_axi_lite_bresp       (s_axi_lite_bresp),
         .s_axi_lite_bready      (s_axi_lite_bready),
         .s_axi_lite_bvalid      (s_axi_lite_bvalid),

         .rx_pkt_hndler_ddr_m_axi_wready( 1'b1),
         .rx_pkt_hndler_ddr_m_axi_awready( 1'b1 ),
         .rx_pkt_hndler_ddr_m_axi_wvalid(rx_pkt_hndler_ddr_m_axi_wvalid),
         .rx_pkt_hndler_ddr_m_axi_bvalid (1'b1),
         .rx_pkt_hndler_ddr_m_axi_wlast (rx_pkt_hndler_ddr_m_axi_wlast),
         .rx_pkt_hndler_ddr_m_axi_bresp ( 2'b00 ),
         .rx_pkt_hndler_ddr_m_axi_bid ( 1'b0 ),
         .rx_pkt_hndler_ddr_m_axi_rresp ( 2'b00 ),
         .rx_pkt_hndler_ddr_m_axi_wstrb     (rx_pkt_hndler_ddr_m_axi_wstrb  ),   
         .rx_pkt_hndler_ddr_m_axi_awid      (rx_pkt_hndler_ddr_m_axi_awid   ),
         .rx_pkt_hndler_ddr_m_axi_awaddr    (rx_pkt_hndler_ddr_m_axi_awaddr ), 
         .rx_pkt_hndler_ddr_m_axi_awlen     (rx_pkt_hndler_ddr_m_axi_awlen  ),
         .rx_pkt_hndler_ddr_m_axi_awsize    (rx_pkt_hndler_ddr_m_axi_awsize ),
         .rx_pkt_hndler_ddr_m_axi_awburst   (rx_pkt_hndler_ddr_m_axi_awburst),
         .rx_pkt_hndler_ddr_m_axi_awcache   (rx_pkt_hndler_ddr_m_axi_awcache),
         .rx_pkt_hndler_ddr_m_axi_awprot    (rx_pkt_hndler_ddr_m_axi_awprot ), 
         .rx_pkt_hndler_ddr_m_axi_awvalid   (rx_pkt_hndler_ddr_m_axi_awvalid),
         .rx_pkt_hndler_ddr_m_axi_wdata     (rx_pkt_hndler_ddr_m_axi_wdata  ),
         .rx_pkt_hndler_ddr_m_axi_bready    (rx_pkt_hndler_ddr_m_axi_bready ),
         .rx_pkt_hndler_ddr_m_axi_rid       (1'b0),
         .rx_pkt_hndler_ddr_m_axi_rdata     (512'd0),
         .rx_pkt_hndler_ddr_m_axi_rlast     (1'b0),
         .rx_pkt_hndler_ddr_m_axi_rvalid    (1'b0),
         .rx_pkt_hndler_ddr_m_axi_arready   (1'b1),

         .rx_pkt_hndler_rdrsp_m_axi_awready (1'b1),
         .rx_pkt_hndler_rdrsp_m_axi_wready  (1'b1),
         .rx_pkt_hndler_rdrsp_m_axi_bid     (1'b0),
         .rx_pkt_hndler_rdrsp_m_axi_bresp   (2'b00),
         .rx_pkt_hndler_rdrsp_m_axi_bvalid  (1'b1),
         .rx_pkt_hndler_rdrsp_m_axi_rresp   ( 2'b00 ),
         .rx_pkt_hndler_rdrsp_m_axi_wstrb   (rx_pkt_hndler_rdrsp_m_axi_wstrb  ),   
         .rx_pkt_hndler_rdrsp_m_axi_awid    (rx_pkt_hndler_rdrsp_m_axi_awid   ),
         .rx_pkt_hndler_rdrsp_m_axi_awaddr  (rx_pkt_hndler_rdrsp_m_axi_awaddr ), 
         .rx_pkt_hndler_rdrsp_m_axi_awlen   (rx_pkt_hndler_rdrsp_m_axi_awlen  ),
         .rx_pkt_hndler_rdrsp_m_axi_awsize  (rx_pkt_hndler_rdrsp_m_axi_awsize ),
         .rx_pkt_hndler_rdrsp_m_axi_awburst (rx_pkt_hndler_rdrsp_m_axi_awburst),
         .rx_pkt_hndler_rdrsp_m_axi_awcache (rx_pkt_hndler_rdrsp_m_axi_awcache),
         .rx_pkt_hndler_rdrsp_m_axi_awprot  (rx_pkt_hndler_rdrsp_m_axi_awprot ), 
         .rx_pkt_hndler_rdrsp_m_axi_awvalid (rx_pkt_hndler_rdrsp_m_axi_awvalid),
         .rx_pkt_hndler_rdrsp_m_axi_wdata   (rx_pkt_hndler_rdrsp_m_axi_wdata  ),
         .rx_pkt_hndler_rdrsp_m_axi_bready  (rx_pkt_hndler_rdrsp_m_axi_bready ),
         .rx_pkt_hndler_rdrsp_m_axi_wvalid  (rx_pkt_hndler_rdrsp_m_axi_wvalid),
         .rx_pkt_hndler_rdrsp_m_axi_wlast   (rx_pkt_hndler_rdrsp_m_axi_wlast),
         .rx_pkt_hndler_rdrsp_m_axi_rid       (1'b0),
         .rx_pkt_hndler_rdrsp_m_axi_rdata     (512'd0),
         .rx_pkt_hndler_rdrsp_m_axi_rlast     (1'b0),
         .rx_pkt_hndler_rdrsp_m_axi_rvalid    (1'b0),
         .rx_pkt_hndler_rdrsp_m_axi_arready   (1'b1),


 
//DATA response channel
        .qp_mgr_m_axi_araddr   (qp_mgr_m_axi_araddr ),       
        .qp_mgr_m_axi_arvalid  (qp_mgr_m_axi_arvalid),
        .qp_mgr_m_axi_arready  (qp_mgr_m_axi_arready),
        .qp_mgr_m_axi_rdata    (qp_mgr_m_axi_rdata  ),
        .qp_mgr_m_axi_rresp    (2'b00  ),
        .qp_mgr_m_axi_rlast    (qp_mgr_m_axi_rlast  ),
        .qp_mgr_m_axi_rvalid   (qp_mgr_m_axi_rvalid ),
        .qp_mgr_m_axi_rready   (qp_mgr_m_axi_rready ),
        .qp_mgr_m_axi_awready  (1'b1),
        .qp_mgr_m_axi_wready   (1'b1),
        .qp_mgr_m_axi_bid      (1'b0),
        .qp_mgr_m_axi_bresp    (2'b00),
        .qp_mgr_m_axi_bvalid   (1'b1),
        .qp_mgr_m_axi_rid      (1'b0),



        //read request channel for NVME_write    
        .cmac_m_axis_tdata(cmac_m_axis_tdata),
        .cmac_m_axis_tkeep(cmac_m_axis_tkeep),
        .cmac_m_axis_tvalid(cmac_m_axis_tvalid),
        .cmac_m_axis_tlast(cmac_m_axis_tlast),
        .cmac_m_axis_tready (1'b1),

        // wqe proc wr ddr i/f
        .wqe_proc_wr_ddr_m_axi_awready   (1'b1),
        .wqe_proc_wr_ddr_m_axi_wready    (1'b1),                    
        .wqe_proc_wr_ddr_m_axi_bid       (1'b0),                       
        .wqe_proc_wr_ddr_m_axi_bresp     (2'b00),                     
        .wqe_proc_wr_ddr_m_axi_bvalid    (1'b1),                    
        .wqe_proc_wr_ddr_m_axi_arready   (1'b1),                   
        .wqe_proc_wr_ddr_m_axi_rid       (1'b0),                       
        .wqe_proc_wr_ddr_m_axi_rdata     (512'd0),                     
        .wqe_proc_wr_ddr_m_axi_rresp     (2'b00),                     
        .wqe_proc_wr_ddr_m_axi_rlast     (1'b0),                     
        .wqe_proc_wr_ddr_m_axi_rvalid    (1'b0),  


        //read response channel for NVME_READ
        .wqe_proc_top_m_axi_rid(1'b0),                       
        .wqe_proc_top_m_axi_rdata(wqe_proc_top_m_axi_rdata),                     
        .wqe_proc_top_m_axi_rresp(2'b00),                     
        .wqe_proc_top_m_axi_rlast(wqe_proc_top_m_axi_rlast),                     
        .wqe_proc_top_m_axi_rvalid(wqe_proc_top_m_axi_rvalid),  
        .wqe_proc_top_m_axi_arready(wqe_proc_top_m_axi_arready),
        .wqe_proc_top_m_axi_arvalid (wqe_proc_top_m_axi_arvalid),
        .wqe_proc_top_m_axi_bid(1'b0),                       
        .wqe_proc_top_m_axi_bresp(2'b00),                     
        .wqe_proc_top_m_axi_bvalid(1'b1),
        .wqe_proc_top_m_axi_rready (wqe_proc_top_m_axi_rready),
        .wqe_proc_top_m_axi_arlen (wqe_proc_top_m_axi_arlen),
        .wqe_proc_top_m_axi_awready (1'b1),
        .wqe_proc_top_m_axi_wready(1'b1),
        
        .resp_hndler_m_axi_awready   (1'b1),
        .resp_hndler_m_axi_wready    (1'b1),
        .resp_hndler_m_axi_bid       (1'b0),
        .resp_hndler_m_axi_bresp     (2'b00),
        .resp_hndler_m_axi_bvalid    (1'b1),
        .resp_hndler_m_axi_rid       (1'b0),
        .resp_hndler_m_axi_rdata     (512'd0),
        .resp_hndler_m_axi_rlast     (1'b0),
        .resp_hndler_m_axi_rvalid    (1'b0),
        .resp_hndler_m_axi_arready   (1'b1),
        .resp_hndler_m_axi_rresp     (2'b00),
       
        .i_qp_rq_cidb_hndshk         (qp_rq_cidb_hndshk),
        .i_qp_rq_cidb_wr_addr_hndshk (qp_rq_cidb_wr_addr_hndshk),
        .i_qp_rq_cidb_wr_valid_hndshk(qp_rq_cidb_wr_valid_hndshk),
        .o_qp_rq_cidb_wr_rdy         (qp_rq_cidb_wr_rdy),

        .i_qp_sq_pidb_hndshk          (o_qp_sq_pidb_hndshk),
        .i_qp_sq_pidb_wr_addr_hndshk  (o_qp_sq_pidb_wr_addr_hndshk),
        .i_qp_sq_pidb_wr_valid_hndshk (o_qp_sq_pidb_wr_valid_hndshk),
        .o_qp_sq_pidb_wr_rdy          (i_qp_sq_pidb_wr_rdy),

        .rx_pkt_hndler_o_rq_db_data       (rx_pkt_hndler_o_rq_db_data),
        .rx_pkt_hndler_o_rq_db_addr       (rx_pkt_hndler_o_rq_db_addr),
        .rx_pkt_hndler_o_rq_db_data_valid (rx_pkt_hndler_o_rq_db_data_valid),
        .rx_pkt_hndler_i_rq_db_rdy        (rx_pkt_hndler_i_rq_db_rdy),

        .resp_hndler_o_send_cq_db_cnt_valid  (resp_hndler_o_send_cq_db_cnt_valid),
        .resp_hndler_o_send_cq_db_addr       (resp_hndler_o_send_cq_db_addr),
        .resp_hndler_o_send_cq_db_cnt        (resp_hndler_o_send_cq_db_cnt),
        .resp_hndler_i_send_cq_db_rdy (1'b1),
         
// Streaming I/F
         .roce_cmac_s_axis_tvalid (tx_m_axis_tvalid_filter),                   
         .roce_cmac_s_axis_tdata  (tx_m_axis_tdata_filter),                    
         .roce_cmac_s_axis_tkeep  (tx_m_axis_tkeep_filter),                    
         .roce_cmac_s_axis_tlast  (tx_m_axis_tlast_filter),                    
         .roce_cmac_s_axis_tuser  (tx_m_axis_tlast_filter),
		 .non_roce_cmac_s_axis_tvalid (1'b0),                   
         .non_roce_cmac_s_axis_tdata  (512'd0),                    
         .non_roce_cmac_s_axis_tkeep  (64'd0),                    
         .non_roce_cmac_s_axis_tlast  (1'b0),                    
         .non_roce_cmac_s_axis_tuser  (1'b0),
         
         .non_roce_dma_s_axis_tvalid (1'b0),                   
         .non_roce_dma_s_axis_tdata  (512'd0),                    
         .non_roce_dma_s_axis_tkeep  (64'd0),                    
         .non_roce_dma_s_axis_tlast  (1'b0), 
         .non_roce_dma_s_axis_tready (),
		 
         .non_roce_dma_m_axis_tvalid (),                   
         .non_roce_dma_m_axis_tdata  (),                    
         .non_roce_dma_m_axis_tkeep  (),                    
         .non_roce_dma_m_axis_tlast  (),       
         .non_roce_dma_m_axis_tready  (1'b0), 
		 
         .stat_rx_pause_req(8'h0),                                    // input wire [8 : 0] stat_rx_pause_req
         //.ctl_rx_pause_ack(),                                      // output wire [8 : 0] ctl_rx_pause_ack
         .ctl_tx_pause_req(),                                      // output wire [8 : 0] ctl_tx_pause_req
         .ctl_tx_resend_pause(),                                // output wire ctl_tx_resend_pause
         //.stat_tx_pause(1'b0),                                            // input wire stat_tx_pause
         //.stat_tx_user_pause(1'b0),                                  // input wire stat_tx_user_pause
         //.stat_tx_pause_valid(8'h0),                                // input wire [8 : 0] stat_tx_pause_valid
         .ieth_immdt_axis_tvalid(),                          // output wire ieth_immdt_axis_tvalid
         .ieth_immdt_axis_tlast(),                            // output wire ieth_immdt_axis_tlast
         .ieth_immdt_axis_tdata(),                            // output wire [63 : 0] ieth_immdt_axis_tdata
         .ieth_immdt_axis_trdy(1'b1)                              // input wire ieth_immdt_axis_trdy

  );

// xpm_fifo_axis: AXI Stream FIFO
// Xilinx Parameterized Macro, version 2018.1
xpm_fifo_axis #(
.CDC_SYNC_STAGES(2), // DECIMAL
.CLOCKING_MODE("independent_clock"), // String
.ECC_MODE("no_ecc"), // String
.FIFO_DEPTH(32), // DECIMAL
.FIFO_MEMORY_TYPE("auto"), // String
.PACKET_FIFO("true"), // String
.PROG_EMPTY_THRESH(5), // DECIMAL
.PROG_FULL_THRESH(5), // DECIMAL
.RD_DATA_COUNT_WIDTH(1), // DECIMAL
.RELATED_CLOCKS(0), // DECIMAL
.TDATA_WIDTH(C_AXIS_DATA_WIDTH), // DECIMAL
.TDEST_WIDTH(1), // DECIMAL
.TID_WIDTH(1), // DECIMAL
.TUSER_WIDTH(1), // DECIMAL
.USE_ADV_FEATURES("1000"), // String
.WR_DATA_COUNT_WIDTH(1) // DECIMAL
)
xpm_fifo_axis_inst (
.almost_empty_axis(), 
.almost_full_axis(), 
.dbiterr_axis(), 
.m_axis_tdata(wqe_proc_top_m_axis_tdata), 
.m_axis_tdest(), 
.m_axis_tid(), 
.m_axis_tkeep(wqe_proc_top_m_axis_tkeep), 
.m_axis_tlast(wqe_proc_top_m_axis_tlast), 
.m_axis_tstrb(), 
.m_axis_tuser(), 
.m_axis_tvalid(wqe_proc_top_m_axis_tvalid), 
.prog_empty_axis(), 
.prog_full_axis(), 
.rd_data_count_axis(), 
.s_axis_tready(cmac_m_axis_tready), 
.sbiterr_axis(), 
.wr_data_count_axis(), 
.injectdbiterr_axis(1'b0), 
.injectsbiterr_axis(1'b0), 
.m_aclk(aclk), 
.m_axis_tready(1'b1), 
.s_aclk(cmac_tx_clk), 
.s_aresetn(~cmac_rst), 
.s_axis_tdata(cmac_m_axis_tdata), 
.s_axis_tdest(1'b0), 
.s_axis_tid(1'b0), 
.s_axis_tkeep(cmac_m_axis_tkeep), 
.s_axis_tlast(cmac_m_axis_tlast), 
.s_axis_tstrb({64{1'b1}}), 
.s_axis_tuser(1'b0), 
.s_axis_tvalid(cmac_m_axis_tvalid) 
);
// End of xpm_fifo_axis_inst instantiation



   exdes_reg_config
   #(
	 .C_S_AXI_LITE_ADDR_WIDTH (32)
	)
	exdes_reg_config_inst (
         .s_axi_lite_aclk        (aclk),
         .s_axi_lite_arstn       (aresetn),
         .s_axi_lite_awaddr      (s_axi_lite_awaddr),
         .s_axi_lite_awready     (s_axi_lite_awready),
         .s_axi_lite_awvalid     (s_axi_lite_awvalid),
         .s_axi_lite_araddr      (s_axi_lite_araddr),
         .s_axi_lite_arready     (s_axi_lite_arready),
         .s_axi_lite_arvalid     (s_axi_lite_arvalid),
         .s_axi_lite_wdata       (s_axi_lite_wdata),
         .s_axi_lite_wstrb       (s_axi_lite_wstrb),
         .s_axi_lite_wready      (s_axi_lite_wready),
         .s_axi_lite_wvalid      (s_axi_lite_wvalid),
         .s_axi_lite_rdata       (s_axi_lite_rdata),
         .s_axi_lite_rresp       (s_axi_lite_rresp),
         .s_axi_lite_rready      (s_axi_lite_rready),
         .s_axi_lite_rvalid      (s_axi_lite_rvalid),
         .s_axi_lite_bresp       (s_axi_lite_bresp),
         .s_axi_lite_bready      (s_axi_lite_bready),
         .s_axi_lite_bvalid      (s_axi_lite_bvalid),
         .conf_of_reg_done       (conf_of_reg_done),
         .MAC_SRC_ADDR_LSB       (MAC_SRC_ADDR_LSB),
         .MAC_SRC_ADDR_MSB       (MAC_SRC_ADDR_MSB),		 
         .QP3_MAC_DEST_ADDR_LSB  (QP3_MAC_DEST_ADDR_LSB),	 
         .QP3_MAC_DEST_ADDR_MSB  (QP3_MAC_DEST_ADDR_MSB),		 
         .IP4H_QP3_DEST_ADDR_1   (IP4H_QP3_DEST_ADDR_1),	 
         .IP4H_QP3_SRC_ADDR_1    (IP4H_QP3_SRC_ADDR_1),
         .QP3_PSN                (QP3_PSN)	,	
         .QP2_MAC_DEST_ADDR_LSB  (QP2_MAC_DEST_ADDR_LSB),	 
         .QP2_MAC_DEST_ADDR_MSB  (QP2_MAC_DEST_ADDR_MSB),         
         .IP4H_QP2_DEST_ADDR_1   (IP4H_QP2_DEST_ADDR_1),     
         .IP4H_QP2_SRC_ADDR_1    (IP4H_QP2_SRC_ADDR_1),
         .QP2_PSN                (QP2_PSN)    ,

         .QP4_MAC_DEST_ADDR_LSB  (QP4_MAC_DEST_ADDR_LSB),	 
         .QP4_MAC_DEST_ADDR_MSB  (QP4_MAC_DEST_ADDR_MSB),         
         .IP4H_QP4_DEST_ADDR_1   (IP4H_QP4_DEST_ADDR_1),     
         .QP4_PSN                (QP4_PSN)    ,

         .QP5_MAC_DEST_ADDR_LSB  (QP5_MAC_DEST_ADDR_LSB),	 
         .QP5_MAC_DEST_ADDR_MSB  (QP5_MAC_DEST_ADDR_MSB),         
         .IP4H_QP5_DEST_ADDR_1   (IP4H_QP5_DEST_ADDR_1),     
         .QP5_PSN                (QP5_PSN)    ,

         .QP6_MAC_DEST_ADDR_LSB  (QP6_MAC_DEST_ADDR_LSB),	 
         .QP6_MAC_DEST_ADDR_MSB  (QP6_MAC_DEST_ADDR_MSB),         
         .IP4H_QP6_DEST_ADDR_1   (IP4H_QP6_DEST_ADDR_1),     
         .QP6_PSN                (QP6_PSN)    ,

         .QP7_MAC_DEST_ADDR_LSB  (QP7_MAC_DEST_ADDR_LSB),	 
         .QP7_MAC_DEST_ADDR_MSB  (QP7_MAC_DEST_ADDR_MSB),         
         .IP4H_QP7_DEST_ADDR_1   (IP4H_QP7_DEST_ADDR_1),     
         .QP7_PSN                (QP7_PSN)    ,

         .rdma_write_path_done   (rdma_write_path_done),
         .num_send_pkt_rcvd      (num_send_pkt_rcvd),
         .num_rd_resp_pkt_rcvd   (num_rd_resp_pkt_rcvd),
         .num_rdma_rd_wr_wqe     (num_rdma_rd_wr_wqe),
         .num_ack_rcvd           (num_ack_rcvd),
         .final_reg_read_done    (final_reg_read_done)
  );
exdes_rx_path_checker
  #(
	 .C_AXI_ADDR_WIDTH (32)
	)
  exdes_rx_path_checker_inst (
    .core_clk                     (aclk),
    .core_rst                     (~aresetn),
    .capsule_ddr_m_axi_awid       (rx_pkt_hndler_ddr_m_axi_awid),
    .capsule_ddr_m_axi_awaddr     (rx_pkt_hndler_ddr_m_axi_awaddr),
    .capsule_ddr_m_axi_awlen      (rx_pkt_hndler_ddr_m_axi_awlen),
    .capsule_ddr_m_axi_awsize     (rx_pkt_hndler_ddr_m_axi_awsize),
    .capsule_ddr_m_axi_awburst    (rx_pkt_hndler_ddr_m_axi_awburst),
    .capsule_ddr_m_axi_awcache    (rx_pkt_hndler_ddr_m_axi_awcache),
    .capsule_ddr_m_axi_awprot     (rx_pkt_hndler_ddr_m_axi_awprot),
    .capsule_ddr_m_axi_awvalid    (rx_pkt_hndler_ddr_m_axi_awvalid),
    .capsule_ddr_m_axi_awready    (rx_pkt_hndler_ddr_m_axi_awready),
    .capsule_ddr_m_axi_wdata      (rx_pkt_hndler_ddr_m_axi_wdata),
    .capsule_ddr_m_axi_wstrb      (rx_pkt_hndler_ddr_m_axi_wstrb),
    .capsule_ddr_m_axi_wlast      (rx_pkt_hndler_ddr_m_axi_wlast),
    .capsule_ddr_m_axi_wvalid     (rx_pkt_hndler_ddr_m_axi_wvalid),
    .capsule_ddr_m_axi_wready     (rx_pkt_hndler_ddr_m_axi_wready),
    .capsule_ddr_m_axi_bid        (rx_pkt_hndler_ddr_m_axi_bid),
    .capsule_ddr_m_axi_bresp      (rx_pkt_hndler_ddr_m_axi_bresp),
    .capsule_ddr_m_axi_bvalid     (rx_pkt_hndler_ddr_m_axi_bvalid),
    .capsule_ddr_m_axi_bready     (rx_pkt_hndler_ddr_m_axi_bready),

    .data_m_axi_awid              (rx_pkt_hndler_rdrsp_m_axi_awid),
    .data_m_axi_awaddr            (rx_pkt_hndler_rdrsp_m_axi_awaddr),
    .data_m_axi_awlen             (rx_pkt_hndler_rdrsp_m_axi_awlen),
    .data_m_axi_awsize            (rx_pkt_hndler_rdrsp_m_axi_awsize),
    .data_m_axi_awburst           (rx_pkt_hndler_rdrsp_m_axi_awburst),
    .data_m_axi_awcache           (rx_pkt_hndler_rdrsp_m_axi_awcache),
    .data_m_axi_awprot            (rx_pkt_hndler_rdrsp_m_axi_awprot),
    .data_m_axi_awvalid           (rx_pkt_hndler_rdrsp_m_axi_awvalid),
    .data_m_axi_awready           (rx_pkt_hndler_rdrsp_m_axi_awready),
    .data_m_axi_wdata             (rx_pkt_hndler_rdrsp_m_axi_wdata),
    .data_m_axi_wstrb             (rx_pkt_hndler_rdrsp_m_axi_wstrb),
    .data_m_axi_wlast             (rx_pkt_hndler_rdrsp_m_axi_wlast),
    .data_m_axi_wvalid            (rx_pkt_hndler_rdrsp_m_axi_wvalid),
    .data_m_axi_wready            (rx_pkt_hndler_rdrsp_m_axi_wready),
    .data_m_axi_bid               (rx_pkt_hndler_rdrsp_m_axi_bid),
    .data_m_axi_bresp             (rx_pkt_hndler_rdrsp_m_axi_bresp),
    .data_m_axi_bvalid            (rx_pkt_hndler_rdrsp_m_axi_bvalid),
    .data_m_axi_bready            (rx_pkt_hndler_rdrsp_m_axi_bready),
    .rx_pkt_hndler_o_rq_db_data_valid (rx_pkt_hndler_o_rq_db_data_valid),
    .rx_pkt_hndler_o_rq_db_data       (rx_pkt_hndler_o_rq_db_data),
    .rx_pkt_hndler_o_rq_db_addr       (rx_pkt_hndler_o_rq_db_addr),
    .rx_pkt_hndler_i_rq_db_rdy        (rx_pkt_hndler_i_rq_db_rdy),
    .resp_hndler_o_send_cq_db_cnt_valid (resp_hndler_o_send_cq_db_cnt_valid),
    .send_capsule_matched                   (send_capsule_matched),
    .rd_rsp_payload_matched                 (rd_rsp_payload_matched),
    .qp_rq_cidb_hndshk         (qp_rq_cidb_hndshk),
    .qp_rq_cidb_wr_addr_hndshk (qp_rq_cidb_wr_addr_hndshk),
    .qp_rq_cidb_wr_valid_hndshk(qp_rq_cidb_wr_valid_hndshk),
    .qp_rq_cidb_wr_rdy         (qp_rq_cidb_wr_rdy),
    .rqci_completions_written_out (rqci_completions_written_out)
);
// RDMA SEND,RD RESP and ACK Packet Generator

  exdes_send_rdresp_ack_pkt_gen  exdes_send_rdresp_ack_pkt_gen_inst
  (
    .core_clk                     (aclk),
    .core_aresetn                 (aresetn),
    .tx_m_axis_tdata_send_test    (tx_m_axis_tdata_send_test),
    .tx_m_axis_tkeep_send_test    (tx_m_axis_tkeep_send_test),
    .tx_m_axis_tvalid_send_test   (tx_m_axis_tvalid_send_test),
    .conf_of_reg_done             (conf_of_reg_done),
    .tx_m_axis_tlast_send_test    (tx_m_axis_tlast_send_test),
    .MAC_SRC_ADDR_LSB             (MAC_SRC_ADDR_LSB),	
    .MAC_SRC_ADDR_MSB             (MAC_SRC_ADDR_MSB),		
    .QP3_MAC_DEST_ADDR_LSB        (QP3_MAC_DEST_ADDR_LSB),	
    .QP3_MAC_DEST_ADDR_MSB        (QP3_MAC_DEST_ADDR_MSB),	
    .IP4H_QP3_DEST_ADDR_1         (IP4H_QP3_DEST_ADDR_1),	
    .IP4H_QP3_SRC_ADDR_1          (IP4H_QP3_SRC_ADDR_1),	
    .QP3_PSN                      (QP3_PSN),

    .QP2_MAC_DEST_ADDR_LSB        (QP2_MAC_DEST_ADDR_LSB),	 
    .QP2_MAC_DEST_ADDR_MSB        (QP2_MAC_DEST_ADDR_MSB),         
    .IP4H_QP2_DEST_ADDR_1         (IP4H_QP2_DEST_ADDR_1),     
    .IP4H_QP2_SRC_ADDR_1          (IP4H_QP2_SRC_ADDR_1),
    .QP2_PSN                      (QP2_PSN),

    .QP4_MAC_DEST_ADDR_LSB        (QP4_MAC_DEST_ADDR_LSB),	 
    .QP4_MAC_DEST_ADDR_MSB        (QP4_MAC_DEST_ADDR_MSB),         
    .IP4H_QP4_DEST_ADDR_1         (IP4H_QP4_DEST_ADDR_1),     
    .QP4_PSN                      (QP4_PSN)    ,

    .QP5_MAC_DEST_ADDR_LSB        (QP5_MAC_DEST_ADDR_LSB),	 
    .QP5_MAC_DEST_ADDR_MSB        (QP5_MAC_DEST_ADDR_MSB),         
    .IP4H_QP5_DEST_ADDR_1         (IP4H_QP5_DEST_ADDR_1),     
    .QP5_PSN                      (QP5_PSN)    ,

    .QP6_MAC_DEST_ADDR_LSB        (QP6_MAC_DEST_ADDR_LSB),	 
    .QP6_MAC_DEST_ADDR_MSB        (QP6_MAC_DEST_ADDR_MSB),         
    .IP4H_QP6_DEST_ADDR_1         (IP4H_QP6_DEST_ADDR_1),     
    .QP6_PSN                      (QP6_PSN)    ,

    .QP7_MAC_DEST_ADDR_LSB        (QP7_MAC_DEST_ADDR_LSB),	 
    .QP7_MAC_DEST_ADDR_MSB        (QP7_MAC_DEST_ADDR_MSB),         
    .IP4H_QP7_DEST_ADDR_1         (IP4H_QP7_DEST_ADDR_1),     
    .QP7_PSN                      (QP7_PSN)    ,

    .post_rdma_rd_wqe             (post_rdma_rd_wqe),
    .post_rdma_wr_wqe             (post_rdma_wr_wqe),
    .wqe_proc_top_m_axis_tlast    (wqe_proc_top_m_axis_tlast),  
    .rdma_write_path_done         (rdma_write_path_done),
    .rdma_read_path_done          (rdma_read_path_done),
    .wqe_proc_top_m_axis_tdata(wqe_proc_top_m_axis_tdata),
    .wqe_proc_top_m_axis_tvalid(wqe_proc_top_m_axis_tvalid),
    .RDMA_SND_TST_DONE            (RDMA_SND_TST_DONE)
     
  );

//RDMA_PKT_FILTER
  RDMA_pkt_filter RDMA_pkt_filter_inst(
    .core_clk                  (aclk),
    .core_rst                  (aresetn),
    .s_axis_tdata              (tx_m_axis_tdata_int),
    .s_axis_tkeep              (tx_m_axis_tkeep_int),
    .s_axis_tlast              (tx_m_axis_tlast_int),
    .s_axis_tuser              (1'b0),
    .s_axis_tvalid             (tx_m_axis_tvalid_int),
    .dma_m_axis_tdata          (),
    .dma_m_axis_tkeep          (),
    .dma_m_axis_tlast          (),
    .dma_m_axis_tuser          (),
    .dma_m_axis_tvalid         (),
    .rx_pkt_hndler_m_axis_tdata(tx_m_axis_tdata_filter),
    .rx_pkt_hndler_m_axis_tkeep(tx_m_axis_tkeep_filter),
    .rx_pkt_hndler_m_axis_tlast(tx_m_axis_tlast_filter),
    .rx_pkt_hndler_m_axis_tuser(),
    .rx_pkt_hndler_m_axis_tvalid(tx_m_axis_tvalid_filter)
  );

// RDMA RD RESP Packet Generator
  exdes_wqe_gen
 #(
	 .C_AXI_ADDR_WIDTH (32)
	)
  exdes_wqe_gen_inst (
    .core_clk                     (aclk),
    .core_aresetn                 (aresetn),
    .MAC_SRC_ADDR_LSB             (MAC_SRC_ADDR_LSB),	
    .MAC_SRC_ADDR_MSB             (MAC_SRC_ADDR_MSB),		
    .QP3_MAC_DEST_ADDR_LSB        (QP3_MAC_DEST_ADDR_LSB),	
    .QP3_MAC_DEST_ADDR_MSB        (QP3_MAC_DEST_ADDR_MSB),	
    .IP4H_QP3_DEST_ADDR_1         (IP4H_QP3_DEST_ADDR_1),	
    .IP4H_QP3_SRC_ADDR_1          (IP4H_QP3_SRC_ADDR_1),	
    .QP3_PSN                      (QP3_PSN),
    .o_qp_sq_pidb_hndshk          (o_qp_sq_pidb_hndshk),
    .o_qp_sq_pidb_wr_addr_hndshk  (o_qp_sq_pidb_wr_addr_hndshk),
    .o_qp_sq_pidb_wr_valid_hndshk (o_qp_sq_pidb_wr_valid_hndshk),
    .i_qp_sq_pidb_wr_rdy          (i_qp_sq_pidb_wr_rdy),
    .qp_mgr_m_axi_araddr         (qp_mgr_m_axi_araddr ),
    .qp_mgr_m_axi_arvalid        (qp_mgr_m_axi_arvalid),
    .qp_mgr_m_axi_arready        (qp_mgr_m_axi_arready),           
    .qp_mgr_m_axi_rdata          (qp_mgr_m_axi_rdata  ),
    .qp_mgr_m_axi_rlast          (qp_mgr_m_axi_rlast  ),
    .qp_mgr_m_axi_rvalid         (qp_mgr_m_axi_rvalid ),
    .qp_mgr_m_axi_rready         (qp_mgr_m_axi_rready ),
    .conf_of_reg_done            (conf_of_reg_done),
    .RDMA_SND_TST_DONE           (RDMA_SND_TST_DONE),
    .wqe_proc_top_m_axi_arvalid (wqe_proc_top_m_axi_arvalid),
    .wqe_proc_top_m_axi_arready (wqe_proc_top_m_axi_arready),
    .wqe_proc_top_m_axis_tlast(wqe_proc_top_m_axis_tlast),                    
    .wqe_proc_top_m_axi_rdata(wqe_proc_top_m_axi_rdata),                                         
    .wqe_proc_top_m_axi_rlast(wqe_proc_top_m_axi_rlast),                     
    .wqe_proc_top_m_axi_rvalid(wqe_proc_top_m_axi_rvalid),  
    .wqe_proc_top_m_axi_rready(wqe_proc_top_m_axi_rready),
    .wqe_proc_top_m_axi_arlen (wqe_proc_top_m_axi_arlen),
    .post_rdma_rd_wqe         (post_rdma_rd_wqe),
    .post_rdma_wr_wqe         (post_rdma_wr_wqe),
    .rdma_read_path_done    (rdma_read_path_done),
    .rdma_write_path_done (rdma_write_path_done)
  );
always @(posedge aclk or negedge aresetn) begin
  if(~aresetn) begin
   tx_m_axis_tdata_to_crc  <= 'b0;
   tx_m_axis_tkeep_to_crc  <= 'b0;
   tx_m_axis_tvalid_to_crc <= 1'b0;
   tx_m_axis_tlast_to_crc  <= 1'b0;
  end
  else begin
    tx_m_axis_tdata_to_crc  <= tx_m_axis_tdata_send_test;
    tx_m_axis_tkeep_to_crc  <= tx_m_axis_tkeep_send_test;
    tx_m_axis_tvalid_to_crc <= tx_m_axis_tvalid_send_test;
    tx_m_axis_tlast_to_crc  <= tx_m_axis_tlast_send_test;
   end
end

// CRC module instance

 exdes_crc_wrap inst_crc  (
   .core_clk           (aclk),
   .core_rst           (~aresetn),
   .m_axis_tdata       (tx_m_axis_tdata_int),  //need output with crc
   .m_axis_tkeep       (tx_m_axis_tkeep_int),
   .m_axis_tvalid      (tx_m_axis_tvalid_int),
   .m_axis_tready      (conf_of_reg_done),
   .m_axis_tlast       (tx_m_axis_tlast_int),
   .s_axis_tdata       (tx_m_axis_tdata_to_crc),
   .s_axis_tkeep       (tx_m_axis_tkeep_to_crc),
   .s_axis_tvalid      (tx_m_axis_tvalid_to_crc),
   .s_axis_tlast       (tx_m_axis_tlast_to_crc),
   .s_axis_tready      ()
);

  rnic_exdes_tx_checker rnic_exdes_tx_checker (
  .core_clk                     (aclk),
  .core_aresetn                 (aresetn),
  .wqe_proc_top_m_axis_tdata(wqe_proc_top_m_axis_tdata),
  .wqe_proc_top_m_axis_tkeep(wqe_proc_top_m_axis_tkeep),
  .wqe_proc_top_m_axis_tvalid(wqe_proc_top_m_axis_tvalid),
  .wqe_proc_top_m_axis_tlast(wqe_proc_top_m_axis_tlast),
  .rdma_write_payload_chk_pass_cnt (rdma_write_payload_chk_pass_cnt)
); 

//INITIATOR CHANGES
endmodule

