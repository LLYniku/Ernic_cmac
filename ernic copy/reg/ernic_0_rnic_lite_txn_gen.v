
`timescale 1ns/1ns
module rnic_lite_txn_gen
#(
  parameter C_S_AXI_LITE_ADDR_WIDTH = 32,
  parameter C_S_AXI_LITE_DATA_WIDTH = 32,
  parameter C_READ_BCK_REG = 0
)
(
  input   wire                                s_axi_lite_aclk,
  input   wire                                s_axi_lite_arstn,

  output  reg   [C_S_AXI_LITE_ADDR_WIDTH-1:0] s_axi_lite_awaddr,
  input   wire                                s_axi_lite_awready,
  output  reg                                 s_axi_lite_awvalid,

  output  reg   [C_S_AXI_LITE_ADDR_WIDTH-1:0] s_axi_lite_araddr,
  input   wire                                s_axi_lite_arready,
  output  reg                                 s_axi_lite_arvalid,

  output  reg   [C_S_AXI_LITE_DATA_WIDTH-1:0] s_axi_lite_wdata,
  output  reg   [C_S_AXI_LITE_DATA_WIDTH/8 -1:0] s_axi_lite_wstrb,
  input   wire                                s_axi_lite_wready,
  output  reg                                 s_axi_lite_wvalid,

  input   wire  [C_S_AXI_LITE_DATA_WIDTH-1:0] s_axi_lite_rdata,
  input   wire  [1:0]                         s_axi_lite_rresp,
  output  reg                                 s_axi_lite_rready,
  input   wire                                s_axi_lite_rvalid,

  input   wire  [1:0]                         s_axi_lite_bresp,
  output  reg                                 s_axi_lite_bready,
  input   wire                                s_axi_lite_bvalid,

  input   wire                                i_gen_txns,
  input   wire [C_S_AXI_LITE_ADDR_WIDTH-1:0]  i_addr,
  input   wire [C_S_AXI_LITE_ADDR_WIDTH-1:0]  i_data,
  input   wire                                test_completed,
  output  reg                                 o_txns_done,
  output  reg  [15:0]                         num_send_pkt_rcvd, 
  output  reg  [15:0]                         num_rd_resp_pkt_rcvd,
  output  reg  [15:0]                         num_rdma_rd_wr_wqe,
  output  reg  [15:0]                         num_ack_rcvd,
  output  reg                                 final_reg_read_done
);

// Parameter declaration

parameter LITE_FSM_ST_1 = 4'h0;
parameter LITE_FSM_ST_2 = 4'h1;
parameter LITE_FSM_ST_3 = 4'h2;
parameter LITE_FSM_ST_4 = 4'h3;
parameter LITE_FSM_ST_5 = 4'h4;
parameter LITE_FSM_ST_6 = 4'h5;

// Internal signal declaration
reg [3:0] lite_fsm_ps;
reg       re_trigger_wr;
reg [1:0] reg_read_cnt;
// AXI_LITE transaction generate FSM

always @(posedge s_axi_lite_aclk ) begin
  if(~s_axi_lite_arstn) begin
    s_axi_lite_awaddr  <= 'b0;  
    s_axi_lite_awvalid <= 1'b0;
    s_axi_lite_araddr  <= 'b0;
    s_axi_lite_arvalid <= 1'b0;
    s_axi_lite_wdata   <= 'b0;
    s_axi_lite_wstrb   <= 'b0;
    s_axi_lite_wvalid  <= 1'b0;
    s_axi_lite_rready  <= 1'b0;
    s_axi_lite_bready  <= 1'b0;
    re_trigger_wr      <= 1'b0;
    o_txns_done        <= 1'b0;
    reg_read_cnt       <= 'b0;
    num_send_pkt_rcvd  <= 'b0;
    num_rd_resp_pkt_rcvd <= 'b0;
    num_rdma_rd_wr_wqe <= 'b0;
    num_ack_rcvd       <= 'b0;
    final_reg_read_done <= 1'b0;
    lite_fsm_ps        <= LITE_FSM_ST_1;
  end
  else begin
    case (lite_fsm_ps)
      LITE_FSM_ST_1 : begin
        // wait for the start signal
        if(test_completed && reg_read_cnt <= 2'b10) begin // If test is completed, Read the number of packets received by IP
          lite_fsm_ps         <= LITE_FSM_ST_4;
          s_axi_lite_awvalid  <= 1'b0;
        end 
        else begin
          if(i_gen_txns | re_trigger_wr) begin
            s_axi_lite_awaddr   <= i_addr;
            s_axi_lite_awvalid  <= 1'b1;
            lite_fsm_ps         <= LITE_FSM_ST_2;
          end
        end
          s_axi_lite_bready <= 1'b0;
          o_txns_done       <= 1'b0;
      end
      LITE_FSM_ST_2 : begin
        // wait for the start signal
        if(s_axi_lite_awready == 1'b1) begin
          s_axi_lite_awaddr   <= i_addr;
          s_axi_lite_awvalid  <= 1'b0;
        // Generate wvalid and wdata
          s_axi_lite_wdata    <= i_data;
          s_axi_lite_wstrb    <= {(C_S_AXI_LITE_DATA_WIDTH/8){1'b1}};
          s_axi_lite_wvalid   <= 1'b1;
          lite_fsm_ps         <= LITE_FSM_ST_3;
        end
        re_trigger_wr <= 1'b0;
      end
      LITE_FSM_ST_3 : begin
        // wait for the start signal
        if(s_axi_lite_wready)
          s_axi_lite_wvalid   <= 1'b0;
        // wait fot the response
        if(s_axi_lite_bvalid) begin
          s_axi_lite_bready <= 1'b1;
          if(s_axi_lite_bresp == 2'b00) begin
            re_trigger_wr  <= 1'b0;
            if(C_READ_BCK_REG == 1)
              lite_fsm_ps         <= LITE_FSM_ST_4;
            else begin 
              lite_fsm_ps         <= LITE_FSM_ST_1;
              o_txns_done    <= 1'b1;
            end
          end
          else begin
            o_txns_done         <= 1'b0;
            re_trigger_wr       <= 1'b1;
            lite_fsm_ps         <= LITE_FSM_ST_1;
          end
        end
        else
          lite_fsm_ps           <= LITE_FSM_ST_3;
      end
      LITE_FSM_ST_4 : begin
        if(test_completed) begin
          if(reg_read_cnt == 2'b00)
            s_axi_lite_araddr  <= 32'h50060100;
          else if(reg_read_cnt == 2'b01)
            s_axi_lite_araddr  <= 32'h50060108;
          else
            s_axi_lite_araddr  <= 32'h50060104;
        end
        else
          s_axi_lite_araddr  <= i_addr;
        s_axi_lite_arvalid <= 1'b1;
        if(s_axi_lite_arready)
          lite_fsm_ps           <= LITE_FSM_ST_5;
      end
      LITE_FSM_ST_5 : begin
        s_axi_lite_arvalid <= 1'b0;
        if(s_axi_lite_rvalid) begin
          s_axi_lite_rready <= 1'b1;
          lite_fsm_ps       <= LITE_FSM_ST_6;
        end
      end
      LITE_FSM_ST_6 : begin
        s_axi_lite_rready <= 1'b0;
        if(test_completed) begin
          if(reg_read_cnt == 2'b00) begin
            num_send_pkt_rcvd <= s_axi_lite_rdata[15 -: 16];
            num_rd_resp_pkt_rcvd <= s_axi_lite_rdata[31 -: 16];
          end
          else if(reg_read_cnt == 2'b01)
            num_rdma_rd_wr_wqe <= s_axi_lite_rdata[31 -: 16];
          else begin
            num_ack_rcvd       <= s_axi_lite_rdata[15 -: 16];
            final_reg_read_done  <= 1'b1;
          end
          reg_read_cnt <= reg_read_cnt + 1'b1;
        end
        else begin
          if(i_data == s_axi_lite_rdata) begin
            re_trigger_wr       <= 1'b0;
            o_txns_done         <= 1'b1;
          end
          else begin
            re_trigger_wr       <= 1'b1;
            o_txns_done         <= 1'b0;
          end
        end
        lite_fsm_ps       <= LITE_FSM_ST_1;
      end
      default : begin
        s_axi_lite_awaddr  <= 'b0;  
        s_axi_lite_awvalid <= 1'b0;
        s_axi_lite_araddr  <= 'b0;
        s_axi_lite_arvalid <= 1'b0;
        s_axi_lite_wdata   <= 'b0;
        s_axi_lite_wstrb   <= 'b0;
        s_axi_lite_wvalid  <= 1'b0;
        s_axi_lite_rready  <= 1'b0;
        s_axi_lite_bready  <= 1'b0;
        re_trigger_wr      <= 1'b0;
        lite_fsm_ps        <= LITE_FSM_ST_1;
      end
    endcase
  end
end

endmodule
