//состояния slave logic
localparam STATE_IDLE_0						= 4'd0;
localparam STATE_RECEIVE_2					= 4'd2;	
localparam STATE_SEND_4						= 4'd4;
localparam STATE_WAIT_STOP_6				= 4'd6;
localparam STATE_STOP_7 					= 4'd7;
localparam STATE_GET_CHIP_ID_8			= 4'd8;
localparam STATE_GET_INT_16_HIGH_9		= 4'd9;
localparam STATE_GET_INT_16_LOW_10		= 4'd10;
								
//const address chip
localparam SLAVE_ADDRESS						= 7'h77;//1110111 address slave 
localparam SLAVE_ADDRESS_CHIP_ID				= 8'hD0;//address chipId 
localparam SLAVE_CHIP_ID						= 8'h81;//chipId slave
localparam SLAVE_ADDRESS_GET_INT_16			= 8'h16;//get data 16 bit  
localparam SLAVE_ADDRESS_HIGH_INT_16		= 8'hAF;
localparam SLAVE_ADDRESS_LOW_INT_16			= 8'hA5;

//состояния master logic
localparam STATE_IDLE_10					= 6'd10;		//состояние ожидани выбора команды
localparam STATE_GET_ID_11					= 6'd11;
localparam STATE_WAIT_READY_12			= 6'd12;

localparam STATE_START_DATA_SEND_20		= 6'd20;
localparam STATE_START_PREPARE_SEND_21	= 6'd21;
localparam STATE_UNLOCK_DATA_SEND_22	= 6'd22;
localparam STATE_PREPARE_SEND_23			= 6'd23;
localparam STATE_SEND_24					= 6'd24;
localparam STATE_GEN_SEND_25				= 6'd25;

localparam STATE_PREPARE_SEND_TO_GET_30= 6'd30;
localparam STATE_SEND_TO_GET_31			= 6'd31;
localparam STATE_GEN_RECEIVE_32			= 6'd32;

localparam STATE_PREPARE_GET_40			= 6'd40;
localparam STATE_GET_41						= 6'd41;
localparam STATE_GEN_RECEIVE_42			= 6'd42;
localparam STATE_END_43						= 6'd43;

localparam STATE_PREPARE_SHOW_61			= 6'd61;
localparam STATE_SHOW_62					= 6'd62;
localparam STATE_SHOW_END_63				= 6'd63;