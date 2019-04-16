//use only to load on board Chip
`define WITH_DEBOUNCE
`undef WITH_DEBOUNCE

`define FULL_QUERY_BMP180
`undef FULL_QUERY_BMP180

module I2C_MASTER_SLAVE(
	receive,
	received,
	send,
	sended,
	clk, 
	reset, 
	out, 
	ready, 
	scl, 
	sda
);

input 	wire clk;					//сигнал тактовой частоты
input 	wire reset;					//сигнал сброса

output	wire [7:0] out;			//данные
output	wire ready;					//готовность контроллера I2C

inout 	sda;							//линия передачи данных I2C 
inout 	scl;							//сигнал тактирования I2C

wire [7:0] datareceive;
wire [7:0] datasend;
wire [6:0] address;

wire[5:0] state;
output wire receive;
output wire received;
output wire send;
output wire sended;


wire[7:0] slv_datasend;
wire slv_sended;
wire[7:0] slv_datareceive;
wire slv_received;

wire startIC;

`ifdef WITH_DEBOUNCE
	wire resetDeBounce;
	wire swIdDeBounce;
	wire swShowDeBounce;

	DEBOUNCE resetKey( 
	.clk(clk), 
	.keyBounce(reset), 
	.keyDeBounce(resetDeBounce)
	);
	
	DEBOUNCE swIdKey( 
	.clk(clk), 
	.keyBounce(swId), 
	.keyDeBounce(swIdDeBounce)
	);
	
	DEBOUNCE swShowKey( 
	.clk(clk), 
	.keyBounce(swShow), 
	.keyDeBounce(swShowDeBounce)
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
	.state(stateIC)
);

I2C_SLAVE I2C_SLAVE (
.clk(clk), 
.reset(reset), 
.sda(sda), 
.scl(scl), 
.address(address),
.datasend(slv_datasend), 
.sended(slv_sended), 
.datareceive(slv_datareceive), 
.received(slv_received)
);

SLAVE_DRIVER SLAVE_DRIVER (
.clk(clk), 
.reset(reset), 
.address(address), 
.datasend(slv_datasend), 
.sended(slv_sended), 
.datareceive(slv_datareceive), 
.received(slv_received)
);

endmodule
