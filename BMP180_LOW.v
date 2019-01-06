module BMP180_LOW(swId, swShow, clk, reset, start, send, datasend, sended, receive, datareceive, received, out, stateOut);

input		wire clk;

input		wire swId;					//кнопка режим - прочитать ID чипа BMP180
input		wire swShow;				//кнопка режим - прочитать показать принятые данные

input		wire reset;					//сброс
output	reg start;					//запустить транзакцию
output	wire [3:0] stateOut;					

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

localparam STATE_IDLE			= 3'd0;
localparam STATE_START			= 3'd1;
localparam STATE_COMMAND		= 3'd3;
localparam STATE_GET				= 3'd4;
localparam STATE_SHOW			= 3'd5;
localparam STATE_GET_ID			= 3'd6;
localparam STATE_BLINK			= 3'd7;

//localparam MAX					= 16'h00FF;
localparam MAX					= 8'h0F;
localparam MAX_LOAD			= 8'h02;
localparam NULL				= 8'h00;

//localparam MAX_DATA			= 8'd21;
localparam MAX_DATA			= 2'b11;

reg[23:0] 	data;

reg[3:0] 	state;
reg[7:0]		delay;
reg[2:0]		pCommand;
reg[7:0]		pData;
reg[1:0]		pOut;
reg[7:0]		Data	[MAX_DATA:0];
reg 			lastSended;
reg 			lastReceived;

wire			read;

integer i;

assign datasend = (pCommand==2)? data[7:0] : (pCommand==1)? data[15:8] : (pCommand==0)? data[23:16] : NULL;
assign read = datasend[0];
assign out = (pOut <= MAX_DATA)? Data[pOut]: NULL;
assign stateOut = state;

always@(posedge clk)
begin
if (!reset) 
	begin
		state 			<= STATE_IDLE;
		send 				<= 1'b0;
		receive 			<= 1'b0;
		delay 			<= 8'd0;
		pCommand 		<= 2'd2;
		pData				<= NULL;
		data				<= 23'd0;
		lastSended		<= 1'b0;	
		lastReceived	<= 1'b0;	
		start				<= 1'b1;
		pOut				<= 2'd0;
	end
else
	begin
		case (state)
			STATE_IDLE:begin
				case({swId,swShow})
				   2'b01:begin
								if(delay == MAX) 
									begin
										state 		<= STATE_GET_ID;
										delay 		<= 8'd0;
									end
								else
									delay <= delay + 8'd1;
							end						
				   2'b10:begin
								if(delay == MAX) 
									begin
										state <= STATE_SHOW;
										delay <= 8'd0;
									end
								else
									delay <= delay + 8'd1;
							end			
				endcase
				start			<= 1'b1;
				send 			<= 1'b0;
				lastSended	<= 1'b0;
				receive	 	<= 1'b0;
				lastReceived	<= 1'b0;
				pOut				<= 2'd0;
				pCommand 	<= 2'd2;
			end
			STATE_GET_ID: begin
				if (pData == 8'hFF)
					state 		<= STATE_IDLE;
				else
					begin
						data[7:0]	<=	{ADR,!READ};
						data[15:8]	<=	ADR_ID;
						data[23:16]	<=	{ADR, READ};
						state 		<= STATE_START;
						pData			<= NULL;
					end
			end
			STATE_START: begin
				if(delay == (MAX/4) )
					begin
						state <= STATE_COMMAND;
						delay <= 8'd0;
						start	<=	1'b1;
					end
				else
					begin
						delay <= delay + 8'd1;
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
									 end
							2'b10: begin
										send 		<= 1'b0;
										receive	<= 1'b0;
										if(pCommand == 2'd0)
											begin
													state 		<= STATE_GET;
											end
									 end
						endcase
						lastSended <= sended;
			end
			STATE_GET:begin
				case ({lastReceived,received})
					2'b01: begin
								if (pData != NULL) 
									begin
										receive	<= 1'b1;
									end
								pData <= pData + 8'd1;								
							 end
					2'b10: begin
								receive	<= 1'b0;
								if (pData == MAX_LOAD)
									state 		<= STATE_IDLE;
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
								pOut <= pOut + 2'd1;
								delay <= 8'd0;
							end
						else
							delay <= delay + 8'd1;
					end
				else
					delay <= 8'd0;
			end
			STATE_BLINK: begin
				if(delay == MAX) 
					begin
						pOut <= pOut - 2'd1;
						state 		<= STATE_SHOW;
						delay <= 8'd0;
					end
				else
					delay <= delay + 8'd1;
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
