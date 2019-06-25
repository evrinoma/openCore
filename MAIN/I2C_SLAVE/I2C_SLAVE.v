//use only to load on board Chip
`define WITH_DEBOUNCE
`define WITH_CLK_DIV
`define I2C_SLAVE_DEBUG
//`undef WITH_CLK_DIV
//`undef WITH_DEBOUNCE
//`undef I2C_SLAVE_DEBUG

module I2C_MASTER_SLAVE(
`ifdef I2C_SLAVE_DEBUG
	stateDA,
	stateDB,
	stateDC,
	stateDD,
	stateDE,
	stateDF,
`endif
	receive,
	received,
	send,
	sended,
	clk, 
	reset, 
	ready, 
	scl, 
	sda
);

input 	wire clk;					//сигнал тактовой частоты
input 	wire reset;					//сигнал сброса

output	wire ready;					//готовность контроллера I2C

inout 	sda;							//линия передачи данных I2C 
inout 	scl;							//сигнал тактирования I2C

wire [7:0] datareceive;
wire [7:0] datasend;
wire [6:0] address;

output wire receive;
output wire received;
output wire send;
output wire sended;

`ifdef I2C_SLAVE_DEBUG
output wire[5:0] stateDA;
output wire[5:0] stateDB;
output wire stateDC;
output wire stateDD;
output wire stateDE;
output wire stateDF;	
	`ifdef WITH_CLK_DIV		
			assign stateDF=div_clk;
	`endif
`endif

wire[7:0] slv_datasend;
wire slv_sended;
wire[7:0] slv_datareceive;
wire slv_received;

`ifdef WITH_CLK_DIV
wire div_clk;

DIV_CLK div(
	.clk(clk), 
	.freqMhz(div_clk)
);
`endif

`ifdef WITH_DEBOUNCE
	wire resetDeBounce;

	DEBOUNCE resetKey( 
	`ifdef WITH_CLK_DIV
		.clk(div_clk), 
	`else
		.clk(clk), 
	`endif
	.keyBounce(reset), 
	.keyDeBounce(resetDeBounce)
	);
`endif



I2C_SLAVE I2C_SLAVE (
`ifdef I2C_SLAVE_DEBUG
	.stateDSda(stateDA), 
	.stateDFSM(stateDB),
	.stateDTopSda(stateDC),
	.stateDBottomSda(stateDD),
	.stateDzsda(stateDE),
`endif
`ifdef WITH_CLK_DIV
	.clk(div_clk), 
`else
	.clk(clk), 
`endif
`ifdef WITH_DEBOUNCE
	.reset(resetDeBounce), 
`else
	.reset(reset), 
`endif
.sda(sda), 
.scl(scl), 
.address(address),
.datasend(slv_datasend), 
.sended(slv_sended), 
.datareceive(slv_datareceive), 
.received(slv_received)
);

SLAVE_DRIVER SLAVE_DRIVER (
`ifdef WITH_CLK_DIV
	.clk(div_clk), 
`else
	.clk(clk), 
`endif
`ifdef WITH_DEBOUNCE
	.reset(resetDeBounce), 
`else
	.reset(reset), 
`endif
.address(address), 
.datasend(slv_datasend), 
.sended(slv_sended), 
.datareceive(slv_datareceive), 
.received(slv_received)
);

endmodule
