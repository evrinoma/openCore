module debounce(keyBounce,clk,keyDeBounce);

input wire keyBounce;
input wire clk;
output wire keyDeBounce;

wire clk_en;
wire Q1,Q2,Q2Bar;

clockDiv div(clk,keyBounce,clk_en);

dff_en d1(clk,clk_en,keyBounce,Q1);

dff_en d2(clk,clk_en,Q1,Q2);

assign Q2Bar = ~Q2;
assign keyDeBounce = Q1 & Q2Bar;

endmodule
// Slow clock enable for debouncing button 
module clockDiv(clk,keyBounce, clkEn);
input wire clk;
input wire keyBounce;
output wire clkEn;
localparam MAX	= 16'hFF;
localparam MIN	= 16'h00;
reg [15:0] counter = MIN;
	always @(posedge clk, negedge keyBounce)
	begin
	if(keyBounce == 0)
		counter <= MIN;
	else
		counter <= (counter>=MAX) ? MIN : counter+1;
	end
	
	assign clkEn = (counter == MAX) ? 1'b1 : 1'b0;
endmodule

// D-flip-flop with clock enable signal for debouncing module 
module dff_en(clock, en, D, Q);
input wire clock; 
input wire en;
input wire D;
output reg Q = 1'd0;
	always @ (posedge clock)
	begin
		if(en == 1) 
           Q <= D;
   end
endmodule 
