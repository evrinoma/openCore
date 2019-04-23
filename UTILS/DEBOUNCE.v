`define DEBUG_DEBOUNCE
`undef DEBUG_DEBOUNCE

module DEBOUNCE( 
`ifdef DEBUG_DEBOUNCE
dclk, dkeyBounce, 
`endif
clk, keyBounce, keyDeBounce);
input wire clk;
input wire keyBounce;
output wire keyDeBounce;

`ifdef DEBUG_DEBOUNCE
output wire dclk;
output wire dkeyBounce;
`endif

reg lockDeBounce = 1'b1;
localparam MAX	= 16'hFF;
localparam MIN	= 16'h00;
localparam TIK	= 16'b1;
reg [15:0] counter = MIN;

assign keyDeBounce 	= (lockDeBounce) 	? 1'b1 : 1'b0;

`ifdef DEBUG_DEBOUNCE
assign dclk 	= clk;
assign dkeyBounce 	= keyBounce;
`endif

always@(posedge clk)
begin
		begin
			case (counter)
				MIN: begin
					lockDeBounce = 1'b1;
					if(keyBounce == 0) counter <= counter+TIK;
				end
				MAX: begin
					lockDeBounce = 1'b0;
					if(keyBounce == 1) counter <= counter-TIK;
				end
				default: begin
						if (lockDeBounce) 
							counter <= (keyBounce == 0) ? counter+TIK : MIN;
						else
							counter <= (keyBounce == 1) ? counter-TIK : MAX;
				end
			endcase			
		end 
end
endmodule
