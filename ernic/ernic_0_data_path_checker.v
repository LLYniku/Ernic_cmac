

`timescale 1ns/1ns
module exdes_data_path_checker #(
 parameter C_AXI_THREAD_ID_WIDTH =1,
 parameter C_AXI_ADDR_WIDTH = 32,
 parameter C_AXI_DATA_WIDTH = 512
) (
  // capsule I/F
  input core_clk,
  input core_aresetn,
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
  output reg [3:0]                           data_write_chk_cnt                 

);

reg[511:0] data_write_chk ;
always @(posedge core_clk or negedge core_aresetn) begin
    if(~core_aresetn) begin
       data_write_chk <= 'b0;
       data_write_chk_cnt <= 'b0;
     end else begin
              if ( capsule_ddr_m_axi_wvalid) begin
                 if(capsule_ddr_m_axi_wdata == {512{1'b1}}) begin
                    data_write_chk <= 1'b1;
                    data_write_chk_cnt <= data_write_chk_cnt + 1'b1;
                 end
              end
              end
    

end

endmodule
