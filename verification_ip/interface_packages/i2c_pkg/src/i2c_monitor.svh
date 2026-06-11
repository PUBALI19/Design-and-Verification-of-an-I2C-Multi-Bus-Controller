//i2c_monitor class as an extension of ncsu_component
class i2c_monitor extends ncsu_component #(.T(i2c_transaction));

	virtual i2c_if #() bus;
	i2c_configuration  configuration;
	
	ncsu_component #(T) agent;
	
	function new(string name = "", ncsu_component_base parent = null);
		super.new(name, parent);
	endfunction
	
	function void set_configuration(i2c_configuration cfg);
		configuration = cfg;
	endfunction
	
	function void set_agent(ncsu_component #(T) agent_h);
		this.agent = agent_h;
	endfunction
	
	virtual task run();
		forever 
		begin
			i2c_transaction monitored_trans;
			bit [6:0] sampled_addr;
			bit       sampled_op; 
			bit [7:0] sampled_data[];
			
			monitored_trans = new("monitored_trans");
			
			if (enable_transaction_viewing)
			begin
				monitored_trans.start_time = $time;
			end
			
			//this output will be a bit indicating read (1) or
			//write (0) operation
			bus.monitor(sampled_addr, sampled_op, sampled_data);
			
			monitored_trans.addr = sampled_addr;
			monitored_trans.op   = i2c_transaction::i2c_op_t'(sampled_op);
			monitored_trans.data = new[sampled_data.size()](sampled_data);
			
			//debug prints
			//ncsu_info("i2c_monitor::run()",$sformatf("%s %s", get_full_name(), monitored_trans.convert2string()),NCSU_HIGH);
			if (enable_transaction_viewing) 
			begin
			  	monitored_trans.end_time = $time;
			  	monitored_trans.add_to_wave(transaction_viewing_stream);
			end
			
			agent.nb_put(monitored_trans);
		end
	endtask
endclass
