//////////////////////////////////////////////////////////////////////////////////
// digitalvlsidesign.com
// Create Date: 17/07/2018 
// Design Name: Power N circuit
// Module Name: power_n 
//////////////////////////////////////////////////////////////////////////////////

module power_n(clk,reset,start,exponent,base,out);  

  input clk;
  input reset;
  input start;
  input [2:0] exponent;
  input [2:0] base;
  output [7:0] out;
  
  parameter [2:0] S0 = 3'b000,
                  S1 = 3'b001,
						S2 = 3'b010,
						S3 = 3'b100;
						
  reg [2:0] state, next_state;
  reg [2:0] n_reg, n_next;
  reg [7:0] p_reg, p_next;
  reg [7:0] out_reg;
  
  
  always @(posedge clk, posedge reset)
  if(reset)
  begin
  state <= S0;
  n_reg <= 0;
  p_reg <= 0;
  end
  else
  begin
  state <= next_state;
  n_reg <= n_next;
  p_reg <= p_next;
  end

  always @(*)
  begin
  next_state = state;
  n_next = n_reg;
  p_next = p_reg;
  out_reg = 0;
  case(state)
  S0: begin 
  if(start)
  next_state = S1;
  else
  next_state = S0;
  end
  S1: begin
  n_next = exponent;
  p_next = 1;
  next_state = S2;
  end
  S2: begin
  if(n_reg == 0)
  next_state = S3;
  else
  begin
  n_next = n_reg - 1;
  p_next = p_reg * base;
  next_state = S2;
  end
  end
  S3: begin
  out_reg = p_reg;  
  next_state = S0;
  end
  default: next_state = S0;
  endcase
  end

  assign out = out_reg;
  
endmodule   

