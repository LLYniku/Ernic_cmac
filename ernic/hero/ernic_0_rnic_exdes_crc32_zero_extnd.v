
`timescale 1ns/1ns
module exdes_crc32_zero_extnd #(
  parameter        NUM_ZEROS  = 0) 
(
  input  wire [31:0] crc_in,
  output reg  [31:0] crc_out
);
  
  integer i;

  always @(*)
  begin
    crc_out = crc_in;
    for (i=0; i<NUM_ZEROS; i=i+1)
      crc_out = {crc_out[30:0], 1'b0} ^ ({32{crc_out[31]}} & 32'h04C1_1DB7);
  end  

endmodule
