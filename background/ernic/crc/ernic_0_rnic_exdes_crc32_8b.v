
`timescale 1ns/1ns
module exdes_crc32_8b #(
  parameter [31:0] INIT_SEED  = {32{1'b0}},
  parameter        NUM_ZEROS  = 0 ) 
(
  input  wire        clk,
  input  wire [ 7:0] crc_data_in,
  output reg  [31:0] crc_out
);

  localparam CRC_IN_DW = NUM_ZEROS + 8;
  
  wire [CRC_IN_DW-1:0] crc_data_in_extnd;
  reg  [31:0]          next_crc_out;
  
  integer i;
  
  assign crc_data_in_extnd = {{(NUM_ZEROS){1'b0}}, crc_data_in};

  always @(*)
  begin
    next_crc_out = INIT_SEED;
    for (i=0; i<CRC_IN_DW; i=i+1)
      next_crc_out = {next_crc_out[30:0], 1'b0} ^ ({32{next_crc_out[31] ^ crc_data_in_extnd[i]}} & 32'h04C1_1DB7);    
  end
  
  always @(posedge clk)
    crc_out <= next_crc_out;

endmodule 
