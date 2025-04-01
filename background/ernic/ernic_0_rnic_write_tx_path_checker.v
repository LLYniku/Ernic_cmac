



`timescale 1ns/1ns
module rnic_exdes_write_tx_checker
# (
   parameter C_AXIS_DATA_WIDTH = 512
)
(
  input wire                  core_clk,
  input wire                  core_aresetn,
  input wire [511:0]          wqe_proc_top_m_axis_tdata,
  input wire [63:0]           wqe_proc_top_m_axis_tkeep,
  input wire                  wqe_proc_top_m_axis_tvalid,
  input wire                  wqe_proc_top_m_axis_tlast,
  output reg [4:0]            rdma_write_payload_chk_pass_cnt,
  output reg [3:0]            rd_rsp_data_payload_chk_cnt,
  input wire [23:0]            write_pkt_psn,
  output reg [4:0]            rdma_write_chk_pass_cnt,
  output reg [3:0]            rdma_rdrsp_chk_pass_cnt,
  output reg [3:0]            rdrsp_data_chk_pass_cnt,
  
  input wire                  rdma_write_test_done_i,
  input wire                  rx_pkt_hndler_s_axis_tvalid
);
`include "XRNIC_Reg_Config.vh"
localparam ACK_OPCODE = 8'h11;
localparam [7:0] RESP_FIRST = 8'h0d;
localparam RESP_MIDDLE = 8'h0e;
localparam RESP_LAST = 8'h0f;
localparam RESP_ONLY = 8'h10;
reg  rdma_write_chk_pass;
reg  rdma_write_chk_fail;
reg ack_opcode_chk;
reg ack_psn_chk;
wire [23:0] write_pkt_psn_fifo;
reg [1:0] state;
reg wqe_proc_top_m_axis_tvalid_d;
reg wqe_proc_top_m_axis_tvalid_d1;
reg rx_pkt_hndler_s_axis_tvalid_d;

localparam CHECK = 2'h00;
localparam COUNT = 2'h01;
always @(posedge core_clk) begin
    if(~core_aresetn) begin
       wqe_proc_top_m_axis_tvalid_d <= 1'b0;
       wqe_proc_top_m_axis_tvalid_d1 <= 1'b0;
    end else begin 
       wqe_proc_top_m_axis_tvalid_d <= wqe_proc_top_m_axis_tvalid;
       wqe_proc_top_m_axis_tvalid_d1 <= wqe_proc_top_m_axis_tvalid_d;
  end
end  
always @(posedge core_clk) begin
    if(~core_aresetn) begin
       rx_pkt_hndler_s_axis_tvalid_d <= 1'b0;
    end else 
       rx_pkt_hndler_s_axis_tvalid_d <= rx_pkt_hndler_s_axis_tvalid;
end  
always @(posedge core_clk) begin
    if(~core_aresetn) begin
      ack_opcode_chk <= 'b0;
      ack_psn_chk <= 'b0;
      rdma_write_chk_pass <= 'b0;
      rdma_write_chk_pass_cnt <= 'b0;
      rdma_write_chk_fail <= 'b0;
      state <= CHECK;
   end else begin
            case(state) 
            CHECK: begin
            if(rdma_write_test_done_i == 1'b0) begin
            if(wqe_proc_top_m_axis_tvalid && ~wqe_proc_top_m_axis_tvalid_d) begin
              if ( wqe_proc_top_m_axis_tdata [431 -: 24] == write_pkt_psn_fifo) begin
                  ack_psn_chk <= 1'b1;
              end
              if (wqe_proc_top_m_axis_tdata [343:336] == ACK_OPCODE) begin
                  ack_opcode_chk <= 1'b1;
              end
            end
            if(ack_psn_chk &&  ack_opcode_chk && (wqe_proc_top_m_axis_tvalid_d && ~wqe_proc_top_m_axis_tvalid_d1)) begin
               rdma_write_chk_pass <= 1'b1;
               rdma_write_chk_pass_cnt <= rdma_write_chk_pass_cnt + 1'b1;
               ack_psn_chk <= 1'b0;
               ack_opcode_chk <= 1'b0;
               rdma_write_chk_fail <= 1'b0;
               state <= CHECK;
            end else if ((wqe_proc_top_m_axis_tvalid_d && ~wqe_proc_top_m_axis_tvalid_d1) && !(ack_psn_chk &&  ack_opcode_chk)) begin
               rdma_write_chk_fail <= 1'b1;
               rdma_write_chk_pass <= 1'b0;
            end else begin
               rdma_write_chk_fail <= 1'b0;
               rdma_write_chk_pass <= 1'b0;
	    end
           end
           end
           default: begin
                 ack_opcode_chk <= 'b0;
                 ack_psn_chk <= 'b0;
                 rdma_write_chk_pass <= 'b0;
                 rdma_write_chk_pass_cnt <= 'b0;
                 rdma_write_chk_fail <= 'b0;
                 state <= CHECK;
                 end
endcase  
end
end
//XPM_FIFO

  xpm_fifo_sync #(
      .DOUT_RESET_VALUE("0"),    // String
      .ECC_MODE("no_ecc"),       // String
      .FIFO_MEMORY_TYPE("auto"), // String
      .FIFO_READ_LATENCY(0),     // DECIMAL
      .FIFO_WRITE_DEPTH(16),   // DECIMAL
      .FULL_RESET_VALUE(0),      // DECIMAL
      .PROG_EMPTY_THRESH(5),    // DECIMAL
      .PROG_FULL_THRESH(7),     // DECIMAL
      .RD_DATA_COUNT_WIDTH(1),   // DECIMAL
      .READ_DATA_WIDTH(24),      // DECIMAL
      .READ_MODE("fwft"),         // String
      .USE_ADV_FEATURES("0000"), // String
      .WAKEUP_TIME(0),           // DECIMAL
      .WRITE_DATA_WIDTH(24),     // DECIMAL
      .WR_DATA_COUNT_WIDTH(1)    // DECIMAL
   )
   ack_psn_chk_inst (
      .almost_empty(),
      .almost_full(),
      .data_valid(),
      .dbiterr(),
      .dout(write_pkt_psn_fifo),
      .empty(),
      .full(),
      .overflow(),
      .prog_empty(),
      .prog_full(),
      .rd_data_count(),
      .rd_rst_busy(),
      .sbiterr(),
      .underflow(),
      .wr_ack(),
      .wr_data_count(),
      .wr_rst_busy(),
      .din(write_pkt_psn),
      .injectdbiterr(),
      .injectsbiterr(),
      .rd_en(wqe_proc_top_m_axis_tvalid),
      .rst(~core_aresetn),
      .sleep(),
      .wr_clk(core_clk),
      .wr_en(rx_pkt_hndler_s_axis_tvalid && ~rx_pkt_hndler_s_axis_tvalid_d)
   );

reg [2:0] state1;
wire rdrsp_pkt_psn_chk;
reg  rdrsp_pkt_psn_chk_d;
wire rdrsp_opcode_chk;
reg  rdrsp_opcode_chk_d;
reg rdma_rdrsp_chk_pass;
reg rdma_rdrsp_chk_fail;
reg rdrsp_data_chk;
reg [7:0] rdrsp_data_chk_cnt;
reg cycle;
reg first_pktofqp;
localparam HDR=3'h0;
localparam RDRSP_DATA_CHK=3'h1;


always @(posedge core_clk) begin
  if (~core_aresetn) begin
    rdrsp_pkt_psn_chk_d  <= 1'b0;  
    rdrsp_opcode_chk_d   <= 1'b0;
  end else begin
    rdrsp_pkt_psn_chk_d  <= rdrsp_pkt_psn_chk;
    rdrsp_opcode_chk_d   <= rdrsp_opcode_chk;
  end
end

assign rdrsp_pkt_psn_chk = (wqe_proc_top_m_axis_tdata [431 -: 24] == write_pkt_psn_fifo) ? 1'b1 : (wqe_proc_top_m_axis_tlast && wqe_proc_top_m_axis_tvalid) ? 1'b0 : rdrsp_pkt_psn_chk_d;
assign rdrsp_opcode_chk =  ((wqe_proc_top_m_axis_tdata[343:336] == RESP_FIRST) || (wqe_proc_top_m_axis_tdata[343:336] == RESP_MIDDLE) || (wqe_proc_top_m_axis_tdata[343:336] == RESP_LAST) || (wqe_proc_top_m_axis_tdata[343:336] == RESP_ONLY)) ? 1'b1 : (wqe_proc_top_m_axis_tlast && wqe_proc_top_m_axis_tvalid) ? 1'b0 : rdrsp_opcode_chk_d;
//RDMA READ RESPONSE CHECK
always @(posedge core_clk or negedge core_aresetn) begin
    if(~core_aresetn) begin
      rdma_rdrsp_chk_pass <= 'b0;
      rdma_rdrsp_chk_pass_cnt <= 'b0;
      rdma_rdrsp_chk_fail <= 'b0;
      rdrsp_data_chk <= 'b0;
      rdrsp_data_chk_pass_cnt <= 'b0;
      rdrsp_data_chk_cnt <= 'b0;
      cycle <= 'b0; 
      first_pktofqp <= 'b0;
      state1 <= HDR;
   end else begin
            case(state1) 
            HDR: begin
                  if(EN_INITIATOR_RD && EN_INITIATOR_WR) begin
                  if(rdma_write_test_done_i) begin
                     if((wqe_proc_top_m_axis_tvalid == 1'b1) && (cycle == 1'b0) && (wqe_proc_top_m_axis_tlast == 1'b0)) begin
                       if(rdrsp_pkt_psn_chk &&  rdrsp_opcode_chk) begin
                                      rdma_rdrsp_chk_pass <= 1'b1;
                                      rdma_rdrsp_chk_pass_cnt <= rdma_rdrsp_chk_pass_cnt + 1'b1;
                                      cycle <= 1'b1;
                                      state1 <= RDRSP_DATA_CHK;
                       end else begin
                                      rdma_rdrsp_chk_fail <= 1'b1;
                                      end
                        end
                 end
                 end else begin
                          if(EN_INITIATOR_RD && ~EN_INITIATOR_WR) begin
                             if((wqe_proc_top_m_axis_tvalid == 1'b1) && (cycle == 1'b0) && (wqe_proc_top_m_axis_tlast == 1'b0)) begin
                                                 if(rdrsp_pkt_psn_chk &&  rdrsp_opcode_chk) begin
                                                                rdma_rdrsp_chk_pass <= 1'b1;
                                                                rdma_rdrsp_chk_pass_cnt <= rdma_rdrsp_chk_pass_cnt + 1'b1;
                                                                cycle <= 1'b1;
                                                                state1 <= RDRSP_DATA_CHK;
                                                 end else begin
                                                                rdma_rdrsp_chk_fail <= 1'b1;
                                                          end
                              end
                           end
                          end
                 end
             RDRSP_DATA_CHK: begin
                             if((wqe_proc_top_m_axis_tvalid == 1'b1) && (cycle == 1'b1) && (wqe_proc_top_m_axis_tlast == 1'b0)) begin
                                if(wqe_proc_top_m_axis_tdata == {512{1'b1}}) begin
                                  rdrsp_data_chk <= 1'b1;
                                  rdrsp_data_chk_cnt <= rdrsp_data_chk_cnt + 1'b1;
                                end
                             end
                             if ((wqe_proc_top_m_axis_tvalid == 1'b1) && (cycle == 1'b1) && (wqe_proc_top_m_axis_tlast == 1'b1)) begin
                                state1 <= HDR;
                                cycle <= 1'b0;
                                rdrsp_data_chk_cnt <= 'b0;
                                rdrsp_data_chk_pass_cnt <= rdrsp_data_chk_pass_cnt + 1'b1;
                             end else
                                state1 <= RDRSP_DATA_CHK;
                            end
             default: begin
                  rdma_rdrsp_chk_pass <= 'b0;
                  rdma_rdrsp_chk_pass_cnt <= 'b0;
                  rdrsp_data_chk_cnt <= 'b0;
                  rdma_rdrsp_chk_fail <= 'b0;
                  rdrsp_data_chk <= 1'b0;
                  rdrsp_data_chk_pass_cnt <= 'b0;
                  cycle <= 'b0;
                  state1 <= HDR;
                      end
             endcase
            end
            end    
endmodule


