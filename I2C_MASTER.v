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
reg zscl	= 1;						//первод лини scl в состояние Z
reg rw	= 1;						//операция - поумолчанию чтение read = 1 write = 0
reg ask	= 1;						//подтверждение приема
reg waitSend	= 0;				//новая порция данных для отправки в ведомого
reg waitReceive	= 0;			//новая порция данных для приема с ведомого
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

//0.25MHz основная частота QUARTER8 - 2.5kHz HALF8 - 1.25kHz  scl период 0.4kHz
//0.25MHz основная частота QUARTER8 - 2.5kHz HALF8 - 1.25kHz  scl период 0.625kHz
//0.5MHz основная частота  QUARTER8 - 5kHz HALF8 - 2.5kHz  scl период 1.25kHz
//1MHz основная частота  QUARTER8 - 10kHz HALF8 - 5kHz  scl период 2.5kHz
//2MHz основная частота  QUARTER8 - 20kHz HALF8 - 10kHz scl период 5kHz
//4MHz основная частота  QUARTER8 - 40kHz HALF8 - 20kHz scl период 10kHz
localparam ZERO8						= 8'd0;
localparam ONE8						= 8'd1;
//clkScl 2.5kHz clk 1Mhz
//localparam QUARTER8					= 8'd99;
//localparam HALF8						= 8'd199;
//clkScl 5kHz clk 1Mhz
//localparam QUARTER8					= 8'd49;
//localparam HALF8						= 8'd99;
//clkScl 50kHz clk 5Mhz
//localparam QUARTER8					= 8'd24;
//localparam HALF8						= 8'd49;

//clkScl 100kHz clk 5Mhz
//localparam QUARTER8					= 8'd12;
//localparam HALF8						= 8'd24;
//clkScl 100kHz clk 25Mhz
localparam QUARTER8					= 8'd62;
localparam HALF8						= 8'd124;



//assign sda = (zsda) ? 1'bz : dsda;
//assign scl = (zscl) ? 1'bz : dscl;
assign sda = (zsda) ? 1'bz : 0;// 1'bz монтажное И поэтому тут не может быть высокого уровня
assign scl = (zscl) ? 1'bz : 0;// 1'bz монтажное И поэтому тут не может быть высокого уровня
assign ready = (stateSda == STATE_IDLE) ? 1 : 0;

always@(posedge clk)
begin
	if (!reset)
		begin
			stateSda	<= STATE_IDLE;
			zsda	<= 1;
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
			end			
			STATE_GET_SEND: begin	//осуществляем выборку данных
				if (stateScl == STATE_GET_SEND) 
					begin //ожидаем когда закончится этап подготовки данных
						stateSda <= STATE_SEND;
						count <= count - 4'd1;
					end
				if (datasend[count] == 1)
					zsda	<= 1;	
				else
					zsda	<= 0;	
				ask	<= 1;
			end
			STATE_SEND: begin
				if (stateScl == STATE_SEND) 
					begin //ожидаем когда закончится этап послыки данных
						if (count == 4'hF) 
							begin
								stateSda <= STATE_WAIT_ACK;
								count <= 4'd7;
								rw	<=	datasend[0];
							end
						else
							stateSda <= STATE_GET_SEND;
					end
			end
			STATE_WAIT_ACK: begin
				if (stateScl == STATE_ACK) 
					begin //ожидаем когда начнется этап приема данных подтверждения
						stateSda <= STATE_ACK;						
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
												zsda	<= 1;
											end
									end
								else	
									begin			//запись данных в ведомый										
										if (waitSend) 
											begin		
												if (datasend[count] == 1)
													zsda	<= 1;	
												else
													zsda	<= 0;	
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
					zsda	<= 0;	
			end
			STATE_WAIT_RESTART: begin
				if (stateScl == STATE_WAIT_RESTART) 
					begin
						stateSda <= STATE_RESTART;
						isRestarted <= 1;
					end
				else
					zsda	<= 1;
			end			
			STATE_RESTART: begin
				if (stateScl == STATE_RESTART) 
						stateSda <= STATE_GET_RECEIVE;
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
				zsda	<= 0;
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
			end
			endcase
		end
end

always@(negedge clk)
begin
	if (!reset)
		begin
			zscl	<= 1;
			stateScl <= STATE_IDLE;
			delay <= ZERO8;
		end
	else
		begin
			case (stateSda)
			STATE_IDLE: begin		
				zscl	<= 1;
				stateScl <= STATE_IDLE;
				delay <= ZERO8;
			end
			STATE_START: begin		
				if (delay == HALF8+QUARTER8) 
					begin //исходим из того что частота работы 100кГц берем интервал и просаживаем scl в ноль
						stateScl <= STATE_START;									
						delay <= QUARTER8;
					end
				else 
					delay <= delay + ONE8;
				if (delay < HALF8)
					zscl	<= 1;
				else
					zscl	<= 0;
			end	
			STATE_GET_SEND: begin
				if (delay == HALF8)
					begin 
						stateScl <= STATE_GET_SEND;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 0;
			end		
			STATE_SEND: begin		
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_SEND;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 1;
			end
			STATE_WAIT_ACK: begin
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_ACK;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 0;
			end
			STATE_ACK: begin
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_WAIT_SCL;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 1;		
			end
			STATE_WAIT_SCL: begin
				if (scl == 0) 
					begin
						delay <= ZERO8;
					end
				else 
					begin
						if (delay == HALF8) 
							begin //ждем пол периода прижатия слайвом нуля если прижал значит даем ему время на переработку байта
								stateScl <= STATE_SCL;
								delay <= ZERO8;
							end
						else
							delay <= delay + ONE8;
					end
				zscl	<= 1;		
			end
			STATE_WAIT_RESTART: begin
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_WAIT_RESTART;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				if (delay < QUARTER8)
					zscl	<= 0;
				else
					zscl	<= 1;// 1'bz монтажное И поэтому тут не может быть высокого уровня
			end
			STATE_RESTART: begin
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_RESTART;
						delay <= QUARTER8;
					end
				else
					delay <= delay + ONE8;
				if (delay < QUARTER8)
					zscl	<= 1;// 1'bz монтажное И поэтому тут не может быть высокого уровня
				else
					zscl	<= 0;
			end
			STATE_GET_RECEIVE: begin
				if (delay == HALF8)
					begin 
						stateScl <= STATE_GET_RECEIVE;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;	
				zscl	<= 0;
			end		
			STATE_RECEIVE: begin		
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_RECEIVE;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 1;
			end
			STATE_WAIT_GEN_ACK: begin		
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_WAIT_GEN_ACK;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 0;
			end
			STATE_GEN_ACK: begin		
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_GEN_ACK;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 1;
			end
			STATE_NO_GEN_ACK: begin		
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_NO_GEN_ACK;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 1;
			end				
			STATE_STOP: begin	
				if (delay == HALF8+QUARTER8) 
					begin 
						stateScl <= STATE_IDLE;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				if (delay < HALF8)
					zscl	<= 0;
				else
					zscl	<= 1;
			end
			endcase
		end
end

endmodule