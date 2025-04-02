
`timescale 1 ns / 1 ns

module RDMA_pkt_filter
(
input          core_clk,
input          core_rst,
//input streaming signals from CMAC
input [511:0]  s_axis_tdata,
input [63:0]   s_axis_tkeep,
input          s_axis_tlast,
input [0:0]    s_axis_tuser,
input          s_axis_tvalid,
//input         s_axis_tready,

// DMA streaming interface
output reg [511:0] dma_m_axis_tdata,
output reg [63:0]  dma_m_axis_tkeep,
output reg        dma_m_axis_tlast,
output reg [0:0]   dma_m_axis_tuser,
output reg        dma_m_axis_tvalid,
// xrnic streaming interface
output reg [511:0] rx_pkt_hndler_m_axis_tdata,
output reg [63:0]  rx_pkt_hndler_m_axis_tkeep,
output reg        rx_pkt_hndler_m_axis_tlast,
output reg [0:0]   rx_pkt_hndler_m_axis_tuser,
output reg        rx_pkt_hndler_m_axis_tvalid
);

localparam [15:0] ETH_TYPE_IPv4 = 16'h0008;
localparam [15:0] ETH_TYPE_IPv6 = 16'hdd86; 
localparam [15:0] UDP_HDR_Type  = 16'hB712;
//reg pkt_send = 1'b0;
localparam IDLE = 2'h0;
localparam RX_PKT = 2'h1;
localparam DMA_PKT = 2'h2;
reg [1:0] current_state;

 always @(posedge core_clk) begin
      if(core_rst == 1'b0) begin
          current_state <= IDLE;
           rx_pkt_hndler_m_axis_tdata <= 0;
           rx_pkt_hndler_m_axis_tkeep <= 0;
           rx_pkt_hndler_m_axis_tlast <= 0;
           rx_pkt_hndler_m_axis_tuser <= 0;
           rx_pkt_hndler_m_axis_tvalid <= 0;
           dma_m_axis_tdata <= 0;
           dma_m_axis_tkeep <= 0;
           dma_m_axis_tlast <= 0;
           dma_m_axis_tuser <= 0;
           dma_m_axis_tvalid <= 0;


      end else begin
        case (current_state)
        IDLE: begin
            if(s_axis_tvalid) begin
               if((s_axis_tdata[12*8+:16] == ETH_TYPE_IPv4) && (s_axis_tdata[23*8+:8] == 8'h11) && (s_axis_tdata[36*8+:16] == UDP_HDR_Type)) begin
                  rx_pkt_hndler_m_axis_tdata <= s_axis_tdata;
                  rx_pkt_hndler_m_axis_tkeep <= s_axis_tkeep;
                  rx_pkt_hndler_m_axis_tlast <= s_axis_tlast;
                  rx_pkt_hndler_m_axis_tuser <= s_axis_tuser;
                  rx_pkt_hndler_m_axis_tvalid <= s_axis_tvalid;
                 if(s_axis_tlast)
                       current_state <= IDLE; 
                 else
                       current_state <= RX_PKT;
                  dma_m_axis_tdata <= 0;
                  dma_m_axis_tkeep <= 0;
                  dma_m_axis_tlast <= 0;
                  dma_m_axis_tuser <= 0;
                  dma_m_axis_tvalid <= 0;
               end else if((s_axis_tdata[12*8+:16] == ETH_TYPE_IPv6) && (s_axis_tdata[20*8+:8] == 8'h11) && (s_axis_tdata[56*8+:16] == UDP_HDR_Type)) begin
                  rx_pkt_hndler_m_axis_tdata <= s_axis_tdata;
                  rx_pkt_hndler_m_axis_tkeep <= s_axis_tkeep;
                  rx_pkt_hndler_m_axis_tlast <= s_axis_tlast;
                  rx_pkt_hndler_m_axis_tuser <= s_axis_tuser;
                  rx_pkt_hndler_m_axis_tvalid <= s_axis_tvalid;
                 if(s_axis_tlast)
                       current_state <= IDLE; 
                 else
                       current_state <= RX_PKT;
                  dma_m_axis_tdata <= 0;
                  dma_m_axis_tkeep <= 0;
                  dma_m_axis_tlast <= 0;
                  dma_m_axis_tuser <= 0;
                  dma_m_axis_tvalid <= 0;
               end else begin
                 dma_m_axis_tdata <= s_axis_tdata;
                 dma_m_axis_tkeep <= s_axis_tkeep;
                 dma_m_axis_tlast <= s_axis_tlast;
                 dma_m_axis_tuser <= s_axis_tuser;
                 dma_m_axis_tvalid <= s_axis_tvalid;
                 rx_pkt_hndler_m_axis_tdata <= 0;
                 rx_pkt_hndler_m_axis_tkeep <= 0;
                 rx_pkt_hndler_m_axis_tlast <= 0;
                 rx_pkt_hndler_m_axis_tuser <= 0;
                 rx_pkt_hndler_m_axis_tvalid <= 0;
                 if(s_axis_tlast)
                       current_state <= IDLE; 
                 else
                       current_state <= DMA_PKT;
               end
            end else begin
               current_state <= IDLE;
                 rx_pkt_hndler_m_axis_tdata <= 0;
                 rx_pkt_hndler_m_axis_tkeep <= 0;
                 rx_pkt_hndler_m_axis_tlast <= 0;
                 rx_pkt_hndler_m_axis_tuser <= 0;
                 rx_pkt_hndler_m_axis_tvalid <= 0;
                 dma_m_axis_tdata <= 0;
                 dma_m_axis_tkeep <= 0;
                 dma_m_axis_tlast <= 0;
                 dma_m_axis_tuser <= 0;
                 dma_m_axis_tvalid <= 0;

            end
        end
       RX_PKT: begin
        if((s_axis_tlast==1'b1) && (s_axis_tvalid == 1'b1))
              current_state <= IDLE; 
        else
              current_state <= RX_PKT;
       
                  rx_pkt_hndler_m_axis_tdata <= s_axis_tdata;
                  rx_pkt_hndler_m_axis_tkeep <= s_axis_tkeep;
                  rx_pkt_hndler_m_axis_tlast <= s_axis_tlast;
                  rx_pkt_hndler_m_axis_tuser <= s_axis_tuser;
                  rx_pkt_hndler_m_axis_tvalid <= s_axis_tvalid;
                  dma_m_axis_tdata <= 0;
                  dma_m_axis_tkeep <= 0;
                  dma_m_axis_tlast <= 0;
                  dma_m_axis_tuser <= 0;
                  dma_m_axis_tvalid <= 0;


       end
       DMA_PKT: begin
       if((s_axis_tlast==1'b1) && (s_axis_tvalid == 1'b1))
              current_state <= IDLE; 
        else
              current_state <= DMA_PKT;
                 dma_m_axis_tdata <= s_axis_tdata;
                 dma_m_axis_tkeep <= s_axis_tkeep;
                 dma_m_axis_tlast <= s_axis_tlast;
                 dma_m_axis_tuser <= s_axis_tuser;
                 dma_m_axis_tvalid <= s_axis_tvalid;
                 rx_pkt_hndler_m_axis_tdata <= 0;
                 rx_pkt_hndler_m_axis_tkeep <= 0;
                 rx_pkt_hndler_m_axis_tlast <= 0;
                 rx_pkt_hndler_m_axis_tuser <= 0;
                 rx_pkt_hndler_m_axis_tvalid <= 0;


       end
       default:begin
                 rx_pkt_hndler_m_axis_tdata <= 0;
                 rx_pkt_hndler_m_axis_tkeep <= 0;
                 rx_pkt_hndler_m_axis_tlast <= 0;
                 rx_pkt_hndler_m_axis_tuser <= 0;
                 rx_pkt_hndler_m_axis_tvalid <= 0;
                 dma_m_axis_tdata <= 0;
                 dma_m_axis_tkeep <= 0;
                 dma_m_axis_tlast <= 0;
                 dma_m_axis_tuser <= 0;
                 dma_m_axis_tvalid <= 0;
                 current_state <= IDLE; 

      end

    endcase
    end
  end




endmodule


