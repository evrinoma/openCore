module SLAVE_DRIVER(clk, reset, address, datasend, sended, datareceive, received );

`include "SLAVE_DRIVER.vh"

input wire clk;					//сигнал тактовой частоты
input wire reset;					//сигнал сброса

output reg[7:0] datasend;		//
input	wire sended;				//

input wire[7:0] datareceive;	//
input	wire received;				//

output reg[6:0] address = SLAVE_ADDRESS; 		//регистр адреса устройства

reg[2:0] stateFSM;				//состояние	

reg lastReceived	= 1'b0;
reg lastSended		= 1'b0;

//assign address = SLAVE_ADDRESS;

always@(negedge clk)
begin
	if (!reset)
		begin
			lastReceived <= 1'b0;
			lastSended	<= 1'b0;
			stateFSM <= STATE_IDLE_0;
		end
	else
		begin
			case (stateFSM)
				STATE_IDLE_0:begin
					case ({lastReceived,received,lastSended,sended})	
					4'b0100:begin 
								stateFSM <= STATE_RECEIVE_2;
							 end
					4'b0001:begin 
								stateFSM <= STATE_SEND_4;		
							 end	 
					endcase
				end
				STATE_RECEIVE_2,
				STATE_SEND_4:begin
					stateFSM <= STATE_IDLE_0;
				end
			endcase	
			lastReceived <= received;				
			lastSended <= sended;	
		end
end

endmodule