//use only to load on board Chip
`define WITH_DEBOUNCE
//`undef WITH_DEBOUNCE
//`define DEBUG_SLAVE_DRIVER

module I2C_MASTER_SLAVE(
	receive,
	received,
	send,
	sended,
	clk, 
	reset, 
	ready, 
	scl, 
	sda,
	out,
	state
);

input 	wire clk;					//сигнал тактовой частоты
input 	wire reset;					//сигнал сброса

output	wire [7:0] out;			//данные
output	wire [7:0] state;			//данные
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


wire[7:0] slv_datasend;
wire slv_sended;
wire[7:0] slv_datareceive;
wire slv_received;

wire[5:0] startMaster;
wire[5:0] startSlave;
wire[5:0] _stateScl;

`ifdef WITH_DEBOUNCE
	wire resetDeBounce;

	DEBOUNCE resetKey( 
	.clk(clk), 
	.keyBounce(reset), 
	.keyDeBounce(resetDeBounce)
	);
`endif

I2C_MASTER I2C_MASTER(
	.clk(clk), 
`ifdef WITH_DEBOUNCE
	.reset(resetDeBounce), 
`else
	.reset(reset), 
`endif
	.start(start), 
	.ready(ready), 
	.sda(sda), 
	.scl(scl), 
	.send(send), 
	.datasend(datasend), 
	.sended(sended), 
	.receive(receive), 
	.datareceive(datareceive), 
	.received(received), 
	.state(startMaster)
);

I2C_SLAVE I2C_SLAVE (
.clk(clk), 
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
.received(slv_received),
.state(state), 
._stateScl(out)
);

`ifdef DEBUG_SLAVE_DRIVER
	wire[6:0] dstate;
`endif

SLAVE_DRIVER SLAVE_DRIVER (
`ifdef DEBUG_SLAVE_DRIVER
	.dstate(state), 
`endif
.clk(clk), 
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