module MASTER_DRIVER(
	isReady,
	clk, reset, start, send, datasend, sended, receive, datareceive, received,
	address,
	loadAddress,
	length,
	loadLength,
	control,
	loadControl,
	status,
	toPut,
	dataTo
);

input		wire clk;

input		wire reset;					//сброс

input		wire isReady;				//готовность к новой транзакции

output	wire start;					//запустить транзакцию
output	wire send;					//отправить новую порцию данных до тех пор пока истинно
output	wire receive;				//принять новую порцию данных до тех пор пока истинно

output	wire [7:0] datasend;		//адрес и данные, которые шлем в устройство,  а так же тут задаем тип операции - чтения или записи данных
input		wire sended;				//сигнал записи новой порции данных при много байтном обмене

input		wire[7:0] datareceive;	//регистр принятых данных по шине - полученый байт
input		wire received;				//готовность полученого байта для выгрузки

input		wire[6:0] address;		//адресс ведомого устройства
input		wire loadAddress;			//защелкнуть адресс 
input		wire[31:0] length;		//длина посылки
input		wire loadLength;			//защелкнуть адресс
input		wire[15:0] control;		//управление
input		wire loadControl;			//защелкнуть управление			
output	wire[15:0] status;		//статус 



//блок фифо отправляемых данных
//wire toGet;
input wire toPut;
input wire [7:0]  dataTo;
wire [7:0]  dataToOut;
wire toIsEmpty;
wire toIsFull;

defparam to.FIFO_SIZE_EXP = 3;

FIFO to (
// port map - connection between master ports and signals/registers   
        .clk(clk),
        .dataIn(dataTo),
        .dataOut(dataToOut),
        .get(send),
        .isEmpty(toIsEmpty),
        .isFull(toIsFull),
        .put(toPut),
        .reset(reset)
);


//блок фифо принимаемых данных
wire fromGet;
wire [7:0]  dataFrom;
wire fromIsEmpty;
wire fromIsFull;

defparam from.FIFO_SIZE_EXP = 3;

FIFO from (
// port map - connection between master ports and signals/registers   
        .clk(clk),
        .dataIn(datareceive),
        .dataOut(dataFrom),
        .get(fromGet),
        .isEmpty(fromIsEmpty),
        .isFull(fromIsFull),
        .put(received),
        .reset(reset)
);


localparam ADR 				= 7'h77;		//адрес чипа BMP180
localparam READ				= 1'h1;		//чтение или запись 
localparam ADR_ID 			= 8'hD0;		//адрес регистра ID чипа
localparam START				= 1'h1; 		//режим старт для i2c мастера
localparam RESTART			= 1'h1; 		//режим рестарт для i2c мастера
localparam SEND				= 1'h1; 		//
localparam RECEIVE			= 1'h1; 		//



localparam STATE_IDLE_0						= 6'd0;		//состояние ожидани выбора команды
localparam STATE_WAIT_READY_11			= 6'd11;
localparam STATE_INIT_READ_12				= 6'd12;
localparam STATE_INIT_WRITE_13			= 6'd13;
localparam STATE_DEC_LENGTH_LOW_14			= 6'd14;
localparam STATE_INC_LENGTH_LOW_15			= 6'd15;
localparam STATE_DEC_LENGTH_HIGH_16			= 6'd16;
localparam STATE_INC_LENGTH_HIGH_17			= 6'd17;



localparam STATE_NOP_START_DATA_SEND_19		= 6'd19;
localparam STATE_START_DATA_SEND_20		= 6'd20;
localparam STATE_START_PREPARE_SEND_21	= 6'd21;
localparam STATE_RESTART_PREPARE_SEND_26	= 6'd21;
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

localparam RESET_ST			= 16'hFF7F;					//сброс бита старта
localparam DELAY_START		= 16'h000F;
localparam NULL_16			= 16'h0000;
localparam NULL_32			= 32'h00000000;
localparam ONE_16				= 16'h0001;
localparam NULL_8				= 8'h00;
localparam NULL_7				= 7'h00;
localparam HIGH_HALF_16		= 16'hFF00;
localparam LOW_HALF_16		= 16'h00FF;

localparam TYPE_R			= 2'd1;
localparam TYPE_W			= 2'd2;
localparam TYPE_WR		= 2'd3;


reg[5:0] 	stateFSM;
reg[5:0] 	saveStateFSM;

reg[2:0]		pCommand;
reg[7:0]		pData;
reg 			lastSended;
reg 			lastReceived;

reg 			lockSend;
reg 			lockReceive;
reg			loadControlSt;		//защелкнуть сигнал управления St

//Re - reserved
//register  control 
//  15	14	13	12	11	10	09	08	07	06	05 04 03	02 01 00
//[ Re	Re	Re	Re	Re	Re	Re	Re	ST	Re	Re	Re	Re	Re	W	R	]
//register length 
//  31..16 			15..00
//[ length Read	length Write]
//register  status 
//  15	14	13	12	11	10	09	08	07	06	05 04 	03				02 			01 		00
//[ Re	Re	Re	Re	Re	Re	Re	Re	ST	Re	Re	len	fromIsFull	fromIsEmpty	toIsFull	toIsEmpty	]

reg[15:0]	cont;				//регистр управления контроллером 
reg[6:0]		addr;				//регистр адресата 
reg[31:0]	len;				//регистр кол-ва передаваемых байт 
reg[7:0]		data;

reg 			lockStart;
reg[15:0]	delayStart;
reg 			lockDataSend;

assign datasend = !lockDataSend ? data  : NULL_8;
assign start    = !lockStart;
assign status = NULL_16 | {(len == NULL_16 ? 1'h1:1'h0),fromIsFull,fromIsEmpty,toIsFull,toIsEmpty};

assign send 	=  !lockSend 		? SEND 		: !SEND;
assign receive =  !lockReceive 	? RECEIVE 	: !RECEIVE;

always@(posedge clk)
begin
//при сбросе конечного автомата выставлям параметры
if (!reset) 
	begin
		stateFSM 			<= STATE_IDLE_0;		//режим ожидания
		saveStateFSM		<= STATE_IDLE_0;		//режим ожидания
		lastSended		<= 1'b0;
		lastReceived	<= 1'b0;
		
		pCommand 		<= 2'd2;
		pData				<= NULL_8;
	
		loadControlSt <=	1'b0;
		data <= NULL_8;
	end
else
	begin
		case (stateFSM)
			STATE_IDLE_0:begin			
				if (cont[7] && !loadControl) 				//если установлен бит запуска и запись в регистр завершена то запускаем процесс передачи
					begin
						stateFSM			<= STATE_WAIT_READY_11;						
						loadControlSt	<=	1'b1;
					end
				else 
					begin
						lastSended		<= 1'b0;
						lastReceived	<= 1'b0;
						loadControlSt <=	1'b0;
					end
			end
			STATE_WAIT_READY_11:begin				//переходим в режим обработки запросов автомата I2C, только после того как он сообщит нам что он простаивает
				if (isReady) 
					begin						
						loadControlSt <=	1'b0;
						case (cont[1:0])				//определяем тип тразакции
							TYPE_R:begin
										saveStateFSM 	<= STATE_NOP_START_DATA_SEND_19;
										stateFSM 	<= STATE_INIT_READ_12;
									 end
							TYPE_W,
							TYPE_WR:begin
										saveStateFSM 	<= STATE_NOP_START_DATA_SEND_19;
										stateFSM 	<= STATE_INIT_WRITE_13;	
									 end
						endcase
					end
			end
			STATE_INIT_READ_12:begin
				data <= {addr,READ};
				stateFSM 	<= saveStateFSM;
			end
			STATE_INIT_WRITE_13:begin
				data 	<= {addr,!READ};
				stateFSM 	<= saveStateFSM;
			end
			STATE_NOP_START_DATA_SEND_19:begin			//разрешаем данные для обработки и формируем сигнал start если он задан				
																	//генерируем сигнал новой порции данных
					stateFSM 	<= STATE_START_DATA_SEND_20;
			end
			STATE_START_DATA_SEND_20:begin				//разрешаем данные для обработки и формируем сигнал start если он задан				
																	//генерируем сигнал новой порции данных
					stateFSM 	<= STATE_START_PREPARE_SEND_21;
			end
			STATE_UNLOCK_DATA_SEND_22,
			STATE_GEN_SEND_25:begin
				stateFSM 	<= STATE_PREPARE_SEND_23;
			end
			STATE_START_PREPARE_SEND_21,
			STATE_RESTART_PREPARE_SEND_26,
			STATE_PREPARE_SEND_23:begin					//дожидаемся ответа от i2c мастера что данные переданы и он готов обработать новую порцию данных
				case ({lastSended,sended})					//сравниваем состояния сигнала уведомления 
					2'b01: begin
								stateFSM 	<= STATE_GEN_SEND_25;
								data 	<= dataToOut;		//пришел сигнал от мастера что он передал порцию данных и находится в режиме ожидания ACK подтвержения,
																	//поэтому можно обновить данные в регистре данных идущих в к мастеру
							 end
					2'b10: begin
								stateFSM 	<= STATE_SEND_24;
							 end
				endcase
				lastSended <= sended;
			end
			STATE_DEC_LENGTH_LOW_14:begin
				stateFSM<=saveStateFSM;	
			end
			STATE_INC_LENGTH_LOW_15:begin
				stateFSM<=STATE_INIT_READ_12;	
			end
			STATE_SEND_24:begin								//получен сигнал от местера что он хочетновую порцию данных
					if (len[15:0] == NULL_16)	
						begin
							if (cont[1:0] == TYPE_WR) 						//передали все данные - проверяем режим - 
								begin												//если это режим записи с рестартом и чтением
									stateFSM 	<=STATE_INC_LENGTH_LOW_15;		
									saveStateFSM 	<= STATE_RESTART_PREPARE_SEND_26;
								end
							else
								begin												//это режим просто записи то выходим в ожидание
									stateFSM 	<= STATE_IDLE_0;	
								end
						end
					else
						begin		//
							saveStateFSM <= STATE_UNLOCK_DATA_SEND_22;	//сохраняем состояние, в которое нужно перейти в новом сосотянии - отправка данных
							stateFSM 	<=STATE_DEC_LENGTH_LOW_14;				//переходим в новое состояние и уменьшание счетчик отправляемых байт на единицу
						end
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
		endcase
	end	
end

//автомат отработки stateFSM
always@(posedge clk)
begin
	if (!reset)
		begin
			
			
			lockReceive		<= 1'b1;				//сброс бита start
			lockSend			<= 1'b1;				//сброс шины данных
				
			lockStart	<= 1'b1;				//сброс бита start
			delayStart	<= DELAY_START;
			lockDataSend	<= 1'b1;				//сброс шины данных
		end
	else
		begin
			case (stateFSM)	
				STATE_IDLE_0:begin		
						lockSend			<= 1'b1;				//сброс шины данных
						lockReceive		<= 1'b1;				//сброс бита start
						lockStart	<= 1'b1;	
						delayStart	<= DELAY_START;	
						lockDataSend	<= 1'b1;
				end
				STATE_NOP_START_DATA_SEND_19:begin										
						lockSend		<= 1'b0;	
						lockReceive	<= 1'b1;
						lockDataSend	<= 1'b0;
				end
				STATE_START_DATA_SEND_20:begin		//переходим в режим обработки запросов автомата I2C, только после того как он сообщит нам что он простаивает
						delayStart	<= NULL_16;
						lockSend		<= 1'b1;
						lockReceive	<= 1'b1;
				end	
				STATE_GEN_SEND_25:begin		//переходим в режим обработки запросов автомата I2C, только после того как он сообщит нам что он простаивает
						delayStart	<= DELAY_START;
						if (saveStateFSM!=STATE_RESTART_PREPARE_SEND_26)
							begin
								lockSend		<= 1'b0;
								lockReceive	<= 1'b1;
							end
						else
							begin
								lockSend		<= 1'b1;
								lockReceive	<= 1'b0;
							end
						lockDataSend	<= 1'b0;
				end	
				STATE_GEN_RECEIVE_32,				
				STATE_GEN_RECEIVE_42:begin
					lockSend		<= 1'b1;
					lockReceive	<= 1'b0;
				end
				STATE_PREPARE_SEND_23:begin
					if (len[15:0] == NULL_16 & cont[1:0] == TYPE_WR & !lockSend) 
					begin
						delayStart	<= NULL_16;
					end
					lockSend		<= 1'b1;
					lockReceive	<= 1'b1;
				end
				STATE_INIT_READ_12,
				STATE_INIT_WRITE_13,
				STATE_WAIT_READY_11,
				STATE_DEC_LENGTH_LOW_14,
				STATE_INC_LENGTH_LOW_15,
				STATE_DEC_LENGTH_HIGH_16,
				STATE_INC_LENGTH_HIGH_17,
				STATE_START_PREPARE_SEND_21,
				STATE_RESTART_PREPARE_SEND_26,
				STATE_UNLOCK_DATA_SEND_22,
				STATE_SEND_24,	
				STATE_PREPARE_SEND_TO_GET_30,
				STATE_SEND_TO_GET_31,
				STATE_PREPARE_GET_40,
				STATE_GET_41,
				STATE_END_43:begin
						lockSend		<= 1'b1;
						lockReceive	<= 1'b1;
				end
		////////////////////////////////////		
			endcase	
			if(delayStart == DELAY_START) 	  //задержка
				begin		
					lockStart	<= 1'b1;	  //сброс бита start
				end
			else
				begin
					delayStart <= delayStart + ONE_16;	
					lockStart 	<= 1'b0;	  //сброс бита start
				end
		end 
end	





//адресс ведомого устройства
always@(posedge clk)
begin
if (!reset) 
	begin			
		addr <= NULL_7;	
	end
else
	if (loadAddress)
		begin
			addr <= address;
		end
end


//длина посылки
always@(negedge clk)
begin
if (!reset) 
	begin			
		len <= NULL_32;	
	end
else
	if (loadLength)
		begin
			len <= length;
		end
	if (stateFSM == STATE_DEC_LENGTH_LOW_14 & len[15:0] != NULL_16)
		begin
			len[15:0] <= len[15:0] - ONE_16;
		end
	else if (stateFSM == STATE_INC_LENGTH_LOW_15 & len[15:0] == NULL_16)
		begin
			len[15:0] <= len[15:0] + ONE_16;
		end
	if (stateFSM == STATE_DEC_LENGTH_HIGH_16 & len[15:0] != NULL_16)
		begin
			len[15:0] <= len[15:0] - ONE_16;
		end
	else if (stateFSM == STATE_INC_LENGTH_HIGH_17 & len[15:0] == NULL_16)
		begin
			len[15:0] <= len[15:0] + ONE_16;
		end
end

//управление
always@(posedge clk)
begin
if (!reset) 
	begin			
		cont <= NULL_16;	
	end
else
	begin
		if (loadControl)
			begin
				cont <= control;
			end
		else
			if (loadControlSt)
				begin
					cont <= cont & RESET_ST;
				end
	end
end





endmodule
