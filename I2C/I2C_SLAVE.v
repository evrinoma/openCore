module I2C_SLAVE(clk, reset, sda, scl, datasend, sended, datareceive, received, address, addressLatch);

`include "I2C.vh"

input wire clk;					//сигнал тактовой частоты
input wire reset;					//сигнал сброса
inout sda;							//линия передачи данных I2C 
inout scl;							//сигнал тактирования I2C

input wire [7:0] datasend;		//адрес и данные, которые шлем в устройство,  а так же тут задаем тип операции - чтения или записи данных
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


reg lastSda	= 1'b1;
reg lastScl	= 1'b1;
reg lockReceived	= 1'b1;
reg lockSended		= 1'b1;

assign sda = (zsda) ? 1'bz : 1'b0;// 1'bz монтажное И поэтому тут не может быть высокого уровня
assign scl = (zscl) ? 1'bz : 1'b0;// 1'bz монтажное И поэтому тут не может быть высокого уровня

assign sended 		= (lockSended) 	? 1'b1 : 1'b0;
assign received 	= (lockReceived) 	? 1'b1 : 1'b0;

always@(posedge clk)
begin
	if (!reset)
		begin
			stateSda	<= STATE_IDLE_0;
			saveSda	<= STATE_IDLE_0;
			lastSda <= 1'b1;
			zsda	<= 1'b1;			
			datareceive <= ZERO8;	
			lockReceived	<= 1'b1;	
			lockSended	<= 1'b1;	
		end
	else
		begin
			case (stateSda)
				STATE_IDLE_0: begin							//поумолчанию переходим в режим ожидания старта транзакции
					stateSda <= STATE_START_11;
					saveSda <= STATE_START_11;
					lastSda <= 1'b1;
					zsda	<= 1'b1;
				end
				STATE_START_11: begin 						//как только линия sda просела в ноль, и при этом на линии scl высокий уровень - переходим в режим ожидания приема адреса и бита операции 
					if (scl)
						begin
							case ({lastSda,sda})			
							2'b10: begin 									
										stateSda <= STATE_PREPARE_RECEIVE_41;
									 end
							2'b01: begin 								
										stateSda <= STATE_STOP_63;
									 end
							endcase				
							lastSda <= sda;
						end
				end
				STATE_PREPARE_RECEIVE_41: begin
					if (stateScl == STATE_RECEIVE_42) 
						stateSda <= STATE_RECEIVE_42;		
					zsda	<= 1'b1;
					lockReceived	<= 1'b1;
				end
				STATE_RECEIVE_42: begin						//если мы приняли все биты с 7 по 0, то устанавливаем счетчик приема бит на старший бит
						if (count == 4'h0) 			
							begin
								stateSda <= STATE_WAIT_GEN_ACK_32;												
								count <= 4'd7;
							end
						else
							begin
								stateSda <= STATE_PREPARE_RECEIVE_41;
								count <= count - 4'd1;
							end
						datareceive[count] <= (sda == 0) ? 1'b0: 1'b1;
				end
				STATE_WAIT_GEN_ACK_32: begin  			//если адрес не наш то переходим в ожидание, если наш то запоминаем операцию 
						if (datareceive[7:1] != devAddress & saveSda == STATE_START_11) //прием адреса
							stateSda <= STATE_IDLE_0;
						else										//прием байта данных
							begin
								if (saveSda == STATE_START_11)
									rw <= datareceive[0];
								else 
									begin
										lockReceived	<= 1'b0;
									end
								stateSda <= STATE_ACK_33;	
								saveSda <= STATE_ACK_33;						
							end								
				end
				STATE_ACK_33: begin							//просаживаем линию sda в ноль подтверждая присутствие на шине
						if (stateScl == STATE_RECEIVE_42) 
							begin
								stateSda <= (rw) ? STATE_PREPARE_SEND_21 : STATE_PREPARE_RECEIVE_41;	
							end
						zsda	<= 1'b0;
				end
				STATE_PREPARE_SEND_21: begin				//если мы передали все биты с 7 по 0, то устанавливаем счетчик приема бит на старший бит
					if (count == 4'h0) 			
						begin
							stateSda <= STATE_WAIT_ACK_31;
							count <= 4'd7;
						end
					else
						begin
							stateSda <= STATE_SEND_22;
							count <= count - 4'd1;
						end
					zsda <= (send[count] == 0) ? 1'b0: 1'b1;
				end
				STATE_SEND_22: begin							
					if (stateScl == STATE_SEND_22) 
						stateSda <= STATE_PREPARE_SEND_21;
					lockSended	<= 1'b1;	
				end
				STATE_WAIT_ACK_31: begin							
					if (stateScl == STATE_SEND_22) 
						stateSda <= STATE_PREPARE_SEND_21;
					lockSended	<= 1'b1;	
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
				STATE_PREPARE_RECEIVE_41: begin		
					if ({lastScl,scl} == 2'b01)
						stateScl 	<= STATE_RECEIVE_42;		
					lastScl <= scl;
				end	
				STATE_RECEIVE_42: begin	
					stateScl <= STATE_PREPARE_RECEIVE_41;
				end	
				STATE_PREPARE_SEND_21: begin	
					stateScl <= STATE_PREPARE_SEND_21;
				end	
				STATE_SEND_22: begin		
					if ({lastScl,scl} == 2'b01)
						stateScl 	<= STATE_SEND_22;		
					lastScl <= scl;
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