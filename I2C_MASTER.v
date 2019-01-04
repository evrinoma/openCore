module I2C_MASTER(clk, reset, start, ready, sda, scl, send, datasend, sended, receive, datareceive, received);
input wire clk;					//сигнал тактовой частоты
input wire reset;					//сигнал сброса
input wire start;					//запустить транзакцию
output wire ready;				//готовность контроллера I2C

inout sda;							//линия передачи данных I2C 
inout scl;							//сигнал тактирования I2C

input	wire send;					//отправить новую порцию данных до тех пор пока истинно
input wire [7:0] datasend;		//адрес и данные, которые шлем в устройство,  а так же тут задаем тип операции - чтения или записи данных
output reg sended;				//сигнал записи новой порции данных при много байтном обмене

input	wire receive;				//принять новую порцию данных до тех пор пока истинно
output reg[7:0] datareceive;	//регистр принятых данных по шине - полученый байт
output reg received;				//готовность полученого байта для выгрузки

reg zsda	= 1;						//первод лини sda в состояние Z
reg dsda = 1;						//данные выставляемые на линию sda
reg zscl	= 1;						//первод лини scl в состояние Z
reg dscl = 1;						//данные выставляемые на линию scl
reg rw	= 1;						//операция - поумолчанию чтение read = 1 write = 0
reg ask	= 1;						//подтверждение приема
reg waitSend	= 0;				//новая порция данных для отправки в ведомого
reg waitReceive	= 0;				//новая порция данных для приема с ведомого
reg isRestarted	= 0;			//передача перезапущена на прием данных

reg[3:0]	count;					//счетчик пересылаемых байт
reg[7:0]	delay;					//делитель входной частоты

reg[3:0] stateSda;				//состояние линии sda
reg[3:0] stateScl;				//состояние линии scl

//состояния
localparam STATE_IDLE				= 4'd0;
localparam STATE_START				= 4'd1;
localparam STATE_GET_SEND			= 4'd2;
localparam STATE_SEND				= 4'd3;
localparam STATE_WAIT_ACK			= 4'd4;
localparam STATE_ACK					= 4'd5;
localparam STATE_WAIT_SCL			= 4'd6;
localparam STATE_SCL					= 4'd7;
localparam STATE_STOP				= 4'd8;
localparam STATE_GET_RECEIVE		= 4'd9;
localparam STATE_RECEIVE			= 4'd10;
localparam STATE_WAIT_RESTART		= 4'd11;
localparam STATE_RESTART			= 4'd12;
localparam STATE_WAIT_GEN_ACK		= 4'd13;
localparam STATE_GEN_ACK			= 4'd14;
localparam STATE_NO_GEN_ACK		= 4'd15;


assign sda = (zsda) ? 1'bz : dsda;
assign scl = (zscl) ? 1'bz : dscl;
assign ready = (stateSda	== STATE_IDLE) ? 1 : 0;

always@(posedge clk)
begin
	if (!reset)
		begin
			stateSda	<= STATE_IDLE;
			zsda	<= 1;
			dsda	<= 1;
			rw		<= 0;
			ask	<= 1;
			sended<= 0;
			isRestarted <= 0;
			count <= 4'd7;
			datareceive <= 8'd0;
			received<= 0;
			waitSend<= 1'b0;
			waitReceive<= 1'b0;
		end
	else
		begin
			case (stateSda)
			STATE_IDLE: begin
				if (!start) 
					begin
						stateSda <= STATE_START;						
					end
				else
					begin
						stateSda <= STATE_IDLE;
					end
				zsda	<= 1;
				dsda	<= 1;				
				ask	<= 1;
				sended<= 0;
				isRestarted <= 0;
				received<= 0;
				count <= 4'd7;
				rw		<= 0;
				waitSend<= 1'b0;
				waitReceive<= 1'b0;
			end
			STATE_START: begin		//начальная последовательность sda = 0 scl = 1 задержка sda = 0 scl = 0
				if (stateScl == STATE_START) 
					begin //ожидаем когда закончится этап старта
						stateSda <= STATE_GET_SEND;	
					end
				zsda	<= 0;
				dsda	<= 0;
				count <= 4'd7;				
			end			
			STATE_GET_SEND: begin	//осуществляем выборку данных
				if (stateScl == STATE_GET_SEND) 
					begin //ожидаем когда закончится этап подготовки данных
						stateSda <= STATE_SEND;
						count <= count - 4'd1;
					end
				dsda	<= datasend[count];
			end
			STATE_SEND: begin
				if (stateScl == STATE_SEND) 
					begin //ожидаем когда закончится этап послыки данных
						if (count == 4'hF) 
							begin
								stateSda <= STATE_WAIT_ACK;
								count <= 4'd7;
							end
						else
							stateSda <= STATE_GET_SEND;
					end
				zsda	<= 0;
			end
			STATE_WAIT_ACK: begin
				if (stateScl == STATE_ACK) 
					begin //ожидаем когда начнется этап приема данных подтверждения
						stateSda <= STATE_ACK;
						rw	<=	datasend[0];
					end
				zsda	<= 1;	
			end
			STATE_ACK: begin
				if (sda == 0) 
					begin
						ask	<= 0;
					end
				if (stateScl == STATE_WAIT_SCL ) 
					begin //переходим в этап опроса лини scl если вдруг наш ведомый не успеет обработать данные он об этом сообщит
						stateSda <= STATE_WAIT_SCL;
						sended <= 0;
						count <= 4'd7;
					end
				else
					sended <= 1;
				if (send)
					waitSend<= 1'b1;
				if (receive)
					waitReceive<= 1'b1;
				zsda	<= 1;			
			end
			STATE_WAIT_SCL: begin	
				if (stateScl == STATE_SCL) 
					begin //ожидаем этап когда будем уверены в ведомый справился с порцией данных					
						if (!ask) 
							begin		//если пришло подтвреждение от ведомого
								if (rw)				//чтение данных из ведомого
									begin
										if (isRestarted)
											begin
												stateSda <= STATE_GET_RECEIVE;
											end
										else
											begin
												stateSda <= STATE_WAIT_RESTART;//STATE_RECEIVE;
												dsda	<= 1;
											end
									end
								else	
									begin			//запись данных в ведомый										
										if (waitSend) 
											begin						
												dsda	<= datasend[count];
												//count <= count - 4'd1;
												waitSend <= 1'b0;
												stateSda <= STATE_GET_SEND;
											end
										else
											stateSda <= STATE_STOP;
									end
							end
						else						//если не пришло подтвреждение от ведомого то заканчиваем посылку
							stateSda <= STATE_STOP;
					end
				else 
					dsda	<= 0;
				zsda	<= 0;	
			end
			STATE_WAIT_RESTART: begin
				if (stateScl == STATE_WAIT_RESTART) 
					begin
						stateSda <= STATE_RESTART;
						isRestarted <= 1;
					end
				else
					dsda	<= 1;
				zsda	<= 0;	
			end			
			STATE_RESTART: begin
				if (stateScl == STATE_RESTART) 
						stateSda <= STATE_GET_RECEIVE;
				dsda	<= 0;
				zsda	<= 0;	
			end	
			STATE_GET_RECEIVE: begin	//осуществляем считывание данных с ведомого
				if (stateScl == STATE_GET_RECEIVE) 
					begin //ожидаем когда закончится этап подготовки данных ведомым
						stateSda <= STATE_RECEIVE;
						datareceive[count] <= 1;	
					end
				zsda	<= 1;
			end			
			STATE_RECEIVE: begin
				if (stateScl == STATE_RECEIVE) 
					begin //ожидаем когда закончится этап считывание данных с ведомого
						if (count == 4'h0) 
							begin
								stateSda <= STATE_WAIT_GEN_ACK;
								waitReceive<= 1'b0;
								count <= 4'd7;
							end
						else
							begin
								stateSda <= STATE_GET_RECEIVE;
								count <= count - 4'd1;
							end
					end
				if (sda == 0) 
					begin
						datareceive[count] <= 0;
					end
				zsda	<= 1;
			end
			STATE_WAIT_GEN_ACK: begin
				if (stateScl == STATE_WAIT_GEN_ACK ) 
					begin 
						if (waitReceive) 
							stateSda <= STATE_GEN_ACK;
						else 						
							stateSda <= STATE_NO_GEN_ACK;						
					end
				if (receive)
					waitReceive<= 1'b1;
				received	<= 1;
				zsda	<= 1;
				dsda	<= 0;	
			end	
			STATE_GEN_ACK: begin
				if (stateScl == STATE_GEN_ACK ) 
					begin 
						stateSda <= STATE_GET_RECEIVE;											
					end
				received	<= 0;	
				zsda	<= 0;
			end		
			STATE_NO_GEN_ACK: begin
				if (stateScl == STATE_NO_GEN_ACK ) 
					begin 
						stateSda <= STATE_STOP;
					end
				received	<= 0;
				zsda	<= 1;
			end					
			STATE_STOP: begin	
				if (stateScl == STATE_IDLE)
					begin
						stateSda <= STATE_IDLE;
					end
				zsda	<= 0;
				dsda	<= 0;
			end
			endcase
		end
end

always@(negedge clk)
begin
	if (!reset)
		begin
			zscl	<= 0;
			dscl	<= 1;	
			stateScl <= STATE_IDLE;
			delay <= 8'd0;
		end
	else
		begin
			case (stateSda)
			STATE_IDLE: begin		
				zscl	<= 0;
				dscl	<= 1;
				stateScl <= STATE_IDLE;
				delay <= 8'd0;
			end
			STATE_START: begin		
				if (delay == 8'd200) 
					begin //исходим из того что частота работы 400кГц берем пол интервала и просаживаем scl в ноль
						stateScl <= STATE_START;									
						delay <= 8'd100;
					end
				else 
					delay <= delay + 8'd1;
				if (delay < 8'd100)
					dscl	<= 1;
				else
					dscl	<= 0;
				zscl	<= 0;
			end	
			STATE_GET_SEND: begin
				if (delay == 8'd200)
					begin 
						stateScl <= STATE_GET_SEND;
						delay <= 8'd0;
					end
				else
					delay <= delay + 8'd1;
				dscl	<= 0;
				zscl	<= 0;
			end		
			STATE_SEND: begin		
				if (delay == 8'd200) 
					begin 
						stateScl <= STATE_SEND;
						delay <= 8'd0;
					end
				else
					delay <= delay + 8'd1;
				dscl	<= 1;
				zscl	<= 0;
			end
			STATE_WAIT_ACK: begin
				if (delay == 8'd200) 
					begin 
						stateScl <= STATE_ACK;
						delay <= 8'd0;
					end
				else
					delay <= delay + 8'd1;
				dscl	<= 0;
				zscl	<= 0;
			end
			STATE_ACK: begin
				if (delay == 8'd200) 
					begin 
						stateScl <= STATE_WAIT_SCL;
						delay <= 8'd0;
					end
				else
					delay <= delay + 8'd1;
				dscl	<= 1;
				zscl	<= 0;		
			end
			STATE_WAIT_SCL: begin
				if (scl == 0) 
					begin
						delay <= 8'd0;
					end
				else 
					begin
						if (delay == 8'd200) 
							begin //ждем пол периода прижатия слайвом нуля если прижал значит даем ему время на переработку байта
								stateScl <= STATE_SCL;
								delay <= 8'd0;
							end
						else
							delay <= delay + 8'd1;
					end
				zscl	<= 1;		
			end
			STATE_WAIT_RESTART: begin
				if (delay == 8'd200) 
					begin 
						stateScl <= STATE_WAIT_RESTART;
						delay <= 8'd0;
					end
				else
					delay <= delay + 8'd1;
				if (delay < 8'd100)
					dscl	<= 0;
				else
					dscl	<= 1;
				zscl	<= 0;
			end
			STATE_RESTART: begin
				if (delay == 8'd200) 
					begin 
						stateScl <= STATE_RESTART;
						delay <= 8'd100;
					end
				else
					delay <= delay + 8'd1;
				if (delay < 8'd100)
					dscl	<= 1;
				else
					dscl	<= 0;
				zscl	<= 0;
			end
			STATE_GET_RECEIVE: begin
				if (delay == 8'd200)
					begin 
						stateScl <= STATE_GET_RECEIVE;
						delay <= 8'd0;
					end
				else
					delay <= delay + 8'd1;
				dscl	<= 0;
				zscl	<= 0;
			end		
			STATE_RECEIVE: begin		
				if (delay == 8'd200) 
					begin 
						stateScl <= STATE_RECEIVE;
						delay <= 8'd0;
					end
				else
					delay <= delay + 8'd1;
				dscl	<= 1;
				zscl	<= 0;
			end
			STATE_WAIT_GEN_ACK: begin		
				if (delay == 8'd200) 
					begin 
						stateScl <= STATE_WAIT_GEN_ACK;
						delay <= 8'd0;
					end
				else
					delay <= delay + 8'd1;
				dscl	<= 0;
				zscl	<= 0;
			end
			STATE_GEN_ACK: begin		
				if (delay == 8'd200) 
					begin 
						stateScl <= STATE_GEN_ACK;
						delay <= 8'd0;
					end
				else
					delay <= delay + 8'd1;
				dscl	<= 1;
				zscl	<= 0;
			end
			STATE_NO_GEN_ACK: begin		
				if (delay == 8'd200) 
					begin 
						stateScl <= STATE_NO_GEN_ACK;
						delay <= 8'd0;
					end
				else
					delay <= delay + 8'd1;
				dscl	<= 1;
				zscl	<= 0;
			end				
			STATE_STOP: begin	
				if (delay == 8'd200) 
					begin 
						stateScl <= STATE_IDLE;
						delay <= 8'd0;
					end
				else
					delay <= delay + 8'd1;
				if (delay < 8'd100)
					dscl	<= 0;
				else
					dscl	<= 1;
				zscl	<= 0;
			end
			endcase
		end
end

endmodule
