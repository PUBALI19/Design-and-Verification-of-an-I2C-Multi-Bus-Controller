package wb_pkg;
	//import the necessary packages first
	import ncsu_pkg::*;
	//define the classes in separate .svh files and include them inside wb_pkg
	`include "../ncsu_pkg/ncsu_macros.svh"
	`include "src/wb_transaction.svh";
	`include "src/wb_configuration.svh";
	`include "src/wb_driver.svh";
	`include "src/wb_monitor.svh";
	`include "src/wb_agent.svh";
endpackage
