module DEBOUNCE( clk, keyBounce, keyDeBounce);
input wire clk;
input wire keyBounce;
output wire keyDeBounce;

reg lockDeBounce = 1'b1;
localparam MAX	= 16'hFF;
localparam MIN	= 16'h00;
reg [15:0] counter = MIN;

assign keyDeBounce 	= (lockDeBounce) 	? 1'b1 : 1'b0;

always@(posedge clk)
begin
		begin
			case (counter)
				MIN: begin
					lockDeBounce = 1'b1;
					if(keyBounce == 0) counter <= counter+16'b1;
				end
				MAX: begin
					lockDeBounce = 1'b0;
					if(keyBounce == 1) counter <= counter-16'b1;
				end
				default: begin
						if (lockDeBounce) 
							counter <= (keyBounce == 0) ? counter+16'b1 : MIN;
						else
							counter <= (keyBounce == 1) ? counter-16'b1 : MAX;
				end
			endcase			
		end 
end
endmodule
