module I2C_SLAVE(clk, reset, sda, scl, send, datasend, sended, receive, datareceive, received);
input wire clk;					//сигнал тактовой частоты
input wire reset;					//сигнал сброса
output wire ready;				//готовность контроллера I2C
inout sda;							//линия передачи данных I2C 
inout scl;							//сигнал тактирования I2C

input	wire send;					//отправить новую порцию данных до тех пор пока истинно
input wire [7:0] datasend;		//адрес и данные, которые шлем в устройство,  а так же тут задаем тип операции - чтения или записи данных
output wire sended;				//сигнал записи новой порции данных при много байтном обмене

input	wire receive;				//принять новую порцию данных до тех пор пока истинно
output reg[7:0] datareceive;	//регистр принятых данных по шине - полученый байт
output wire received;				//готовность полученого байта для выгрузки

assign sda = (zsda) ? 1'bz : 1'b0;// 1'bz монтажное И поэтому тут не может быть высокого уровня
assign scl = (zscl) ? 1'bz : 1'b0;// 1'bz монтажное И поэтому тут не может быть высокого уровня

always@(posedge clk)
begin
	if (!reset)
		begin
			stateSda	<= STATE_IDLE_0;
			
			zsda	<= 1'b1;
			zscl	<= 1'b1;
		end
	else
		begin
			case (stateSda)
				STATE_IDLE_0: begin
				//wait start transaction sda scl lines
				end
				STATE_IS_START: begin
				
				end
				endcase
		end
end
			

endmodule