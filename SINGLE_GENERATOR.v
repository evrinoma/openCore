module SINGLE_GENERATOR(clk, start, out);

input 	wire clk;
input 	wire start;

output	wire out;
wire lstart;

shift shift (
	.clk(clk), 
	.run(start), 
	.start(lstart)
);


waitCount waitCount (
	.clk(clk), //
	.start(lstart),
	.out(out) //
);

endmodule