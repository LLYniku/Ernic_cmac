
`timescale 1ns/1ns
module exdes_send_rdresp_ack_pkt_gen
# (
  parameter C_AXIS_DATA_WIDTH = 512
  )
(
  input  wire                             core_clk,
  input  wire                             core_aresetn,
  input  wire                             tx_m_axis_tready_send_tst,
  output reg [C_AXIS_DATA_WIDTH-1 : 0]    tx_m_axis_tdata_send_test,    //发送的数据
  output reg [C_AXIS_DATA_WIDTH/8-1:0]    tx_m_axis_tkeep_send_test,    //哪些字节是有效的（64bit）
  output reg                              tx_m_axis_tvalid_send_test,   //数据有效
  output reg                              tx_m_axis_tlast_send_test,    //包尾
  input  wire [31:0]                      MAC_SRC_ADDR_LSB,
  input  wire [31:0]                      MAC_SRC_ADDR_MSB,
  input  wire [31:0]                      QP3_MAC_DEST_ADDR_LSB,
  input  wire [31:0]                      QP3_MAC_DEST_ADDR_MSB,
  input  wire [31:0]                      IP4H_QP3_DEST_ADDR_1,
  input  wire [31:0]                      IP4H_QP3_SRC_ADDR_1,
  input  wire [31:0]                      QP3_PSN,
  input  wire [31:0]                      QP2_MAC_DEST_ADDR_LSB,
  input  wire [31:0]                      QP2_MAC_DEST_ADDR_MSB,
  input  wire [31:0]                      IP4H_QP2_DEST_ADDR_1,
  input  wire [31:0]                      IP4H_QP2_SRC_ADDR_1,
  input  wire [31:0]                      QP2_PSN,
  input  wire [31:0]                      QP4_MAC_DEST_ADDR_LSB,
  input  wire [31:0]                      QP4_MAC_DEST_ADDR_MSB,
  input  wire [31:0]                      IP4H_QP4_DEST_ADDR_1,
  input  wire [31:0]                      QP4_PSN,

  input  wire [31:0]                      QP5_MAC_DEST_ADDR_LSB,
  input  wire [31:0]                      QP5_MAC_DEST_ADDR_MSB,
  input  wire [31:0]                      IP4H_QP5_DEST_ADDR_1,
  input  wire [31:0]                      QP5_PSN,

  input  wire [31:0]                      QP6_MAC_DEST_ADDR_LSB,
  input  wire [31:0]                      QP6_MAC_DEST_ADDR_MSB,
  input  wire [31:0]                      IP4H_QP6_DEST_ADDR_1,
  input  wire [31:0]                      QP6_PSN,

  input  wire [31:0]                      QP7_MAC_DEST_ADDR_LSB,
  input  wire [31:0]                      QP7_MAC_DEST_ADDR_MSB,
  input  wire [31:0]                      IP4H_QP7_DEST_ADDR_1,
  input  wire [31:0]                      QP7_PSN,

  input  wire                             conf_of_reg_done,               //寄存器配置完成  代表本循环的开始
  output wire                             RDMA_SND_TST_DONE,              //发送测试是否完成（Send+Send With Invalidate）
  input  wire [C_AXIS_DATA_WIDTH-1 : 0]   wqe_proc_top_m_axis_tdata,
  input  wire                             wqe_proc_top_m_axis_tvalid,
  input  wire                             wqe_proc_top_m_axis_tlast,
  output reg                              post_rdma_rd_wqe,
  output reg                              post_rdma_wr_wqe,
  output wire                             rdma_write_path_done,           //RDMA写是否完成
  output wire                             rdma_read_path_done             //RDMA读是否完成
 
);

reg [3:0]    axis_gen_st;
reg          rdma_send_test_done_i;
reg          rdma_send_with_inv_test_done_i;
reg          rdma_read_path_done_i;
localparam TX_AXIS_PKT_GEN_ST0 = 4'h0;
localparam TX_AXIS_PKT_GEN_ST1 = 4'h1;
localparam TX_AXIS_PKT_GEN_ST2 = 4'h2;
localparam TX_AXIS_PKT_GEN_ST3 = 4'h3;
localparam TX_AXIS_PKT_GEN_ST4 = 4'h4;
localparam TX_AXIS_PKT_GEN_ST5 = 4'h5;                                        
localparam TX_AXIS_PKT_GEN_ST6 = 4'h6;
localparam TX_AXIS_PKT_GEN_ST7 = 4'h7;
localparam TX_AXIS_PKT_GEN_ST8 = 4'h8;
localparam TX_AXIS_PKT_GEN_ST9 = 4'h9;
localparam TX_AXIS_PKT_GEN_ST10 = 4'hA;
localparam TX_AXIS_PKT_GEN_ST11 = 4'hB;
localparam TX_AXIS_PKT_GEN_ST12 = 4'hC;
localparam TX_AXIS_PKT_GEN_ST13 = 4'hD;
localparam TX_AXIS_PKT_GEN_ST14 = 4'hE;

reg [7:0] pkt_sent_cnt;
reg [7:0] pkt_sent_QP3;
reg [7:0] pkt_sent_QP4;
reg [7:0] pkt_sent_QP5;
reg [7:0] pkt_sent_QP6;
reg [7:0] pkt_sent_QP7;
reg [2:0] cnt;
reg [8:0] remaining_len_to_tx;
reg [15:0] wait_cnt;
reg [15:0] wait_cnt_rr;
reg [23:0] rd_resp_req_psn;
localparam NUM_SEND_PKT    = 8;
localparam NUM_SEND_WITH_INV_PKT    = 8;
localparam NUM_RDMA_RD_PKT = 8;
localparam NUM_RDMA_WR_PKT = 8;

// Signals to drive the CRC module
reg [64*8*5-1:0] pkt_to_tx;
reg [24:0] chekcsum_i;

function [54*8-1 : 0] hdr_byte_reorder;
  input [54*8-1 :0] in_hdr;
  integer i;
  for(i=0;i<54;i=i+1) begin
    hdr_byte_reorder[((54-i)*8)-1 -: 8] = in_hdr[((i+1)*8)-1 -: 8];
  end
endfunction

function [58*8-1 : 0] inv_hdr_byte_reorder;
  input [58*8-1 :0] in_hdr;
  integer i;
  for(i=0;i<58;i=i+1) begin
    inv_hdr_byte_reorder[((58-i)*8)-1 -: 8] = in_hdr[((i+1)*8)-1 -: 8];
  end
endfunction


function [58*8-1 : 0] hdr_byte_reorder_rd_rsp;
  input [58*8-1 :0] in_hdr;
  integer i;
  for(i=0;i<58;i=i+1) begin
    hdr_byte_reorder_rd_rsp[((58-i)*8)-1 -: 8] = in_hdr[((i+1)*8)-1 -: 8];
  end
endfunction

function [2*8-1 : 0] chk_sum_calc;
  input [18*8-1 :0] in_ipv4_hdr;
begin

  chekcsum_i = in_ipv4_hdr[18*8-1 -: 16] + in_ipv4_hdr[16*8-1 -: 16] +  in_ipv4_hdr[14*8-1 -: 16] + in_ipv4_hdr[12*8-1 -: 16] + in_ipv4_hdr[10*8-1 -: 16] + in_ipv4_hdr[8*8-1 -: 16] + 
                  in_ipv4_hdr[6*8-1 -: 16] + in_ipv4_hdr[4*8-1 -: 16] + in_ipv4_hdr[2*8-1 -: 16];
  if(|chekcsum_i[19:16]) begin
    chekcsum_i = chekcsum_i[15:0] + chekcsum_i[19:16];
  end
  chk_sum_calc = {~chekcsum_i[15:8],~chekcsum_i[7:0]};
end

endfunction


// Header fields

localparam IPV4_CHKSUM = 16'h245c;
localparam pkt_len_rd_resp = 314;
localparam Total_Len_rd_resp = 16'h0130;

localparam Protocol_ID = 16'h0800;
localparam Total_Len = 16'h007c;
localparam Total_Len_inv = 16'h0080;
localparam UDP_Len_inv = Total_Len_inv - 8'h14;
//initiator changes
localparam UDP_Protocol_ID = 8'h11;
localparam IPV4_CHKSUM_QP3 = 16'h76f8; // QP3
localparam IPV4_CHKSUM_QP2 = 16'h2510; //QP2
localparam UDP_Len = Total_Len - 8'h14;
localparam UDP_Len_rd_resp = Total_Len_rd_resp - 8'h14;

reg [54*8-1:0] in_hdr;
reg [58*8-1:0] in_hdr_inv;
reg [64*8-1:0] in_hdr_in;
reg [58*8-1:0] in_hdr_rd_rsp;
reg [58*8-1:0] hdr_byte_reorder1;
// packet length
localparam send_pkt_len = 134;// in bytes -- including header (header : 54 bytes + payload : 80 bytes)
localparam send_pkt_len_inv = 138;// in bytes -- including header (header : 58 bytes + payload : 80 bytes)

reg [511:0] mem_ack [7:0];
localparam ack_pkt_len = 58;
reg rdma_write_path_done_i;

`include "XRNIC_Reg_Config.vh"

// Below block shall drive the CRC module to calculate the CRC
//控制当前的数据发送流程，状态包括：
	// •	TX_AXIS_PKT_GEN_ST0：选择需要发送哪种类型的包（Send/Inv/ReadResp/ACK）
	// •	TX_AXIS_PKT_GEN_ST1/2/3：负责组织数据包并分段发送
	// •	TX_AXIS_PKT_GEN_ST5：发送完所有Send后进入RDMA读流程
	// •	TX_AXIS_PKT_GEN_ST6/7：准备并组织RDMA Read Response
	// •	TX_AXIS_PKT_GEN_ST9/10：准备并发送ACK包（用于RDMA Write）


  
reg [23:0] rcvd_qp_num;
  always @(posedge core_clk or negedge core_aresetn) begin
    if(~core_aresetn) begin
      tx_m_axis_tdata_send_test  <= 'b0;
      tx_m_axis_tkeep_send_test  <= 'b0;
      tx_m_axis_tvalid_send_test <= 1'b0;
      tx_m_axis_tlast_send_test  <= 1'b0;
      remaining_len_to_tx        <= 'b0;
      pkt_sent_cnt               <= 'b0;
      cnt                        <= 0;
      wait_cnt                   <= 16'h0000;
      in_hdr                     <= 'b0;
      in_hdr_inv                 <= 'b0;
      in_hdr_rd_rsp              <= 'b0;
      post_rdma_rd_wqe           <= 1'b0;
      post_rdma_wr_wqe           <= 1'b0;
      rd_resp_req_psn            <= 'b0;
      rdma_send_test_done_i      <= 1'b0;
      rdma_send_with_inv_test_done_i <= 1'b0;
      rdma_read_path_done_i      <= 1'b0;
      rdma_write_path_done_i     <= 1'b0;
      rcvd_qp_num                <= 'b0;
      axis_gen_st                <= TX_AXIS_PKT_GEN_ST0;
    end
    else begin
      case(axis_gen_st)
        TX_AXIS_PKT_GEN_ST0 : begin
          if (~rdma_send_test_done_i) begin
            if(pkt_sent_cnt < 4'h3)
              in_hdr <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP3_MAC_DEST_ADDR_MSB[15:0],QP3_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,Total_Len,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,Total_Len,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP3_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP3_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len,16'h0000,8'h04,8'h30,16'h666f,24'h050000,16'h0300,QP3_PSN[23:8],(QP3_PSN[7:0]+pkt_sent_cnt+1'b1)};
            else if(pkt_sent_cnt == 4'h3)
              in_hdr <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,16'h16c4,32'h50560f2e,Protocol_ID,8'h45,8'hb8,Total_Len,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,Total_Len,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,32'h610c6007,IP4H_QP3_SRC_ADDR_1}),32'h610c6007,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len,16'h0000,8'h04,8'h30,16'h666f,24'h050000,16'h0200,16'ha02a,(8'ha9+1'b1)}; // Pkt count is at 4
            else if(pkt_sent_cnt == 4'h4)
              in_hdr <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP4_MAC_DEST_ADDR_MSB[15:0],QP4_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,Total_Len,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,Total_Len,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP4_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP4_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len,16'h0000,8'h04,8'h30,16'h666f,24'h050000,16'h0400,QP4_PSN[23:8],(QP4_PSN[7:0]+1'b1)};
            else if(pkt_sent_cnt == 4'h5)
              in_hdr <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP5_MAC_DEST_ADDR_MSB[15:0],QP5_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,Total_Len,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,Total_Len,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP5_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP5_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len,16'h0000,8'h04,8'h30,16'h666f,24'h050000,16'h0500,QP5_PSN[23:8],(QP5_PSN[7:0]+1'b1)};
            else if(pkt_sent_cnt == 4'h6)
              in_hdr <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP6_MAC_DEST_ADDR_MSB[15:0],QP6_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,Total_Len,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,Total_Len,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP6_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP6_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len,16'h0000,8'h04,8'h30,16'h666f,24'h050000,16'h0600,QP6_PSN[23:8],(QP6_PSN[7:0]+1'b1)};
            else
              in_hdr <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP7_MAC_DEST_ADDR_MSB[15:0],QP7_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,Total_Len,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,Total_Len,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP7_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP7_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len,16'h0000,8'h04,8'h30,16'h666f,24'h050000,16'h0700,QP7_PSN[23:8],(QP7_PSN[7:0]+(pkt_sent_cnt-4'h6))};
          remaining_len_to_tx  <= send_pkt_len_inv;         //
          end else begin
            if(pkt_sent_cnt < 4'h3)
              in_hdr_inv <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP3_MAC_DEST_ADDR_MSB[15:0],QP3_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,Total_Len_inv,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,Total_Len_inv,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP3_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP3_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len_inv,16'h0000,8'h17,8'h30,16'h666f,24'h050000,16'h0300,QP3_PSN[23:8],(QP3_PSN[7:0]+pkt_sent_cnt+4'h4),32'haaaabbbb};
            else if(pkt_sent_cnt == 4'h3)
              in_hdr_inv <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,16'h16c4,32'h50560f2e,Protocol_ID,8'h45,8'hb8,Total_Len_inv,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,Total_Len_inv,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,32'h610c6007,IP4H_QP3_SRC_ADDR_1}),32'h610c6007,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len_inv,16'h0000,8'h17,8'h30,16'h666f,24'h050000,16'h0200,16'ha02a,(8'ha9+2'h2),32'haaaabbbb}; // Pkt count is at 4
            else if(pkt_sent_cnt == 4'h4)
              in_hdr_inv <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP4_MAC_DEST_ADDR_MSB[15:0],QP4_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,Total_Len_inv,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,Total_Len_inv,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP4_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP4_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len_inv,16'h0000,8'h17,8'h30,16'h666f,24'h050000,16'h0400,QP4_PSN[23:8],(QP4_PSN[7:0]+2'h2),32'haaaabbbb};
            else if(pkt_sent_cnt == 4'h5)                                                                                                      
              in_hdr_inv <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP5_MAC_DEST_ADDR_MSB[15:0],QP5_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,Total_Len_inv,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,Total_Len_inv,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP5_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP5_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len_inv,16'h0000,8'h17,8'h30,16'h666f,24'h050000,16'h0500,QP5_PSN[23:8],(QP5_PSN[7:0]+2'h2),32'haaaabbbb};
            else if(pkt_sent_cnt == 4'h6)                                                                                                      
              in_hdr_inv <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP6_MAC_DEST_ADDR_MSB[15:0],QP6_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,Total_Len_inv,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,Total_Len_inv,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP6_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP6_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len_inv,16'h0000,8'h17,8'h30,16'h666f,24'h050000,16'h0600,QP6_PSN[23:8],(QP6_PSN[7:0]+2'h2),32'haaaabbbb};
            else                                                                                                                               
              in_hdr_inv <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP7_MAC_DEST_ADDR_MSB[15:0],QP7_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,Total_Len_inv,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,Total_Len_inv,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP7_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP7_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len_inv,16'h0000,8'h17,8'h30,16'h666f,24'h050000,16'h0700,QP7_PSN[23:8],(QP7_PSN[7:0]+(pkt_sent_cnt-4'h5)),32'haaaabbbb};
        
          end
           
          remaining_len_to_tx  <= send_pkt_len;  //有点问题
          cnt                  <= 'b0;
          if(EN_SEND_PKT) begin
            if(conf_of_reg_done == 1'b1) begin
              if(~rdma_send_test_done_i)
                axis_gen_st          <= TX_AXIS_PKT_GEN_ST1;
              else if (~rdma_send_with_inv_test_done_i) 
                axis_gen_st <= TX_AXIS_PKT_GEN_ST11;
              else begin
                axis_gen_st          <= TX_AXIS_PKT_GEN_ST5;
                pkt_sent_cnt         <= 'b0;
              end
            end
          end
          else begin
            axis_gen_st          <= TX_AXIS_PKT_GEN_ST5;
            rdma_send_test_done_i<= 1'b1;
            rdma_send_with_inv_test_done_i <= 1'b1;
          end
        end
        TX_AXIS_PKT_GEN_ST1 : begin
          if(~rdma_send_test_done_i)
            pkt_to_tx            <= {{80{pkt_sent_cnt+1'b1}},hdr_byte_reorder(in_hdr)};
          else if (~rdma_read_path_done_i)
            pkt_to_tx            <= {{256{4'h1,(pkt_sent_cnt[3:0]+1'b1)}},hdr_byte_reorder_rd_rsp(in_hdr_rd_rsp)};
          else
            pkt_to_tx            <= hdr_byte_reorder_rd_rsp(in_hdr_rd_rsp);
          axis_gen_st          <= TX_AXIS_PKT_GEN_ST2;
        end
        TX_AXIS_PKT_GEN_ST2 : begin
          if(remaining_len_to_tx > 64) begin
            tx_m_axis_tdata_send_test  <= pkt_to_tx[(64*8*(cnt+1'b1))-1 -: 512];
            tx_m_axis_tkeep_send_test  <= {64{1'b1}};
            tx_m_axis_tvalid_send_test <= 1'b1;
            tx_m_axis_tlast_send_test  <= 1'b0;          
            remaining_len_to_tx     <= remaining_len_to_tx-64;
          end
          else begin
            tx_m_axis_tdata_send_test  <= pkt_to_tx[(64*8*(cnt+1'b1))-1 -: 512];
            if(~rdma_send_test_done_i)
              tx_m_axis_tkeep_send_test  <= {6{1'b1}};
            else
              tx_m_axis_tkeep_send_test  <= {58{1'b1}};
            tx_m_axis_tvalid_send_test <= 1'b1;
            tx_m_axis_tlast_send_test  <= 1'b1;
            remaining_len_to_tx        <= 'b0;
            axis_gen_st                <= TX_AXIS_PKT_GEN_ST3;
          end
            cnt                     <= cnt+1'b1;
        end
        TX_AXIS_PKT_GEN_ST3 : begin // wait state
          if(wait_cnt == 16'h00FF) begin
            wait_cnt     <= 16'h0000;
            if(~rdma_send_test_done_i)
              axis_gen_st  <= TX_AXIS_PKT_GEN_ST4;
            else if(~rdma_read_path_done_i)
              axis_gen_st  <= TX_AXIS_PKT_GEN_ST5;
            else
              axis_gen_st  <= TX_AXIS_PKT_GEN_ST8;
            pkt_sent_cnt <= pkt_sent_cnt + 1'b1;
          end
          else begin
            wait_cnt     <= wait_cnt + 1'b1;
          end
          cnt                     <= 'b0;
          tx_m_axis_tvalid_send_test <= 1'b0;
          tx_m_axis_tlast_send_test  <= 1'b0;
        end
        TX_AXIS_PKT_GEN_ST4 : begin
          // if(pkt_sent_cnt == NUM_SEND_PKT) begin
          //   rdma_send_test_done_i <= 1'b1;
          //   pkt_sent_cnt <= 'b0;
          // end
          axis_gen_st      <= TX_AXIS_PKT_GEN_ST0;
          
        end
        
        TX_AXIS_PKT_GEN_ST11 : begin          
          pkt_to_tx            <= {{80{pkt_sent_cnt+1'b1}},inv_hdr_byte_reorder(in_hdr_inv)};         
          axis_gen_st          <= TX_AXIS_PKT_GEN_ST12;
        end
        TX_AXIS_PKT_GEN_ST12 : begin
          if(remaining_len_to_tx > 64) begin
            tx_m_axis_tdata_send_test  <= pkt_to_tx[(64*8*(cnt+1'b1))-1 -: 512];
            tx_m_axis_tkeep_send_test  <= {64{1'b1}};
            tx_m_axis_tvalid_send_test <= 1'b1;
            tx_m_axis_tlast_send_test  <= 1'b0;          
            remaining_len_to_tx     <= remaining_len_to_tx-64;
          end
          else begin
            tx_m_axis_tdata_send_test  <= pkt_to_tx[(64*8*(cnt+1'b1))-1 -: 512];
            if(~rdma_send_with_inv_test_done_i)
              tx_m_axis_tkeep_send_test  <= {10{1'b1}};
            else
              tx_m_axis_tkeep_send_test  <= {58{1'b1}};
            tx_m_axis_tvalid_send_test <= 1'b1;
            tx_m_axis_tlast_send_test  <= 1'b1;
            remaining_len_to_tx        <= 'b0;
            axis_gen_st                <= TX_AXIS_PKT_GEN_ST13;
          end
            cnt                     <= cnt+1'b1;
        end
        TX_AXIS_PKT_GEN_ST13 : begin // wait state
          if(wait_cnt == 16'h00FF) begin
            wait_cnt     <= 16'h0000;
            if(~rdma_send_with_inv_test_done_i)
              axis_gen_st  <= TX_AXIS_PKT_GEN_ST14;
            else if(~rdma_read_path_done_i)
              axis_gen_st  <= TX_AXIS_PKT_GEN_ST5;
            else
              axis_gen_st  <= TX_AXIS_PKT_GEN_ST8;
            pkt_sent_cnt <= pkt_sent_cnt + 1'b1;
          end
          else begin
            wait_cnt     <= wait_cnt + 1'b1;
          end
          cnt                     <= 'b0;
          tx_m_axis_tvalid_send_test <= 1'b0;
          tx_m_axis_tlast_send_test  <= 1'b0;
        end
        TX_AXIS_PKT_GEN_ST14 : begin
          if(pkt_sent_cnt == NUM_SEND_WITH_INV_PKT)
            rdma_send_with_inv_test_done_i <= 1'b1;
          axis_gen_st      <= TX_AXIS_PKT_GEN_ST0;
        end
        TX_AXIS_PKT_GEN_ST5 : begin
          if(EN_RDMA_RD_PKT) begin
            if(rdma_send_test_done_i == 1'b1 && conf_of_reg_done == 1'b1) begin // Send and Read Response tests are done, now RDMA write testing to progress
              if(pkt_sent_cnt == NUM_RDMA_RD_PKT) begin
                axis_gen_st      <= TX_AXIS_PKT_GEN_ST8;
                post_rdma_rd_wqe <= 1'b0;
                rdma_read_path_done_i <= 1'b1;
                pkt_sent_cnt          <= 'b0;
              end
              else begin
                post_rdma_rd_wqe <= 1'b1;
                axis_gen_st      <= TX_AXIS_PKT_GEN_ST6;
              end
            end
          end
          else begin
            axis_gen_st      <= TX_AXIS_PKT_GEN_ST8;
            rdma_read_path_done_i <= 1'b1;
          end
        end
        TX_AXIS_PKT_GEN_ST6 : begin
          post_rdma_rd_wqe <= 1'b0;
          remaining_len_to_tx  <= pkt_len_rd_resp;
          cnt                  <= 'b0;
          if(wqe_proc_top_m_axis_tvalid) begin
            axis_gen_st          <= TX_AXIS_PKT_GEN_ST7;
            rd_resp_req_psn      <= {wqe_proc_top_m_axis_tdata[51*8+:8],wqe_proc_top_m_axis_tdata[52*8+:8],wqe_proc_top_m_axis_tdata[53*8+:8]};
            rcvd_qp_num          <= {wqe_proc_top_m_axis_tdata[47*8+:8],wqe_proc_top_m_axis_tdata[48*8+:8],wqe_proc_top_m_axis_tdata[49*8+:8]};
          end
        end
        TX_AXIS_PKT_GEN_ST7 : begin
          post_rdma_rd_wqe <= 1'b0;
          if(rcvd_qp_num == 24'h000002)
            in_hdr_rd_rsp <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,16'h16c4,32'h50560f2e,Protocol_ID,8'h45,8'hb8,Total_Len_rd_resp,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IPV4_CHKSUM,32'h610c6007,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len_rd_resp,16'h0000,8'h10,8'h00,16'h666f,24'h050000,16'h0200,rd_resp_req_psn,32'h00000000};
          else if(rcvd_qp_num == 24'h000003)
            in_hdr_rd_rsp <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP3_MAC_DEST_ADDR_MSB[15:0],QP3_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,Total_Len_rd_resp,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,Total_Len_rd_resp,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP3_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP3_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len_rd_resp,16'h0000,8'h10,8'h00,16'h666f,24'h050000,16'h0300,rd_resp_req_psn,32'h00000000};
          else if(rcvd_qp_num == 24'h000004)
            in_hdr_rd_rsp <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP4_MAC_DEST_ADDR_MSB[15:0],QP4_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,Total_Len_rd_resp,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,Total_Len_rd_resp,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP4_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP4_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len_rd_resp,16'h0000,8'h10,8'h00,16'h666f,24'h050000,16'h0400,rd_resp_req_psn,32'h00000000};
          else if(rcvd_qp_num == 24'h000005)
            in_hdr_rd_rsp <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP5_MAC_DEST_ADDR_MSB[15:0],QP5_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,Total_Len_rd_resp,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,Total_Len_rd_resp,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP5_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP5_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len_rd_resp,16'h0000,8'h10,8'h00,16'h666f,24'h050000,16'h0500,rd_resp_req_psn,32'h00000000};
          else if(rcvd_qp_num == 24'h000006)
            in_hdr_rd_rsp <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP6_MAC_DEST_ADDR_MSB[15:0],QP6_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,Total_Len_rd_resp,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,Total_Len_rd_resp,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP6_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP6_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len_rd_resp,16'h0000,8'h10,8'h00,16'h666f,24'h050000,16'h0600,rd_resp_req_psn,32'h00000000};
          else if(rcvd_qp_num == 24'h000007)
            in_hdr_rd_rsp <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP7_MAC_DEST_ADDR_MSB[15:0],QP7_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,Total_Len_rd_resp,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,Total_Len_rd_resp,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP7_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP7_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len_rd_resp,16'h0000,8'h10,8'h00,16'h666f,24'h050000,16'h0700,rd_resp_req_psn,32'h00000000};
          else
            in_hdr_rd_rsp <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,16'h16c4,32'h50560f2e,Protocol_ID,8'h45,8'hb8,Total_Len_rd_resp,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IPV4_CHKSUM,32'h610c6007,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,UDP_Len_rd_resp,16'h0000,8'h10,8'h00,16'h666f,24'h050000,16'h0200,rd_resp_req_psn,32'h00000000};
          
          remaining_len_to_tx  <= pkt_len_rd_resp;
          cnt                  <= 'b0;
          if(wqe_proc_top_m_axis_tlast)
            axis_gen_st          <= TX_AXIS_PKT_GEN_ST1;
        end
        TX_AXIS_PKT_GEN_ST8 : begin
          if(EN_RDMA_WR_PKT) begin
            if(rdma_read_path_done_i == 1'b1 && conf_of_reg_done == 1'b1) begin
              if(pkt_sent_cnt == NUM_RDMA_WR_PKT) begin
                axis_gen_st            <= TX_AXIS_PKT_GEN_ST8;
                post_rdma_wr_wqe       <= 1'b0;
                rdma_write_path_done_i <= 1'b1;
                pkt_sent_cnt           <= 'b0;
              end
              else begin
                post_rdma_wr_wqe <= 1'b1;
                axis_gen_st      <= TX_AXIS_PKT_GEN_ST9;
              end
            end
          end
          else begin
            rdma_write_path_done_i <= 1'b1;
            axis_gen_st            <= TX_AXIS_PKT_GEN_ST8;
          end
        end
         TX_AXIS_PKT_GEN_ST9 : begin
           post_rdma_wr_wqe <= 1'b0;
           remaining_len_to_tx  <= ack_pkt_len;
           cnt                  <= 'b0;
           if(wqe_proc_top_m_axis_tvalid) begin
             axis_gen_st          <= TX_AXIS_PKT_GEN_ST10;
             rd_resp_req_psn      <= {wqe_proc_top_m_axis_tdata[51*8+:8],wqe_proc_top_m_axis_tdata[52*8+:8],wqe_proc_top_m_axis_tdata[53*8+:8]};
             rcvd_qp_num          <= {wqe_proc_top_m_axis_tdata[47*8+:8],wqe_proc_top_m_axis_tdata[48*8+:8],wqe_proc_top_m_axis_tdata[49*8+:8]};
           end
        end
        TX_AXIS_PKT_GEN_ST10 : begin
          if(rcvd_qp_num == 24'h000002)
            in_hdr_rd_rsp <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,16'h16c4,32'h50560f2e,Protocol_ID,8'h45,8'hb8,16'h0030,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,16'h0030,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,32'h610c6007,IP4H_QP3_SRC_ADDR_1}),32'h610c6007,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,16'h001c,16'h0000,8'h11,8'h00,16'h666f,24'h050000,16'h0200,rd_resp_req_psn,32'h00000000};
          else if(rcvd_qp_num == 24'h000003)
            in_hdr_rd_rsp <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP3_MAC_DEST_ADDR_MSB[15:0],QP3_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,16'h0030,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,16'h0030,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP3_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP3_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,16'h001c,16'h0000,8'h11,8'h00,16'h666f,24'h050000,16'h0300,rd_resp_req_psn,32'h00000000};
          else if(rcvd_qp_num == 24'h000004)
            in_hdr_rd_rsp <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP4_MAC_DEST_ADDR_MSB[15:0],QP4_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,16'h0030,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,16'h0030,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP4_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP4_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,16'h001c,16'h0000,8'h11,8'h00,16'h666f,24'h050000,16'h0400,rd_resp_req_psn,32'h00000000};
          else if(rcvd_qp_num == 24'h000005)
            in_hdr_rd_rsp <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP5_MAC_DEST_ADDR_MSB[15:0],QP5_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,16'h0030,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,16'h0030,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP5_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP5_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,16'h001c,16'h0000,8'h11,8'h00,16'h666f,24'h050000,16'h0500,rd_resp_req_psn,32'h00000000};
          else if(rcvd_qp_num == 24'h000006)
            in_hdr_rd_rsp <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP6_MAC_DEST_ADDR_MSB[15:0],QP6_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,16'h0030,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,16'h0030,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP6_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP6_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,16'h001c,16'h0000,8'h11,8'h00,16'h666f,24'h050000,16'h0600,rd_resp_req_psn,32'h00000000};
          else if(rcvd_qp_num == 24'h000007)
            in_hdr_rd_rsp <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,QP7_MAC_DEST_ADDR_MSB[15:0],QP7_MAC_DEST_ADDR_LSB,Protocol_ID,8'h45,8'hb8,16'h0030,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,chk_sum_calc({8'h45,8'hb8,16'h0030,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IP4H_QP7_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1}),IP4H_QP7_DEST_ADDR_1,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,16'h001c,16'h0000,8'h11,8'h00,16'h666f,24'h050000,16'h0700,rd_resp_req_psn,32'h00000000};
          else
            in_hdr_rd_rsp <= {MAC_SRC_ADDR_MSB[15:0],MAC_SRC_ADDR_LSB,16'h16c4,32'h50560f2e,Protocol_ID,8'h45,8'hb8,16'h0030,16'h5555,16'h4000,8'hba,UDP_Protocol_ID,IPV4_CHKSUM,32'h610c6007,IP4H_QP3_SRC_ADDR_1,16'h6851,16'h12b7,16'h001c,16'h0000,8'h11,8'h00,16'h666f,24'h050000,16'h0200,rd_resp_req_psn,32'h00000000};

          post_rdma_wr_wqe <= 1'b0;
          remaining_len_to_tx <= ack_pkt_len;
          if(wqe_proc_top_m_axis_tlast)
            axis_gen_st  <= TX_AXIS_PKT_GEN_ST1;
        end

        default : begin
          tx_m_axis_tdata_send_test  <= 'b0;
          tx_m_axis_tkeep_send_test  <= 'b0;
          tx_m_axis_tvalid_send_test <= 1'b0;
          tx_m_axis_tlast_send_test  <= 1'b0;
          remaining_len_to_tx     <= 1'b0;
          pkt_sent_cnt            <= 0;
          cnt                     <= 0;
          wait_cnt         <= 16'h0000;
        end
      endcase
    end
  end


assign rdma_read_path_done  = rdma_read_path_done_i;
assign rdma_write_path_done = rdma_write_path_done_i;
assign RDMA_SND_TST_DONE = rdma_send_test_done_i && rdma_send_with_inv_test_done_i;

//initiator 

endmodule
