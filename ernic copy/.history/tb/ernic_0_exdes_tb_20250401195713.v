

`timescale 1ns/1ns

module xrnic_exdes_tb(
);

wire [15:0] num_send_pkt_rcvd;
wire [15:0] num_rd_resp_pkt_rcvd;
wire [15:0] num_rdma_rd_wr_wqe;
wire [15:0] num_ack_rcvd;
wire        final_reg_read_done;
`include "XRNIC_Reg_Config.vh"

reg aclk = 0;
reg aresetn;
reg cmac_rx_clk = 0;
reg cmac_tx_clk = 0;
reg cmac_rst;
always
  #10 aclk <= ~aclk;
initial begin
aresetn <= 1'b1;
#20;
aresetn <= 1'b0;
#400;
aresetn <= 1'b1;
end


initial begin
cmac_rst <= 1'b0;
#20;
cmac_rst <= 1'b1;
#400;
cmac_rst <= 1'b0;
end

always
  #10 cmac_rx_clk <= ~cmac_rx_clk;
  
always
  #10 cmac_tx_clk <= ~cmac_tx_clk;
exdes_top exdes_top_inst 
(
.aclk(aclk),
.aresetn_1(aresetn),
.cmac_rx_clk(cmac_rx_clk),
.cmac_tx_clk(cmac_tx_clk),
.cmac_rst(cmac_rst),
.num_send_pkt_rcvd      (num_send_pkt_rcvd),
.num_rd_resp_pkt_rcvd   (num_rd_resp_pkt_rcvd),
.num_rdma_rd_wr_wqe     (num_rdma_rd_wr_wqe),
.num_ack_rcvd           (num_ack_rcvd),
.final_reg_read_done    (final_reg_read_done)
);



//always @(num_ack_rcvd or num_rd_resp_pkt_rcvd or num_rdma_rd_wr_wqe or num_ack_rcvd or num_send_pkt_rcvd) begin
always @(final_reg_read_done) begin   //它表示每当 final_reg_read_done 这个信号的值变化时（即从 0 变为 1，或从 1 变为 0），后面的代码块就会被执行。
  $display ("Number of Send Packets received == %d",num_send_pkt_rcvd);
  $display ("Number of RDMA Read Response Packets received == %d",num_rd_resp_pkt_rcvd);
  $display ("Number of RDMA READ/WRITE Packets transmitted== %d",num_rdma_rd_wr_wqe);
  $display ("Number of ACK Packets received== %d",num_ack_rcvd);

  if(final_reg_read_done == 1'b1) begin
    if(EN_SEND_PKT == 1) begin
      if(EN_RDMA_WR_PKT == 1) begin
        if(EN_RDMA_RD_PKT == 1) begin
          if(num_send_pkt_rcvd == 8'h10 && num_rd_resp_pkt_rcvd == 8'h08 && num_rdma_rd_wr_wqe == 16'h0010 && num_ack_rcvd == 8'h08) begin
            $display (" Test Completed Successfully");
            $finish;
          end
          else begin 
            $display ("ERROR:Test Failed");
            $finish;
          end
        end
        else begin
          if(num_send_pkt_rcvd == 8'h10 && num_rdma_rd_wr_wqe == 16'h0008 && num_ack_rcvd == 8'h08) begin
            $display (" Test Completed Successfully");
            $finish;
          end
          else begin 
            $display ("ERROR:Test Failed");
            $finish;
          end
        end
      end
      else begin
        if(EN_RDMA_RD_PKT == 1) begin
          if(num_send_pkt_rcvd == 8'h10 && num_rd_resp_pkt_rcvd == 8'h08 && num_rdma_rd_wr_wqe == 16'h0008) begin
            $display (" Test Completed Successfully");
            $finish;
          end
          else begin 
            $display ("ERROR:Test Failed");
            $finish;
          end
        end
        else begin
          if(num_send_pkt_rcvd == 8'h10) begin
            $display (" Test Completed Successfully");
            $finish;
          end
          else begin 
            $display ("ERROR:Test Failed");
            $finish;
          end
        end
      end
    end 
    else begin
      if(EN_RDMA_WR_PKT == 1) begin
        if(EN_RDMA_RD_PKT == 1) begin
          if(num_rd_resp_pkt_rcvd == 8'h08 && num_rdma_rd_wr_wqe == 16'h0010 && num_ack_rcvd == 8'h08) begin
            $display (" Test Completed Successfully");
            $finish;
          end
          else begin 
            $display ("ERROR:Test Failed");
            $finish;
          end
        end
        else begin
          if(num_rdma_rd_wr_wqe == 16'h0008 && num_ack_rcvd == 8'h08) begin
            $display (" Test Completed Successfully");
            $finish;
          end
          else begin 
            $display ("ERROR:Test Failed");
            $finish;
          end
        end
      end
      else begin
        if(EN_RDMA_RD_PKT == 1) begin
          if(num_rd_resp_pkt_rcvd == 8'h08 && num_rdma_rd_wr_wqe == 16'h0008) begin
            $display (" Test Completed Successfully");
            $finish;
          end
          else begin 
            $display ("ERROR:Test Failed");
            $finish;
          end
        end
        else begin
            $display("ERROR:Set atleast one parameter from EN_RDMA_RD_PKT, EN_RDMA_WR_PKT, EN_SEND_PKT");
        end
      end
    end
  end
end

initial
begin
  #1000000;
        $display("ERROR:Test did not complete (timed-out)");
        $finish;
end  

endmodule
