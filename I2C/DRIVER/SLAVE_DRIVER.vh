//состояния
localparam STATE_IDLE_0						= 4'd0;
localparam STATE_RECEIVE_2					= 4'd2;	
localparam STATE_SEND_4						= 4'd4;
localparam STATE_STOP_7 					= 4'd7;
localparam STATE_GET_CHIP_ID_8			= 4'd8;
localparam STATE_GET_INT_16_LOW_9		= 4'd9;
localparam STATE_GET_INT_16_HIDH_10		= 4'd10;
								
//const address chip
localparam SLAVE_ADDRESS						= 7'h77;//1110111 address slave 
localparam SLAVE_ADDRESS_CHIP_ID				= 8'hD0;//address chipId 
localparam SLAVE_CHIP_ID						= 8'h5A;//chipId slave
localparam SLAVE_ADDRESS_GET_INT_16			= 8'h16;//get data 16 bit  
localparam SLAVE_ADDRESS_LOW_INT_16			= 8'hAF;
localparam SLAVE_ADDRESS_HIDH_INT_16		= 8'hA5;