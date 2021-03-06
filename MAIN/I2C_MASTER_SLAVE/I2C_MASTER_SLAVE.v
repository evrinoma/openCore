//use only to load on board Chip
`define WITH_DEBOUNCE
//`undef WITH_DEBOUNCE

module I2C_MASTER_SLAVE(
	receive,
	received,
	send,
	sended,
	swId,
	swShow,
	clk,
	reset, 
	ready, 
	scl, 
	sda,
	out,
	state
);
input		wire swId;					//кнопка режим - прочитать ID чипа BMP180
input		wire swShow;				//кнопка режим - прочитать показать принятые данные

input 	wire clk;					//сигнал тактовой частоты
input 	wire reset;					//сигнал сброса

output	wire [7:0] out;			//данные
output	wire [5:0] state;			//данные
wire [7:0] stateMaster;			//данные
wire [5:0] stateSlave;			//данные
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
wire clk_slave;

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
	.received(received)
);

MASTER_DRIVER MASTER_DRIVER (
// port map - connection between master ports and signals/registers   
        .clk(clk), //
        .datareceive(datareceive),
        .datasend(datasend), 
        .receive(receive),
        .received(received),
        .send(send),
        .sended(sended),
        .start(start),
`ifdef WITH_DEBOUNCE
        .reset(resetDeBounce), 
        .swId(swIdDeBounce), 
        .swShow(swShowDeBounce),
`else
		  .swId(swId), 
        .swShow(swShow), 
        .reset(reset),

`endif
        .isReady(ready),
        .out(out), 
        .state(stateMaster)
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
.received(slv_received)
);

SLAVE_DRIVER SLAVE_DRIVER (
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
