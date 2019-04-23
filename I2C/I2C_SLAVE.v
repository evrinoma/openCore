module I2C_SLAVE(clk, reset, sda, scl, address, datasend, sended, datareceive, received, state, _stateScl);

`include "I2C.vh"
`include "../UTILS/NO_ARCH.vh"

input wire clk;					//сигнал тактовой частоты
input wire reset;					//сигнал сброса
inout sda;							//линия передачи данных I2C 
inout scl;							//сигнал тактирования I2C

input  wire[7:0] datasend;		//адрес и данные, которые шлем в устройство,  а так же тут задаем тип операции - чтения или записи данных
output wire sended;				//сигнал записи новой порции данных при много байтном обмене

output reg[7:0] datareceive;	//регистр принятых данных по шине - полученый байт
output wire received;			//готовность полученого байта для выгрузки
output wire[5:0] state;
output wire[5:0] _stateScl;

input	wire[6:0] address;

reg zsda	= 1'b1;					//первод лини sda в состояние Z
reg zscl	= 1'b1;					//первод лини scl в состояние Z
reg rw	= 1'b1;					//операция - поумолчанию чтение read = 1 write = 0
reg[3:0]	count;					//счетчик пересылаемых байт
reg[5:0] stateSda;				//состояние линии sda
reg[5:0] stateScl;				//состояние линии scl

reg[7:0] send = ZERO8;			//адрес и данные, которые шлем в устройство,  а так же тут задаем тип операции - чтения или записи данных
reg[7:0]	delay;					//
reg[5:0] stateFSM;				//отслеживание начала и окончание транзакции


reg lastSda	= 1'b1;
reg lastScl	= 1'b1;
reg lockReceived	= 1'b1;
reg lockSended		= 1'b1;
reg ack		= 1'b1;

assign sda = (zsda) ? 1'bz : 1'b0;// 1'bz монтажное И поэтому тут не может быть высокого уровня
assign scl = (zscl) ? 1'bz : 1'b0;// 1'bz монтажное И поэтому тут не может быть высокого уровня

assign sended 		= (lockSended) 	? 1'b0 : 1'b1;
assign received 	= (lockReceived) 	? 1'b0 : 1'b1;
//assign state = {lastSda,stateFSM[4:0]};
//assign state = {reset,lastSda,stateFSM[3:0]};
assign state = stateSda;
//assign _stateScl = count;
assign _stateScl = stateScl;
//assign _stateScl = {lastScl,stateScl[4:0]};

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
					if (zsda)		//старт, рестарт или стоп может быть только тогда когда ведомый не управляет шиной sda
						begin
							case ({lastSda,sda,scl})	
							3'b101:begin 
										stateFSM <= STATE_WAIT_START_10;
									 end
							3'b011:begin 
										 if (stateSda!=STATE_PREPARE_SEND_21) 
											begin
												stateFSM <= STATE_STOP_63;		
											end
									 end		 
							endcase
						end
					delay <= ZERO8;
				end
				STATE_WAIT_START_10:begin	
					if ({lastSda,sda,scl} == 3'b001)
						begin
							if(delay == EIGHTH8)
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
end

always@(posedge clk)
begin
if (!reset)
	begin
		stateSda	<= STATE_IDLE_0;
		zsda	<= 1'b1;			
		datareceive <= ZERO8;
		lockReceived	<= 1'b1;	
		lockSended	<= 1'b1;	
		count <= COUNT_MAX4;
		ack	<= 1'b1;
	end
else
	begin
		if (stateFSM == STATE_START_11)
			begin
				stateSda <= STATE_PREPARE_RECEIVE_ADR_43;
				zsda	<= 1'b1;
				count <= COUNT_MAX4;
			end
		else
			begin
				case (stateSda)
					STATE_IDLE_0: begin							//поумолчанию переходим в режим ожидания старта транзакции	
						zsda	<= 1'b1;		
						datareceive <= ZERO8;				
					end
					STATE_PREPARE_RECEIVE_41: begin
							if (stateScl == STATE_RECEIVE_42) 
								begin
									stateSda <= STATE_RECEIVE_42;	
								end				
							zsda	<= 1'b1;
							lockReceived	<= 1'b1;
							lockSended	<= 1'b1;							
					end
					STATE_PREPARE_RECEIVE_ADR_43: begin
							if (stateScl == STATE_RECEIVE_ADR_44) 
								begin
									stateSda <= STATE_RECEIVE_ADR_44;	
								end					
							zsda	<= 1'b1;
							lockReceived	<= 1'b1;
							lockSended	<= 1'b1;							
					end										
					STATE_RECEIVE_42: begin						//если мы приняли все биты с 7 по 0, то устанавливаем счетчик приема бит на старший бит
							datareceive[count] <= (sda == 0) ? 1'b0: 1'b1;	
							if (stateScl == STATE_PREPARE_RECEIVE_41) 	
								begin
									if (count == 4'h0) 
										begin
											stateSda<= STATE_WAIT_GEN_ACK_32;
											count <= COUNT_MAX4;
										end
									else
										begin
											stateSda<= STATE_PREPARE_RECEIVE_41;
											count <= count - 4'd1;
										end
								end							
					end					
					STATE_RECEIVE_ADR_44: begin						//если мы приняли все биты с 7 по 0, то устанавливаем счетчик приема бит на старший бит
							datareceive[count] <= (sda == 0) ? 1'b0: 1'b1;	
							if (stateScl == STATE_PREPARE_RECEIVE_ADR_43) 	
								begin
									if (count == 4'h0) 
										begin
											stateSda<= STATE_WAIT_GEN_ACK_ADR_34;
											count <= COUNT_MAX4;
										end
									else
										begin
											stateSda<= STATE_PREPARE_RECEIVE_ADR_43;
											count <= count - 4'd1;
										end
								end		
					end
					STATE_PREPARE_SEND_21: begin
						if (stateScl == STATE_SEND_22) 
							begin
								stateSda <= STATE_SEND_22;
							end
						else
							begin
								lockReceived	<= 1'b1;
								lockSended	<= 1'b1;
								zsda =  datasend[count] ? 1'b1: 1'b0;
							end
					end
					STATE_SEND_22: begin
						if (stateScl == STATE_PREPARE_SEND_21) 
							begin
								if (count == 4'h0) 			
									begin
										stateSda<=STATE_WAIT_ACK_31;
										count <= COUNT_MAX4;
									end
								else
									begin
										stateSda<=STATE_PREPARE_SEND_21;
										count <= count - 4'd1;
									end
							end
					end
					STATE_WAIT_GEN_ACK_ADR_34: begin  			//если адрес не наш то переходим в ожидание, если наш то запоминаем операцию 
							if (stateScl == STATE_GEN_ACK_35)
								begin
									stateSda <= (datareceive[7:1] == address) ? STATE_GEN_ACK_35:STATE_IDLE_0;
									rw <= datareceive[0];
								end
								zsda	<= 1'b0;	
								count <= COUNT_MAX4;
					end
					STATE_WAIT_GEN_ACK_32: begin  			
							if (stateScl == STATE_GEN_ACK_35)
								begin
									stateSda <= STATE_GEN_ACK_35;
									rw <= datareceive[0];
								end
							lockReceived	<= 1'b0;
							zsda	<= 1'b0;								
					end
					STATE_GEN_ACK_35: begin	
							if (stateScl == STATE_PREPARE_RECEIVE_41 || stateScl == STATE_PREPARE_SEND_21)
								begin
									stateSda <= (rw) ? STATE_PREPARE_SEND_21:STATE_PREPARE_RECEIVE_41;							
								end
								zsda	<= 1'b0;	
					end	

					STATE_WAIT_ACK_31: begin					//состояние подготовки АСК если у slave есть еще данные то мы должны их подготовить  
							if (stateScl == STATE_WAIT_ACK_31) 
								begin
									stateSda <= STATE_ACK_33;
									ack	<= 1'b1;							
								end
							else
								begin
									zsda =  1'b1;
									lockSended	<= 1'b0;
								end
					end
					STATE_ACK_33: begin	
						if (stateScl == STATE_ACK_33) 	//если от мастера не пришло подтверждение значит стоп
							begin							
								stateSda <= (ack == 1'b0) ? STATE_PREPARE_SEND_21: STATE_STOP_63;
							end
						else
							begin
								if (sda == 0)
								begin
									ack	<= 1'b0;
								end
							end
					end
					STATE_STOP_63: begin	
						if (stateFSM == STATE_STOP_63) 	//стоп
							begin							
								stateSda <= STATE_IDLE_0;
							end
						else
							begin
								lockReceived	<= 1'b1;
								lockSended	<= 1'b1;
							end
					end
				endcase
		end
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
						begin
							stateScl 	<= STATE_RECEIVE_ADR_44;
						end
					lastScl <= scl;
				end
				STATE_RECEIVE_ADR_44: begin
					if ({lastScl,scl} == 2'b10)
						begin
							stateScl 	<= STATE_PREPARE_RECEIVE_ADR_43;
						end
					lastScl <= scl;
				end
			
				STATE_PREPARE_RECEIVE_41: begin	
					if ({lastScl,scl} == 2'b01)
						begin
							stateScl 	<= STATE_RECEIVE_42;
						end
					lastScl <= scl;
				end	
				STATE_RECEIVE_42: begin	
					if ({lastScl,scl} == 2'b10)
						begin
							stateScl 	<= STATE_PREPARE_RECEIVE_41;
						end
					lastScl <= scl;
				end
				
				STATE_PREPARE_SEND_21: begin
					if ({lastScl,scl} == 2'b01)
						begin
							stateScl <= STATE_SEND_22;
						end
					else
						begin
							lastScl <= scl;
						end
				end	
				STATE_SEND_22: begin
					if ({lastScl,scl} == 2'b10)
						begin
							stateScl 	<= STATE_PREPARE_SEND_21;
						end
					lastScl <= scl;
				end
				
				STATE_WAIT_GEN_ACK_ADR_34,
				STATE_WAIT_GEN_ACK_32: begin
					if ({lastScl,scl} == 2'b01)
						begin
							stateScl 	<= STATE_GEN_ACK_35;
						end
					lastScl <= scl;
				end
				
				STATE_GEN_ACK_35: begin	
					if ({lastScl,scl} == 2'b10)
						begin
							stateScl 	<= (rw) ? STATE_PREPARE_SEND_21:STATE_PREPARE_RECEIVE_41;
						end
					lastScl <= scl;
				end
				
				STATE_WAIT_ACK_31: begin
					if ({lastScl,scl} == 2'b01)
						begin
							stateScl 	<= STATE_WAIT_ACK_31;
						end
					lastScl <= scl;
				end
				
				STATE_ACK_33: begin
					if ({lastScl,scl} == 2'b10)
						begin
							stateScl 	<= STATE_ACK_33;
						end
					lastScl <= scl;
				end
			endcase			
		end
end

endmodule
