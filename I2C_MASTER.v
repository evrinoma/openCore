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

reg[4:0] stateSda;				//состояние линии sda
reg[4:0] stateScl;				//состояние линии scl
reg[1:0] stateStart;				//состояние перехода в режим start илии restart

localparam START_IDLE_0	= 2'd0;
localparam START_1		= 2'd1;
localparam RESTART_2		= 2'd2;


//состояния
localparam STATE_IDLE_0				= 5'd0;
localparam STATE_START_1				= 5'd1;
localparam STATE_PREPARE_SEND_2		= 5'd2;
localparam STATE_SEND_3				= 5'd3;

localparam STATE_WAIT_ACK_4			= 5'd4;
localparam STATE_ACK_5					= 5'd5;
//localparam STATE_WAIT_SCL			= 5'd6;
//localparam STATE_SCL					= 5'd7;
localparam STATE_STOP_8				= 5'd8;

localparam STATE_PREPARE_RECEIVE_9	= 5'd9;
localparam STATE_RECEIVE_10			= 5'd10;

localparam STATE_WAIT_RESTART_11		= 5'd11;
localparam STATE_RESTART_12			= 5'd12;

localparam STATE_WAIT_GEN_ACK_13		= 5'd13;
localparam STATE_GEN_ACK_14			= 5'd14;
localparam STATE_NO_GEN_ACK_15		= 5'd15;


localparam STATE_START_PREPARE_SEND_13		= 5'd13;
localparam STATE_START_SEND_14			= 5'd14;
localparam STATE_START_WAIT_ACK_15		= 5'd15;
localparam STATE_START_ACK_16		= 5'd16;

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
assign ready = (stateSda == STATE_IDLE_0) ? 1 : 0;


always@(posedge clk)
begin
	if (!reset)
		begin
			stateStart	<= START_IDLE_0;
		end
	else
		begin
			if (start) 
				begin
					stateStart <= START_1;								
				end
			else
				begin
					if (stateSda == STATE_START_1 || stateSda == STATE_RESTART_12)
						begin
							stateStart <= START_IDLE_0;
						end
				end
		end
end 
		
always@(posedge clk)
begin
	if (!reset)
		begin
			stateSda	<= STATE_IDLE_0;
			zsda	<= 1;
			rw		<= 0;
			ask	<= 1;
			sended<= 0;
		
			count <= 4'd7;
			datareceive <= 8'd0;
			received<= 0;
			waitSend<= 1'b0;
			waitReceive<= 1'b0;
		end
	else
		begin
			case (stateSda)
			STATE_IDLE_0: begin
				if (stateStart == START_1) 
					begin
						stateSda <= STATE_START_1;						
					end
				else
					begin
						stateSda <= STATE_IDLE_0;
					end
				zsda	<= 1;								//линия sda в состоянии z
				count <= 4'd7;							//счетчик передачи бит указывает на старший бит, так с него начинаем передачу данных
				rw		<= 0;								//поумолчанию записываем в устройство
				ask	<= 1;								//сбрасываем бит подтвержедния приема данных ведомым
				
				sended<= 0;								//сбрасываем сигнал уведомелния о передачи порции данных
				received<= 0;							//сбрасываем сигнал уведомления о приеме порции данных
				waitSend<= 1'b0;						//сбрасываем сигнал передачи в ведомого новой порции данных
				waitReceive<= 1'b0;					//сбрасываем сигнал приема с ведомого новой порции данных
			
			end
			STATE_START_1: begin						//начальная последовательность sda = 0 scl = 1 задержка sda = 0 scl = 0 задержка
				if (stateScl == STATE_START_1) 
					begin 								//ожидаем когда закончится этап старта
						stateSda <= STATE_START_PREPARE_SEND_13;	
						rw	<=	datasend[0];				//устанавливаем режим чтение или запись						
					end
				zsda	<= 0;	
				sended<= 0;								//сбрасываем сигнал уведомелния о передачи порции данных
				received<= 0;							//сбрасываем сигнал уведомления о приеме порции данных
			end	
			STATE_WAIT_RESTART_11: begin
				 if (stateScl == STATE_WAIT_RESTART_11) 
					begin
						stateSda <= STATE_RESTART_12;
					end
				zsda    <= 1;
			end  
			STATE_RESTART_12: begin
				if (stateScl == STATE_RESTART_12) 
					begin 								//ожидаем когда закончится этап старта
						stateSda <= STATE_START_PREPARE_SEND_13;	
						rw	<=	datasend[0];			//устанавливаем режим чтение или запись						
					end
				zsda	<= 0;	
				sended<= 0;								//сбрасываем сигнал уведомелния о передачи порции данных
				received<= 0;							//сбрасываем сигнал уведомления о приеме порции данных  
			end    		
			STATE_START_PREPARE_SEND_13: begin	//осуществляем выборку данных
				if (stateScl == STATE_START_PREPARE_SEND_13) 
					begin 								//ожидаем когда закончится этап подготовки данных
						stateSda <= STATE_START_SEND_14;
						count <= count - 4'd1;		//уменьшаем счетчик передачи бит 
					end
				if (datasend[count] == 1)			//переключаем линию sda в ноль, если отправляемый бит равен нулю
					zsda	<= 1;	
				else
					zsda	<= 0;	
			end
			STATE_START_SEND_14: begin
				if (stateScl == STATE_START_SEND_14) 
					begin 											//ожидаем когда закончится этап послыки данных
						if (count == 4'hF) 						//если мы отправили все биты с 7 по 0, то устанавливаем счетчик передачи бит на старший бит
							begin
								stateSda <= STATE_START_WAIT_ACK_15;	//преходим в состояние приема ответа ACK или NACK
								count <= 4'd7;
							
							end
						else
							stateSda <= STATE_START_PREPARE_SEND_13; //преходим в состояние подготовки данных к отправке
					end
			end
			STATE_START_WAIT_ACK_15: begin
				if (stateScl == STATE_START_WAIT_ACK_15) 
					begin 										//ожидаем когда начнется этап приема данных подтверждения
						stateSda <= STATE_START_ACK_16;
					end
				zsda	<= 1;
				sended <= 1;									//выставляем сигнал уведомления о передачи порции данных - готовность устройства к принятию новой порции данных	
			end
			STATE_START_ACK_16: begin
				if (stateScl == STATE_START_ACK_16 ) 
					begin 				
						if (!ask) 
							begin									//если пришло подтвреждение от ведомого
								if (stateStart == START_1) 
									begin
										stateSda <= STATE_WAIT_RESTART_11;						
									end
								else
									begin
										if (rw)							//чтение данных из ведомого
											begin						
												if (waitReceive) 			
													begin	
														waitReceive <= 1'b0;						//сбрасываем сигнал передачи в ведомого новой порции данных
														stateSda <= STATE_PREPARE_RECEIVE_9;//переходим в состояние подготовки к отправке новой порции данных
													end
												else
													stateSda <= STATE_STOP_8;					//если пришло подтвреждение от ведомого, а посылать больше нечего, то заканчиваем отправку
											end
										else	
											begin							//запись данных в ведомый	
												if (waitSend) 			
													begin	
														waitSend <= 1'b0;							//сбрасываем сигнал передачи в ведомого новой порции данных
														stateSda <= STATE_START_PREPARE_SEND_13;	//переходим в состояние подготовки к отправке новой порции данных
													end
												else
													stateSda <= STATE_STOP_8;					//если пришло подтвреждение от ведомого, а посылать больше нечего, то заканчиваем отправку
											end
									end
							end
						else																	//если не пришло подтвреждение от ведомого, то заканчиваем посылку
							stateSda <= STATE_STOP_8;						
					end
				else
					begin
						if (sda == 0) 			//фиксируем наличие низкого уровня на линии sda
							ask <= 0;		
					
						//внешний источник должен выставлять сигналы send или receive так как нельзя положиться на анализ бита rw
						if (send)				//фиксируем наличие высокого уровея на линии send, дополнительная порция информации будет отправлена в ведомый
							waitSend <= 1'b1;							
						if (receive)			//фиксируем наличие высокого уровня на линии receive, дополнительная порция информации будет принята с ведомого
							waitReceive <= 1'b1;
					end
					
				sended<= 0;								//сбрасываем сигнал уведомелния о передачи порции данных
				received<= 0;							//сбрасываем сигнал уведомления о приеме порции данных
				zsda	<= 1;			
			end 



			STATE_PREPARE_RECEIVE_9: begin	//осуществляем считывание данных с ведомого
				if (stateScl == STATE_PREPARE_RECEIVE_9) 
					begin 						//ожидаем когда закончится этап подготовки данных ведомым
						stateSda <= STATE_RECEIVE_10;
						datareceive[count] <= 1;	
					end
				zsda	<= 1;
			end			
			STATE_RECEIVE_10: begin
				if (stateScl == STATE_RECEIVE_10) 
					begin 								//ожидаем когда закончится этап считывание данных с ведомого
						if (count == 4'hF) 			//если мы отправили все биты с 7 по 0, то устанавливаем счетчик приема бит на старший бит
							begin
								stateSda <= STATE_WAIT_GEN_ACK_13;
								waitReceive<= 1'b0;
								count <= 4'd7;
							end
						else
							begin
								stateSda <= STATE_PREPARE_RECEIVE_9;
								count <= count - 4'd1;
							end
					end
				if (sda == 0) 							//фиксируем наличие низкого уровня на линии sda - сохраняем значение принятого бита
					begin
						datareceive[count] <= 0;
					end
				zsda	<= 1;
			end
			
			
			
			
			STATE_WAIT_GEN_ACK_13: begin
				if (stateScl == STATE_WAIT_GEN_ACK_13 ) 
					begin 
						if (waitReceive) 
							begin
								stateSda <= STATE_GEN_ACK_14;
								zsda	<= 0;		
							end
						else 	
							begin
								stateSda <= STATE_NO_GEN_ACK_15;	
								zsda	<= 1;
							end
						waitReceive <= 1'b0;						//сбрасываем сигнал передачи в ведомого новой порции данных	
						received	<= 0;								//сбрасываем сигнал уведомления о приема порции данных
					end
				else
					begin
						if (receive)								//фиксируем наличие высокого уровня на линии receive, дополнительная порция информации будет принята с ведомого
							waitReceive <= 1'b1;
						received	<= 1;								//выставляем сигнал уведомления о приеме порции данных 
						zsda	<= 1;
					end				
			end	
			STATE_GEN_ACK_14: begin
				if (stateScl == STATE_GEN_ACK_14 ) 
					begin 
						stateSda <= STATE_PREPARE_RECEIVE_9;		//переходим в состояние подготовки к отправке новой порции данных									
					end
			end	
			STATE_NO_GEN_ACK_15: begin
				if (stateScl == STATE_NO_GEN_ACK_15 ) 
					begin 
						stateSda <= STATE_STOP_8;
					end
			end	
		
			STATE_STOP_8: begin	
				if (stateScl == STATE_IDLE_0)
					begin
						stateSda <= STATE_IDLE_0;
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
			stateScl <= STATE_IDLE_0;
			delay <= ZERO8;
		end
	else
		begin
			case (stateSda)
			STATE_IDLE_0: begin		
				zscl	<= 1;
				stateScl <= STATE_IDLE_0;
				delay <= ZERO8;
			end
			STATE_START_1: begin		
				if (delay == HALF8+QUARTER8) 
					begin //исходим из того что частота работы 100кГц берем интервал и просаживаем scl в ноль
						stateScl <= STATE_START_1;									
						delay <= QUARTER8;
					end
				else 
					delay <= delay + ONE8;
				if (delay < HALF8)
					zscl	<= 1;
				else
					zscl	<= 0;
			end	
			
			STATE_START_PREPARE_SEND_13: begin
				if (delay == HALF8)
					begin 
						stateScl <= STATE_START_PREPARE_SEND_13;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 0;
			end		
			STATE_START_SEND_14: begin		
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_START_SEND_14;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 1;
			end
			STATE_START_WAIT_ACK_15: begin
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_START_WAIT_ACK_15;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 0;
			end
			STATE_START_ACK_16: begin
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_START_ACK_16;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 1;		
			end			
			STATE_WAIT_RESTART_11: begin
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_WAIT_RESTART_11;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				if (delay < QUARTER8)
					zscl	<= 0;
				else
					zscl	<= 1;
			end			
			STATE_RESTART_12: begin
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_RESTART_12;
						delay <= QUARTER8;
					end
				else
					delay <= delay + ONE8;
				if (delay < QUARTER8)
					zscl	<= 1;
				else
					zscl	<= 0;
			end
		
			
			
			
			
			
			
			
			
			
			STATE_PREPARE_SEND_2: begin
				if (delay == HALF8)
					begin 
						stateScl <= STATE_PREPARE_SEND_2;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 0;
			end		
			STATE_SEND_3: begin		
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_SEND_3;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 1;
			end
			STATE_WAIT_ACK_4: begin
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_WAIT_ACK_4;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 0;
			end
			STATE_ACK_5: begin
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_ACK_5;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 1;		
			end

			
			
			
			
			
			STATE_PREPARE_RECEIVE_9: begin
				if (delay == HALF8)
					begin 
						stateScl <= STATE_PREPARE_RECEIVE_9;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;	
				zscl	<= 0;
			end		
			STATE_RECEIVE_10: begin		
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_RECEIVE_10;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 1;
			end
			STATE_WAIT_GEN_ACK_13: begin		
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_WAIT_GEN_ACK_13;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 0;
			end
			STATE_GEN_ACK_14: begin		
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_GEN_ACK_14;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 1;
			end
			STATE_NO_GEN_ACK_15: begin		
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_NO_GEN_ACK_15;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 1;
			end				
			STATE_STOP_8: begin	
				if (delay == HALF8+HALF8) 
					begin 
						stateScl <= STATE_IDLE_0;
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