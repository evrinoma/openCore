module I2C_MASTER(clk, reset, start, ready, sda, scl, send, datasend, sended, receive, datareceive, received, state);

`include "I2C.vh"

input wire clk;					//сигнал тактовой частоты
input wire reset;					//сигнал сброса
input wire start;					//запустить транзакцию
output wire ready;				//готовность контроллера I2C
output wire[5:0] state;

inout sda;							//линия передачи данных I2C 
inout scl;							//сигнал тактирования I2C

input	wire send;					//отправить новую порцию данных до тех пор пока истинно
input wire [7:0] datasend;		//адрес и данные, которые шлем в устройство,  а так же тут задаем тип операции - чтения или записи данных
output wire sended;				//сигнал записи новой порции данных при много байтном обмене

input	wire receive;				//принять новую порцию данных до тех пор пока истинно
output reg[7:0] datareceive;	//регистр принятых данных по шине - полученый байт
output wire received;				//готовность полученого байта для выгрузки

reg zsda	= 1'b1;						//первод лини sda в состояние Z
reg zscl	= 1'b1;						//первод лини scl в состояние Z
reg rw	= 1'b1;						//операция - поумолчанию чтение read = 1 write = 0
reg ask	= 1'b1;						//подтверждение приема
reg waitSend	= 0;				//новая порция данных для отправки в ведомого
reg waitReceive	= 0;			//новая порция данных для приема с ведомого


reg[3:0]	count;					//счетчик пересылаемых байт
reg[7:0]	delay;					//делитель входной частоты

reg[5:0] stateSda;				//состояние линии sda
reg[5:0] stateScl;				//состояние линии scl
reg	   stateStart;				//состояние перехода в режим start илии restart

reg receivedBit; 
reg lockReceived	= 1'b0;
reg lockSended		= 1'b0;

localparam START_IDLE_0	= 1'b0;
localparam START_1		= 1'b1;


assign sda = (zsda) ? 1'bz : 1'b0;// 1'bz монтажное И поэтому тут не может быть высокого уровня
assign scl = (zscl) ? 1'bz : 1'b0;// 1'bz монтажное И поэтому тут не может быть высокого уровня
assign ready = (stateSda == STATE_IDLE_0) ? 1'b1 : 1'b0;
assign sended 		= (lockSended) 	? 1'b1 : 1'b0;
assign received 	= (lockReceived) 	? 1'b1 : 1'b0;
assign state = stateSda;

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
					if (stateSda == STATE_START_11 || stateSda == STATE_RESTART_13)
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
			
			zsda	<= 1'b1;
			rw		<= 1'b0;
			ask	<= 1'b1;
			
			lockSended		<= 1'b0;		
			lockReceived	<= 1'b0;
			
			count 			<= 4'd7;
			datareceive 	<= 8'd0;
			waitSend			<= 1'b0;
			waitReceive		<= 1'b0;
			
			receivedBit		<= 1'b1;	
		end
	else
		begin
			case (stateSda)
			STATE_IDLE_0: begin
				if (stateStart == START_1) 
					begin
						stateSda <= STATE_START_11;						
					end
				else
					begin
						stateSda <= STATE_IDLE_0;
					end
				zsda	<= 1'b1;							//линия sda в состоянии z
				count <= 4'd7;							//счетчик передачи бит указывает на старший бит, так с него начинаем передачу данных
				ask	<= 1'b1;							//сбрасываем бит подтвержедния приема данных ведомым				
				lockSended		<= 1'b0;				//сбрасываем сигнал уведомелния о передачи порции данных
				lockReceived	<= 1'b0;				//сбрасываем сигнал уведомления о приеме порции данных
				waitSend			<= 1'b0;				//сбрасываем сигнал передачи в ведомого новой порции данных
				waitReceive		<= 1'b0;				//сбрасываем сигнал приема с ведомого новой порции данных	
				receivedBit		<= 1'b1;			
			end
			STATE_START_11: begin						//начальная последовательность sda = 0 scl = 1 задержка sda = 0 scl = 0 задержка
				if (stateScl == STATE_START_11) 
					begin 								//ожидаем когда закончится этап старта
						stateSda <= STATE_PREPARE_SEND_21;	
						rw	<=	datasend[0];				//устанавливаем режим чтение или запись						
					end
				zsda	<= 1'b0;	
				lockSended		<= 1'b0;							//сбрасываем сигнал уведомелния о передачи порции данных
				lockReceived	<= 1'b0;							//сбрасываем сигнал уведомления о приеме порции данных
			end	
			STATE_WAIT_RESTART_12: begin
				 if (stateScl == STATE_WAIT_RESTART_12) 
					begin
						stateSda <= STATE_RESTART_13;
					end
				zsda    <= 1'b1;
			end  
			STATE_RESTART_13: begin
				if (stateScl == STATE_RESTART_13) 
					begin 								//ожидаем когда закончится этап старта
						stateSda <= STATE_PREPARE_SEND_21;	
						rw	<=	datasend[0];			//устанавливаем режим чтение или запись						
					end
				zsda	<= 1'b0;	
				lockSended		<= 1'b0;							//сбрасываем сигнал уведомелния о передачи порции данных
				lockReceived	<= 1'b0;							//сбрасываем сигнал уведомления о приеме порции данных  
			end    		
			STATE_PREPARE_SEND_21: begin			//осуществляем выборку данных
				if (stateScl == STATE_PREPARE_SEND_21) 
					begin 								//ожидаем когда закончится этап подготовки данных
						stateSda <= STATE_PREPARE_STRETCH_51;
						count <= count - 4'd1;		//уменьшаем счетчик передачи бит 
					end
				if (datasend[count] == 1)			//переключаем линию sda в ноль, если отправляемый бит равен нулю
					zsda	<= 1'b1;	
				else
					zsda	<= 1'b0;	
			end
			STATE_SEND_22: begin
				if (stateScl == STATE_SEND_22) 
					begin 											//ожидаем когда закончится этап послыки данных
						if (count == 4'hF) 						//если мы отправили все биты с 7 по 0, то устанавливаем счетчик передачи бит на старший бит
							begin
								stateSda <= STATE_WAIT_ACK_31;	//преходим в состояние приема ответа ACK или NACK
								waitSend<= 1'b0;						//сбрасываем сигнал передачи в ведомого новой порции данных
								waitReceive<= 1'b0;					//сбрасываем сигнал приема с ведомого новой порции данных	
								count <= 4'd7;
							end
						else
							stateSda <= STATE_PREPARE_SEND_21; //преходим в состояние подготовки данных к отправке
					end
			end
			STATE_WAIT_GEN_ACK_32: begin
				if (waitSend == 1'b1 || waitReceive ==  1'b1)
						zsda	<= 1'b0;
				else
						zsda	<= 1'b1;	
				lockReceived	<= 1'b1;								//выставляем сигнал уведомления о передачи порции данных - готовность устройства к принятию новой порции данных	
				//внешний источник должен выставлять сигналы send или receive так как нельзя положиться на анализ бита rw
				if (send)										//фиксируем наличие высокого уровея на линии send, дополнительная порция информации будет отправлена в ведомый
						waitSend <= 1'b1;							
				if (receive)									//фиксируем наличие высокого уровня на линии receive, дополнительная порция информации будет принята с ведомого
						waitReceive <= 1'b1;
				if (stateScl == STATE_WAIT_GEN_ACK_32) 
					begin 										//ожидаем когда начнется этап приема данных подтверждения
						stateSda <= STATE_PREPARE_STRETCH_55;	
						ask	<= 1'b1;							
					end
			end	
			STATE_WAIT_ACK_31: begin
				zsda	<= 1'b1;
				lockSended		<= 1'b1;									//выставляем сигнал уведомления о передачи порции данных - готовность устройства к принятию новой порции данных	
				//внешний источник должен выставлять сигналы send или receive так как нельзя положиться на анализ бита rw
				if (send)										//фиксируем наличие высокого уровея на линии send, дополнительная порция информации будет отправлена в ведомый
						waitSend <= 1'b1;							
				if (receive)									//фиксируем наличие высокого уровня на линии receive, дополнительная порция информации будет принята с ведомого
						waitReceive <= 1'b1;
				if (stateScl == STATE_WAIT_ACK_31) 
					begin 										//ожидаем когда начнется этап приема данных подтверждения
						stateSda <= STATE_PREPARE_STRETCH_53;
						ask	<= 1'b1;	
					end
			end
			//Clock stretching
			STATE_ACK_33: begin
				if (stateScl == STATE_ACK_33) 
					begin 				
						if (!ask) 
							begin									//если пришло подтвреждение от ведомого
								if (stateStart == START_1) 
									begin
										stateSda <= STATE_WAIT_RESTART_12;						
									end
								else
									begin
										if (rw)							//чтение данных из ведомого
											begin						
												if (waitReceive) 			
													begin	
														waitReceive <= 1'b0;						//сбрасываем сигнал передачи в ведомого новой порции данных
														stateSda <= STATE_PREPARE_RECEIVE_41;//переходим в состояние подготовки к отправке новой порции данных
													end
												else
													stateSda <= STATE_STOP_63;					//если пришло подтвреждение от ведомого, а посылать больше нечего, то заканчиваем отправку
											end
										else	
											begin							//запись данных в ведомый	
												if (waitSend) 			
													begin	
														waitSend <= 1'b0;							//сбрасываем сигнал передачи в ведомого новой порции данных
														stateSda <= STATE_PREPARE_SEND_21;	//переходим в состояние подготовки к отправке новой порции данных
													end
												else
													stateSda <= STATE_STOP_63;					//если пришло подтвреждение от ведомого, а посылать больше нечего, то заканчиваем отправку
											end
									end
							end
						else																	//если не пришло подтвреждение от ведомого, то заканчиваем посылку
							stateSda <= STATE_STOP_63;						
					end
				else
					begin
						if (sda == 0) 			//фиксируем наличие низкого уровня на линии sda
							ask <= 1'b0;						
					end
					
				lockSended		<= 1'b0;							//сбрасываем сигнал уведомелния о передачи порции данных
				lockReceived	<= 1'b0;							//сбрасываем сигнал уведомления о приеме порции данных
			end 
			STATE_PREPARE_RECEIVE_41: begin	//осуществляем считывание данных с ведомого
				if (stateScl == STATE_PREPARE_RECEIVE_41) 
					begin 						//ожидаем когда закончится этап подготовки данных ведомым
						stateSda <= STATE_PREPARE_STRETCH_57;
						receivedBit<= 1'b1;
					end
				zsda	<= 1'b1;
			end			
			STATE_RECEIVE_42: begin
				if (stateScl == STATE_RECEIVE_42) 
					begin 								//ожидаем когда закончится этап считывание данных с ведомого
						if (count == 4'h0) 			//если мы отправили все биты с 7 по 0, то устанавливаем счетчик приема бит на старший бит
							begin
								stateSda <= STATE_WAIT_GEN_ACK_32;
								waitSend<= 1'b0;						//сбрасываем сигнал передачи в ведомого новой порции данных
								waitReceive<= 1'b0;					//сбрасываем сигнал приема с ведомого новой порции данных							
								count <= 4'd7;
							end
						else
							begin
								stateSda <= STATE_PREPARE_RECEIVE_41;
								count <= count - 4'd1;
							end
						datareceive[count] <= receivedBit;
					end
				if (sda == 0) 							//фиксируем наличие низкого уровня на линии sda - сохраняем значение принятого бита
					begin
						receivedBit<= 1'b0;
					end
				zsda	<= 1'b1;
			end	

			STATE_PREPARE_STRETCH_51: begin
				if (stateScl == STATE_PREPARE_STRETCH_51) 
				begin
					stateSda <= STATE_STRETCH_52;
				end
			end
			STATE_STRETCH_52: begin
				if (stateScl == STATE_PREPARE_SEND_21) 
				begin
					stateSda <= STATE_SEND_22;
				end
			end
			
			STATE_PREPARE_STRETCH_53: begin
				if (stateScl == STATE_PREPARE_STRETCH_53) 
				begin
					stateSda <= STATE_STRETCH_54;
				end
			end
			STATE_STRETCH_54: begin
				if (stateScl == STATE_WAIT_ACK_31) 
				begin
					stateSda <= STATE_ACK_33;
				end
			end		
			
			STATE_PREPARE_STRETCH_55: begin
				if (stateScl == STATE_PREPARE_STRETCH_55) 
				begin
					stateSda <= STATE_STRETCH_56;
				end
			end
			STATE_STRETCH_56: begin
				if (stateScl == STATE_WAIT_GEN_ACK_32) 
				begin
					stateSda <= STATE_ACK_33;
				end
			end	
			
			STATE_PREPARE_STRETCH_57: begin
				if (stateScl == STATE_PREPARE_STRETCH_57) 
				begin
					stateSda <= STATE_STRETCH_58;
				end
			end
			STATE_STRETCH_58: begin
				if (stateScl == STATE_PREPARE_RECEIVE_41) 
				begin
					stateSda <= STATE_RECEIVE_42;
				end
			end
		
			STATE_STOP_63: begin	
				if (stateScl == STATE_IDLE_0)
					begin
						stateSda <= STATE_IDLE_0;
					end
				zsda	<= 1'b0;
			end
			endcase
		end
end

always@(negedge clk)
begin
	if (!reset)
		begin
			zscl	<= 1'b1;
			stateScl <= STATE_IDLE_0;
			delay <= ZERO8;
		end
	else
		begin
			case (stateSda)
			STATE_IDLE_0: begin		
				zscl	<= 1'b1;
				stateScl <= STATE_IDLE_0;
				delay <= ZERO8;
			end			
			
			STATE_START_11: begin		
				if (delay == HALF8+QUARTER8) 
					begin //частота работы 100кГц берем интервал и просаживаем scl в ноль
						stateScl <= STATE_START_11;									
						delay <= QUARTER8;
					end
				else 
					delay <= delay + ONE8;
				if (delay < HALF8)
					zscl	<= 1'b1;
				else
					zscl	<= 1'b0;
			end	
			STATE_WAIT_RESTART_12: begin
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_WAIT_RESTART_12;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				if (delay < QUARTER8)
					zscl	<= 1'b0;
				else
					zscl	<= 1'b1;
			end			
			STATE_RESTART_13: begin
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_RESTART_13;
						delay <= QUARTER8;
					end
				else
					delay <= delay + ONE8;
				if (delay < QUARTER8)
					zscl	<= 1'b1;
				else
					zscl	<= 1'b0;
			end
			STATE_STOP_63: begin	
				if (delay == HALF8+HALF8) 
					begin 
						stateScl <= STATE_IDLE_0;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				if (delay < HALF8)
					zscl	<= 1'b0;
				else
					zscl	<= 1'b1;
			end
			
			
			STATE_PREPARE_SEND_21: begin
				if (delay == HALF8-STRETCH_2)
					begin 
						stateScl <= STATE_PREPARE_SEND_21;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 1'b0;
			end	
			STATE_WAIT_GEN_ACK_32: begin		
				if (delay == HALF8-STRETCH_2) 
					begin 
						stateScl <= STATE_WAIT_GEN_ACK_32;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 1'b0;
			end
			STATE_WAIT_ACK_31: begin
				if (delay == HALF8-STRETCH_2) 
					begin 
						stateScl <= STATE_WAIT_ACK_31;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 1'b0;
			end
			STATE_PREPARE_RECEIVE_41: begin
				if (delay == HALF8-STRETCH_2)
					begin 
						stateScl <= STATE_PREPARE_RECEIVE_41;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;	
				zscl	<= 1'b0;
			end	
			
			STATE_SEND_22: begin		
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_SEND_22;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 1'b1;
			end				
			STATE_ACK_33: begin
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_ACK_33;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 1'b1;		
			end
			STATE_RECEIVE_42: begin		
				if (delay == HALF8) 
					begin 
						stateScl <= STATE_RECEIVE_42;
						delay <= ZERO8;
					end
				else
					delay <= delay + ONE8;
				zscl	<= 1'b1;
			end

			STATE_PREPARE_STRETCH_51: begin
				stateScl <= STATE_PREPARE_STRETCH_51;
				zscl	<= 1'b1;
			end
			STATE_STRETCH_52: begin
				if (scl == 1'b1) 
					begin
						stateScl <= STATE_PREPARE_SEND_21;
					end
			end			
			STATE_PREPARE_STRETCH_53: begin
				stateScl <= STATE_PREPARE_STRETCH_53;
				zscl	<= 1'b1;
			end
			STATE_STRETCH_54: begin
				if (scl == 1'b1) 
					begin
						stateScl <= STATE_WAIT_ACK_31;
					end
			end			
			STATE_PREPARE_STRETCH_55: begin
				stateScl <= STATE_PREPARE_STRETCH_55;
				zscl	<= 1'b1;
			end
			STATE_STRETCH_56: begin
				if (scl == 1'b1) 
					begin
						stateScl <= STATE_WAIT_GEN_ACK_32;
					end
			end			
			STATE_PREPARE_STRETCH_57: begin
				stateScl <= STATE_PREPARE_STRETCH_57;
				zscl	<= 1'b1;
			end
			STATE_STRETCH_58: begin
				if (scl == 1'b1) 
					begin
						stateScl <= STATE_PREPARE_RECEIVE_41;
					end
			end

			endcase
		end
end

endmodule