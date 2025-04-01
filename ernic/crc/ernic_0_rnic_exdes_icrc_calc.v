
`timescale 1ns/1ns
module exdes_icrc_calc #(
  parameter C_PKT_NUM_WIDTH = 3)
( 
  input  wire                           clk,
  input  wire                           rst_n,
  input  wire [511:0]                   t_data,
  input  wire                           t_valid,
  input  wire                           t_first,
  input  wire                           t_last,
  input  wire [63:0]                    t_keep,
  input  wire [C_PKT_NUM_WIDTH-1:0]     t_pkt,
  output wire [C_PKT_NUM_WIDTH-1:0]     o_crc_pkt,
  output wire  [31:0]                   o_crc_out,
  output wire                           o_crc_err,
  output wire                           o_crc_valid
);

  localparam [15:0] ETH_TYPE_IPv4 = 16'h0008;
  localparam [15:0] ETH_TYPE_IPv6 = 16'hdd86;
  
  reg         ether_type_ipv6;
  
  reg [511:0] next_t_data_masked;
  reg [511:0] t_data_masked;
  
  reg [  5:0] next_num_bytes_to_shift;
  reg [  5:0] num_bytes_to_shift;
  
  reg [511:0] next_crc_data_in;
  reg [511:0] crc_data_in;
  
  reg [  5:0] first_byte_d1;
  
  reg         t_valid_d1;
  reg         t_first_d1; 
  reg         t_last_d1; 
  
  wire [ 31:0] byte_wide_crc32_seed_all_0s[0:63];
  wire [ 31:0] byte_wide_crc32_seed_all_1s[0:63];
  reg  [ 31:0] byte_wide_crc32[0:63];
  
  reg  [ 31:0] next_line_wide_crc32;
  reg  [ 31:0] line_wide_crc32;

  reg [  5:0] first_byte_d2;
  
  reg         t_valid_d2;
  reg         t_first_d2; 
  reg         t_last_d2; 

  reg [  5:0] first_byte_d3;
  
  reg         t_valid_d3;
  reg         t_first_d3; 
  reg         t_last_d3;  
  
  reg [  5:0] first_byte_d4;
  
  reg         t_valid_d4;
  reg         t_first_d4; 
  reg         t_last_d4;
  
  //wire [C_PKT_NUM_WIDTH-1:0] t_pkt_d1;
  reg  [C_PKT_NUM_WIDTH-1:0] t_pkt_d1;
  reg  [C_PKT_NUM_WIDTH-1:0] t_pkt_d2;
  reg  [C_PKT_NUM_WIDTH-1:0] t_pkt_d3;
  reg  [C_PKT_NUM_WIDTH-1:0] t_pkt_d4;
     
  wire [ 31:0] prev_crc32_premux[0:63];
  
  wire [ 31:0] crc_out_preinv;
  reg  [ 31:0] prev_crc32;
  
  reg  [ 31:0] crc_out;    
  
  integer i;
  
  genvar j;

  /************************
    Cycle 0
  ************************/
  always @(posedge clk)
    if (t_first)
      if (t_data[12*8+:16] == ETH_TYPE_IPv6)
        ether_type_ipv6 <= 1'b1;
      else
        ether_type_ipv6 <= 1'b0;

  always @(*)
  begin
    next_t_data_masked = t_data;
    if ((t_data[12*8 +: 16] == ETH_TYPE_IPv4) && t_first)
    begin  
      next_t_data_masked[46*8+: 8]    = { 8{1'b1}};         // BTH RSVD8
      next_t_data_masked[40*8+:16]    = {16{1'b1}};         // UDP Checksum
      next_t_data_masked[24*8+:16]    = {16{1'b1}};         // IP Header Checksum
      next_t_data_masked[22*8+: 8]    = { 8{1'b1}};         // Time to Leave
      next_t_data_masked[15*8+: 8]    = { 8{1'b1}};         // DSCP, ECN
      next_t_data_masked[ 6*8+:64]    = {64{1'b1}};         // CA17-22(a)
      next_t_data_masked[   47: 0]    = {48{1'b0}};         
    end     
    if ((t_data[12*8 +: 16] == ETH_TYPE_IPv6) && t_first)
    begin
      next_t_data_masked[60*8+:16]    = {16{1'b1}};         // UDP Checksum
      next_t_data_masked[21*8+: 8]    = { 8{1'b1}};         // Hop Limit
      next_t_data_masked[14*8+: 4]    = {4{1'b1}};
      next_t_data_masked[15*8+:24]    = {24{1'b1}};
      next_t_data_masked[ 6*8+:64]    = {64{1'b1}};         // CA17-22(a) 
      next_t_data_masked[   47: 0]    = {48{1'b0}};      
    end
    if (ether_type_ipv6 && t_first_d1)
      next_t_data_masked[ 2*8+: 8] = 8'hff;
  end
  
  always @(posedge clk)
    if (t_valid)
      t_data_masked <= next_t_data_masked;

  always @(*)
  begin
    next_num_bytes_to_shift = 6'd0;
    for (i=1; i<64; i=i+1)
      if (!t_keep[i]) next_num_bytes_to_shift = next_num_bytes_to_shift+6'd1;
  end
  
  always @(posedge clk)
    if (t_valid)
      num_bytes_to_shift <= next_num_bytes_to_shift;
    
  // pipeline control to next stage
  always @(posedge clk)
    if (t_first)
      first_byte_d1 <= next_num_bytes_to_shift+6'd6;
    else
      first_byte_d1 <= next_num_bytes_to_shift;    
  
  always @(posedge clk)
    if (!rst_n)
      {t_first_d1,      
       t_last_d1 }  <= {1'b0, 1'b0};
    else if (t_valid)
      {t_first_d1,      
       t_last_d1}  <= {t_first,
                       t_last }; 
                       
  //assign t_pkt_d1 = t_pkt;      // t_pkt is already registered in other module  
  
  
  always @(posedge clk)
    if (t_valid)
      t_pkt_d1 <= t_pkt;
  

  always @(posedge clk)
    t_valid_d1 <= t_valid;
    
  /************************
    Cycle 1
  ************************/
  always @(*)
  begin  
    next_crc_data_in = {512{1'b0}};    
    for (i=0; i<64; i=i+1)
    begin
      if (i>=num_bytes_to_shift)
      begin
        next_crc_data_in[8*i+7] = t_data_masked[8*(i-num_bytes_to_shift)+7];
        next_crc_data_in[8*i+6] = t_data_masked[8*(i-num_bytes_to_shift)+6];
        next_crc_data_in[8*i+5] = t_data_masked[8*(i-num_bytes_to_shift)+5];
        next_crc_data_in[8*i+4] = t_data_masked[8*(i-num_bytes_to_shift)+4];
        next_crc_data_in[8*i+3] = t_data_masked[8*(i-num_bytes_to_shift)+3];
        next_crc_data_in[8*i+2] = t_data_masked[8*(i-num_bytes_to_shift)+2];
        next_crc_data_in[8*i+1] = t_data_masked[8*(i-num_bytes_to_shift)+1];
        next_crc_data_in[8*i+0] = t_data_masked[8*(i-num_bytes_to_shift)+0];
      end
    end 
  end
  
  always @(posedge clk)
    if (t_valid_d1)
      crc_data_in   <= next_crc_data_in;

  // pipeline control to next stage
  always @(posedge clk)
    if (!rst_n)
      {t_first_d2,      
       t_last_d2 }  <= {1'b0, 1'b0};
    else if (t_valid_d1)
      {t_first_d2,      
       t_last_d2}   <= {t_first_d1,
                        t_last_d1};   
  
  always @(posedge clk)
    if (t_valid_d1)
    begin
      first_byte_d2 <= first_byte_d1;
      t_pkt_d2      <= t_pkt_d1;
    end
    
  always @(posedge clk)
    t_valid_d2 <= t_valid_d1;    
  
  /************************
    Cycle 2
  ************************/  
  generate 
    for (j=0; j<=63; j=j+1)
      begin : b1
        exdes_crc32_8b #(
          .INIT_SEED ({32{1'b0}}),
          .NUM_ZEROS (504-8*j))
        u_crc32_8b_all_0s (
          .clk          (clk),
          .crc_data_in  (crc_data_in[8*j+:8]),
          .crc_out      (byte_wide_crc32_seed_all_0s[j][31:0])
        );
        exdes_crc32_8b #(
          .INIT_SEED ({32{1'b1}}),
          .NUM_ZEROS (504-8*j))
        u_crc32_8b_all_1s (
          .clk          (clk),
          .crc_data_in  (crc_data_in[8*j+:8]),
          .crc_out      (byte_wide_crc32_seed_all_1s[j][31:0])
        );
      end   
  endgenerate
  
  // pipeline control to next stage
  always @(posedge clk)
    if (!rst_n)
      {t_first_d3,      
       t_last_d3 }  <= {1'b0, 1'b0};
    else if (t_valid_d2)
      {t_first_d3,      
       t_last_d3}   <= {t_first_d2,
                        t_last_d2};   
  
  always @(posedge clk)
    if (t_valid_d2)
    begin
      first_byte_d3 <= first_byte_d2;
      t_pkt_d3      <= t_pkt_d2;
    end
    
  always @(posedge clk)
    t_valid_d3 <= t_valid_d2;     
  
  /************************
    Cycle 3
  ************************/  
  always @(*)
  begin
    next_line_wide_crc32 = {32{1'b0}};
    for (i=0; i<64; i=i+1)
    begin
      if ((i==first_byte_d3) && t_first_d3)
        byte_wide_crc32[i][31:0] = byte_wide_crc32_seed_all_1s[i][31:0];
      else
        byte_wide_crc32[i][31:0] = byte_wide_crc32_seed_all_0s[i][31:0];           
      next_line_wide_crc32 = next_line_wide_crc32 ^ byte_wide_crc32[i][31:0];
    end
  end
  
  always @(posedge clk)
    if (t_valid_d3)
      line_wide_crc32 <= next_line_wide_crc32;
    
  generate
    for (j=0; j<=63; j=j+1)
      begin : b2
        exdes_crc32_zero_extnd #(
          .NUM_ZEROS (512-8*j))
        u_crc32_zero_extnd (
          .crc_in  (crc_out_preinv),
          .crc_out (prev_crc32_premux[j][31:0])
        );
      end
  endgenerate    
    
  always @(posedge clk)
    if (t_valid_d3)
      prev_crc32 <= prev_crc32_premux[first_byte_d3];    
    
  // pipeline control to next stage
  always @(posedge clk)
    if (!rst_n)
      {t_first_d4,      
       t_last_d4 }  <= {1'b0, 1'b0};
    else if (t_valid_d3)
      {t_first_d4,      
       t_last_d4}   <= {t_first_d3,
                        t_last_d3};   
  
  always @(posedge clk)
    if (t_valid_d3)
    begin
      first_byte_d4 <= first_byte_d3;
      t_pkt_d4      <= t_pkt_d3;
    end
    
  always @(posedge clk)
    t_valid_d4 <= t_valid_d3;    
  
  /************************
    Cycle 4
  ************************/
    
  assign crc_out_preinv = t_first_d4 ? line_wide_crc32 : (line_wide_crc32 ^ prev_crc32);    
  
  always @(*)
    for (i=0; i<8; i=i+1)
    begin
      crc_out[   i] = ~crc_out_preinv[31-i];
      crc_out[ 8+i] = ~crc_out_preinv[23-i];
      crc_out[16+i] = ~crc_out_preinv[15-i];
      crc_out[24+i] = ~crc_out_preinv[ 7-i];
    end
    
  assign o_crc_pkt   = t_pkt_d4;
  assign o_crc_out   = crc_out;
  assign o_crc_err   = t_valid_d4 & ((crc_out != 32'h2144_DF1C) ? 1'b1 : 1'b0);       
  assign o_crc_valid = t_last_d4 & t_valid_d4;
 
endmodule
    
