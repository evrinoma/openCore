module I2C_BMP180(
receive,
received,
send,
sended,
swId, swSettings, swTemp, swGTemp, swPress, swGPress, swShow, 
clk, 
reset, 
out, 
ready, 
scl, 
sda,
state,
stateStart,
stateBMP,
resetOut
);

input		wire swId;					//кнопка режим - прочитать ID чипа BMP180
input		wire swSettings;			//кнопка режим - прочитать коэфициенты чипа BMP180
input		wire swTemp;				//кнопка режим - переключить режим на получение температуры
input		wire swGTemp;				//кнопка режим - прочитать температуру
input		wire swPress;				//кнопка режим - прочитать режим на получение давления
input		wire swGPress;				//кнопка режим - прочитать давление
input		wire swShow;				//кнопка режим - прочитать показать принятые данные

input 	wire clk;					//сигнал тактовой частоты
input 	wire reset;					//сигнал сброса

output	wire [7:0] out;			//данные
output	wire ready;					//готовность контроллера I2C

inout 	sda;							//линия передачи данных I2C 
inout 	scl;							//сигнал тактирования I2C

wire [7:0] datareceive;
wire [7:0] datasend;
output wire[5:0] state;
output wire stateStart;
output wire[5:0] stateBMP;
output wire receive;
output wire received;
output wire send;
output wire sended;
output wire resetOut;
wire start;

assign resetOut = reset;

I2C_MASTER I2C_MASTER(
.clk(clk), 
.reset(reset), 
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
.state(state),
.stateStart(stateStart)
);

// assign statements (if any)                          
BMP180 BMP180 (
// port map - connection between master ports and signals/registers   
	.clk(clk), //
	.datareceive(out),
	.datasend(datasend), //datasend
	.receive(receive),
	.received(received),
	.reset(reset), //
	.send(send),
	.sended(sended),
	.start(start),
	.swId(swId), //
	.swPress(swPress), //
	.swGTemp(swGTemp), // 
	.swGPress(swGPress), //
	.swSettings(swSettings), //
	.swShow(swShow), //
	.swTemp(swTemp), //
	.isReady(ready),
	.out(datareceive),
	.state(stateBMP)
);

endmodule
