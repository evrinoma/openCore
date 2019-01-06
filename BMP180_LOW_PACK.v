module BMP180_LOW_PACK(clk, reset, swId, swShow, start, send, datasend, receive, out);
input 	wire clk;					//сигнал тактовой частоты
input 	wire reset;					//сигнал сброса
input		wire swId;					//кнопка режим - прочитать ID чипа BMP180
input		wire swShow;				//кнопка режим - прочитать показать принятые данные
output wire start;
output wire send;
output wire [7:0] datasend;
output wire receive;
output	wire [7:0] out;			//данные

wire sended;
wire received;


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
	.out(out) //
);


SINGLE_GENERATOR SENDED (
// port map - connection between master ports and signals/registers   
	.clk(clk), //
	.start(send),
	.out(sended)
);
SINGLE_GENERATOR RECEIVED (
// port map - connection between master ports and signals/registers   
	.clk(clk), //
	.start(receive),
	.out(received)
);

endmodule
