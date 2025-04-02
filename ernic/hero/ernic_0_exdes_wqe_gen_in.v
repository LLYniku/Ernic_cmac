
`timescale 1ns/1ns
module exdes_wqe_gen_in
# (
  parameter C_AXIS_DATA_WIDTH = 512
  )
(
  input  wire                             core_clk,
  input  wire                             core_aresetn,
  input wire [7:0]                        wqe_proc_top_m_axi_arlen,
  input  wire                             wqe_proc_top_m_axi_arvalid,
  output reg                              wqe_proc_top_m_axi_arready,
  output reg    [511:0]                   wqe_proc_top_m_axi_rdata,                                         
  output reg                              wqe_proc_top_m_axi_rlast,                     
  output reg                              wqe_proc_top_m_axi_rvalid,  
  input wire                              wqe_proc_top_m_axi_rready
);

reg [2:0] data_gen;
reg [7:0] cnt;
localparam ST0=3'b000;
localparam ST1=3'b001;
reg [2:0] cnt_arvalid;
reg wqe_proc_top_m_axi_rlast_d;

always @(posedge core_clk ) begin
  if(~core_aresetn) begin
    wqe_proc_top_m_axi_rlast_d   <= 1'b0;
  end else begin
    wqe_proc_top_m_axi_rlast_d   <= wqe_proc_top_m_axi_rlast;
  end
end

always @(posedge core_clk ) begin
  if(~core_aresetn) begin
    cnt_arvalid    <= 'd0;
  end else if(wqe_proc_top_m_axi_arvalid && wqe_proc_top_m_axi_arready) begin
    cnt_arvalid    <= cnt_arvalid + 1'b1;
  end else if (wqe_proc_top_m_axi_rlast && ~wqe_proc_top_m_axi_rlast_d) begin
    cnt_arvalid    <= cnt_arvalid - 1'b1;
  end else begin
    cnt_arvalid    <= cnt_arvalid;
  end
end

always @(posedge core_clk) begin
    if(~core_aresetn) begin
         data_gen <= 'b0;
         cnt  <= 'b0;
         wqe_proc_top_m_axi_rvalid <= 1'b0;
         wqe_proc_top_m_axi_rlast <= 1'b0;
         wqe_proc_top_m_axi_rdata <= 'b0;
         wqe_proc_top_m_axi_arready <= 1'b0;
         data_gen <= ST0;

    end else begin
        case (data_gen)
             ST0: begin
                     wqe_proc_top_m_axi_rlast <= 1'b0;
                    
                    if(cnt_arvalid > 0) begin
                      //if(wqe_proc_top_m_axi_rready && cnt_arvalid > 0) begin
                         wqe_proc_top_m_axi_rdata <= {512{1'b1}};
                         wqe_proc_top_m_axi_rvalid <= 1'b1;                     
                         cnt <= cnt + 1'b1;
                         
                       //end
                         if (cnt == wqe_proc_top_m_axi_arlen) begin
                             data_gen <= ST1;
                            
                             wqe_proc_top_m_axi_rlast <= 1'b1;
                         end else
                             data_gen <= ST0;
                      //end //wqe_proc_top_m_axi_rready && cnt_arvalid > 0
                    end //cnt_arvalid > 0
                    if (wqe_proc_top_m_axi_arvalid) begin
                       wqe_proc_top_m_axi_arready <= 1'b1;
                     end // wqe_proc_top_m_axi_arvalid
                       else
                       wqe_proc_top_m_axi_arready <= 1'b0;
             end // ST0
             ST1: begin
                   wqe_proc_top_m_axi_rvalid <= 1'b0;
                   wqe_proc_top_m_axi_rdata <= 'b0;
                   cnt <= 'b0; 
                   data_gen <= ST0;
                  end
              default: begin
                   wqe_proc_top_m_axi_rvalid <= 1'b0;
                   wqe_proc_top_m_axi_rlast <= 1'b0;
                   wqe_proc_top_m_axi_rdata <= 'b0;
                   cnt <= 'b0;
                   data_gen <= ST0;
                  end
           endcase
        end
        end

endmodule
