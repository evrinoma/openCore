module BMP180(
	swId, 
	swShow,
`ifdef FULL_QUERY_BMP180
	swSettings, swTemp, swGTemp, swPress, swGPress,  
`endif
	isReady,
	clk, reset, start, send, datasend, sended, receive, datareceive, received, out,
	state
);

input		wire clk;

input		wire swId;					//кнопка режим - прочитать ID чипа BMP180
input		wire swShow;				//кнопка режим - прочитать показать принятые данные

`ifdef FULL_QUERY_BMP180
input		wire swSettings;			//кнопка режим - прочитать коэфициенты чипа BMP180
input		wire swGTemp;				//кнопка режим - переключить режим на получение температуры
input		wire swTemp;				//кнопка режим - прочитать температуру
input		wire swGPress;				//кнопка режим - прочитать режим на получение давления
input		wire swPress;				//кнопка режим - прочитать давление
`endif

input		wire reset;					//сброс

input		wire isReady;				//готовность к новой транзакции

output	wire start;					//запустить транзакцию
output	wire send;					//отправить новую порцию данных до тех пор пока истинно
output	wire receive;				//принять новую порцию данных до тех пор пока истинно

output	wire [7:0] datasend;		//адрес и данные, которые шлем в устройство,  а так же тут задаем тип операции - чтения или записи данных
input		wire sended;				//сигнал записи новой порции данных при много байтном обмене

input		wire[7:0] datareceive;	//регистр принятых данных по шине - полученый байт
input		wire received;				//готовность полученого байта для выгрузки

output	wire[7:0] out;				//данные
output 	wire[5:0] state;

localparam ADR 				= 7'h77;		//адрес чипа BMP180
localparam READ				= 1'h1;		//чтение или запись 
localparam ADR_ID 			= 8'hD0;		//адрес регистра ID чипа
localparam START				= 1'h1; 		//режим старт для i2c мастера
localparam RESTART			= 1'h1; 		//режим рестарт для i2c мастера
localparam SEND				= 1'h1; 		//
localparam RECEIVE			= 1'h1; 		//

localparam STATE_IDLE_0						= 6'd0;		//состояние ожидани выбора команды
localparam STATE_GET_ID_11					= 6'd11;
localparam STATE_WAIT_READY_12			= 6'd12;

localparam STATE_UNLOCK_DATA_SEND_20	= 6'd20;
localparam STATE_PREPARE_SEND_21			= 6'd21;
localparam STATE_SEND_22					= 6'd22;
localparam STATE_GEN_SEND_23				= 6'd23;

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

localparam DELAY_START		= 16'h000F;
localparam NULL_16			= 16'h0000;
localparam NULL_8				= 8'h00;

localparam MAX_DATA			= 8'd21;

reg[26:0] 	data;

reg[5:0] 	stateFSM;
reg[15:0]	delayStart;
reg[2:0]		pCommand;
reg[7:0]		pData;
reg[7:0]		pOut;
reg[7:0]		Data	[MAX_DATA:0];
reg 			lastSended;
reg 			lastReceived;
reg 			singleQuery;				//одиночное срабатывание автомата

integer i;

reg 			lockDataSend;
reg 			lockStart;
reg 			lockSend;
reg 			lockReceive;

//мапинг ренистра data к примеру посылка чтения ID чипа 
//08 07 06 05 04 03 02 01 00
//S  D6 D5 D4 D3 D2 D1 D0 R/W
//  26   25 24 23 22 21 20 19  18  
//[ S]  [ADR                ]  [R]  
//  17   16 15 14 13 12 11 10  09
//[!S]  [ADR_ID                  ] 
//  08   07 06 05 04 03 02 01  00
//[ S]  [ADR                ]  [W]
assign datasend = !lockDataSend ? ( (pCommand==2) ? data[7:0] : (pCommand==1) ? data[16:9] : (pCommand==0) ? data[25:18] : NULL_8 ) : NULL_8;
assign start    = !lockStart    ? ( (pCommand==2) ? data[8]   : (pCommand==1) ? data[17]   : (pCommand==0) ? data[26]    : !START ) : !START;

assign send 	=  !lockSend 		? SEND 		: !SEND;
assign receive =  !lockReceive 	? RECEIVE 	: !RECEIVE;

assign out = (pOut <= MAX_DATA)? Data[pOut]: NULL_8;

assign state = stateFSM;

always@(posedge clk)
begin
//при сбросе конечного автомата выставлям параметры
if (!reset) 
	begin
		stateFSM 			<= STATE_IDLE_0;		//режим ожидания
		singleQuery		<= 1'b0;				//одиночное срабатывание автомата сброшено
		
		lastSended		<= 1'b0;	
		lastReceived	<= 1'b0;
		
		pCommand 		<= 2'd2;			
		pData				<= NULL_8;	

		data				<= 26'd0;
		pOut				<= NULL_8;
	end
else
	begin
		case (stateFSM)
			STATE_IDLE_0:begin
`ifdef FULL_QUERY_BMP180				
				case({swId, swSettings, swTemp, swPress, swGTemp, swGPress, swShow})
							7'b1011111,
							7'b1101111,
							7'b1110111,
							7'b1111011,
							7'b1111101:
							begin
								stateFSM <= STATE_IDLE_0;	
							end
							7'b0111111:
`else							
				case({swId, swShow})
							2'b01:
`endif
							begin
								if (!singleQuery)									//первое срабатываение автомата
									begin
										begin
											stateFSM 		<= STATE_GET_ID_11;	//переходим в режим установки передаваемых по шине I2C значений
											singleQuery	<= 1'b1;
										end
								end
							end
`ifdef FULL_QUERY_BMP180						
							7'b1111110:
`else	
							2'b10:
`endif
							begin
								stateFSM <= STATE_PREPARE_SHOW_61;	
							end
				endcase

				lastSended		<= 1'b0;
				lastReceived	<= 1'b0;
				pOut				<= NULL_8;
			end
			STATE_GET_ID_11: begin							//собираем посылку, устанавливаем указатель передачи и устнавливаем указатель на буфер принятых данных число принимаемых байт
				data[8:0]	<=	{START,ADR,!READ};
				data[17:9]	<=	{!START,ADR_ID};
				data[26:18]	<=	{RESTART,ADR, READ};
				stateFSM 		<= STATE_WAIT_READY_12;		//переходим в режим ожидания готовности автомата I2C
				pData			<= 8'd0;
				pCommand 	<= 2'd2;	
			end		
			STATE_WAIT_READY_12:begin						//переходим в режим обработки запросов автомата I2C, только после того как он сообщит нам что он простаивает
				if (isReady) 
				begin						
					stateFSM 	<= STATE_UNLOCK_DATA_SEND_20;
				end
			end
			
			STATE_UNLOCK_DATA_SEND_20,
			STATE_GEN_SEND_23:begin			//разрешаем данные для обработки и формируем сигнал start если он задан				
													//генерируем сигнал новой порции данных
					stateFSM 	<= STATE_PREPARE_SEND_21;
			end
			STATE_PREPARE_SEND_21:begin						//дожидаемся ответа от i2c мастера что данные переданы и он готов обработать новую порцию данных
				case ({lastSended,sended})					//сравниваем состояния сигнала уведомления 
					2'b01: begin
								stateFSM 	<= STATE_GEN_SEND_23;										
								pCommand <= pCommand - 2'd1;										
							 end
					2'b10: begin
								stateFSM 	<= STATE_SEND_22;																		
							 end
				endcase
				lastSended <= sended;
			end
			STATE_SEND_22:begin								//получен сигнал от местера что он хочетновую порцию данных
					if(pCommand == 2'd0)
						begin
							//если данные принимаются то переходим в режим приема данных. 
							//При этом от масетра придет должен прийти сигнал Sended, на который мы должны ответить сигналом прима данных
							stateFSM <= STATE_PREPARE_SEND_TO_GET_30;   	
						end
					else 	
						stateFSM <= STATE_UNLOCK_DATA_SEND_20;
			end
			
			STATE_PREPARE_SEND_TO_GET_30,
			STATE_GEN_RECEIVE_32:begin
					stateFSM 	<= STATE_SEND_TO_GET_31;
			end
			STATE_SEND_TO_GET_31:begin
				case ({lastSended,sended})				//сравниваем состояния сигнала уведомления 
					2'b01: begin
								stateFSM 	<= STATE_GEN_RECEIVE_32;	
							 end
					2'b10: begin
								stateFSM 	<= STATE_PREPARE_GET_40;																		
							 end
				endcase				
				lastSended <= sended;	
			end
	
	
			STATE_PREPARE_GET_40,
			STATE_GEN_RECEIVE_42:begin
					stateFSM 	<= STATE_GET_41;
			end		
			STATE_GET_41:begin
				case ({lastReceived,received})				//сравниваем состояния сигнала уведомления 
					2'b01: begin
								if (pData == 8'h00)
										stateFSM <= STATE_PREPARE_GET_40;
								else 
									begin
										stateFSM <= STATE_GEN_RECEIVE_42;	
										pData <= pData - 8'd1;	
									end
							 end
					2'b10: begin
								stateFSM 	<= STATE_END_43;																		
							 end
				endcase				
				lastReceived	<= received;	
			end
			STATE_END_43:begin
					if (pData == 8'h00)
						stateFSM <= STATE_IDLE_0;
					else 	
						stateFSM <= STATE_GET_41;
			end
			STATE_PREPARE_SHOW_61:begin
					if (swShow)
					begin
						pOut 		<= pOut + 8'd1;
						stateFSM <= STATE_SHOW_62;
					end
			end
			STATE_SHOW_62: begin
					if (!swShow)
					begin
						stateFSM <= (pOut == MAX_DATA) ? STATE_SHOW_END_63 : STATE_PREPARE_SHOW_61;
					end
			end
			STATE_SHOW_END_63: begin
					if (swShow)
					begin
						stateFSM <= STATE_IDLE_0;
					end
			end
		endcase
	end	
end

always@(posedge clk)
begin
	if (!reset)
		begin
			lockDataSend	<= 1'b1;				//сброс шины данных
			lockStart		<= 1'b1;				//сброс бита start
			lockSend			<= 1'b1;				//сброс шины данных
			lockReceive		<= 1'b1;				//сброс бита start
			delayStart		<= DELAY_START;
			
		end
	else
		begin
			case (stateFSM)	
				STATE_IDLE_0:begin					
						lockDataSend	<= 1'b1;				//сброс шины данных
						lockStart		<= 1'b1;				//сброс бита start
						lockSend			<= 1'b1;				//сброс шины данных
						lockReceive		<= 1'b1;				//сброс бита start
						delayStart		<= DELAY_START;	
				end
				STATE_GEN_SEND_23,
				STATE_UNLOCK_DATA_SEND_20:begin			//переходим в режим обработки запросов автомата I2C, только после того как он сообщит нам что он простаивает
						lockDataSend	<= 1'b0;				//разрешаем шину данных
						delayStart	<= NULL_16;	
						lockSend		<= 1'b0;	
						lockReceive	<= 1'b1;
				end	
				STATE_GEN_RECEIVE_32,				
				STATE_GEN_RECEIVE_42:begin
					lockSend		<= 1'b1;
					lockReceive	<= 1'b0;
				end
				STATE_GET_ID_11,		
				STATE_WAIT_READY_12,
				STATE_PREPARE_SEND_21,	
				STATE_SEND_22,	
				STATE_PREPARE_SEND_TO_GET_30,
				STATE_SEND_TO_GET_31,
				STATE_PREPARE_GET_40,
				STATE_GET_41,
				STATE_END_43,
				STATE_SHOW_62:begin
						lockSend		<= 1'b1;
						lockReceive	<= 1'b1;
				end			
			endcase	
			if(delayStart == DELAY_START) 	  //задержка
				begin		
					lockStart	<= 1'b1;	  //сброс бита start
				end
			else
				begin
					delayStart <= delayStart + 16'd1;	
					lockStart 	<= 1'b0;	  //сброс бита start
				end
		
		end 
end	

always@(posedge clk or negedge reset )
begin
	if(!reset)
		begin
			for(i=0;i<=MAX_DATA;i=i+1)
				Data[i] = NULL_8;
		end
	else
		begin
			Data[pData] <= datareceive;
		end
end


endmodule
