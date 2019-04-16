//состояния
localparam STATE_IDLE_0						= 4'd0;
localparam STATE_RECEIVE_2					= 4'd2;	
localparam STATE_SEND_4						= 4'd4;
localparam STATE_STOP_7 					= 4'd7;
localparam STATE_GET_CHIP_ID_8			= 4'd8;
								
//const address chip
localparam SLAVE_ADDRESS						= 7'h77;//1110111 address slave 
localparam SLAVE_ADDRESS_CHIP_ID				= 8'hD0;//address chipId 
localparam SLAVE_CHIP_ID						= 8'h5A;//chipId slave

