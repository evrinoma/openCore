module waitCount(clk, start, out);
input clk;
input start;

output out;

localparam NULL	= 16'h0000;
localparam DIV1	= 16'h3FFF;
localparam DIV2	= 16'h7FFF;
localparam DIV3	= 16'hBFFF;
localparam MAX		= 16'hFFFF;
reg[15:0] counter=NULL;

reg out=1'b0;	

always@(posedge clk)
begin
if(!start)
	begin
		case(counter)								
			DIV1:begin
					 out <=1'b1;
				 end		
			DIV2:begin
				    out <=1'b0;					
				 end	 
			DIV3:begin
					 out <=1'b1;	
				 end
			MAX:begin
					 out <=1'b0;	
				 end			 
		endcase
		if (counter!=MAX)
				counter<=counter+16'h0001;
	end
else
	begin
		out <=1'b0;
		if (counter!=MAX) 
			counter<=NULL;
		else 
			counter<=MAX;
	end
end

endmodule
