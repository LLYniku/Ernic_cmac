
`timescale 1ns/1ns

module exdes_crc_wrap (
    input                    core_clk,
    input                    core_rst,

    //AXI streaming interface signals
    output reg [511 : 0]     m_axis_tdata,
    output reg [63:0]        m_axis_tkeep,
    output reg               m_axis_tvalid,
    input                    m_axis_tready,
    output reg               m_axis_tlast,

    input      [511 : 0]     s_axis_tdata,
    input      [63:0]        s_axis_tkeep,
    input                    s_axis_tvalid,
    input                    s_axis_tlast,
    output                   s_axis_tready
);

    genvar i;
    wire t_first;
    reg t_valid_r4;
    reg t_valid_r3;
    reg t_valid_r2;
    reg t_valid_r1;
    reg t_valid_r;
    reg t_last_r4;
    reg t_last_r3;
    reg t_last_r2;
    reg t_last_r1;
    reg t_last_r;
    reg [511:0] t_data_r4;
    reg [511:0] t_data_r3;
    reg [511:0] t_data_r2;
    reg [511:0] t_data_r1;
    reg [511:0] t_data_r;
    reg [63:0] t_keep_r4;
    reg [63:0] t_keep_r3;
    reg [63:0] t_keep_r2;
    reg [63:0] t_keep_r1;
    reg [63:0] t_keep_r;
    reg        axis_idle;
    wire [31:0] crc_out;
    reg  [255:0] crc_out_r;
    reg  [2:0]  num_crc;
    wire        crc_valid;
    reg         extra_cycle;
    reg [31:0]  extra_cycle_tdata;
    reg [3:0]   extra_cycle_tkeep;
    reg [7:0]   tkeep_valid_byte;

    assign s_axis_tready = (m_axis_tready || ~m_axis_tvalid) && ~extra_cycle;

    always @(posedge core_clk) 
    begin
        if(core_rst) begin
            m_axis_tdata <= 'd0;
            m_axis_tvalid <= 1'b0;
            m_axis_tkeep <= 'd0;
            m_axis_tlast <= 1'b0;
            t_valid_r4 <= 1'b0;
            t_valid_r3 <= 1'b0;
            t_valid_r2 <= 1'b0;
            t_valid_r1 <= 1'b0;
            t_valid_r <= 1'b0;
            t_last_r4 <= 1'b0;
            t_last_r3 <= 1'b0;
            t_last_r2 <= 1'b0;
            t_last_r1 <= 1'b0;
            t_last_r <= 1'b0;
            t_data_r4 <= 'd0;
            t_data_r3 <= 'd0;
            t_data_r2 <= 'd0;
            t_data_r1 <= 'd0;
            t_data_r <= 'd0;
            t_keep_r4 <= 'd0;
            t_keep_r3 <= 'd0;
            t_keep_r2 <= 'd0;
            t_keep_r1 <= 'd0;
            t_keep_r <= 'd0;
            extra_cycle <= 1'b0;
            extra_cycle_tdata <= 32'd0;
            extra_cycle_tkeep <= 4'b0000;
            tkeep_valid_byte <= 8'h00;
        end else begin
            if((m_axis_tready || !m_axis_tvalid) && ~extra_cycle) begin // || !m_axis_tvalid) begin
                t_valid_r4 <= s_axis_tvalid;
                t_valid_r3 <= t_valid_r4;
                t_valid_r2 <= t_valid_r3;
                t_valid_r1 <= t_valid_r2;
                t_valid_r <= t_valid_r1;
                t_last_r4 <= s_axis_tlast;
                t_last_r3 <= t_last_r4;
                t_last_r2 <= t_last_r3;
                t_last_r1 <= t_last_r2;
                t_last_r <= t_last_r1;
                t_data_r4 <= s_axis_tdata;
                t_data_r3 <= t_data_r4;
                t_data_r2 <= t_data_r3;
                t_data_r1 <= t_data_r2;
                t_data_r <= t_data_r1;
                t_keep_r4 <= s_axis_tkeep;
                t_keep_r3 <= t_keep_r4;
                t_keep_r2 <= t_keep_r3;
                t_keep_r1 <= t_keep_r2;
                t_keep_r <= t_keep_r1;
                m_axis_tvalid <= t_valid_r || extra_cycle;


                if(t_last_r1 && t_valid_r1) begin
                    tkeep_valid_byte[0] <= ~t_keep_r1[8] && t_keep_r1[0];
                    tkeep_valid_byte[1] <= ~t_keep_r1[16] && t_keep_r1[8];
                    tkeep_valid_byte[2] <= ~t_keep_r1[24] && t_keep_r1[16];
                    tkeep_valid_byte[3] <= ~t_keep_r1[32] && t_keep_r1[24];
                    tkeep_valid_byte[4] <= ~t_keep_r1[40] && t_keep_r1[32];
                    tkeep_valid_byte[5] <= ~t_keep_r1[48] && t_keep_r1[40];
                    tkeep_valid_byte[6] <= ~t_keep_r1[56] && t_keep_r1[48];
                    tkeep_valid_byte[7] <= t_keep_r1[56];
                end 
                if(t_last_r && t_valid_r ) begin
                    case(tkeep_valid_byte) 
                        8'h01: begin
                            m_axis_tlast <= 1'b1;
                            if(~t_keep_r[4]) begin
                                if(~t_keep_r[2]) begin
                                    if(~t_keep_r[1]) begin
                                        m_axis_tdata[7:0] <= t_data_r[7:0];
                                        m_axis_tdata[39:8] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h000000000000001F;
                                    end else begin
                                        m_axis_tdata[15:0] <= t_data_r[15:0];
                                        m_axis_tdata[47:16] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h000000000000003F;
                                    end 
                                end else begin
                                    if(~t_keep_r[3]) begin
                                        m_axis_tdata[23:0] <= t_data_r[23:0];
                                        m_axis_tdata[55:24] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h000000000000007F;
                                    end else begin
                                        m_axis_tdata[31:0] <= t_data_r[31:0];
                                        m_axis_tdata[63:32] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h00000000000000FF;
                                    end
                                end
                            end else begin
                                if(~t_keep_r[6]) begin
                                    if(~t_keep_r[5]) begin
                                        m_axis_tdata[39:0] <= t_data_r[39:0];
                                        m_axis_tdata[71:40] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h00000000000001FF;
                                    end else begin
                                        m_axis_tdata[47:0] <= t_data_r[47:0];
                                        m_axis_tdata[79:48] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h00000000000003FF;
                                    end 
                                end else begin
                                    if(~t_keep_r[7]) begin
                                        m_axis_tdata[55:0] <= t_data_r[55:0];
                                        m_axis_tdata[87:56] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h00000000000007FF;
                                    end else begin
                                        m_axis_tdata[63:0] <= t_data_r[63:0];
                                        m_axis_tdata[95:64] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h0000000000000FFF;
                                    end
                                end
                            end
                        end
                        8'h02: begin
                            m_axis_tlast <= 1'b1;
                            if(~t_keep_r[12]) begin
                                if(~t_keep_r[10]) begin
                                    if(~t_keep_r[9]) begin
                                        m_axis_tdata[71:0] <= t_data_r[71:0];
                                        m_axis_tdata[103:72] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h0000000000001FFF;
                                    end else begin
                                        m_axis_tdata[79:0] <= t_data_r[79:0];
                                        m_axis_tdata[111:80] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h0000000000003FFF;
                                    end 
                                end else begin
                                    if(~t_keep_r[11]) begin
                                        m_axis_tdata[87:0] <= t_data_r[87:0];
                                        m_axis_tdata[119:88] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h0000000000007FFF;
                                    end else begin
                                        m_axis_tdata[95:0] <= t_data_r[95:0];
                                        m_axis_tdata[127:96] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h000000000000FFFF;
                                    end
                                end
                            end else begin
                                if(~t_keep_r[14]) begin
                                    if(~t_keep_r[13]) begin
                                        m_axis_tdata[103:0] <= t_data_r[103:0];
                                        m_axis_tdata[135:104] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h000000000001FFFF;
                                    end else begin
                                        m_axis_tdata[111:0] <= t_data_r[111:0];
                                        m_axis_tdata[143:112] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h000000000003FFFF;
                                    end 
                                end else begin
                                    if(~t_keep_r[15]) begin
                                        m_axis_tdata[119:0] <= t_data_r[119:0];
                                        m_axis_tdata[151:120] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h000000000007FFFF;
                                    end else begin
                                        m_axis_tdata[127:0] <= t_data_r[127:0];
                                        m_axis_tdata[159:128] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h00000000000FFFFF;
                                    end
                                end
                            end
                        end
                        8'h04: begin
                            m_axis_tlast <= 1'b1;
                            if(~t_keep_r[20]) begin
                                if(~t_keep_r[18]) begin
                                    if(~t_keep_r[17]) begin
                                        m_axis_tdata[135:0] <= t_data_r[135:0];
                                        m_axis_tdata[167:136] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h00000000001FFFFF;
                                    end else begin
                                        m_axis_tdata[143:0] <= t_data_r[143:0];
                                        m_axis_tdata[175:144] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h00000000003FFFFF;
                                    end 
                                end else begin
                                    if(~t_keep_r[19]) begin
                                        m_axis_tdata[151:0] <= t_data_r[151:0];
                                        m_axis_tdata[183:152] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h00000000007FFFFF;
                                    end else begin
                                        m_axis_tdata[159:0] <= t_data_r[159:0];
                                        m_axis_tdata[191:160] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h0000000000FFFFFF;
                                    end
                                end
                            end else begin
                                if(~t_keep_r[22]) begin
                                    if(~t_keep_r[21]) begin
                                        m_axis_tdata[167:0] <= t_data_r[167:0];
                                        m_axis_tdata[199:168] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h0000000001FFFFFF;
                                    end else begin
                                        m_axis_tdata[175:0] <= t_data_r[175:0];
                                        m_axis_tdata[207:176] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h0000000003FFFFFF;
                                    end 
                                end else begin
                                    if(~t_keep_r[23]) begin
                                        m_axis_tdata[183:0] <= t_data_r[183:0];
                                        m_axis_tdata[215:184] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h0000000007FFFFFF;
                                    end else begin
                                        m_axis_tdata[191:0] <= t_data_r[191:0];
                                        m_axis_tdata[223:192] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h000000000FFFFFFF;
                                    end
                                end
                            end
                        end
                        8'h08: begin
                            m_axis_tlast <= 1'b1;
                            if(~t_keep_r[28]) begin
                                if(~t_keep_r[26]) begin
                                    if(~t_keep_r[25]) begin
                                        m_axis_tdata[199:0] <= t_data_r[199:0];
                                        m_axis_tdata[231:200] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h000000001FFFFFFF;
                                    end else begin
                                        m_axis_tdata[207:0] <= t_data_r[207:0];
                                        m_axis_tdata[239:208] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h000000003FFFFFFF;
                                    end 
                                end else begin
                                    if(~t_keep_r[27]) begin
                                        m_axis_tdata[215:0] <= t_data_r[215:0];
                                        m_axis_tdata[247:216] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h000000007FFFFFFF;
                                    end else begin
                                        m_axis_tdata[223:0] <= t_data_r[223:0];
                                        m_axis_tdata[255:224] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h00000000FFFFFFFF;
                                    end
                                end
                            end else begin
                                if(~t_keep_r[30]) begin
                                    if(~t_keep_r[29]) begin
                                        m_axis_tdata[231:0] <= t_data_r[231:0];
                                        m_axis_tdata[263:232] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h00000001FFFFFFFF;
                                    end else begin
                                        m_axis_tdata[239:0] <= t_data_r[239:0];
                                        m_axis_tdata[271:240] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h00000003FFFFFFFF;
                                    end 
                                end else begin
                                    if(~t_keep_r[31]) begin
                                        m_axis_tdata[247:0] <= t_data_r[247:0];
                                        m_axis_tdata[279:248] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h00000007FFFFFFFF;
                                    end else begin
                                        m_axis_tdata[255:0] <= t_data_r[255:0];
                                        m_axis_tdata[287:256] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h0000000FFFFFFFFF;
                                    end
                                end
                            end
                        end
                        8'h10: begin
                            m_axis_tlast <= 1'b1;
                            if(~t_keep_r[36]) begin
                                if(~t_keep_r[34]) begin
                                    if(~t_keep_r[33]) begin
                                        m_axis_tdata[263:0] <= t_data_r[263:0];
                                        m_axis_tdata[295:264] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h0000001FFFFFFFFF;
                                    end else begin
                                        m_axis_tdata[271:0] <= t_data_r[271:0];
                                        m_axis_tdata[303:272] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h0000003FFFFFFFFF;
                                    end 
                                end else begin
                                    if(~t_keep_r[35]) begin
                                        m_axis_tdata[279:0] <= t_data_r[279:0];
                                        m_axis_tdata[311:280] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h0000007FFFFFFFFF;
                                    end else begin
                                        m_axis_tdata[287:0] <= t_data_r[287:0];
                                        m_axis_tdata[319:288] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h000000FFFFFFFFFF;
                                    end
                                end
                            end else begin
                                if(~t_keep_r[38]) begin
                                    if(~t_keep_r[37]) begin
                                        m_axis_tdata[295:0] <= t_data_r[295:0];
                                        m_axis_tdata[327:296] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h000001FFFFFFFFFF;
                                    end else begin
                                        m_axis_tdata[303:0] <= t_data_r[303:0];
                                        m_axis_tdata[335:304] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h000003FFFFFFFFFF;
                                    end 
                                end else begin
                                    if(~t_keep_r[39]) begin
                                        m_axis_tdata[311:0] <= t_data_r[311:0];
                                        m_axis_tdata[343:312] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h000007FFFFFFFFFF;
                                    end else begin
                                        m_axis_tdata[319:0] <= t_data_r[319:0];
                                        m_axis_tdata[351:320] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h00000FFFFFFFFFFF;
                                    end
                                end
                            end
                        end
                        8'h20: begin
                            m_axis_tlast <= 1'b1;
                            if(~t_keep_r[44]) begin
                                if(~t_keep_r[42]) begin
                                    if(~t_keep_r[41]) begin
                                        m_axis_tdata[327:0] <= t_data_r[327:0];
                                        m_axis_tdata[359:328] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h00001FFFFFFFFFFF;
                                    end else begin
                                        m_axis_tdata[335:0] <= t_data_r[335:0];
                                        m_axis_tdata[367:336] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h00003FFFFFFFFFFF;
                                    end 
                                end else begin
                                    if(~t_keep_r[43]) begin
                                        m_axis_tdata[343:0] <= t_data_r[343:0];
                                        m_axis_tdata[375:344] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h00007FFFFFFFFFFF;
                                    end else begin
                                        m_axis_tdata[351:0] <= t_data_r[351:0];
                                        m_axis_tdata[383:352] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h0000FFFFFFFFFFFF;
                                    end
                                end
                            end else begin
                                if(~t_keep_r[46]) begin
                                    if(~t_keep_r[45]) begin
                                        m_axis_tdata[359:0] <= t_data_r[359:0];
                                        m_axis_tdata[391:360] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h0001FFFFFFFFFFFF;
                                    end else begin
                                        m_axis_tdata[367:0] <= t_data_r[367:0];
                                        m_axis_tdata[399:368] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h0003FFFFFFFFFFFF;
                                    end 
                                end else begin
                                    if(~t_keep_r[47]) begin
                                        m_axis_tdata[375:0] <= t_data_r[375:0];
                                        m_axis_tdata[407:376] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h0007FFFFFFFFFFFF;
                                    end else begin
                                        m_axis_tdata[383:0] <= t_data_r[383:0];
                                        m_axis_tdata[415:384] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h000FFFFFFFFFFFFF;
                                    end
                                end
                            end
                        end
                        8'h40: begin
                            m_axis_tlast <= 1'b1;
                            if(~t_keep_r[52]) begin
                                if(~t_keep_r[50]) begin
                                    if(~t_keep_r[49]) begin
                                        m_axis_tdata[391:0] <= t_data_r[391:0];
                                        m_axis_tdata[423:392] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h001FFFFFFFFFFFFF;
                                    end else begin
                                        m_axis_tdata[399:0] <= t_data_r[399:0];
                                        m_axis_tdata[431:400] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h003FFFFFFFFFFFFF;
                                    end 
                                end else begin
                                    if(~t_keep_r[51]) begin
                                        m_axis_tdata[407:0] <= t_data_r[407:0];
                                        m_axis_tdata[439:408] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h007FFFFFFFFFFFFF;
                                    end else begin
                                        m_axis_tdata[415:0] <= t_data_r[415:0];
                                        m_axis_tdata[447:416] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h00FFFFFFFFFFFFFF;
                                    end
                                end
                            end else begin
                                if(~t_keep_r[54]) begin
                                    if(~t_keep_r[53]) begin
                                        m_axis_tdata[423:0] <= t_data_r[423:0];
                                        m_axis_tdata[455:424] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h01FFFFFFFFFFFFFF;
                                    end else begin
                                        m_axis_tdata[431:0] <= t_data_r[431:0];
                                        m_axis_tdata[463:432] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h03FFFFFFFFFFFFFF;
                                    end 
                                end else begin
                                    if(~t_keep_r[55]) begin
                                        m_axis_tdata[439:0] <= t_data_r[439:0];
                                        m_axis_tdata[471:440] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h07FFFFFFFFFFFFFF;
                                    end else begin
                                        m_axis_tdata[447:0] <= t_data_r[447:0];
                                        m_axis_tdata[479:448] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h0FFFFFFFFFFFFFFF;
                                    end
                                end
                            end
                        end
                        8'h80: begin
                            if(~t_keep_r[60]) begin
                                m_axis_tlast <= 1'b1;
                                if(~t_keep_r[58]) begin
                                    if(~t_keep_r[57]) begin
                                        m_axis_tdata[455:0] <= t_data_r[455:0];
                                        m_axis_tdata[487:456] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h1FFFFFFFFFFFFFFF;
                                    end else begin
                                        m_axis_tdata[463:0] <= t_data_r[463:0];
                                        m_axis_tdata[495:464] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h3FFFFFFFFFFFFFFF;
                                    end 
                                end else begin
                                    if(~t_keep_r[59]) begin
                                        m_axis_tdata[471:0] <= t_data_r[471:0];
                                        m_axis_tdata[503:472] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'h7FFFFFFFFFFFFFFF;
                                    end else begin
                                        m_axis_tdata[479:0] <= t_data_r[479:0];
                                        m_axis_tdata[511:480] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'hFFFFFFFFFFFFFFFF;
                                    end
                                end
                            end else begin
                                extra_cycle <= 1'b1;
                                m_axis_tlast <= 1'b0;
                                if(~t_keep_r[62]) begin
                                    if(~t_keep_r[61]) begin
                                        m_axis_tdata[487:0] <= t_data_r[487:0];
                                        m_axis_tdata[511:488] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[55:32] : crc_out_r[23:0];
                                        extra_cycle_tkeep <= 4'b0001;
                                        extra_cycle_tdata[7:0] <=  (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:56] : crc_out_r[31:24];
                                        m_axis_tkeep <= 64'hFFFFFFFFFFFFFFFF;
                                    end else begin
                                        m_axis_tdata[495:0] <= t_data_r[495:0];
                                        m_axis_tdata[511:496] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[47:32] : crc_out_r[15:0];
                                        extra_cycle_tkeep <= 4'b0011;
                                        extra_cycle_tdata[15:0] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:48] : crc_out_r[31:16];
                                        m_axis_tkeep <= 64'hFFFFFFFFFFFFFFFF;
                                    end 
                                end else begin
                                    if(~t_keep_r[63]) begin
                                        m_axis_tdata[503:0] <= t_data_r[503:0];
                                        m_axis_tdata[511:504] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[40:32] : crc_out_r[7:0];
                                        extra_cycle_tkeep <= 4'b0111;
                                        extra_cycle_tdata[23:0] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:40] : crc_out_r[31:8];
                                        m_axis_tkeep <= 64'hFFFFFFFFFFFFFFFF;
                                    end else begin
                                        m_axis_tdata <= t_data_r;
                                        extra_cycle_tkeep <= 4'b1111;
                                        extra_cycle_tdata[31:0] <= (m_axis_tvalid && m_axis_tlast && m_axis_tready) ? crc_out_r[63:32] : crc_out_r[31:0];
                                        m_axis_tkeep <= 64'hFFFFFFFFFFFFFFFF;
                                    end
                                end
                            end
                        end
                        default: begin
                            m_axis_tdata <= t_data_r;
                            m_axis_tkeep <= t_keep_r;
                            m_axis_tlast <= t_last_r;
                            extra_cycle <= 1'b0;
                        end
                    endcase
                end else begin
                    m_axis_tdata <= t_data_r;
                    m_axis_tkeep <= t_keep_r;
                    m_axis_tlast <= 1'b0;
                    extra_cycle_tdata <= 32'd0;
                    extra_cycle_tkeep <= 4'b0000;
                    extra_cycle <= 1'b0;
                end
            end else if(extra_cycle && m_axis_tready) begin
                m_axis_tdata <= {{480{1'b0}},extra_cycle_tdata};
                m_axis_tkeep <= {{60{1'b0}},extra_cycle_tkeep};
                m_axis_tvalid <= 1'b1;
                m_axis_tlast <= 1'b1;
                extra_cycle <= 1'b0;
            end
        end
    end

    assign t_first = (s_axis_tvalid && s_axis_tready) && axis_idle;

    always@(posedge core_clk)
    begin
        if(core_rst) begin
            axis_idle <= 1'b1;
            crc_out_r <= 32'd0;
            num_crc <= 3'b000;
        end else begin
            if(s_axis_tvalid && s_axis_tready && axis_idle && ~s_axis_tlast) begin
                axis_idle <= 1'b0;
            end else if(s_axis_tlast && s_axis_tvalid && s_axis_tready) begin
                axis_idle <= 1'b1;
            end
            if(crc_valid) begin
                num_crc <= num_crc + ((m_axis_tvalid && m_axis_tlast && m_axis_tready) ? 1'b0 : 1'b1);
                case (num_crc)
                    3'b000: crc_out_r[31:0] <= crc_out;
                    3'b001: begin
                        if(m_axis_tvalid && m_axis_tlast && m_axis_tready) begin
                            crc_out_r[31:0] <= crc_out;
                        end else begin
                            crc_out_r[63:32] <= crc_out;
                        end
                    end
                    3'b010: begin
                        if(m_axis_tvalid && m_axis_tlast && m_axis_tready) begin
                            crc_out_r[63:32] <= crc_out;
                            crc_out_r[31:0] <= crc_out_r[63:32];
                        end else begin
                            crc_out_r[95:64] <= crc_out;
                        end
                    end
                    3'b011: begin
                        if(m_axis_tvalid && m_axis_tlast && m_axis_tready) begin
                            crc_out_r[95:64] <= crc_out;
                            crc_out_r[63:0] <= crc_out_r[95:32];
                        end else begin
                            crc_out_r[127:96] <= crc_out;
                        end
                    end
                    3'b100: begin
                        if(m_axis_tvalid && m_axis_tlast && m_axis_tready) begin
                            crc_out_r[127:96] <= crc_out;
                            crc_out_r[95:0] <= crc_out_r[127:32];
                        end else begin
                            crc_out_r[159:128] <= crc_out;
                        end
                    end
                    3'b101: begin
                        if(m_axis_tvalid && m_axis_tlast && m_axis_tready) begin
                            crc_out_r[159:128] <= crc_out;
                            crc_out_r[127:0] <= crc_out_r[159:32];
                        end else begin
                            crc_out_r[191:160] <= crc_out;
                        end
                    end
                    3'b110: begin
                        if(m_axis_tvalid && m_axis_tlast && m_axis_tready) begin
                            crc_out_r[191:160] <= crc_out;
                            crc_out_r[159:0] <= crc_out_r[191:32];
                        end else begin
                            crc_out_r[223:192] <= crc_out;
                        end
                    end
                    default crc_out_r[31:0] <= crc_out;
                endcase
            //end else if(t_valid_r && t_last_r && m_axis_tready && ~extra_cycle) begin
            end else if(m_axis_tvalid && m_axis_tlast && m_axis_tready && ~extra_cycle) begin
                if(|num_crc) begin
                    num_crc <= num_crc - 1'b1;
                    crc_out_r <= {32'd0,crc_out_r[255:32]};
                end
            end
        end
    end

    exdes_icrc_calc 
#(
  .C_PKT_NUM_WIDTH(1)
 ) inst_crc
 (
   .clk            (core_clk),
   .rst_n          (~core_rst),
   .t_data         (s_axis_tdata),
   .t_valid        (s_axis_tvalid && s_axis_tready),
   .t_first        (t_first),
   .t_last         (s_axis_tlast),
   .t_keep         (s_axis_tkeep),
   .t_pkt          (1'b0),
   .o_crc_pkt      (),
   .o_crc_out      (crc_out),
   .o_crc_err      (),
   .o_crc_valid    (crc_valid)
);

endmodule
