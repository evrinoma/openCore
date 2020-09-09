# openCore
--------------------------------------------
Verilog Implementation:
--------------------------------------------
* APB
    * Controller I2C  
        * Driver I2C - master
        * Driver I2C - slave
    * 1-wire
    * RS-232

Introduction
--------------------------------------------


Getting Started/How to use
--------------------------------------------
   Just clone the project used command **git clone https://github.com/evrinoma/openCore.git**
   
   The  `MAIN/` folder contains precompiled projects. All projects compiled successfully in Quartus 18.<br>
   The  `I2C/` folder directory contains clear i2c master and i2c slave logic descriptions on Verilog.
   The  `UTILS/` folder directory contains clear nonspecific logic descriptions on Verilog.

Simulation
--------------------------------------------
   For simulation used ModelSim is a multi-language HDL simulation environment. Starting a simulation just run in Quartus environment. 
   
    Tools -> Run simulation tool -> RTL simulation 

Documentation
--------------------------------------------
The source of the documentation is stored in the `DOC/` folder
in this repo, and available on here:

   Project openCore/MAIN/I2C_MASTER_SLAVE<br>
   [Read the Documentation for I2C MASTER_SLAVE logic](https://github.com/evrinoma/openCore/blob/master/DOC/I2C_MASTER_SLAVE.md)

   Project openCore/MAIN/MASTER_DRIVER<br>
   [Read the Documentation for I2C MASTER_DRIVER logic](https://github.com/evrinoma/openCore/blob/master/DOC/MASTER_DRIVER.md)



Author

    evrinoma@gmail.com
