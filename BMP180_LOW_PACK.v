module BMP180_LOW_PACK(clk, reset, wsPush, wsSend, swId, swShow, start, send, datasend, receive, out, stateOut, sended, received);
input 	wire clk;					//сигнал тактовой частоты
input 	wire reset;					//сигнал сброса
input		wire swId;					//кнопка режим - прочитать ID чипа BMP180
input		wire swShow;				//кнопка режим - прочитать показать принятые данные
input		wire wsPush;
input		wire wsSend;
output wire start;
output wire send;
output wire [7:0] datasend;
output wire receive;
output wire [7:0] out;			//данные
output wire [3:0] stateOut;

output wire sended;
output wire received;
//wire invPush;
//wire invSend;

// assign statements (if any)                          
BMP180_LOW BMP180_LOW (
// port map - connection between master ports and signals/registers   
	.clk(clk), //
	.reset(reset), 
	.swId(swId), //
	.swShow(swShow), //
	
	.sended(sended),	
	.datareceive(datasend),
	.received(received),
	
	.start(start),
	.send(send),
	.datasend(datasend),
	.receive(receive),
	.out(out), //
	.stateOut(stateOut)
);
//
//MY_NOT NOT_PUSH (
//	.IN(wsPush),
//	.OUT(invPush)
//);
//
//MY_NOT NOT_SEND (
//	.IN(wsSend),
//	.OUT(invSend)
//);
//shift SENDED (
//// port map - connection between master ports and signals/registers   
//	.clk(clk), //
//	.start(sended),
//	.run(wsSend)
//);
//shift RECEIVED (
//// port map - connection between master ports and signals/registers   
//	.clk(clk), //
//	.start(received),
//	.run(wsPush)
//);

SINGLE_GENERATOR SENDED (
// port map - connection between master ports and signals/registers   
	.clk(clk), //
	.start(wsSend),
	.reset(reset),
	.out(sended)
);
SINGLE_GENERATOR RECEIVED (
// port map - connection between master ports and signals/registers   
	.clk(clk), //
	.start(wsPush),
	.reset(reset),
	.out(received)
);

endmodule
