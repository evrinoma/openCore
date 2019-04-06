module I2C_ADDRESS_CHIP(clk, reset, address, send, datasend, receive, datareceive);

`include "I2C.vh"

input wire clk;					//сигнал тактовой частоты
input wire reset;					//сигнал сброса

input	reg[6:0] address; //регистр адреса устройства

input	wire send;					//отправить новую порцию данных до тех пор пока истинно
input wire [7:0] datasend;		//адрес и данные, которые шлем в устройство,  а так же тут задаем тип операции - чтения или записи данных

input	wire receive;				//принять новую порцию данных до тех пор пока истинно
output reg[7:0] datareceive;	//регистр принятых данных по шине - полученый байт
reg[5:0] stateFSM;				//состояние

assign address = SLAVE_ADDRESS;

always@(posedge clk)
begin
	if (!reset)
		begin
			stateSda	<= STATE_IDLE_0;
		
		end
	else
		begin
			case (stateSda)
				STATE_IDLE_0: begin
				//wait start transaction sda scl lines
					case ({lastSda,sda})
					2'b01: begin
									stateSda 	<= STATE_IDLE_0;	
							 end
					2'b10: begin
								if (scl)
									stateSda 	<= STATE_START_11;																		
							 end
					endcase
					lastSda <= sda;		
				end
				STATE_START_11: begin
				
				end
				endcase
		end
end
			

endmodule