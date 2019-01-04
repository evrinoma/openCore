module BMP180(swId, swSettings, swTemp, swGTemp, swPress, swGPress, swShow, clk, reset, start, send, datasend, sended, receive, datareceive, received, out);

input		wire clk;

input		wire swId;					//кнопка режим - прочитать ID чипа BMP180
input		wire swSettings;			//кнопка режим - прочитать коэфициенты чипа BMP180
input		wire swGTemp;				//кнопка режим - переключить режим на получение температуры
input		wire swTemp;				//кнопка режим - прочитать температуру
input		wire swGPress;				//кнопка режим - прочитать режим на получение давления
input		wire swPress;				//кнопка режим - прочитать давление
input		wire swShow;				//кнопка режим - прочитать показать принятые данные

input		wire reset;					//сброс
output	reg start;					//запустить транзакцию

output	reg send;					//отправить новую порцию данных до тех пор пока истинно
output	wire [7:0] datasend;		//адрес и данные, которые шлем в устройство,  а так же тут задаем тип операции - чтения или записи данных
input		wire sended;				//сигнал записи новой порции данных при много байтном обмене

output	reg receive;				//принять новую порцию данных до тех пор пока истинно
input		wire[7:0] datareceive;	//регистр принятых данных по шине - полученый байт
input		wire received;				//готовность полученого байта для выгрузки

output	wire [7:0] out;			//данные


localparam ADR 				= 7'h77;
localparam READ				= 1'h1;
localparam ADR_ID 			= 8'hD0;
localparam ADR_SETTINGS 	= 8'hAA;
localparam ADR_CONFIG 		= 8'hF4;
localparam ADR_DATA 			= 8'hF6;
localparam OSS					= 2'h0; 
localparam CONFIG_TEMP 		= 8'h2E;
localparam CONFIG_PRESS		= 8'h34+(OSS <<  6);

localparam STATE_IDLE			= 4'd0;
localparam STATE_START			= 4'd1;
localparam STATE_SETTINGS		= 4'd2;
localparam STATE_COMMAND		= 4'd3;
localparam STATE_GET				= 4'd4;
localparam STATE_SHOW			= 4'd5;
localparam STATE_GET_ID			= 4'd6;
localparam STATE_GET_SETTINGS	= 4'd7;
localparam STATE_SET_TEMP		= 4'd8;
localparam STATE_SET_PRESS		= 4'd9;
localparam STATE_GET_DATA		= 5'd10;
localparam STATE_BLINK			= 4'd11;

localparam MAX					= 16'h00FF;
localparam NULL				= 8'h00;

localparam MAX_DATA			= 8'd21;

reg[23:0] 	data;

reg[3:0] 	state;
reg[15:0]	delay;
reg[2:0]		pCommand;
reg[7:0]		pData;
reg[7:0]		pOut;
reg[7:0]		Data	[MAX_DATA:0];
reg 			lastSended;
reg 			lastReceived;

wire			read;

integer i;

assign datasend = (pCommand==2)? data[7:0] : (pCommand==1)? data[15:8] : (pCommand==0)? data[23:16] : NULL;
assign read = datasend[0];
assign out = (pOut <= MAX_DATA)? Data[pOut]: NULL;


always@(posedge clk)
begin
if (!reset) 
	begin
		state 			<= STATE_IDLE;
		send 				<= 1'b0;
		receive 			<= 1'b0;
		delay 			<= 16'd0;
		pCommand 		<= 2'd2;
		pData				<= 8'd0;
		data				<= 23'd0;
		lastSended		<= 1'b0;	
		lastReceived	<= 1'b0;	
		start				<= 1'b1;
		pOut				<= 8'd0;
	end
else
	begin
		case (state)
			STATE_IDLE:begin
				case({swId, swSettings, swTemp, swPress, swGTemp, swGPress, swShow})
						7'b0111111:begin
								if(delay == MAX) 
									begin
										state 		<= STATE_GET_ID;
										delay 		<= 16'd0;
									end
								else
									delay <= delay + 16'd1;
							end
						7'b1011111:begin
								if(delay == MAX) 
									begin
										state 		<= STATE_GET_SETTINGS;
										delay 		<= 16'd0;
									end
								else
									delay <= delay + 16'd1;
							end
						7'b1101111:begin
								if(delay == MAX) 
									begin
										state 		<= STATE_SET_TEMP;
										delay 		<= 16'd0;
									end
								else
									delay <= delay + 16'd1;
						end
						7'b1110111:begin
								if(delay == MAX) 
									begin
										state 		<= STATE_SET_PRESS;
										delay 		<= 16'd0;
									end
								else
									delay <= delay + 16'd1;
						end
						7'b1111011:begin
								if(delay == MAX) 
									begin
										state <= STATE_GET_DATA;
										delay <= 16'd0;
									end
								else
									delay <= delay + 16'd1;
						end	
						7'b1111101:begin
								if(delay == MAX) 
									begin
										state <= STATE_GET_DATA;
										delay <= 16'd0;
									end
								else
									delay <= delay + 16'd1;
						end
						7'b1111110:begin
								if(delay == MAX) 
									begin
										state <= STATE_SHOW;
										delay <= 16'd0;
									end
								else
									delay <= delay + 16'd1;
						end			
				endcase
				start			<= 1'b1;
				send 			<= 1'b0;
				receive	 	<= 1'b0;
				lastSended	<= 1'b0;
				lastReceived	<= 1'b0;
				pOut				<= 8'd0;
			end
			STATE_GET_ID: begin
				data[7:0]	<=	{ADR,!READ};
				data[15:8]	<=	ADR_ID;
				data[23:16]	<=	{ADR, READ};
				state 		<= STATE_START;
				pData			<= 8'd0;
				pCommand 	<= 2'd2;	
			end
			STATE_GET_SETTINGS: begin
				data[7:0]	<=	{ADR,!READ};
				data[15:8]	<=	ADR_SETTINGS;
				data[23:16]	<=	{ADR, READ};
				state 		<= STATE_START;				
				pData			<= 8'd21;
				pCommand 	<= 2'd2;
			end
			STATE_SET_PRESS: begin
				data[7:0]	<=	{ADR,!READ};
				data[15:8]	<=	ADR_CONFIG;
				data[23:16]	<=	{CONFIG_PRESS};
				state 		<= STATE_START;
				pData			<= 8'hFF;
				pCommand 	<= 2'd2;	
			end
			STATE_SET_TEMP: begin
				data[7:0]	<=	{ADR,!READ};
				data[15:8]	<=	ADR_CONFIG;
				data[23:16]	<=	{CONFIG_TEMP};
				state 		<= STATE_START;
				pData			<= 8'hFF;
				pCommand 	<= 2'd2;
			end
			STATE_GET_DATA: begin
				data[7:0]	<=	{ADR,!READ};
				data[15:8]	<=	ADR_DATA;
				data[23:16]	<=	{ADR, READ};
				state 		<= STATE_START;
				pData			<= 8'd2;
				pCommand 	<= 2'd2;
			end
			STATE_START: begin
				if(delay == (MAX/4) )
					begin
						state <= STATE_COMMAND;
						delay <= 16'd0;
						start	<=	1'b1;
					end
				else
					begin
						delay <= delay + 16'd1;
						start	<=	1'b0;
					end
			end
			STATE_COMMAND:begin			
						case ({lastSended,sended})
							2'b01: begin
										if (read)
											begin
												send 		<= 1'b0;
												receive	<= 1'b1;
											end
										else
											begin
												send 		<= 1'b1;
												receive	<= 1'b0;
											end
										pCommand <= pCommand - 2'd1;
										lastSended <= sended;
									 end
							2'b10: begin
										send 		<= 1'b0;
										receive	<= 1'b0;
										if(pCommand == 2'd0)
											begin
												if (pData == 8'hFF)
													state 		<= STATE_IDLE;
												else
													state 		<= STATE_GET;
											end
										lastSended <= sended;
									 end
						endcase
				
			end
			STATE_GET:begin
				case ({lastReceived,received})
					2'b01: begin
								if (pData != NULL) 
									begin
										receive	<= 1'b1;
									end
								pData <= pData - 8'd1;
								
							 end
					2'b10: begin
								receive	<= 1'b0;
								if (pData == 8'hFF)
									state 		<= STATE_IDLE;
								pCommand 	<= 2'h3;
							 end
				endcase
				
				lastReceived	<= received;	
			end
			STATE_SHOW: begin
				if (!swShow) 
					begin
						if(delay == MAX) 
							begin
								if (pOut==MAX_DATA) 
									state 		<= STATE_BLINK;
								pOut <= pOut + 8'd1;
								delay <= 16'd0;
							end
						else
							delay <= delay + 8'd1;
					end
				else
					delay <= 16'd0;
			end
			STATE_BLINK: begin
				if(delay == MAX) 
					begin
						pOut <= pOut - 16'd1;
						state 		<= STATE_SHOW;
						delay <= 16'd0;
					end
				else
					delay <= delay + 16'd1;
			end
		endcase
	end	
end


always@(posedge received or negedge reset )
begin
	if(!reset)
		begin
			for(i=0;i<(MAX_DATA+1);i=i+1)
				Data[i] = NULL;
		end
	else
		begin
			Data[pData] <= datareceive;
		end
end


endmodule
