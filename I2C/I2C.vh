//states
//MASTER
localparam STATE_IDLE_0							= 6'd0; //0x00		
localparam STATE_START_11						= 6'd11;//0x0B		
localparam STATE_WAIT_RESTART_12				= 6'd12;//0x0C		
localparam STATE_RESTART_13					= 6'd13;//0x0D		
localparam STATE_PREPARE_SEND_21				= 6'd21;//0x15		
localparam STATE_SEND_22						= 6'd22;//0x16		//going to STATE_STRETCH_51 state
localparam STATE_WAIT_ACK_31					= 6'd31;//0x1F		//going to STATE_STRETCH_53 state
localparam STATE_WAIT_GEN_ACK_32				= 6'd32;//0x20		//going to STATE_STRETCH_54 state
localparam STATE_ACK_33							= 6'd33;//0x21		
localparam STATE_PREPARE_RECEIVE_41			= 6'd41;//0x29		
localparam STATE_RECEIVE_42					= 6'd42;//0x2A		//going to STATE_STRETCH_57 state
localparam STATE_PREPARE_STRETCH_51			= 6'd51;//0x33		
localparam STATE_STRETCH_52					= 6'd52;//0x34		
localparam STATE_PREPARE_STRETCH_53			= 6'd53;//0x35		
localparam STATE_STRETCH_54					= 6'd54;//0x36		
localparam STATE_PREPARE_STRETCH_55			= 6'd55;//0x37		
localparam STATE_STRETCH_56					= 6'd56;//0x38		
localparam STATE_PREPARE_STRETCH_57			= 6'd57;//0x39		
localparam STATE_STRETCH_58					= 6'd58;//0x3A		
localparam STATE_STOP_63						= 6'd63;//0x3F		
//SLAVE
localparam STATE_WAIT_START_10				= 6'd10;//0x0A		
localparam STATE_WAIT_GEN_ACK_ADR_34		= 6'd34;//0x22		
localparam STATE_GEN_ACK_35					= 6'd35;//0x23		
localparam STATE_PREPARE_RECEIVE_ADR_43	= 6'd43;//0x2B		
localparam STATE_RECEIVE_ADR_44				= 6'd44;//0x2C		
localparam STATE_WAIT_STOP_62					= 6'd62;//0x3E		

//counter delay
localparam EIGHTH8								= 8'd31;
localparam QUARTER8								= 8'd62;
localparam HALF8									= 8'd124;
localparam STRETCH_2								= 8'd2;
