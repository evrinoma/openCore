module FIFO(clk, reset, dataIn, dataOut,put,get, isFull,isEmpty);
parameter FIFO_SIZE_EXP = 2;					//размер буфера
parameter FIFO_SIZE = 1<<FIFO_SIZE_EXP;	//FIFO_SIZE = 2^FIFO_SIZE_EXP
parameter SIZE = 7;								//SIZE SAVE ITEM

input wire clk;									//тактовая частота
input wire reset;									//сброс буфера
input wire [SIZE:0]dataIn;						//входной регистр
output reg [SIZE:0]dataOut;					//выходной регистр
input wire put;									//сигнал положить байт из входного регистра в буфер
input wire get;									//сигнал загрузить байт из буфера в выходной регистр
output reg isFull = 0;							//буфер заполнен
output reg isEmpty = 1;							//буфер пуст
  
reg [SIZE:0]fifo[0:(FIFO_SIZE-1)];			//буфер
reg [(FIFO_SIZE_EXP-1):0]pointStart = 0;	//индекс начала буфера
reg [(FIFO_SIZE_EXP-1):0]pointEnd = 0;		//индекс конца буфера
reg lastGet = 0;
reg lastPut = 0;

always @(posedge clk) 
begin
if(!reset)
		begin
			 dataOut <= 0;
			 pointEnd <= 0;
			 pointStart <= 0;
			 isFull <= 0;
			 isEmpty <= 1;
		end 
else 
		begin
			 if((lastPut == 0) && (put == 1) && (!isFull)) 
				 begin 
							fifo[pointEnd] <= dataIn;
							pointEnd = pointEnd + 1;
							isEmpty <= 0;
							if(pointEnd == pointStart)
									  isFull <= 1;
				 end
			 if((lastGet == 0) && (get == 1) && (!isEmpty)) 
				 begin
							dataOut <= fifo[pointStart];
							pointStart = pointStart + 1;
							isFull <= 0;
							if(pointEnd == pointStart)
									  isEmpty <= 1;
				 end
			 lastPut = put;
			 lastGet = get;
		end
end

endmodule

