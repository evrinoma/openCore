//состояния
localparam STATE_IDLE_0						= 2'd0;
localparam STATE_RECEIVE_2					= 2'd2;	
localparam STATE_SEND_4						= 2'd4;
localparam STATE_STOP_7 					= 2'd7;
								
//const address chip
localparam SLAVE_ADDRESS						= 7'h77;//1110111 address slave 
localparam SLAVE_ADDRESS_CHIP_ID				= 8'hD0;//address chipId 
localparam SLAVE_CHIP_ID						= 8'h55;//chipId slave

