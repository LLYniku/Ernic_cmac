
`timescale 1ns/1ns
module exdes_reg_config
#(
  parameter C_S_AXI_LITE_ADDR_WIDTH = 32,
  parameter C_S_AXI_LITE_DATA_WIDTH = 32,
  parameter C_READ_BCK_REG = 0
)
(
  input   wire                                 s_axi_lite_aclk,
  input   wire                                 s_axi_lite_arstn,

  output  wire   [C_S_AXI_LITE_ADDR_WIDTH-1:0] s_axi_lite_awaddr,
  input   wire                                 s_axi_lite_awready,
  output  wire                                 s_axi_lite_awvalid,

  output  wire   [C_S_AXI_LITE_ADDR_WIDTH-1:0] s_axi_lite_araddr,
  input   wire                                 s_axi_lite_arready,
  output  wire                                 s_axi_lite_arvalid,

  output  wire   [C_S_AXI_LITE_DATA_WIDTH-1:0] s_axi_lite_wdata,
  output  wire   [C_S_AXI_LITE_DATA_WIDTH/8 -1:0] s_axi_lite_wstrb,
  input   wire                                s_axi_lite_wready,
  output  wire                                 s_axi_lite_wvalid,

  input   wire  [C_S_AXI_LITE_DATA_WIDTH-1:0] s_axi_lite_rdata,
  input   wire  [1:0]                         s_axi_lite_rresp,
  output  wire                                s_axi_lite_rready,
  input   wire                                s_axi_lite_rvalid,

  input   wire  [1:0]                         s_axi_lite_bresp,
  output  wire                                s_axi_lite_bready,
  input   wire                                s_axi_lite_bvalid,

  input   wire                                rdma_write_path_done,
  output  reg                                 conf_of_reg_done,
  output  wire [31:0]                         MAC_SRC_ADDR_LSB,
  output  wire [31:0]                         MAC_SRC_ADDR_MSB,
  output  wire [31:0]                         QP3_MAC_DEST_ADDR_LSB,
  output  wire [31:0]                         QP3_MAC_DEST_ADDR_MSB,
  output  wire [31:0]                         IP4H_QP3_DEST_ADDR_1,
  output  wire [31:0]                         IP4H_QP3_SRC_ADDR_1,
  output  wire [31:0]                         QP3_PSN,
  output  wire [31:0]                         QP2_MAC_DEST_ADDR_LSB,
  output  wire [31:0]                         QP2_MAC_DEST_ADDR_MSB,
  output  wire [31:0]                         IP4H_QP2_DEST_ADDR_1,
  output  wire [31:0]                         IP4H_QP2_SRC_ADDR_1,
  output  wire [31:0]                         QP2_PSN,

  output  wire [31:0]                         QP4_MAC_DEST_ADDR_LSB,
  output  wire [31:0]                         QP4_MAC_DEST_ADDR_MSB,
  output  wire [31:0]                         IP4H_QP4_DEST_ADDR_1,
  output  wire [31:0]                         QP4_PSN,

  output  wire [31:0]                         QP5_MAC_DEST_ADDR_LSB,
  output  wire [31:0]                         QP5_MAC_DEST_ADDR_MSB,
  output  wire [31:0]                         IP4H_QP5_DEST_ADDR_1,
  output  wire [31:0]                         QP5_PSN,

  output  wire [31:0]                         QP6_MAC_DEST_ADDR_LSB,
  output  wire [31:0]                         QP6_MAC_DEST_ADDR_MSB,
  output  wire [31:0]                         IP4H_QP6_DEST_ADDR_1,
  output  wire [31:0]                         QP6_PSN,

  output  wire [31:0]                         QP7_MAC_DEST_ADDR_LSB,
  output  wire [31:0]                         QP7_MAC_DEST_ADDR_MSB,
  output  wire [31:0]                         IP4H_QP7_DEST_ADDR_1,
  output  wire [31:0]                         QP7_PSN,


  output  wire [15:0]                         num_send_pkt_rcvd, 
  output  wire [15:0]                         num_rd_resp_pkt_rcvd,
  output  wire [15:0]                         num_rdma_rd_wr_wqe,
  output  wire [15:0]                         num_ack_rcvd,
  output  wire                                final_reg_read_done
);

// Internal signal declaration
reg gen_txns_i;
reg [C_S_AXI_LITE_ADDR_WIDTH-1 :0] addr_i;
reg [C_S_AXI_LITE_DATA_WIDTH-1 :0] data_i;
wire txns_done_i;

localparam REG_CONFIG_ST1 = 3'h0;
localparam REG_CONFIG_ST2 = 3'h1;
localparam REG_CONFIG_ST3 = 3'h2;
localparam REG_CONFIG_ST4 = 3'h3;
localparam REG_CONFIG_DB = 3'h4;
localparam REG_CONFIG_DB1 = 3'h5;
localparam REG_CONFIG_DB2 = 3'h6;
localparam NUM_REG_TO_CONFIGURE = 141;



//initiator changes



`include "XRNIC_Reg_Config.vh"

reg [2:0] reg_config_st; // Register configuration FSM state variable
reg [8:0] cnt_regs; // count the number of registers whose configuration is completed
reg [15:0] cnt_regs_db; //to count the number of SQ PI DB
reg ena;
reg [C_S_AXI_LITE_ADDR_WIDTH-1 :0] addra;
wire[63:0] douta;

always @(posedge s_axi_lite_aclk) begin
  if(~s_axi_lite_arstn) begin
    conf_of_reg_done <= 1'b0;
    addr_i     <= 'b0;
    data_i     <= 'b0;
    gen_txns_i <= 1'b0;
    cnt_regs   <= 9'h0;
    reg_config_st <= REG_CONFIG_ST1;
  end
  else begin
    case (reg_config_st)
      REG_CONFIG_ST1 : begin
        if(cnt_regs <= NUM_REG_TO_CONFIGURE) begin  //to be modified as per the number of registers 
          addr_i     <= reg_config[(64*(cnt_regs+1))-1 -: 32];
          data_i     <= reg_config[(64*(cnt_regs+1))-33 -: 32];
          gen_txns_i <= 1'b1;
          reg_config_st <= REG_CONFIG_ST2;
       end
      end
      REG_CONFIG_ST2 : begin
        gen_txns_i <= 1'b0;
        if(txns_done_i) begin
          reg_config_st <= REG_CONFIG_ST1;
          cnt_regs <= cnt_regs + 1'b1;
          if(cnt_regs == NUM_REG_TO_CONFIGURE) begin
            conf_of_reg_done <= 1'b1;
          end
        end
      end
      default : begin
        addr_i     <= 'b0;
        data_i     <= 'b0;
        gen_txns_i <= 1'b0;
        cnt_regs   <= 9'h0;
        reg_config_st <= REG_CONFIG_ST1;
      end
    endcase
  end
end

// AXI Lite transactions generator module
  rnic_lite_txn_gen #(
  .C_S_AXI_LITE_ADDR_WIDTH(C_S_AXI_LITE_ADDR_WIDTH),
  .C_S_AXI_LITE_DATA_WIDTH(C_S_AXI_LITE_DATA_WIDTH),
  .C_READ_BCK_REG(C_READ_BCK_REG)
  )
  rnic_lite_txn_gen_inst
         (
         .s_axi_lite_aclk        (s_axi_lite_aclk),
         .s_axi_lite_arstn       (s_axi_lite_arstn),
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
         .i_gen_txns             (gen_txns_i),
         .i_addr                 (addr_i),
         .i_data                 (data_i),
         .test_completed         (rdma_write_path_done),
         .o_txns_done            (txns_done_i),
         .num_send_pkt_rcvd      (num_send_pkt_rcvd),
         .num_rd_resp_pkt_rcvd   (num_rd_resp_pkt_rcvd),
         .num_rdma_rd_wr_wqe     (num_rdma_rd_wr_wqe),
         .num_ack_rcvd           (num_ack_rcvd),
         .final_reg_read_done    (final_reg_read_done)

  );

assign MAC_SRC_ADDR_LSB = reg_config[(63*64)-33 -: 32];     //63
assign MAC_SRC_ADDR_MSB = reg_config[(61*64)-33 -: 32];     //61
assign QP3_MAC_DEST_ADDR_MSB = reg_config[(6*64)-33 -: 32]; //6
assign QP3_MAC_DEST_ADDR_LSB = reg_config[(7*64)-33 -: 32]; //7
assign IP4H_QP3_DEST_ADDR_1 = reg_config[(5*64)-33 -: 32];  //5
assign IP4H_QP3_SRC_ADDR_1 = reg_config[(57*64)-33 -: 32];  //57
assign QP3_PSN =  reg_config[(25*64)-33 -: 32];             //25
  
assign QP2_MAC_DEST_ADDR_MSB = reg_config[(23*64)-33 -: 32]; //23
assign QP2_MAC_DEST_ADDR_LSB = reg_config[(24*64)-33 -: 32]; //24
assign IP4H_QP2_DEST_ADDR_1 = reg_config[(22*64)-33 -: 32];  //22
assign IP4H_QP2_SRC_ADDR_1 = reg_config[(57*64)-33 -: 32];  //57
assign QP2_PSN =  reg_config[(25*64)-33 -: 32];            //25

assign QP4_MAC_DEST_ADDR_MSB = reg_config[(71*64)-33 -:32];  //71
assign QP4_MAC_DEST_ADDR_LSB = reg_config[(72*64)-33 -: 32]; //72
assign IP4H_QP4_DEST_ADDR_1 = reg_config[(70*64)-33 -: 32];  //70
assign QP4_PSN = reg_config[(84*64)-33 -: 32];		    //84

assign QP5_MAC_DEST_ADDR_MSB = reg_config[(90*64)-33 -: 32]; //90
assign QP5_MAC_DEST_ADDR_LSB = reg_config[(91*64)-33 -: 32]; //91
assign IP4H_QP5_DEST_ADDR_1 = reg_config[(89*64)-33 -: 32]; //89
assign QP5_PSN = reg_config[(103*64)-33 -: 32]; //103

assign QP6_MAC_DEST_ADDR_MSB =  reg_config[(109*64)-33 -: 32];  //109
assign QP6_MAC_DEST_ADDR_LSB =  reg_config[(110*64)-33 -: 32]; //110
assign IP4H_QP6_DEST_ADDR_1 =  reg_config[(108*64)-33 -: 32];  //108
assign QP6_PSN =  reg_config[(122*64)-33 -: 32];               // 122

assign QP7_MAC_DEST_ADDR_MSB = reg_config[(128*64)-33 -: 32]; //128
assign QP7_MAC_DEST_ADDR_LSB = reg_config[(129*64)-33 -: 32]; //129
assign IP4H_QP7_DEST_ADDR_1 = reg_config[(127*64)-33 -: 32]; //127
assign QP7_PSN = reg_config[(141*64)-33 -: 32]; //141



endmodule
