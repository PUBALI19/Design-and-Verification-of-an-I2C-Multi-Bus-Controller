//wb_monitor as an extension to ncsu_component class
class wb_monitor extends ncsu_component #(.T(wb_transaction));

	virtual wb_if #(2,8) bus;
	wb_configuration  configuration;
	
	ncsu_component #(T) agent;
	
	function new(string name = "", ncsu_component_base parent = null);
		super.new(name, parent);
	endfunction
	
	function void set_configuration(wb_configuration cfg);
		configuration = cfg;
	endfunction
	
	function void set_agent(ncsu_component #(T) agent_h);
		this.agent = agent_h;
	endfunction
	
	//this will package the result into a wb_transaction
	virtual task run();
		forever 
		begin
			wb_transaction monitored_trans;
			bit [31:0]     sampled_addr;
			bit [15:0]     sampled_data;
			bit            sampled_we;
			
			monitored_trans = new("monitored_trans");
			
			if (enable_transaction_viewing)
			begin
			  	monitored_trans.start_time = $time;
			end
			
			bus.master_monitor(sampled_addr, sampled_data, sampled_we);
			
			//these are the package results
			monitored_trans.addr = sampled_addr;
			monitored_trans.data = sampled_data;
			monitored_trans.op   = wb_transaction::wb_op_t'(sampled_we);
			
			//debug print if required
			ncsu_info("wb_monitor::run()",$sformatf("%s %s", get_full_name(),monitored_trans.convert2string()),NCSU_HIGH);
			
			if (enable_transaction_viewing) 
			begin
			  monitored_trans.end_time = $time;
			  monitored_trans.add_to_wave(transaction_viewing_stream);
			end
			agent.nb_put(monitored_trans);
		end
	endtask

endclass

