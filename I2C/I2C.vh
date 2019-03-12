//states
//MASTER
localparam STATE_IDLE_0						= 6'd0;
localparam STATE_START_11					= 6'd11;
localparam STATE_WAIT_RESTART_12			= 6'd12;
localparam STATE_RESTART_13				= 6'd13;
localparam STATE_PREPARE_SEND_21			= 6'd21;
localparam STATE_SEND_22					= 6'd22;//going to STATE_STRETCH_51 state
localparam STATE_WAIT_ACK_31				= 6'd31;//going to STATE_STRETCH_53 state
localparam STATE_WAIT_GEN_ACK_32			= 6'd32;//going to STATE_STRETCH_54 state
localparam STATE_ACK_33						= 6'd33;
localparam STATE_PREPARE_RECEIVE_41		= 6'd41;
localparam STATE_RECEIVE_42				= 6'd42;//going to STATE_STRETCH_57 state
localparam STATE_PREPARE_STRETCH_51		= 6'd51;
localparam STATE_STRETCH_52				= 6'd52;
localparam STATE_PREPARE_STRETCH_53		= 6'd53;
localparam STATE_STRETCH_54				= 6'd54;
localparam STATE_PREPARE_STRETCH_55		= 6'd55;
localparam STATE_STRETCH_56				= 6'd56;
localparam STATE_PREPARE_STRETCH_57		= 6'd57;
localparam STATE_STRETCH_58				= 6'd58;
localparam STATE_STOP_63					= 6'd63;

//const counter
localparam ZERO8						= 8'd0;
localparam ONE8						= 8'd1;

//counter delay
localparam QUARTER8					= 8'd62;
localparam HALF8						= 8'd124;
localparam STRETCH_2					= 8'd2;
