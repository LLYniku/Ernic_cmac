

`timescale 1ns/1ns
module exdes_rx_path_checker #(
 parameter C_AXI_THREAD_ID_WIDTH =1,
 parameter C_AXI_ADDR_WIDTH = 32,
 parameter C_AXI_DATA_WIDTH = 512
) (
  // capsule I/F
  input core_clk,
  input core_rst,
  input wire [C_AXI_THREAD_ID_WIDTH-1:0]     capsule_ddr_m_axi_awid,                      
  input wire [C_AXI_ADDR_WIDTH-1:0]          capsule_ddr_m_axi_awaddr,                    
  input wire [7:0]                           capsule_ddr_m_axi_awlen,                     
  input wire [2:0]                           capsule_ddr_m_axi_awsize,                    
  input wire [1:0]                           capsule_ddr_m_axi_awburst,                   
  input wire [3:0]                           capsule_ddr_m_axi_awcache,                   
  input wire [2:0]                           capsule_ddr_m_axi_awprot,                    
  input wire                                 capsule_ddr_m_axi_awvalid,                   
  output  wire                               capsule_ddr_m_axi_awready,                   
  input wire [511:0]                         capsule_ddr_m_axi_wdata,                     
  input wire [ 63:0]                         capsule_ddr_m_axi_wstrb,                     
  input wire                                 capsule_ddr_m_axi_wlast,                     
  input wire                                 capsule_ddr_m_axi_wvalid,                    
  output  wire                               capsule_ddr_m_axi_wready,                    
  input wire                                 capsule_ddr_m_axi_awlock,                    
  output  wire [C_AXI_THREAD_ID_WIDTH-1 :0]  capsule_ddr_m_axi_bid,                       
  output  wire [1:0]                         capsule_ddr_m_axi_bresp,                     
  output  wire                               capsule_ddr_m_axi_bvalid,                    
  input wire                                 capsule_ddr_m_axi_bready,                    

  //Data I/F
  input wire [C_AXI_THREAD_ID_WIDTH-1:0]     data_m_axi_awid,                      
  input wire [C_AXI_ADDR_WIDTH-1:0]          data_m_axi_awaddr,                    
  input wire [7:0]                           data_m_axi_awlen,                     
  input wire [2:0]                           data_m_axi_awsize,                    
  input wire [1:0]                           data_m_axi_awburst,                   
  input wire [3:0]                           data_m_axi_awcache,                   
  input wire [2:0]                           data_m_axi_awprot,                    
  input wire                                 data_m_axi_awvalid,                   
  output  wire                               data_m_axi_awready,                   
  input wire [511:0]                         data_m_axi_wdata,                     
  input wire [ 63:0]                         data_m_axi_wstrb,                     
  input wire                                 data_m_axi_wlast,                     
  input wire                                 data_m_axi_wvalid,                    
  output  wire                               data_m_axi_wready,                    
  input wire                                 data_m_axi_awlock,                    
  output  wire [C_AXI_THREAD_ID_WIDTH-1 :0]  data_m_axi_bid,                       
  output  wire [1:0]                         data_m_axi_bresp,                     
  output  wire                               data_m_axi_bvalid,                    
  input wire                                 data_m_axi_bready,                    
// Door bell signals
  input wire                                 rx_pkt_hndler_o_rq_db_data_valid,
  input wire [31:0]                          rx_pkt_hndler_o_rq_db_data,
  input wire [9:0]                           rx_pkt_hndler_o_rq_db_addr,
  output reg                                 rx_pkt_hndler_i_rq_db_rdy, 
  input wire                                 resp_hndler_o_send_cq_db_cnt_valid,
// Payload Checks
  output wire                                send_capsule_matched,
  output wire                                rd_rsp_payload_matched,
  output wire                                rqci_completions_written_out,
  output reg   [15:0]                        qp_rq_cidb_hndshk,
  output reg   [31:0]                        qp_rq_cidb_wr_addr_hndshk,
  output reg                                 qp_rq_cidb_wr_valid_hndshk,
  input wire                                 qp_rq_cidb_wr_rdy

   );

// SEND Packets Checks
localparam rx_capsule_chk_st0 = 3'b000;
localparam rx_capsule_chk_st1 = 3'b001;
localparam rx_capsule_chk_st2 = 3'b010;
localparam rx_capsule_chk_st3 = 3'b011;
localparam rx_capsule_chk_st4 = 3'b100;
localparam rx_capsule_chk_st5 = 3'b101;

reg [2:0] rx_capsule_chk_st;
reg [7:0] transfer_len;
// SEND Packet Payload is set to 80 Bytes while transmitting from Exdes, and
// each packet will have incremental data.
reg [1023:0] rdma_capsule_rcvd;
reg [3:0] rcvd_payload_cnt;
reg send_payload_chk_fail;
reg send_payload_chk_pass;
reg send_payload_chk_completed;
reg [3:0] rq_db_cnt;
reg [4:0] resp_handler_db_cnt;
reg [31:0]   rx_pkt_hndler_o_rq_db_data_i;
reg [9:0]    rx_pkt_hndler_o_rq_db_addr_i; 
// completion address counts
/*

QP2 - 04 address -- 324 is the completion addr
QP3 - 08 address -- 424 is the completion addr
QP4 - 10 address -- 524 is the completion addr
QP5 - 14 address -- 624 is the completion addr
QP6 - 18 address -- 724 is the completion addr
QP7 - 1C address -- 824 is the completion addr

*/

always @(posedge core_clk) begin
  if (core_rst) begin
    rx_capsule_chk_st <= rx_capsule_chk_st0;
    transfer_len      <= 'b0;
    rdma_capsule_rcvd <= 'b0;
    rcvd_payload_cnt  <= 4'h0;
    send_payload_chk_fail <= 1'b0;
    send_payload_chk_pass <= 1'b0;
    send_payload_chk_completed <= 1'b0;
  end
  else begin
    case(rx_capsule_chk_st)
      rx_capsule_chk_st0: begin
        if(capsule_ddr_m_axi_awvalid) begin
          rx_capsule_chk_st  <= rx_capsule_chk_st1;
          transfer_len       <= capsule_ddr_m_axi_awlen;
        end
      end
      rx_capsule_chk_st1: begin
        if(capsule_ddr_m_axi_wvalid) begin
          rdma_capsule_rcvd  <= {capsule_ddr_m_axi_wdata,rdma_capsule_rcvd[1023-:512]};
        end
        if(capsule_ddr_m_axi_wvalid && capsule_ddr_m_axi_wlast) begin
          rx_capsule_chk_st  <= rx_capsule_chk_st2;
          rcvd_payload_cnt   <= rcvd_payload_cnt + 1'b1;
        end
      end
      rx_capsule_chk_st2: begin
        if(rdma_capsule_rcvd[0 +: 80*8] == {80{4'h0,rcvd_payload_cnt}}) begin
          send_payload_chk_fail     <= 1'b0;
          send_payload_chk_pass     <= 1'b1; end
        else begin
          send_payload_chk_fail     <= 1'b1;
          send_payload_chk_pass     <= 1'b0; end
        if(rcvd_payload_cnt == 4'h8) begin
          send_payload_chk_completed <= 1'b1;
          rcvd_payload_cnt <= 4'h0; end
        rx_capsule_chk_st <= rx_capsule_chk_st0;
      end
      default: begin
        rx_capsule_chk_st <= rx_capsule_chk_st0;
        transfer_len      <= 'b0;
        rdma_capsule_rcvd <= 'b0;
        rcvd_payload_cnt  <= 4'h0;
        send_payload_chk_fail <= 1'b0;
        send_payload_chk_completed <= 1'b0;
      end
    endcase
  end
end


localparam rx_db_chk_st0 = 3'b000;
localparam rx_db_chk_st1 = 3'b001;
localparam rx_db_chk_st2 = 3'b010;                                    
localparam rx_db_chk_st3 = 3'b011;

reg [2:0] rx_db_chk_st;
reg rqci_completions_written;

always @(posedge core_clk) begin
  if (core_rst) begin
    rx_db_chk_st <= rx_db_chk_st0;
    rq_db_cnt <= 'b0;
    qp_rq_cidb_wr_addr_hndshk <= 'b0;
    qp_rq_cidb_hndshk <= 'b0;
    qp_rq_cidb_wr_valid_hndshk <= 1'b0;
    rx_pkt_hndler_o_rq_db_data_i <= 'b0;
    rx_pkt_hndler_o_rq_db_addr_i <= 'b0;
    rx_pkt_hndler_i_rq_db_rdy    <= 1'b0;
    rqci_completions_written     <= 1'b0;
  end
  else begin
    case(rx_db_chk_st)
      rx_db_chk_st0: begin
        if(rx_pkt_hndler_o_rq_db_data_valid) begin // wait for door bell update
          rx_db_chk_st  <= rx_db_chk_st1;

          rx_pkt_hndler_o_rq_db_data_i <= rx_pkt_hndler_o_rq_db_data;
          rx_pkt_hndler_o_rq_db_addr_i <= rx_pkt_hndler_o_rq_db_addr; 
          rx_pkt_hndler_i_rq_db_rdy    <= 1'b1;
        end
        rqci_completions_written     <= 1'b0;
      end

      rx_db_chk_st1: begin // state to update RQCI DB
       if(rx_pkt_hndler_o_rq_db_addr_i == 10'h004)
         qp_rq_cidb_wr_addr_hndshk <= 32'h50040334;
       else if(rx_pkt_hndler_o_rq_db_addr_i == 10'h008)
         qp_rq_cidb_wr_addr_hndshk <= 32'h50040434;
       else if(rx_pkt_hndler_o_rq_db_addr_i == 10'h010)
         qp_rq_cidb_wr_addr_hndshk <= 32'h50040534;
       else if(rx_pkt_hndler_o_rq_db_addr_i == 10'h014)
         qp_rq_cidb_wr_addr_hndshk <= 32'h50040634;         
       else if(rx_pkt_hndler_o_rq_db_addr_i == 10'h018)
         qp_rq_cidb_wr_addr_hndshk <= 32'h50040734; 
       else
         qp_rq_cidb_wr_addr_hndshk <= 32'h50040834;           

         qp_rq_cidb_hndshk <= rx_pkt_hndler_o_rq_db_data_i;
         qp_rq_cidb_wr_valid_hndshk <= 1'b1;

        rx_db_chk_st <= rx_db_chk_st2;
      end
      rx_db_chk_st2: begin
        if(qp_rq_cidb_wr_rdy) begin
          rx_db_chk_st <= rx_db_chk_st3;
          qp_rq_cidb_wr_valid_hndshk <= 1'b0;
          rq_db_cnt <= rq_db_cnt + 1'b1;
        end
      end
      rx_db_chk_st3: begin
        if(rq_db_cnt == 4'h8)
          rqci_completions_written <= 1'b1;
        else
          rqci_completions_written <= 1'b0;
        rx_db_chk_st <= rx_db_chk_st0;
      end
      default: begin
        rq_db_cnt <= 'b0;
        qp_rq_cidb_wr_addr_hndshk <= 'b0;
        qp_rq_cidb_hndshk <= 'b0;
        qp_rq_cidb_wr_valid_hndshk <= 1'b0;
        rx_pkt_hndler_o_rq_db_data_i <= 'b0;
        rx_pkt_hndler_o_rq_db_addr_i <= 'b0;
        rx_pkt_hndler_i_rq_db_rdy    <= 1'b0;
      end
    endcase
  end
end

// SEND Packets Checks
localparam rx_payload_chk_st0 = 3'b000;
localparam rx_payload_chk_st1 = 3'b001;
localparam rx_payload_chk_st2 = 3'b010;
localparam rx_payload_chk_st3 = 3'b011;

reg [2:0] rx_payload_chk_st;
reg [7:0] transfer_len_rd_resp;
// Read Response Packet Payload is set to 256 Bytes while transmitting from Exdes, and
// each packet will have incremental data.
reg [4*512-1:0] rdma_rd_resp_data_received;
reg [3:0] rcvd_rd_resp_payload_cnt;
reg rd_rsp_payload_chk_fail;
reg rd_rsp_payload_chk_pass;
reg rd_rsp_payload_chk_completed;
always @(posedge core_clk) begin
  if (core_rst) begin
    rx_payload_chk_st <= rx_payload_chk_st0;
    transfer_len_rd_resp      <= 'b0;
    rdma_rd_resp_data_received <= 'b0;
    rcvd_rd_resp_payload_cnt  <= 4'h0;
    rd_rsp_payload_chk_fail <= 1'b0;
    rd_rsp_payload_chk_pass <= 1'b0;
    rd_rsp_payload_chk_completed <= 1'b0;
  end
  else begin
    case(rx_payload_chk_st)
      rx_payload_chk_st0: begin
        if(data_m_axi_awvalid) begin
          rx_payload_chk_st  <= rx_payload_chk_st1;
          transfer_len_rd_resp       <= capsule_ddr_m_axi_awlen;
        end
      end
      rx_payload_chk_st1: begin
        if(data_m_axi_wvalid) begin
          rdma_rd_resp_data_received  <= {data_m_axi_wdata,rdma_rd_resp_data_received[512*4-1-:512*3]};
        end
        if(data_m_axi_wvalid && data_m_axi_wlast) begin
          rx_payload_chk_st       <= rx_payload_chk_st2;
          rcvd_rd_resp_payload_cnt   <= rcvd_rd_resp_payload_cnt + 1'b1;
        end
      end
      rx_payload_chk_st2: begin
        if(rdma_rd_resp_data_received[256*8-1 : 0] == {256{4'h1,rcvd_rd_resp_payload_cnt}}) begin
          rd_rsp_payload_chk_fail     <= 1'b0;
          rd_rsp_payload_chk_pass     <= 1'b1; end
        else begin
          rd_rsp_payload_chk_fail     <= 1'b1;
          rd_rsp_payload_chk_pass     <= 1'b0; end
        if(rcvd_rd_resp_payload_cnt == 4'h8)
          rd_rsp_payload_chk_completed <= 1'b1;
        rx_payload_chk_st <= rx_payload_chk_st0;
      end
      default: begin
        rx_payload_chk_st          <= rx_payload_chk_st0;
        transfer_len_rd_resp       <= 'b0;
        rdma_rd_resp_data_received <= 'b0;
        rcvd_rd_resp_payload_cnt   <= 4'h0;
        rd_rsp_payload_chk_fail <= 1'b0;
        rd_rsp_payload_chk_pass <= 1'b0;
        rd_rsp_payload_chk_completed <= 1'b0;
      end
    endcase
  end
end
always @(posedge core_clk) begin
  if(core_rst) begin
    resp_handler_db_cnt <= 5'h0;
  end
  else begin
    if(resp_hndler_o_send_cq_db_cnt_valid)
      resp_handler_db_cnt <= resp_handler_db_cnt + 1'b1;
  end
end


assign send_capsule_matched   = (send_payload_chk_completed & send_payload_chk_pass);
assign rd_rsp_payload_matched = (send_payload_chk_completed & rd_rsp_payload_chk_pass);
assign rqci_completions_written_out = rqci_completions_written;

// synthesis translate_off

always @(send_payload_chk_completed or send_payload_chk_pass) begin
  if(send_payload_chk_completed) begin
    if(send_payload_chk_pass)
      $display("PASS : Send Capsule Matched");
    else
      $display("FAIL: SEND Capsule Mismatch");

  end
end

always @(rqci_completions_written) begin
    if(rqci_completions_written)
      $display("PASS : RQ Door bell count Matched");
end
always @(rd_rsp_payload_chk_completed or rd_rsp_payload_chk_pass) begin
  if(rd_rsp_payload_chk_completed) begin
    if(rd_rsp_payload_chk_pass)
      $display("PASS : RDMA Read Reponse Payload Matched");
    else
      $display("FAIL: RDMA Read Reponse Payload Mismatch");
  end
end

always @(resp_handler_db_cnt) begin
    if(resp_handler_db_cnt == 5'h10)
      $display("PASS : Response door bell count Matched");
end

// synthesis translate_on

endmodule

