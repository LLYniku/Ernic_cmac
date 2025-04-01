
`timescale 1ns/1ns
module exdes_wqe_gen 
# (
  parameter C_AXIS_DATA_WIDTH = 512,
  parameter C_AXI_ADDR_WIDTH = 32
  )
(
  input  wire                             core_clk,
  input  wire                             core_aresetn,
  input  wire [31:0]                      MAC_SRC_ADDR_LSB,
  input  wire [31:0]                      MAC_SRC_ADDR_MSB,
  input  wire [31:0]                      QP3_MAC_DEST_ADDR_LSB,
  input  wire [31:0]                      QP3_MAC_DEST_ADDR_MSB,
  input  wire [31:0]                      IP4H_QP3_DEST_ADDR_1,
  input  wire [31:0]                      IP4H_QP3_SRC_ADDR_1,
  input  wire [31:0]                      QP3_PSN,
  input  wire                             wqe_proc_top_m_axis_tlast,

// WQE Posting -- Related Signals
  input wire   [C_AXI_ADDR_WIDTH-1 :0]    qp_mgr_m_axi_araddr,
  input wire                              qp_mgr_m_axi_arvalid,
  output  reg                             qp_mgr_m_axi_arready,
// Read data/response channel
  output  reg   [511:0]                   qp_mgr_m_axi_rdata,
  output  reg                             qp_mgr_m_axi_rlast,
  output  reg                             qp_mgr_m_axi_rvalid,
  input wire                              qp_mgr_m_axi_rready,
  input wire [7:0]                        wqe_proc_top_m_axi_arlen,
  input  wire                             wqe_proc_top_m_axi_arvalid,
  output reg                              wqe_proc_top_m_axi_arready,
  output reg    [511:0]                   wqe_proc_top_m_axi_rdata,                                         
  output reg                              wqe_proc_top_m_axi_rlast,                     
  output reg                              wqe_proc_top_m_axi_rvalid,  
  input wire                              wqe_proc_top_m_axi_rready,
  input wire                              rdma_write_path_done,
  input wire                              rdma_read_path_done,
  input wire                              post_rdma_rd_wqe,
  input wire                              post_rdma_wr_wqe,
//SQ PI hardware handshake
  output reg [15:0]                       o_qp_sq_pidb_hndshk,
  output reg [31:0]                       o_qp_sq_pidb_wr_addr_hndshk,
  output reg                              o_qp_sq_pidb_wr_valid_hndshk,
  input  wire                             i_qp_sq_pidb_wr_rdy,
  input  wire                             conf_of_reg_done,
  input  wire                             RDMA_SND_TST_DONE

);


localparam TX_AXIS_PKT_GEN_ST0 = 4'h0;
localparam TX_AXIS_PKT_GEN_ST1 = 4'h1;
localparam TX_AXIS_PKT_GEN_ST2 = 4'h2;
localparam TX_AXIS_PKT_GEN_ST3 = 4'h3;
localparam TX_AXIS_PKT_GEN_ST4 = 4'h4;
localparam TX_AXIS_PKT_GEN_ST5 = 4'h5;
localparam WAIT = 4'h6;
localparam no_rdma_snd_pkt = 8;

//reg [511:0] mem_int [15:0];
reg [5:0] mem_loc_cnt_rd_resp;
reg [2:0] axi_gen_st_rd_resp;
localparam RX_DONE = 3'b000;
localparam ADDR_SEND = 3'b001;
localparam DATA_RESP = 3'b010;
localparam TRANSFER_DONE = 3'b011;
localparam RDMA_READ=8'h04;
localparam NUM_OF_WQE=8;
reg[3:0] wqe_sent_cnt;
reg [3:0] wqe_send;

localparam TX_AXI_WQE_TXN_ST0 = 4'h0;
localparam TX_AXI_WQE_TXN_ST1 = 4'h1;
localparam TX_AXI_WQE_TXN_ST2 = 4'h2;

`include "XRNIC_Reg_Config.vh"


// Read Response generation
// Capture the PSN sent to send the next Read Response packet
always @(posedge core_clk ) begin
  if(~core_aresetn) begin
    o_qp_sq_pidb_hndshk           <= 'b0;
    o_qp_sq_pidb_wr_addr_hndshk   <= 'b0;
    o_qp_sq_pidb_wr_valid_hndshk  <= 1'b0;
    wqe_sent_cnt  <= 4'h0;
    wqe_send <= TX_AXI_WQE_TXN_ST0;
  end
  else begin
    case(wqe_send)
       TX_AXI_WQE_TXN_ST0: begin
       if(EN_RDMA_RD_PKT) begin
         if(conf_of_reg_done == 1'b1 && RDMA_SND_TST_DONE == 1'b1) begin
           if(wqe_sent_cnt< NUM_RD_WQE) begin
             if(post_rdma_rd_wqe) begin
               if(wqe_sent_cnt < 3) begin
                 o_qp_sq_pidb_wr_addr_hndshk <= 32'h50040338;
                 o_qp_sq_pidb_hndshk         <= wqe_sent_cnt+1'b1;
                 o_qp_sq_pidb_wr_valid_hndshk  <= 1'b1;
                 wqe_send <= TX_AXI_WQE_TXN_ST2;
               end
               else begin
                 o_qp_sq_pidb_wr_addr_hndshk <= 32'h50040438 + {20'h00000,wqe_sent_cnt-4'h3,8'h00};
                 o_qp_sq_pidb_hndshk         <= 4'h1;
                 o_qp_sq_pidb_wr_valid_hndshk  <= 1'b1;
                 wqe_send <= TX_AXI_WQE_TXN_ST2;
               end
             end
           end
           else begin
             if(rdma_read_path_done && EN_RDMA_WR_PKT) begin
               wqe_send     <= TX_AXI_WQE_TXN_ST1;
               wqe_sent_cnt <= 'b0;
             end
           end
         end
         end
         else begin
           wqe_send     <= TX_AXI_WQE_TXN_ST1;
           wqe_sent_cnt <= 'b0;         
         end
       end
       TX_AXI_WQE_TXN_ST1: begin
         if(wqe_sent_cnt< NUM_WR_WQE) begin
           if(post_rdma_wr_wqe) begin
             if(wqe_sent_cnt < 3) begin
               o_qp_sq_pidb_wr_addr_hndshk <= 32'h50040338;
               if(EN_RDMA_RD_PKT) 
                 o_qp_sq_pidb_hndshk         <= wqe_sent_cnt+4'h4; // 3 door bells rang already for RDMA read requests
               else
                 o_qp_sq_pidb_hndshk         <= wqe_sent_cnt+1'b1;
               o_qp_sq_pidb_wr_valid_hndshk  <= 1'b1;
               wqe_send <= TX_AXI_WQE_TXN_ST2;
             end
             else begin
               o_qp_sq_pidb_wr_addr_hndshk <= 32'h50040438 + {20'h00000,wqe_sent_cnt-4'h3,8'h00};
               if(EN_RDMA_RD_PKT)
                 o_qp_sq_pidb_hndshk         <= 4'h2;
               else
                 o_qp_sq_pidb_hndshk         <= 4'h1;
               o_qp_sq_pidb_wr_valid_hndshk  <= 1'b1;
               wqe_send <= TX_AXI_WQE_TXN_ST2;
             end
           end
         end
         else
           wqe_send <= TX_AXI_WQE_TXN_ST1; // stay in the same state as the test is completed
       end
       TX_AXI_WQE_TXN_ST2: begin
         if(i_qp_sq_pidb_wr_rdy) begin
            o_qp_sq_pidb_wr_valid_hndshk  <= 1'b0;
            wqe_sent_cnt <= wqe_sent_cnt + 1'b1;   
            if(~rdma_read_path_done)
              wqe_send <= TX_AXI_WQE_TXN_ST0;
            else
              wqe_send <= TX_AXI_WQE_TXN_ST1;
         end
       end
       default : begin
         o_qp_sq_pidb_hndshk           <= 'b0;
         o_qp_sq_pidb_wr_addr_hndshk   <= 'b0;
         o_qp_sq_pidb_wr_valid_hndshk  <= 1'b0;
         wqe_sent_cnt  <= 4'h0;
         wqe_send <= TX_AXI_WQE_TXN_ST0;
       end
     endcase
  end
end



always @(posedge core_clk ) begin
  if (~core_aresetn) begin
    qp_mgr_m_axi_rdata <= 'b0;
    qp_mgr_m_axi_rlast <= 'b0;
    qp_mgr_m_axi_rvalid <= 'b0;
    qp_mgr_m_axi_arready <= 'b0;
    mem_loc_cnt_rd_resp <= 'b0;   
    axi_gen_st_rd_resp <= RX_DONE;
  end
  else begin
    case(axi_gen_st_rd_resp)
      RX_DONE: begin
        if(conf_of_reg_done == 1'b1 && RDMA_SND_TST_DONE == 1'b1) begin
           axi_gen_st_rd_resp <= ADDR_SEND;
        end
      end
      ADDR_SEND: begin
        if (qp_mgr_m_axi_arvalid) begin
          qp_mgr_m_axi_arready <= 1'b1;
          axi_gen_st_rd_resp <= DATA_RESP;
        end
      end
      DATA_RESP: begin
        qp_mgr_m_axi_arready <= 1'b0;
        if (qp_mgr_m_axi_rready) begin
           qp_mgr_m_axi_rvalid <= 1'b1;
           if(EN_RDMA_RD_PKT)
             qp_mgr_m_axi_rdata <= rdma_rdwr_wqe[(mem_loc_cnt_rd_resp+1)*512-1 -: 512];
           else
             qp_mgr_m_axi_rdata <= rdma_rdwr_wqe[(mem_loc_cnt_rd_resp+9)*512-1 -: 512];
           qp_mgr_m_axi_rlast <= 1'b1;
           axi_gen_st_rd_resp <= TRANSFER_DONE;
        end
      end
      TRANSFER_DONE: begin
        qp_mgr_m_axi_rvalid <= 1'b0;
        qp_mgr_m_axi_rlast <= 1'b0;
        qp_mgr_m_axi_rdata <= 'b0;
        mem_loc_cnt_rd_resp <= mem_loc_cnt_rd_resp + 1'b1; 
        axi_gen_st_rd_resp  <= ADDR_SEND;
      end
      default: begin
        qp_mgr_m_axi_rdata <= 'b0;
        qp_mgr_m_axi_arready <= 'b0;
        qp_mgr_m_axi_rvalid <= 'b0;
        qp_mgr_m_axi_rlast <= 'b0;
        mem_loc_cnt_rd_resp <= 'b0;
        axi_gen_st_rd_resp <= ADDR_SEND;
      end
    endcase
  end
end
localparam RDMA_WRITE=8'h00;
reg [7:0] mem_loc_cnt_data;
reg [7:0] data_transfer_len;
reg [3:0] wqe_data_send;
localparam TX_AXI_DATA_TXN_ST0 = 4'h0;
localparam TX_AXI_DATA_TXN_ST1 = 4'h1;
localparam TX_AXI_DATA_TXN_ST2 = 4'h2;
localparam TX_AXI_DATA_TXN_ST3 = 4'h3;

// NVME_read

always @(posedge core_clk ) begin
   if(~core_aresetn) begin
     mem_loc_cnt_data <= 'b0;
     wqe_proc_top_m_axi_rdata <= 'b0;
     wqe_proc_top_m_axi_rlast <= 'b0;
     wqe_proc_top_m_axi_rvalid <= 'b0;
     wqe_proc_top_m_axi_arready <= 1'b0;
     data_transfer_len <= 'b0;
     wqe_data_send <=TX_AXI_DATA_TXN_ST0;
    end 
    else begin
      case(wqe_data_send)
        TX_AXI_DATA_TXN_ST0: begin
          if(wqe_proc_top_m_axi_arvalid == 1'b1 && conf_of_reg_done == 1'b1) begin
            wqe_proc_top_m_axi_arready <= 1'b1;
            data_transfer_len <= wqe_proc_top_m_axi_arlen;
            wqe_data_send <=TX_AXI_DATA_TXN_ST1;
          end
          else  begin
            wqe_proc_top_m_axi_arready <= 1'b0;
            wqe_data_send <=TX_AXI_DATA_TXN_ST0;
          end
        end
        TX_AXI_DATA_TXN_ST1: begin
          wqe_proc_top_m_axi_arready <= 1'b0;
          if(wqe_proc_top_m_axi_rready) begin
            if(mem_loc_cnt_data == data_transfer_len) begin
              wqe_proc_top_m_axi_rlast <= 1'b1;
              wqe_data_send <= TX_AXI_DATA_TXN_ST2;
            end
            else begin
              wqe_proc_top_m_axi_rlast <= 1'b0;
            end
            wqe_proc_top_m_axi_rdata<= {64*8{1'b1}};
            mem_loc_cnt_data <= mem_loc_cnt_data + 1'b1;
            wqe_proc_top_m_axi_rvalid <= 1'b1;
          end
        end
        TX_AXI_DATA_TXN_ST2: begin
          wqe_proc_top_m_axi_rlast <= 'b0; 
          wqe_proc_top_m_axi_rvalid <= 'b0;
          wqe_data_send <= TX_AXI_DATA_TXN_ST0;
          wqe_proc_top_m_axi_rdata <= 'b0;
          mem_loc_cnt_data <= 'b0;
        end
        default: begin
          mem_loc_cnt_data <= 'b0;
          wqe_proc_top_m_axi_rdata <= 'b0;
          wqe_proc_top_m_axi_rlast <= 'b0;
          wqe_proc_top_m_axi_rvalid <= 'b0;
          wqe_data_send <=TX_AXI_DATA_TXN_ST1 ;  
        end
      endcase
   end
end

endmodule
