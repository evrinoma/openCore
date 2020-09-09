# I2C_MASTER_SLAVE
--------------------------------------------
Verilog Implementation:
--------------------------------------------
* I2C master driver
    * I2C - master
* I2C slave driver
    * I2C - slave
    
Connection map:
--------------------------------------------

The parts I2C slave driver and I2C slave emulate sensor BMP180 partly.
             
sda - i2c data line<br>
scl - i2c clockline<br>
start - is run transaction<br>
out - register show memory contents<br>
state - state machine register<br>
swId - start transaction read chip id button<br>
swShow - show byte from internal memory button<br>
send - start send new data byte<br>
datasend - register with sended byte<br>
sended - byte was sended<br>
receive - start receive new data byte<br>
datareceive - register with received byte<br>
received - byte was received<br>


MASTER_DRIVER has a register memory MAX_DATA size to save data and support read CHIP_ID transaction. 
Then you are pressed swId button the CHIP_ID transaction is staring. Master initiates communication with slave and generate clock. 
Master is sending data to a slave beginning from START event and generate slave address - 0x75. SLAVE_DRIVER is detecting his address and confirm it.
Then master detect confirmation, and he is starting write address function read CHIP ID 0xD0.
if SLAVE DRIVER detect address function read CHIP ID, he write a chip id value 0x81. Then you are pressing swShow button you are iterating over values register memory  with little delays. And value put on register 'out'


Driver Master Schema
--------------------------------------------
<div align=center><img src="https://github.com/evrinoma/openCore/blob/master/DOC/img/I2C_MASTER_SLAVE.png" height="400"/> </div>

