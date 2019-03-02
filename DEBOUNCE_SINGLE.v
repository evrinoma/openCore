module DEBOUNCE_SINGLE(keyBounce,clk,keyDeBounce,repeater);

//кнопка одиночного запуска генерирует один импульс
//макрос для условной компиляции
//если он установлен, то debounce кнопки генерирует сигнал 	  ___/'''\___ EVENT_NEGEDGE_BUTTON
//если он не установлен, то debounce кнопки генерирует сигнал '''\___/''' EVENT_POSEDGE_BUTTON
`define NEGEDGE_BUTTON

input wire keyBounce;
input wire clk;
output wire keyDeBounce;
output wire repeater;

wire clk_en;
wire Q1;
wire Q2;

`ifdef NEGEDGE_BUTTON
	wire Q2Bar;
`endif

clockDiv div(clk,keyBounce,clk_en);
dff_en d1(clk,clk_en,keyBounce,Q1);
dff_en d2(clk,clk_en,Q1,Q2);

assign repeater = keyBounce;

`ifdef NEGEDGE_BUTTON
	assign Q2Bar = ~Q2;
	assign keyDeBounce = Q1 & Q2Bar;
`else
	assign keyDeBounce = ~(~Q1 & Q2);
`endif

endmodule
// Slow clock enable for debouncing button 
module clockDiv(clk,keyBounce, clkEn);
input wire clk;
input wire keyBounce;
output wire clkEn;
localparam MAX	= 16'h0F;
localparam MIN	= 16'h00;
reg [15:0] counter = MIN;
`ifdef NEGEDGE_BUTTON
	always @(posedge clk, negedge keyBounce)
		begin
		if(keyBounce == 0)
			counter <= MIN;
		else
			counter <= (counter>=MAX) ? MIN : counter+1;
		end
		
		assign clkEn = (counter == MAX) ? 1'b1 : 1'b0;
`else
	always @(negedge clk,  posedge keyBounce)
		 begin
		 if(keyBounce == 1)
			  counter <= MIN;
		 else
			  counter <= (counter>=MAX) ? MIN : counter+1;
		 end
		
		 assign clkEn = (counter == MAX) ? 1'b0 : 1'b1;
`endif
endmodule

// D-flip-flop with clock enable signal for debouncing module 
module dff_en(clock, en, D, Q);
input wire clock; 
input wire en;
input wire D;
`ifdef NEGEDGE_BUTTON
	output reg Q = 1'd0;
		always @ (posedge clock)
		begin
			if(en == 1) 
				  Q <= D;
		end
`else
	output reg Q = 1'd1;
		 always @ (negedge clock)
		 begin
			  if(en == 0)
				  Q <= D;
		end
`endif
endmodule 
