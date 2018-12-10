/*
*  Copyright (C) 2018  Siddharth J <www.siddharth.pro>
*
*  Permission to use, copy, modify, and/or distribute this software for any
*  purpose with or without fee is hereby granted, provided that the above
*  copyright notice and this permission notice appear in all copies.
*
*  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
*  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
*  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
*  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
*  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
*  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
*  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*
*/

module IIC_LM75A(clk,reset,scl,sda,dig,seg);

input clk; //FPGA clock
input reset; //Reset

output scl;// SCL clock
inout  sda;// SDA data
output reg [3:0] dig; //Seven segment display enable
output reg [7:0] seg; //Seven segment


localparam [3:0] idle = 4'd0,
                 start = 4'd1,
                 address = 4'd2,
                 addack = 4'd3,
                 read15to8 = 4'd4,
                 readack = 4'd5,
                 read7to0 = 4'd6,
                 nack = 4'd7,
                 stop = 4'd8;


reg [15:0]data_reg;// Temperature data register
reg scl;// SCL register
reg sda_reg;// SDA register
reg sda_link;// SDA bus data enable
reg [8:0]count1;// SCL clock generation counter
reg [24:0]sec_count;// Reading temperature data every second
reg [3:0]data_count;// Data string and conversion register
reg [7:0]address_reg;// Device address register
reg [3:0]state;// Status register
reg [24:0] count2;
reg [3:0] seg_data;


always@(posedge clk)
begin
if(reset)
count1 <= 9'd0;
else if(count1 == 9'd399)
count1 <= 9'd0;
else
count1 <= count1 + 1'b1;
end


always@(posedge clk)
begin
if(reset)
scl <= 1'b0;
else if(count1 == 9'd399)
scl <= 1'b1;
else if(count1 == 9'd199)
scl <= 1'b0;
end


always@(posedge clk)
begin
if(reset)
begin
data_reg <= 16'd0;
sda_reg <= 1'b1;
sda_link <= 1'b1;
state <= idle;
address_reg <= 15'd0;
data_count <= 4'd0;
sec_count <= 0;
end
else
case(state)
idle:
begin
sda_reg   <= 1'b1;
sda_link <= 1'b1;
if(sec_count == 25'd31999999) begin
sec_count <= 0;
state <= start;
end
else begin
sec_count <= sec_count + 1'b1;
state <= idle;
end
end
start:
begin
if(count1 == 9'd99)
begin
sda_reg <= 1'b0;
sda_link <= 1'b1;
address_reg <= 9'b10010001;
state <= address;
data_count <= 4'd0;
end
else
state <= start;
end
address:
begin
if(count1 == 9'd299)
begin
if(data_count == 4'd8)
begin
state <= addack;
data_count <=  4'd0;
sda_reg <= 1'b1;
sda_link <= 1'b0;
end
else
begin
state   <= address;
data_count <= data_count + 1'b1;
case(data_count)
4'd0: sda_reg <= address_reg[7];
4'd1: sda_reg <= address_reg[6];
4'd2: sda_reg <= address_reg[5];
4'd3: sda_reg <= address_reg[4];
4'd4: sda_reg <= address_reg[3];
4'd5: sda_reg <= address_reg[2];
4'd6: sda_reg <= address_reg[1];
4'd7: sda_reg <= address_reg[0];
default: ;
endcase
end
end
else
state <= address;
end
addack:
begin
if(!sda && (count1 == 9'd299))
state <= read15to8;
else if(count1 == 9'd199)
state <= read15to8;
else
state <= addack;
end
read15to8:
begin
if((count1 == 9'd299) && (data_count == 4'd8))
begin
state <= readack;
data_count <= 4'd0;
sda_reg <= 1'b1;
sda_link <= 1'b1;
end
else if(count1 == 9'd99)
begin
data_count <= data_count + 1'b1;
case(data_count)
4'd0: data_reg[15] <= sda;
4'd1: data_reg[14] <= sda;
4'd2: data_reg[13] <= sda;
4'd3: data_reg[12] <= sda;
4'd4: data_reg[11] <= sda;
4'd5: data_reg[10] <= sda;
4'd6: data_reg[9]  <= sda;
4'd7: data_reg[8]  <= sda;
default: ;
endcase
end
else
state <= read15to8;
end
readack:
begin
if(count1 == 9'd299)
sda_reg <= 1'b0;
else if(count1 == 9'd199)
begin
sda_reg <= 1'b1;
sda_link <= 1'b0;
state <= read7to0;
end
else
state <= readack;
end
read7to0:
begin
if((count1 == 9'd299) && (data_count == 4'd8))
begin
state <= nack;
data_count <= 4'd0;
sda_reg <= 1'b1;
sda_link <= 1'b1;
end
else if(count1 == 9'd99)
begin
data_count <= data_count + 1'b1;
case(data_count)
4'd0: data_reg[7] <= sda;
4'd1: data_reg[6] <= sda;
4'd2: data_reg[5] <= sda;
4'd3: data_reg[4] <= sda;
4'd4: data_reg[3] <= sda;
4'd5: data_reg[2] <= sda;
4'd6: data_reg[1] <= sda;
4'd7: data_reg[0] <= sda;
default: ;
endcase
end
else
state <= read7to0;
end
nack:
begin
if(count1 == 9'd299)
begin
state <= stop;
sda_reg <= 1'b0;
end
else
state <= nack;
end
stop:
begin
if(count1 == 9'd99)
begin
state <= idle;
sda_reg <= 1'b1;
end
else
state <= stop;
end
default: state <= idle;
endcase
end


assign sda = sda_link ? sda_reg: 1'bz;


always @(posedge clk) begin
if(reset)
count2 <= 0;
else if(count2 == 25'd31999999)
count2 <= 0;
else
count2 <= count2 + 1'b1;
end


always @(count2) begin
case(count2[16:15])
2'b00: dig = 4'b1110;
2'b01: dig = 4'b1101;
2'b10: dig = 4'b1011;
default: dig = 4'b1111;
endcase
end


always @(count2 or data_reg) begin
case(count2[16:15])
2'b00: seg_data = data_reg[8:5];
2'b01: seg_data = data_reg[12:9];
2'b10: seg_data = {1'b0,data_reg[15:13]};
default: seg_data = 4'd0;
endcase
end



always @(posedge clk) begin
case(seg_data)
4'h0 : seg = ~8'hc0; //0
4'h1 : seg = ~8'hf9; //1
4'h2 : seg = ~8'ha4; //2
4'h3 : seg = ~8'hb0; //3
4'h4 : seg = ~8'h99; //4
4'h5 : seg = ~8'h92; //5
4'h6 : seg = ~8'h82; //6
4'h7 : seg = ~8'hf8; //7
4'h8 : seg = ~8'h80; //8
4'h9 : seg = ~8'h90; //9
4'ha : seg = ~8'h88; //a
4'hb : seg = ~8'h83; //b
4'hc : seg = ~8'hc6; //c
4'hd : seg = ~8'ha1; //d
4'he : seg = ~8'h86; //e
4'hf : seg = ~8'h8e; //f
default : seg = ~8'hc0;  //0
endcase
end


endmodule

