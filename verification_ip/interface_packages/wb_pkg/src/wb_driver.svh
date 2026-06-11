//wb_driver as an extension to ncsu_component class
class wb_driver extends ncsu_component #(.T(wb_transaction));

	virtual wb_if #(2,8) bus;
	wb_configuration  configuration;
	
	function new(string name = "", ncsu_component_base parent = null);
		super.new(name, parent);
	endfunction
	
	function void set_configuration(wb_configuration cfg);
		configuration = cfg;
	endfunction
	
	//this will examine the transaction operation and call the appropriate
	//wb_if task 
	virtual task bl_put(T trans);
		//debug print if required
		ncsu_info("wb_driver::bl_put()",$sformatf("%s %s", get_full_name(), trans.convert2string()),NCSU_HIGH);
		case (trans.op)
			wb_transaction::WB_WRITE: 
			begin
				bus.master_write(trans.addr, trans.data);
			end
			
			wb_transaction::WB_READ: 
			begin
				bit [15:0] read_data;
				bus.master_read(trans.addr, read_data);
				trans.data = read_data;   // write result back into transaction
			end
			
			default: 
			begin
			        //debug prints if required
			  	ncsu_error("wb_driver::bl_put()",$sformatf("Unknown op in transaction: %s",trans.convert2string()));
			end
		endcase
	endtask

endclass

