# I2C
--------------------------------------------
Verilog Implementation:
--------------------------------------------
* Driver - I2C master
    * I2C - master
* I2C - slave

Driver master I2C Register map:
--------------------------------------------

Register control:

          15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
        [ Re Re Re Re Re Re Re Re ST Re Re Re Re Re W  R ]

**Re** - reserved<br>
**ST** - start<br>
**W** - write<br>
**R** - read<br>


Register length:

            31..16    15..00
          [ length Read length Write]
          
**length Read** - count read byte from i2c<br>
**length Write** - count write byte from i2c<br>

Register status:

          15 14 13 12 11 10 09 08 07 06 05  04  03         02          01       00
        [ Re Re Re Re Re Re Re Re ST Re Re  len fromIsFull fromIsEmpty toIsFull toIsEmpty ]
 
**len** - register length is empty<br>
**fromIsFull** - fifo receive data is full<br>
**fromIsEmpty** - fifo receive data is empty<br>
**toIsFull** - fifo send data is full<br>
**toIsEmpty** - fifo send data is empty<br>   

Driver Master Schema
--------------------------------------------
<div align=center><img src="https://github.com/evrinoma/openCore/blob/master/DOC/img/i2c.png" height="400"/> </div>

