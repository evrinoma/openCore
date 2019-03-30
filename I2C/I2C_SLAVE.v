module I2C_SLAVE(clk, reset, sda, scl, datasend, sended, datareceive, received, address, addressLatch);

`include "I2C.vh"

input wire clk;					//сигнал тактовой частоты
input wire reset;					//сигнал сброса
inout sda;							//линия передачи данных I2C 
inout scl;							//сигнал тактирования I2C

input  wire[7:0] datasend;		//адрес и данные, которые шлем в устройство,  а так же тут задаем тип операции - чтения или записи данных
output wire sended;				//сигнал записи новой порции данных при много байтном обмене

output reg[7:0] datareceive;	//регистр принятых данных по шине - полученый байт
output wire received;			//готовность полученого байта для выгрузки

input	wire[6:0] address;
input wire addressLatch;					//сигнал защелкунуть адрес

reg zsda	= 1'b1;					//первод лини sda в состояние Z
reg zscl	= 1'b1;					//первод лини scl в состояние Z
reg rw	= 1'b1;					//операция - поумолчанию чтение read = 1 write = 0
reg[3:0]	count;					//счетчик пересылаемых байт
reg[5:0] stateSda;				//состояние линии sda
reg[5:0] saveSda;					//состояние линии sda
reg[5:0] stateScl;				//состояние линии scl
reg[6:0] devAddress = SLAVE_ADDRESS;	//регистр адреса устройства
reg[7:0] send = ZERO8;			//адрес и данные, которые шлем в устройство,  а так же тут задаем тип операции - чтения или записи данных
reg[7:0]	delay;					//
reg[5:0] stateFSM;					//состояние линии sda


reg lastSda	= 1'b1;
reg lastScl	= 1'b1;
reg lockReceived	= 1'b1;
reg lockSended		= 1'b1;

assign sda = (zsda) ? 1'bz : 1'b0;// 1'bz монтажное И поэтому тут не может быть высокого уровня
assign scl = (zscl) ? 1'bz : 1'b0;// 1'bz монтажное И поэтому тут не может быть высокого уровня

assign sended 		= (lockSended) 	? 1'b1 : 1'b0;
assign received 	= (lockReceived) 	? 1'b1 : 1'b0;

always@(negedge clk)
begin
	if (!reset)
		begin
			lastSda <= 1'b1;
			stateFSM <= STATE_IDLE_0;
			delay <= ZERO8;
		end
	else
		begin
			case (stateFSM)
				STATE_IDLE_0:begin				
					case ({lastSda,sda,scl})	
					3'b101:begin 
								stateFSM <= STATE_WAIT_START_10;
							 end
					3'b011:begin 
								//стоп может быть только тогда когда ведомый не управляет шиной sda
								if (zsda) 
									stateFSM <= STATE_STOP_63;		
							 end		 
					endcase
					delay <= ZERO8;
				end
				STATE_WAIT_START_10:begin	
					if ({lastSda,sda,scl} == 3'b001)
						begin
							if(delay == QUARTER8)
								begin
									stateFSM <= STATE_START_11;
								end
						end	
					else
						begin
							stateFSM <= STATE_IDLE_0;
						end
					delay <= delay + ONE8;
				end				
				STATE_START_11,
				STATE_STOP_63:begin
					stateFSM <= STATE_IDLE_0;
				end
			endcase	
			lastSda <= sda;	
		end
	
	
//		if (zsda) 
//			begin
//				case ({lastSda,sda})	
//				2'b10: begin 
////							if (delay == QUARTER8)
////								begin
////									stateFSM <= (scl) ? STATE_START_11 : STATE_IDLE_0;
////									delay <= ZERO8;
////								end
//								delay <= ZERO8;
//								lastScl <= scl;	
//						 end
//				2'b00: begin 
//							if (delay == QUARTER8)
//								begin
//									stateFSM <= STATE_START_11;
//									delay <= ZERO8;
//								end
//							else
//								begin
//									lastScl <= scl;
//									stateFSM <= STATE_IDLE_0
//								end
//							delay <= delay + ONE8;
//						 end
//				2'b01: begin 
//							if (delay == QUARTER8)
//								begin
//									stateFSM <= (scl) ? STATE_STOP_63 : STATE_IDLE_0;
//									delay <= ZERO8;
//								end
//						 end
//				endcase
//				lastSda <= sda;				
//			end
//		else
//			begin
//				lastSda <= 1'b1;
//				delay <= ZERO8;
//			end
//	end
end

always@(posedge clk)
begin
if (!reset)
	begin
		stateSda	<= STATE_IDLE_0;
		zsda	<= 1'b1;			
		datareceive <= ZERO8;
		//datasend <= QUARTER8;	//тестовый ответ
		lockReceived	<= 1'b1;	
		lockSended	<= 1'b1;	
		count <= COUNT_MAX4;
	end
else
	begin
		case (stateSda)
			STATE_IDLE_0: begin							//поумолчанию переходим в режим ожидания старта транзакции
				stateSda <= (stateFSM == STATE_START_11) ? STATE_PREPARE_RECEIVE_ADR_43 : STATE_IDLE_0;					
				zsda	<= 1'b1;
			end
			STATE_PREPARE_RECEIVE_ADR_43,
			STATE_PREPARE_RECEIVE_41: begin
					if (stateScl == STATE_RECEIVE_42) 
						begin
							stateSda <= STATE_RECEIVE_42;	
						end
					else if (stateScl == STATE_RECEIVE_ADR_44) 
						begin
							stateSda <= STATE_RECEIVE_ADR_44;	
						end					
					zsda	<= 1'b1;
					lockReceived	<= 1'b1;
			end
			STATE_RECEIVE_ADR_44,
			STATE_RECEIVE_42: begin						//если мы приняли все биты с 7 по 0, то устанавливаем счетчик приема бит на старший бит
					if (count == 4'h0) 			
						begin
							stateSda<= (stateScl == STATE_RECEIVE_42) ? STATE_WAIT_GEN_ACK_32 : STATE_WAIT_GEN_ACK_ADR_34;
							count <= COUNT_MAX4;
						end
					else
						begin	
							stateSda<=stateScl;
							count <= count - 4'd1;
						end
					datareceive[count] <= (sda == 0) ? 1'b0: 1'b1;					
			end
			STATE_WAIT_GEN_ACK_ADR_34,
			STATE_WAIT_GEN_ACK_32: begin  			//если адрес не наш то переходим в ожидание, если наш то запоминаем операцию 
					if (stateScl == STATE_ACK_33)
						begin
							stateSda <= (datareceive[7:1] == devAddress) ? STATE_ACK_33:STATE_IDLE_0;
							rw <= datareceive[0];
						end
					else
						begin
							lockReceived	<= 1'b0;
						end
					zsda	<= 1'b0;	
			end
			STATE_ACK_33: begin	
					if (stateScl == STATE_PREPARE_RECEIVE_41 || stateScl == STATE_PREPARE_SEND_21)
						begin
							stateSda <= (rw) ? STATE_PREPARE_SEND_21:STATE_PREPARE_RECEIVE_41;							
						end
					zsda	<= (rw) ? 1'b1:1'b0;
			end	
			STATE_PREPARE_SEND_21: begin
					if (stateScl == STATE_SEND_22) 
						begin
							stateSda <= STATE_SEND_22;	
						end	
					zsda	<= 1'b1;		
			end
			STATE_SEND_22: begin
					if (count == 4'h0) 			
						begin
							stateSda<= (stateScl == STATE_SEND_22) ? STATE_WAIT_GEN_ACK_32 : STATE_WAIT_GEN_ACK_ADR_34;
							count <= COUNT_MAX4;
						end
					else
						begin								
							count <= count - 4'd1;
						end						
					zsda =  datasend[count] ? 1'b0: 1'b1;	
			end
		endcase
	end
end

always@(negedge clk)
begin
	if (!reset)
		begin
			stateScl <= STATE_IDLE_0;
			lastScl <= 1'b1;
			zscl	<= 1'b1;
		end
	else
		begin
			case (stateSda)		
				STATE_IDLE_0: begin
					stateScl <= STATE_IDLE_0;
					lastScl <= 1'b1;
					zscl	<= 1'b1;
				end

				STATE_PREPARE_RECEIVE_ADR_43: begin		
					if ({lastScl,scl} == 2'b01)
						stateScl 	<= STATE_RECEIVE_ADR_44;		
					lastScl <= scl;
				end	
				STATE_RECEIVE_ADR_44: begin	
					stateScl <= STATE_PREPARE_RECEIVE_ADR_43;
				end
			
			
				STATE_PREPARE_RECEIVE_41: begin		
					if ({lastScl,scl} == 2'b01)
						stateScl 	<= STATE_RECEIVE_42;		
					lastScl <= scl;
				end	
				STATE_RECEIVE_42: begin	
					stateScl <= STATE_PREPARE_RECEIVE_41;
				end	

				
				STATE_WAIT_GEN_ACK_ADR_34,
				STATE_WAIT_GEN_ACK_32: begin		
					if ({lastScl,scl} == 2'b01)
						stateScl 	<= STATE_ACK_33;	
					lastScl <= scl;
				end	
				STATE_ACK_33: begin	
						stateScl 	<= (rw) ? STATE_PREPARE_SEND_21:STATE_PREPARE_RECEIVE_41;	
				end	
				STATE_PREPARE_SEND_21: begin		
					if ({lastScl,scl} == 2'b01)
						stateScl 	<= STATE_SEND_22;		
					lastScl <= scl;
				end	
				STATE_SEND_22: begin	
					stateScl <= STATE_PREPARE_SEND_21;
				end	

			endcase
		end
end	

always @(posedge clk, negedge addressLatch)
begin
	if(addressLatch == 1'b0) 
		devAddress <= address;
end	
endmodule
//always@(posedge clk)
//begin
//	if (!reset)
//		begin
//			stateSda	<= STATE_IDLE_0;
//			saveSda	<= STATE_IDLE_0;
//			lastSda <= 1'b1;
//			zsda	<= 1'b1;			
//			datareceive <= ZERO8;	
//			lockReceived	<= 1'b1;	
//			lockSended	<= 1'b1;	
//			count <= COUNT_MAX4;
//		end
//	else
//		begin
//			case (stateSda)
//				STATE_IDLE_0: begin							//поумолчанию переходим в режим ожидания старта транзакции
//					stateSda <= STATE_WAIT_START_10;					
//					lastSda <= 1'b1;
//					zsda	<= 1'b1;
//				end
//				STATE_WAIT_START_10: begin 						//как только линия sda просела в ноль, и при этом на линии scl высокий уровень - переходим в режим ожидания приема адреса и бита операции 
//					if (scl)
//						begin
//							if (stateScl == STATE_WAIT_START_10) 
//							begin
//								case ({lastSda,sda})	
//								2'b10: begin 									
//											stateSda <= STATE_START_11;
//										 end
//								2'b01: begin 								
//											stateSda <= STATE_STOP_63;
//										 end
//								endcase
//							end
//						end
//					lastSda <= sda;
//				end
//				STATE_START_11: begin					
//					if (scl & !sda )
//						begin
//							if (stateScl == STATE_START_11) 
//								begin
//									stateSda <= STATE_PREPARE_RECEIVE_41;
//									lastSda <= 1'b1;
//								end
//							saveSda <= STATE_START_11;
//						end
//					else
//						stateSda <= STATE_IDLE_0;
//				end
//				STATE_PREPARE_RECEIVE_41: begin
//					if (stateScl == STATE_RECEIVE_42) 
//						stateSda <= STATE_RECEIVE_42;		
//					zsda	<= 1'b1;
//					lockReceived	<= 1'b1;
//				end
//				STATE_RECEIVE_42: begin						//если мы приняли все биты с 7 по 0, то устанавливаем счетчик приема бит на старший бит
//						if (count == 4'h0) 			
//							begin
//								stateSda <= STATE_WAIT_GEN_ACK_32;												
//								count <= COUNT_MAX4;
//							end
//						else
//							begin
//								stateSda <= STATE_PREPARE_RECEIVE_41;
//								count <= count - 4'd1;
//							end
//						datareceive[count] <= (sda == 0) ? 1'b0: 1'b1;
//				end
//				STATE_WAIT_GEN_ACK_32: begin  			//если адрес не наш то переходим в ожидание, если наш то запоминаем операцию 
//						if (datareceive[7:1] != devAddress & saveSda == STATE_START_11) //прием адреса
//							stateSda <= STATE_IDLE_0;
//						else										//прием байта данных
//							begin
//								if (saveSda == STATE_START_11)
//									rw <= datareceive[0];
//								else 
//									begin
//										lockReceived	<= 1'b0;
//									end
//								stateSda <= STATE_ACK_33;	
//								saveSda <= STATE_ACK_33;						
//							end								
//				end
//				STATE_ACK_33: begin							//просаживаем линию sda в ноль подтверждая присутствие на шине
//						if (stateScl == STATE_RECEIVE_42) 
//							begin
//								stateSda <= (rw) ? STATE_PREPARE_SEND_21 : STATE_PREPARE_RECEIVE_41;	
//							end
//						zsda	<= 1'b0;
//				end
//				STATE_PREPARE_SEND_21: begin				//если мы передали все биты с 7 по 0, то устанавливаем счетчик приема бит на старший бит
//					if (count == 4'h0) 			
//						begin
//							stateSda <= STATE_WAIT_ACK_31;
//							count <= COUNT_MAX4;
//						end
//					else
//						begin
//							stateSda <= STATE_SEND_22;
//							count <= count - 4'd1;
//						end
//					zsda <= (send[count] == 0) ? 1'b0: 1'b1;
//				end
//				STATE_SEND_22: begin							
//					if (stateScl == STATE_SEND_22) 
//						stateSda <= STATE_PREPARE_SEND_21;
//					lockSended	<= 1'b1;	
//				end
//				STATE_WAIT_ACK_31: begin							
//				
//					lockSended	<= 1'b1;	
//				end
//			endcase
//		end
//end
//		