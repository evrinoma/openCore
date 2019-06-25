module DIV_CLK(clk, freqMhz);
input wire clk; 
output reg freqMhz 		= 1'd0;

localparam  STEP			= 5'd1;
localparam  MIN			= 5'd0;

localparam  DIV1MHZ		= 5'd24;
localparam  DIV2_5MHZ	= 5'd9;
localparam  DIV2_78MHZ	= 5'd8;
localparam  DIV5MHZ		= 5'd4;
localparam  DIV12_5MHZ	= 5'd1;

localparam  DIV_MHZ		= DIV5MHZ;

reg[4:0] div = MIN;


always@(posedge clk)
begin
	if(div==DIV_MHZ)
		begin
			freqMhz <= ~freqMhz;
			div<=MIN;
		end
	else
		begin
			div <= div + STEP;
		end
end
endmodule