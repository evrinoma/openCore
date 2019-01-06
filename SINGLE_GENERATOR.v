module SINGLE_GENERATOR(clk, reset, start, out);

input 	wire clk;
input 	wire start;
input 	wire reset;

output	wire out;
wire lstart;

shift shift (
	.clk(clk), 
	.run(start), 
	.start(lstart)
);


waitCount waitCount (
	.clk(clk), //
	.reset(reset),
	.start(lstart),
	.out(out) //
);

endmodule