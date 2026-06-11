package i2c_pkg;

	//import the required packages first
	import ncsu_pkg::*; 

	typedef enum bit { I2C_WRITE = 1'b0, I2C_READ = 1'b1 } i2c_op_t;
	typedef virtual i2c_if#() i2c_if_t;

	//making all the i2c classes as .svh files and including them inside
	//i2c_pkg
	`include "../ncsu_pkg/ncsu_macros.svh";
	`include "src/i2c_transaction.svh";
	`include "src/i2c_configuration.svh";
	`include "src/i2c_driver.svh";
	`include "src/i2c_monitor.svh";
	`include "src/i2c_agent.svh";
endpackage
