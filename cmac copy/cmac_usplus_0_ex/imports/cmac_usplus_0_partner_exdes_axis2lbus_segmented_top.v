////------------------------------------------------------------------------------
////  (c) Copyright 2013 Xilinx, Inc. All rights reserved.
////
////  This file contains confidential and proprietary information
////  of Xilinx, Inc. and is protected under U.S. and
////  international copyright and other intellectual property
////  laws.
////
////  DISCLAIMER
////  This disclaimer is not a license and does not grant any
////  rights to the materials distributed herewith. Except as
////  otherwise provided in a valid license issued to you by
////  Xilinx, and to the maximum extent permitted by applicable
////  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
////  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
////  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
////  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
////  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
////  (2) Xilinx shall not be liable (whether in contract or tort,
////  including negligence, or under any other theory of
////  liability) for any loss or damage of any kind or nature
////  related to, arising under or in connection with these
////  materials, including for any direct, or any indirect,
////  special, incidental, or consequential loss or damage
////  (including loss of data, profits, goodwill, or any type of
////  loss or damage suffered as a result of any action brought
////  by a third party) even if such damage or loss was
////  reasonably foreseeable or Xilinx had been advised of the
////  possibility of the same.
////
////  CRITICAL APPLICATIONS
////  Xilinx products are not designed or intended to be fail-
////  safe, or for use in any application requiring fail-safe
////  performance, such as life-support or safety devices or
////  systems, Class III medical devices, nuclear facilities,
////  applications related to the deployment of airbags, or any
////  other applications that could lead to death, personal
////  injury, or severe property or environmental damage
////  (individually and collectively, "Critical
////  Applications"). Customer assumes the sole risk and
////  liability of any use of Xilinx products in Critical
////  Applications, subject only to applicable laws and
////  regulations governing limitations on product liability.
////
////  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
////  PART OF THIS FILE AT ALL TIMES.
////------------------------------------------------------------------------------

`timescale 1ps/1ps

(* DowngradeIPIdentifiedWarnings="yes" *)


module cmac_usplus_0_partner_exdes_axis2lbus_segmented_top #(
   parameter DATA_WIDTH = 512
)
(
  input  wire                                    core_clk,
  input  wire                                    core_rst,

  // AXIS IF
  output wire                                    axis_tready,
  input  wire                                    axis_tvalid,
  input  wire [DATA_WIDTH-1:0]                   axis_tdata,
  input  wire                                    axis_tlast,
  input  wire [DATA_WIDTH/8 - 1:0]               axis_tkeep,
  input  wire                                    axis_tuser,

  // LBUS IF
  input   wire                                   lbus_rdyout,
  input   wire                                   lbus_ovfout,
  input   wire                                   lbus_unfout,
  // Segment 0
  output  wire                                   lbus_ena0,
  output  wire [DATA_WIDTH/4 - 1:0]              lbus_data0,
  output  wire                                   lbus_sop0,
  output  wire                                   lbus_eop0,
  output  wire [$clog2(DATA_WIDTH/32) - 1:0]     lbus_mty0,
  output  wire                                   lbus_err0,
  // Segment 1
  output  wire                                   lbus_ena1,
  output  wire [DATA_WIDTH/4 - 1:0]              lbus_data1,
  output  wire                                   lbus_sop1,
  output  wire                                   lbus_eop1,
  output  wire [$clog2(DATA_WIDTH/32) - 1:0]     lbus_mty1,
  output  wire                                   lbus_err1,
  // Segment 2
  output  wire                                   lbus_ena2,
  output  wire [DATA_WIDTH/4 - 1:0]              lbus_data2,
  output  wire                                   lbus_sop2,
  output  wire                                   lbus_eop2,
  output  wire [$clog2(DATA_WIDTH/32) - 1:0]     lbus_mty2,
  output  wire                                   lbus_err2,
  // Segment 3
  output  wire                                   lbus_ena3,
  output  wire [DATA_WIDTH/4 - 1:0]              lbus_data3,
  output  wire                                   lbus_sop3,
  output  wire                                   lbus_eop3,
  output  wire [$clog2(DATA_WIDTH/32) - 1:0]     lbus_mty3,
  output  wire                                   lbus_err3
);

   localparam SEG_DATA_WIDTH = DATA_WIDTH/4;
   localparam SEG_MTY_WIDTH = $clog2(DATA_WIDTH/32);

   wire    [3:0]     seg_valid;


   wire       [3:0]                       lbus_ena;
   wire [DATA_WIDTH - 1:0]                lbus_data;
   wire       [3:0]                       lbus_sop;
   wire       [3:0]                       lbus_eop;
   wire [4*SEG_MTY_WIDTH - 1:0]   lbus_mty;
   wire       [3:0]                       lbus_err;


   exdes_axis2lbus_segmented_corelogic #(.DATA_WIDTH(DATA_WIDTH))
      core            (            
                  .core_clk(core_clk       ),     
                  .core_rst(core_rst       ),
                  .axis_tready(axis_tready    ),
                  .axis_tvalid(axis_tvalid    ),
                  .axis_tdata(axis_tdata     ),
                  .axis_tlast(axis_tlast     ),
                  .axis_tkeep(axis_tkeep     ),
                  .axis_tuser(axis_tuser     ),
                  .lbus_rdyout(lbus_rdyout    ),
                  .lbus_ovfout(lbus_ovfout    ),
                  .lbus_unfout(lbus_unfout    ),
                  .lbus_ena(lbus_ena       ),
                  .lbus_data(lbus_data      ),
                  .lbus_sop(lbus_sop       ),
                  .lbus_eop(lbus_eop       ),
                  .lbus_mty(lbus_mty       ),
                  .lbus_err(lbus_err       )
                      );


    assign    {lbus_ena0,lbus_err0,lbus_eop0,lbus_sop0,lbus_mty0,lbus_data0}      =  {lbus_ena[0],lbus_err[0],lbus_eop[0],lbus_sop[0],lbus_mty[0*SEG_MTY_WIDTH +: SEG_MTY_WIDTH],lbus_data[0*SEG_DATA_WIDTH +: SEG_DATA_WIDTH]};
    assign    {lbus_ena1,lbus_err1,lbus_eop1,lbus_sop1,lbus_mty1,lbus_data1}      =  {lbus_ena[1],lbus_err[1],lbus_eop[1],lbus_sop[1],lbus_mty[1*SEG_MTY_WIDTH +: SEG_MTY_WIDTH],lbus_data[1*SEG_DATA_WIDTH +: SEG_DATA_WIDTH]};
    assign    {lbus_ena2,lbus_err2,lbus_eop2,lbus_sop2,lbus_mty2,lbus_data2}      =  {lbus_ena[2],lbus_err[2],lbus_eop[2],lbus_sop[2],lbus_mty[2*SEG_MTY_WIDTH +: SEG_MTY_WIDTH],lbus_data[2*SEG_DATA_WIDTH +: SEG_DATA_WIDTH]};
    assign    {lbus_ena3,lbus_err3,lbus_eop3,lbus_sop3,lbus_mty3,lbus_data3}      =  {lbus_ena[3],lbus_err[3],lbus_eop[3],lbus_sop[3],lbus_mty[3*SEG_MTY_WIDTH +: SEG_MTY_WIDTH],lbus_data[3*SEG_DATA_WIDTH +: SEG_DATA_WIDTH]};

endmodule // exdes_axis2lbus_segmented_top


`timescale 1ps/1ps
(* DowngradeIPIdentifiedWarnings="yes" *)


module exdes_axis2lbus_segmented_corelogic #(
   parameter DATA_WIDTH = 512
)
(
  input  wire                                   core_clk,
  input  wire                                   core_rst,

  // AXIS IF
  output reg                                    axis_tready, 
  input  wire                                   axis_tvalid,
  input  wire [DATA_WIDTH-1:0]                  axis_tdata,
  input  wire                                   axis_tlast,
  input  wire [DATA_WIDTH/8 - 1:0]              axis_tkeep,
  input  wire                                   axis_tuser,

  // LBUS IF
  input   wire                                  lbus_rdyout,
  input   wire                                  lbus_ovfout,
  input   wire                                  lbus_unfout,

  output  reg    [3:0]                          lbus_ena,
  output  reg [DATA_WIDTH - 1:0]                lbus_data,
  output  reg    [3:0]                          lbus_sop,
  output  reg    [3:0]                          lbus_eop,
  output  reg [4*$clog2(DATA_WIDTH/32) - 1:0]      lbus_mty,
  output  reg    [3:0]                          lbus_err
);

  localparam SEG_DATA_WIDTH = DATA_WIDTH/4;
  localparam SEG_MTY_WIDTH = $clog2(DATA_WIDTH/32);

  wire    [$clog2(DATA_WIDTH/32) - 1:0]  lbus_mty_int[3:0];
  wire    [DATA_WIDTH/4 - 1:0]  lbus_data_int[3:0];
  wire    [3:0]         lbus_sop_int;

  wire              lbus_sopin_int;
  wire    [4:0]     seg_valid;
  wire    [3:0]     lbus_eopin_int;



   genvar i;
   genvar seg;
   generate begin //{
   for (seg=0; seg < 4; seg=seg+1) begin : SEG_LOOP //{
   always @(posedge core_clk)
   begin //{
         axis_tready <= lbus_rdyout;
     // Seg th segment 
         lbus_data[seg*SEG_DATA_WIDTH +: SEG_DATA_WIDTH] <= lbus_data_int[seg];
         lbus_sop[seg] <= lbus_sop_int[seg];
         lbus_eop[seg] <= lbus_eopin_int[seg] & axis_tlast;
         lbus_ena[seg] <= seg_valid[seg] & axis_tvalid & axis_tready;
         lbus_mty[seg*SEG_MTY_WIDTH +: SEG_MTY_WIDTH] <= lbus_mty_int[seg];
         lbus_err[seg] <= seg_valid[seg] & axis_tuser;
   end //}
   end //}
   end //}
   endgenerate

   ////////////////////////////////////////////////////////////////////////////
   //             State Machine to derive sopin                              //
   ////////////////////////////////////////////////////////////////////////////
   localparam WAIT_FOR_SOP = 1'b0;
   localparam PKT = 1'b1;
   reg  state = WAIT_FOR_SOP, next_state;

 	// state reg
	always @(posedge core_clk) begin
		if(core_rst)
				state <= WAIT_FOR_SOP;
		else if(axis_tvalid & axis_tlast & axis_tready)   begin
				state <= WAIT_FOR_SOP;
				end
		else if(axis_tvalid & axis_tready)   begin
				state <= PKT;
				end
	end
   assign lbus_sopin_int = (state == WAIT_FOR_SOP) & axis_tvalid & axis_tready;
   assign lbus_sop_int = {3'b000,lbus_sopin_int};

   ////////////////////////////////////////////////////////////////////////////
   //                      LBUS
   //For a 512-bit wide bus, the first byte of the packet is written on bits //
   //  [511:504], the second byte on bits [503:496], and so forth            //
   ////////////////////////////////////////////////////////////////////////////
   generate //{
   for(seg = 0; seg < 4; seg=seg+1) begin : SEG_LOOP1 //{
   for(i = 0; i < DATA_WIDTH/32; i=i+1)
      begin : SEG_LOOP2 //{
         assign lbus_data_int[seg][i*8 +: 8] = axis_tdata[((seg+1)*(DATA_WIDTH/4)-8-(i*8)) +: 8];
      end//}
   assign   lbus_mty_int[seg] = tkeep_to_mty(axis_tkeep[seg*DATA_WIDTH/32 +: DATA_WIDTH/32]);

   assign seg_valid[seg] =  |axis_tkeep[seg*DATA_WIDTH/32 +: DATA_WIDTH/32]; 
   end//}
   endgenerate //}

   assign seg_valid[4] = 1'b0;
   generate //{
   for(seg = 0; seg < 4; seg=seg+1) begin : LOOP3 //{
      assign lbus_eopin_int[seg] = seg_valid[seg] ^ seg_valid[seg+1]; 
   end//}
   endgenerate //}


   ////////////////////////////////////////////////////////////////////////////
   //             Function: tkeep_to_mty                                     //
   ////////////////////////////////////////////////////////////////////////////
   function [$clog2(DATA_WIDTH/32) - 1:0] tkeep_to_mty(input [DATA_WIDTH/32 - 1:0] idx);
      begin :tkeep_to_mty_blk //{
         case (idx)
            16'hFFFF: begin tkeep_to_mty = 4'd0; end 
            16'h7FFF: begin tkeep_to_mty = 4'd1; end 
            16'h3FFF: begin tkeep_to_mty = 4'd2; end 
            16'h1FFF: begin tkeep_to_mty = 4'd3; end 
            16'h0FFF: begin tkeep_to_mty = 4'd4; end 
            16'h07FF: begin tkeep_to_mty = 4'd5; end 
            16'h03FF: begin tkeep_to_mty = 4'd6; end 
            16'h01FF: begin tkeep_to_mty = 4'd7; end 
            16'h00FF: begin tkeep_to_mty = 4'd8; end 
            16'h007F: begin tkeep_to_mty = 4'd9; end 
            16'h003F: begin tkeep_to_mty = 4'd10; end 
            16'h001F: begin tkeep_to_mty = 4'd11; end 
            16'h000F: begin tkeep_to_mty = 4'd12; end 
            16'h0007: begin tkeep_to_mty = 4'd13; end 
            16'h0003: begin tkeep_to_mty = 4'd14; end 
            16'h0001: begin tkeep_to_mty = 4'd15; end 
            default : begin tkeep_to_mty = 4'd0; end 
         endcase
      end //}
   endfunction // func

endmodule // exdes_axis2lbus_segmented_corelogic

