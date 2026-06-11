//i2c_driver as an extension of ncsu_component class
class i2c_driver extends ncsu_component #(.T(i2c_transaction));

	//this is the virtual interface handle which is given by agent
	virtual i2c_if #() bus;
	
	i2c_configuration configuration;
	
	function new(string name = "", ncsu_component_base parent = null);
		super.new(name, parent);
	endfunction
	
	function void set_configuration(i2c_configuration cfg);
		configuration = cfg;
	endfunction
	
	//this is called by the generator or the agent with a transaction
	//who has the bytes to drive back the i2c master
	virtual task bl_put(T trans);
		bit transfer_complete;
		//debug print if required
		ncsu_info("i2c_driver::bl_put()",$sformatf("%s driving %0d read byte(s) to master",get_full_name(), trans.data.size()),NCSU_HIGH);	
		bus.provide_read_data(trans.data, transfer_complete);
		if (!transfer_complete)
		begin
			//debug print if required
		  	ncsu_warning("i2c_driver::bl_put()",$sformatf("%s provide_read_data returned transfer_complete=0",get_full_name()));
		end
	endtask

endclass

