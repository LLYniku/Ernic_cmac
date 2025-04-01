`timescale 1ns/1ns
module rnic_exdes_tx_checker
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
  output reg [3:0]            rd_rsp_data_payload_chk_cnt
);

reg [511:0] swapped_data;
reg [511:0] reverse_data;
//memory for checking
reg [31:0] mem_loc_cnt_swap;
wire [511:0] doutb;
reg[31:0] addr_in;
reg[31:0] addr_out;
reg[2:0] read_mem;
reg[7:0] cnt_data_in;
reg[7:0] cnt_data_out;
reg enb;
reg enb_d;
reg enb_2d;
reg wqe_proc_top_m_axis_tlast_d;
localparam ENABLE = 3'b001;
localparam READ = 3'b010;
localparam [7:0] PROTOCOL = 8'h11; // 23*8 + 8
localparam [15:0] ETH_TYPE_IPv4 = 16'h0008; // 12*8 + 16
localparam [15:0] UDP_HDR_Type  = 16'hB712; // 36*8 + 16
localparam [15:0] UDP_SRC_PORT = 16'h48E3; // 34*8 + 16
localparam [15:0] CHECKSUM= 16'h0000;// 40*8 +16
localparam [7:0] RDMA_READ = 8'h00;

`include "XRNIC_Reg_Config.vh"

reg eth_chk;
reg udp_chk;
reg udp_src_port_chk;
reg udp_hdr_chk;
//reg chksum_chk;
reg virtual_addr_chk;
reg dma_len_chk;
reg r_key_0;
reg r_key_1;
reg rdma_write_payload_chk_pass;
reg rdma_write_payload_chk_fail;
reg tx_path_done;

xpm_memory_sdpram # (
  // Common module parameters
  .MEMORY_SIZE        (64*512),            //positive integer
  .MEMORY_PRIMITIVE   ("block"),          //string; "auto", "distributed", "block" or "ultra";
  .CLOCKING_MODE      ("common_clock"),  //string; "common_clock", "independent_clock" 
  .MEMORY_INIT_FILE   ("none"),          //string; "none" or "<filename>.mem" 
  .MEMORY_INIT_PARAM  (""    ),          //string;
  .USE_MEM_INIT       (1),               //integer; 0,1
  .WAKEUP_TIME        ("disable_sleep"), //string; "disable_sleep" or "use_sleep_pin" 
  .MESSAGE_CONTROL    (0),               //integer; 0,1
  .ECC_MODE           ("no_ecc"),        //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
  .AUTO_SLEEP_TIME    (0),               //Do not Change

  // Port A module parameters
  .WRITE_DATA_WIDTH_A (512),              //positive integer
  .BYTE_WRITE_WIDTH_A (512),              //integer; 8, 9, or WRITE_DATA_WIDTH_A value
  .ADDR_WIDTH_A       (32),               //positive integer

  // Port B module parameters
  .READ_DATA_WIDTH_B  (512),              //positive integer
  .ADDR_WIDTH_B       (32),               //positive integer
  .READ_RESET_VALUE_B ("0"),             //string
  .READ_LATENCY_B     (1),               //non-negative integer
  .WRITE_MODE_B       ("read_first")     //string; "write_first", "read_first", "no_change" 

) xpm_memory_sdpram_inst (

  // Common module ports
  .sleep          (1'b0),

  // Port A module ports
  .clka           (core_clk),
  .ena            (wqe_proc_top_m_axis_tvalid),
  .wea            (wqe_proc_top_m_axis_tvalid),
  .addra          (addr_in),
  .dina           (wqe_proc_top_m_axis_tdata),
  .injectsbiterra (1'b0),
  .injectdbiterra (1'b0),

  // Port B module ports
  .clkb           (core_clk),
  .rstb           (~core_aresetn),
  .enb            (enb),
  .regceb         (1'b0),
  .addrb          (addr_out),
  .doutb          (doutb),
  .sbiterrb       (),
  .dbiterrb       ()

);

always@(posedge core_clk) begin
   wqe_proc_top_m_axis_tlast_d <= wqe_proc_top_m_axis_tlast;
end

always@(posedge core_clk) begin
  if (!core_aresetn) begin
    addr_in  <= 'b0;
    cnt_data_in <= 'b0;
  end 
  else begin
    if(wqe_proc_top_m_axis_tlast)
      addr_in <= 'b0;
    else begin
      if(wqe_proc_top_m_axis_tvalid) begin
        addr_in <= addr_in + 1'b1;
        cnt_data_in <= cnt_data_in + 1'b1;
      end
    end
  end
end

reg rd_rsp_data_payload_chk;
function [64*8-1 : 0] hdr_byte_reorder;
  input [64*8-1 :0] in_hdr;
  integer i;
  for(i=0;i<64;i=i+1) begin
    hdr_byte_reorder[((64-i)*8)-1 -: 8] = in_hdr[((i+1)*8)-1 -: 8];
  end
endfunction

reg [256*8 -1 :0] rd_rsp_data_payload;
always@(posedge core_clk) begin
       if(~core_aresetn) begin
         addr_out <= 'b0;
         enb <= 'b0;
         enb_d <= 'b0;
         cnt_data_out <= 'b0;
         eth_chk <= 'b0;
         udp_chk <= 'b0;
         udp_src_port_chk <= 'b0;
         udp_hdr_chk <= 'b0;
         //chksum_chk <= 'b0;
         rd_rsp_data_payload_chk <= 'b0;
         virtual_addr_chk <= 'b0;
         r_key_0 <= 'b0;
         r_key_1 <= 'b0;
         dma_len_chk <= 'b0;
         mem_loc_cnt_swap <= 'b0;
         rd_rsp_data_payload <= 'b0;
         reverse_data <= 'b0;
         rdma_write_payload_chk_pass_cnt <= 'b0;
         rd_rsp_data_payload_chk_cnt <= 'b0;
         tx_path_done <= 'b0;
         rdma_write_payload_chk_pass <= 'b0;
         rdma_write_payload_chk_fail <= 'b0;
       end 
       else begin
           case (read_mem)
             ENABLE: begin
               if (wqe_proc_top_m_axis_tlast) begin
                 enb <= 1'b1;
                 read_mem <= READ;
                 rdma_write_payload_chk_pass <= 'b0;
               rd_rsp_data_payload <= 'b0;
               rd_rsp_data_payload_chk <= 'b0;
               rdma_write_payload_chk_fail <= 'b0;
               end
           end
            READ: begin
                           if(cnt_data_out <= cnt_data_in+2) begin
                              addr_out <= addr_out + 1'b1;
                              read_mem <= READ;
                              cnt_data_out <= cnt_data_out + 1'b1;
                              reverse_data <= hdr_byte_reorder({(rdma_rdwr_wqe[(mem_loc_cnt_swap+1)*512-1 -: 512])});
                              if (cnt_data_out == 'd1) begin
                                  if (doutb[12*8+:16] == ETH_TYPE_IPv4) begin
                                      eth_chk <= 1'b1;
                                     end 
                                  if(doutb[23*8+:8] == PROTOCOL) begin
                                     udp_chk <= 'b1;
                                     end
                                  if(doutb[34*8+:16] == UDP_SRC_PORT) begin
                                     udp_src_port_chk <= 'b1;
                                     end
                                  if(doutb[36*8+:16] == UDP_HDR_Type) begin
                                     udp_hdr_chk <= 'b1;
                                     end
                                  if(doutb[54*8+:64] == reverse_data[36*8+:64]) begin
                                     virtual_addr_chk <= 1'b1;   
                                  end
                                  if (doutb[62*8+:16] == reverse_data[32*8+:16]) begin
                                      r_key_0 <= 1'b1;
                                  end
                               end
                                if (cnt_data_out == 'd2) begin
          
                                  if (doutb[0+:16] == reverse_data[34*8+:16])begin
                                      r_key_1 <= 1'b1;
                                  end
                                  if (doutb[2*8+:32] == reverse_data[48*8+:32]) begin
                                      dma_len_chk <= 1'b1;
                                  end
                                  end
                                if (cnt_data_out == 'd2 && (reverse_data[383:376] == RDMA_READ)) begin
                                    rd_rsp_data_payload[463 : 0] <=  doutb[6*8+:464];
                                end
                                if(cnt_data_out == 'd3 && (reverse_data[383:376] == RDMA_READ)) begin
                                   rd_rsp_data_payload[975:464] <= doutb[511:0];
                                end 
                                if(cnt_data_out == 'd4 && (reverse_data[383:376] == RDMA_READ)) begin
                                   rd_rsp_data_payload[1487:976] <= doutb[511:0];
                                end 
                                if(cnt_data_out == 'd5 && (reverse_data[383:376] == RDMA_READ)) begin
                                   rd_rsp_data_payload[1999:1488] <= doutb[511:0];
                                end 
                                if(cnt_data_out == 'd6 && (reverse_data[383:376] == RDMA_READ)) begin
                                   rd_rsp_data_payload[2047:2000] <= doutb[47:0];
                                end 
                               if(cnt_data_out == 'd7 && (reverse_data[383:376] == RDMA_READ) & (rd_rsp_data_payload[256*8-1:0] =={2048{1'b1}})) begin
                                  rd_rsp_data_payload_chk <= 1'b1;
                                  rd_rsp_data_payload_chk_cnt <= rd_rsp_data_payload_chk_cnt + 1'b1;
                               end
                           end
                           else begin
                                 if (eth_chk && udp_chk && udp_src_port_chk && udp_hdr_chk && virtual_addr_chk && r_key_0 && r_key_1 && dma_len_chk) begin
                                   rdma_write_payload_chk_pass <= 1'b1;
                                   rdma_write_payload_chk_pass_cnt <= rdma_write_payload_chk_pass_cnt+1'b1;
                                end else 
                                   rdma_write_payload_chk_fail <= 1'b1;
                     
                                enb <= 1'b0;
                                addr_out <= 'b0;
                                read_mem <= ENABLE;
                                cnt_data_out <= 'b0;
                                eth_chk <= 'b0;
                                udp_chk <= 'b0;
                                udp_src_port_chk <= 'b0;
                                udp_hdr_chk <= 'b0;
                                virtual_addr_chk <= 'b0;
                                dma_len_chk <= 'b0;
                                tx_path_done <= 'b0;
                                r_key_0 <= 'b0;
                                r_key_1 <= 'b0;
                                mem_loc_cnt_swap <= mem_loc_cnt_swap + 1'b1;
                                end
                                end      
                    default:begin
                             enb <= 1'b0;
                             addr_out <= 'b0;
                             read_mem <= ENABLE;
                             cnt_data_out <= 'b0;
                             mem_loc_cnt_swap <= 'b0;
                             eth_chk <= 'b0;
                             udp_chk <= 'b0;
                             udp_src_port_chk <= 'b0;
                             udp_hdr_chk <= 'b0;
                             virtual_addr_chk <= 'b0;
                             dma_len_chk <= 'b0;
                             rdma_write_payload_chk_pass <= 'b0;
                            rd_rsp_data_payload_chk <= 'b0;
                             rdma_write_payload_chk_fail <= 'b0;
                            end
          
                      endcase
                     end
                end
endmodule
