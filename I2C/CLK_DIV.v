module DIV_CLK(clk, freq1Mhz);
input wire clk; 
output reg freq1Mhz 		= 1'd0;

localparam  STEP			= 5'd1;
localparam  MIN			= 5'd0;
//localparam  DIV5MHZ		= 5'd4;
localparam  DIV12_5MHZ		= 5'd1;
//localparam  DIV1MHZ		= 5'd24;
reg[4:0] div = MIN;

//always@(posedge clk)
//begin
//	freq1Mhz <= ~freq1Mhz;
//end
//endmodule
always@(posedge clk)
begin
	if(div==DIV12_5MHZ)
		begin
			freq1Mhz <= ~freq1Mhz;
			div<=MIN;
		end
	else
		begin
			div <= div + STEP;
		end
end
endmodule