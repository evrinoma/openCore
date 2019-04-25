`ifndef DEBUG_SLAVE_DRIVER
	`define DEBUG_SLAVE_DRIVER
	`undef DEBUG_SLAVE_DRIVER
`endif

module SLAVE_DRIVER(
`ifdef DEBUG_SLAVE_DRIVER
dstate, 
`endif
clk, reset, address, datasend, sended, datareceive, received);

`include "SLAVE_DRIVER.vh"
`include "../../UTILS/NO_ARCH.vh"

input wire clk;					//сигнал тактовой частоты
input wire reset;					//сигнал сброса

output reg[7:0] datasend;		//
input	wire sended;				//

input wire[7:0] datareceive;	//
input	wire received;				//

output reg[6:0] address = SLAVE_ADDRESS; 		//регистр адреса устройства

`ifdef DEBUG_SLAVE_DRIVER
output wire[6:0] dstate;
`endif

reg[2:0] stateFSM;				//состояние	
reg[3:0] stateDRIVER;	
reg[3:0] lastStateDRIVER;


reg lastReceived	= 1'b0;
reg lastSended		= 1'b0;

`ifdef DEBUG_SLAVE_DRIVER
assign dstate = {stateDRIVER,stateFSM};
`endif

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
					stateFSM <= STATE_WAIT_STOP_6;
				end
				STATE_WAIT_STOP_6:begin
					if (4'b0000 == {lastReceived,received,lastSended,sended})
						stateFSM <= STATE_IDLE_0;
				end
			endcase	
			lastReceived <= received;				
			lastSended <= sended;	
		end
end

always@(posedge clk)
begin
	if (!reset)
		begin
			datasend<=ZERO8;
			stateDRIVER<=STATE_IDLE_0;
			lastStateDRIVER<=STATE_IDLE_0;
		end
	else
		begin
			case (stateDRIVER)
				STATE_IDLE_0:begin
					stateDRIVER <= (stateFSM == STATE_RECEIVE_2)?STATE_RECEIVE_2:(stateFSM == STATE_SEND_4)?STATE_SEND_4:STATE_IDLE_0;
				end
				STATE_RECEIVE_2:begin
					case (datareceive)
						SLAVE_ADDRESS_CHIP_ID:begin
							stateDRIVER <= STATE_GET_CHIP_ID_8;						
						end
						SLAVE_ADDRESS_GET_INT_16:begin
							stateDRIVER <= STATE_GET_INT_16_LOW_10;						
						end
						default:begin
							stateDRIVER <= STATE_STOP_7;
							lastStateDRIVER<=STATE_IDLE_0;
							datasend<=ZERO8;
						end
					endcase
				end
				STATE_SEND_4:begin
					case (lastStateDRIVER)
						STATE_GET_INT_16_LOW_10:begin
							stateDRIVER <= STATE_GET_INT_16_HIGH_9;						
						end
						default:begin
							stateDRIVER <= STATE_STOP_7;
						end
					endcase
				end
				STATE_STOP_7:begin
					stateDRIVER <= STATE_IDLE_0;
				end
				STATE_GET_CHIP_ID_8:begin				
					datasend<=SLAVE_CHIP_ID;
					stateDRIVER <= STATE_STOP_7;
				end
				STATE_GET_INT_16_LOW_10:begin				
					datasend<=SLAVE_ADDRESS_LOW_INT_16;
					lastStateDRIVER<= STATE_GET_INT_16_LOW_10;
					stateDRIVER <= STATE_STOP_7;
				end
				STATE_GET_INT_16_HIGH_9:begin				
					datasend<=SLAVE_ADDRESS_HIGH_INT_16;
					lastStateDRIVER<= STATE_IDLE_0;
					stateDRIVER <= STATE_STOP_7;
				end
			endcase
		end
end

endmodule