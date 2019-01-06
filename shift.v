module shift(clk, run, start);
input clk;
input run;
output start;

reg a=1'b0;
reg signal_sync=1'b0;
assign start = signal_sync;//?1'b0:1'b1;

always @(posedge clk)
begin
   signal_sync<=a;
   a<=run;
end

endmodule