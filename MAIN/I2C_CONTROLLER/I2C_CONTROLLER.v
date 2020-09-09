module I2C_CONTROLLER(
	wIsReady,
	wClk, wReset, wStart, wSend, wDatasend, wSended, wReceive, wDatareceive, wReceived,
	wAddress,
	wLoadAddress,
	wLength,
	wLoadLength,
	wControl,
	wLoadControl,
	wStatus,
	wToPut,
	wDataTo,
	wFromGet,
	wDataFrom
);

input		wire wIsReady;
input		wire wClk;
input		wire wReset;
output	wire wStart;
output	wire wSend;
output	wire [7:0] wDatasend;
input		wire wSended;
output	wire wReceive;
input		wire [7:0] wDatareceive;
input		wire wReceived;
input		wire [6:0] wAddress;
input		wire wLoadAddress;
input		wire [31:0] wLength;
input		wire wLoadLength;
input		wire [15:0] wControl;
input		wire wLoadControl;
output	wire [15:0] wStatus;
input		wire wToPut;
input		wire [7:0] wDataTo;
input		wire wFromGet;
output	wire [7:0] wDataFrom;


MASTER_DRIVER master_driver_block  (
// port map - connection between master ports and signals/registers   
	.isReady(wIsReady),
	.clk(wClk), 
	.reset(wReset), 
	.start(wStart), 
	.send(wSend), 
	.datasend(wDatasend), 
	.sended(wSended), 
	.receive(wReceive), 
	.datareceive(wDatareceive), 
	.received(wReceived),
	.address(wAddress),
	.loadAddress(wLoadAddress),
	.length(wLength),
	.loadLength(wLoadLength),
	.control(wControl),
	.loadControl(wLoadControl),
	.status(wStatus),
	.toPut(wToPut),
	.dataTo(wDataTo),
	.fromGet(wFromGet),
	.dataFrom(wDataFrom)
);



endmodule
