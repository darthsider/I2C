//////////////////////////////////////////////////////////////////////////////////
// digitalvlsidesign.com
// Create Date: 17/07/2018 
// Design Name: Power N circuit
// Module Name: power_n_tb.v 
//////////////////////////////////////////////////////////////////////////////////

module power_n_tb;

	// Inputs
	reg clk;
	reg reset;
	reg start;
	reg [2:0] exponent;
	reg [2:0] base;

	// Outputs
	wire [7:0] out;

	// Instantiate the Unit Under Test (UUT)
	power_n uut (
		.clk(clk), 
		.reset(reset), 
		.start(start), 
		.exponent(exponent), 
		.base(base), 
		.out(out)
	);

	always
	begin
	clk = 1'b1;
	#10;
	clk = 1'b0;
	#10;
	end
	
	initial
	begin
	reset = 1'b1;
	#20;
	reset = 1'b0;
	end
	
	initial
	begin
	base = 0;
	exponent = 0;
	start = 0;
	@(negedge reset);
	@(negedge clk);
	base = 3'd4;
	exponent = 3'd2;
	start = 1;
	repeat(5)@(negedge clk);
	base = 3'd3;
	exponent = 3'd5;
	start = 1;
	repeat(8)@(negedge clk);
	base = 3'd6;
	exponent = 3'd3;
	start = 1;
	repeat(8)@(negedge clk);
	base = 3'd5;
	exponent = 3'd2;
	start = 1;
	repeat(8)@(negedge clk);
	//Test overflow
   base = 3'd7;
   exponent = 3'd3;
   start = 1;
   repeat(8)@(negedge clk);
	$stop;
	end
	 
	endmodule
	

