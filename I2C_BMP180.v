//use only to load on board Chip
`define WITH_DEBOUNCE
//`undef WITH_DEBOUNCE

`define FULL_QUERY_BMP180
`undef FULL_QUERY_BMP180

module I2C_BMP180(
	receive,
	received,
	send,
	sended,
	swId, 
	swShow,	
`ifdef FULL_QUERY_BMP180
	swSettings, swTemp, swGTemp, swPress, swGPress, 
`endif
	clk, 
	reset, 
	out, 
	ready, 
	scl, 
	sda,
	state,
	pinout,
	pinout2
);

input		wire swId;					//кнопка режим - прочитать ID чипа BMP180
input		wire swShow;				//кнопка режим - прочитать показать принятые данные

`ifdef FULL_QUERY_BMP180
	input		wire swSettings;			//кнопка режим - прочитать коэфициенты чипа BMP180
	input		wire swTemp;				//кнопка режим - переключить режим на получение температуры
	input		wire swGTemp;				//кнопка режим - прочитать температуру
	input		wire swPress;				//кнопка режим - прочитать режим на получение давления
	input		wire swGPress;				//кнопка режим - прочитать давление
`endif

input 	wire clk;					//сигнал тактовой частоты
input 	wire reset;					//сигнал сброса

output	wire [7:0] out;			//данные
output	wire ready;					//готовность контроллера I2C

inout 	sda;							//линия передачи данных I2C 
inout 	scl;							//сигнал тактирования I2C

wire [7:0] datareceive;
wire [7:0] datasend;

output wire[5:0] state;
output wire receive;
output wire received;
output wire send;
output wire sended;

output wire pinout;
output wire pinout2;

wire startIC;

`ifdef WITH_DEBOUNCE
	wire resetDeBounce;
	wire swIdDeBounce;
	wire swShowDeBounce;
	
	assign pinout = swIdDeBounce;
	assign pinout2 = swShowDeBounce;
	
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

// assign statements (if any)                          
BMP180 BMP180 (
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
	`ifdef FULL_QUERY_BMP180
		.swPress(swPress), 
		.swGTemp(swGTemp), 
		.swGPress(swGPress), 
		.swSettings(swSettings),
		.swTemp(swTemp), 
	`endif
`endif
	.isReady(ready),
	.out(out), 
	.state(state)
);

endmodule
