module tb_IIC_LM75A;
  
  reg clk;
  reg reset;
  wire scl;
  wire sda;
  wire [3:0] dig;
  wire [7:0] seg;
  wire [15:0] data_tb;
  wire [7:0] address_tb;
  
 wire sda_t; //input_value;
 reg sda_out; //output_value;
 reg sda_en; //output_value_valid;
 wire scl_t;
 
 reg [7:0] data_reg;
 reg [15:0] sda_out_reg;
 integer i;

IIC_LM75A dut(.clk(clk),
              .reset(reset),
              .scl(scl),
              .sda(sda), //bidirectional signal
              .dig(dig),
              .seg(seg),
              .data_tb(data_tb),
              .address_tb(address_tb)
              );

assign sda_t = sda;
assign sda = (sda_en == 1'b1)? sda_out : 1'hz;
assign scl_t = scl;


initial begin
  clk = 0;
  forever #20 clk = ~clk;
end

initial begin
  reset = 1;
  repeat(4)@(posedge clk);
  reset = 0;
end


initial begin
  sda_out = 0;
  sda_out_reg = 0;
  repeat(31999999)@(posedge clk);
  repeat(1)@(posedge scl_t);
  sda_en = 0; //make sda input
  data_reg = 0;
  /* The sda will now act as input, receive device address from sda and 
     store it in data_reg */
  for(i=0; i<8; i=i+1) begin
    @(posedge scl_t);
    data_reg[7-i] = sda_t;
  end
  $display("-----------------------------------------------------------------------------");
  $display("\n \t Sent address from design = %0b,\n \t Received address in testbench = %0b",address_tb,data_reg);
    if(address_tb == data_reg) 
      $display("Test passed");
    else
      $display("Test failed");
  $display("-----------------------------------------------------------------------------");
  @(posedge clk);
  @(posedge scl_t);
  /////////////////////////////////////////////////////////////////////////
  sda_en = 1; //make sda output
  /* sda will now act as output, send 2 bytes of data and compare with the
     data obtained from the design (data_tb), if it matches then the test
     is passed */
  sda_out_reg[15:8] = 8'b1010_0111; //random value
  for(i=0;i<8;i=i+1) begin
    @(posedge scl_t);
    sda_out = sda_out_reg[15-i];
  end
    @(posedge scl_t);
    @(posedge clk);
  sda_out_reg[7:0] = 8'b1100_1010; //random value  
  for(i=0;i<8;i=i+1) begin
    @(posedge scl_t);
    sda_out = sda_out_reg[7-i];
  end  
    @(posedge scl_t);
    $display("-----------------------------------------------------------------------------");
    $display("\n \t Sent Temperature data from tb = %0b,\n \t Received Temperature data from design = %0b",sda_out_reg,data_tb);
    if(sda_out_reg == data_tb) 
      $display("Test passed");
    else
      $display("Test failed");
    $display("-----------------------------------------------------------------------------");
    repeat(10)@(posedge clk);
    $finish;
  
end
 
  

endmodule