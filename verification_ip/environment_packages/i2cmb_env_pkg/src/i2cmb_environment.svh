//i2cmb_environment class created as an extension of ncsu_component
class i2cmb_environment extends ncsu_component #(.T(wb_transaction));

	i2cmb_env_configuration configuration;
	
	// public agents used by test
	wb_agent  wb_agent_h;
	i2c_agent i2c_agent_h;
	
	i2cmb_predictor  predictor;
	i2cmb_scoreboard scoreboard;
	i2cmb_coverage   coverage;

	function new(string name = "", ncsu_component_base parent = null);
		super.new(name, parent);
	endfunction
	
	function void set_configuration(i2cmb_env_configuration cfg);
	 	configuration = cfg;
	endfunction
	
	virtual function void build();
		super.build();
		
		//WB_AGENT
		//this new wb_agent constructor is going to pull the virtual wb_if
		//from ncsu_config_db
		wb_agent_h = new("wb_agent", this);
		wb_agent_h.set_configuration(configuration.wb_cfg);
		wb_agent_h.build();
		
		//I2C_AGENT
		//the same happens with i2c_agent
		i2c_agent_h = new("i2c_agent", this);
		i2c_agent_h.set_configuration(configuration.i2c_cfg);
		i2c_agent_h.build();
		
		//PREDICTOR
		//this is actually used to forward the predicted i2c transactions to
		//the scoreboard
		predictor = new("predictor", this);
		predictor.set_configuration(configuration);
		predictor.build();
		
		//SCOREBOARD
		if (configuration.enable_scoreboard) 
		begin
		  	scoreboard = new("scoreboard", this);
		  	scoreboard.set_configuration(configuration);
		  	scoreboard.build();
		  	predictor.set_scoreboard(scoreboard);
		end
		
		//COVERAGE
		if (configuration.enable_coverage) 
		begin
		  	coverage = new("coverage", this);
		  	coverage.set_configuration(configuration);
		  	coverage.build();
			//wb_coverage_cg gets sampled here
		  	predictor.set_coverage(coverage);
		end
		wb_agent_h.connect_subscriber(predictor);
		if (configuration.enable_scoreboard)
		begin
		  	i2c_agent_h.connect_subscriber(scoreboard);
	  	end
		if (configuration.enable_coverage)
		begin
			//this is for coverage of i2cmb_op_cg and
			//i2c_timing_cg
			i2c_agent_h.connect_subscriber(coverage);
	  	end
	endfunction
	
	//this task is used to create the runs seperately from test
	virtual task run();
		fork
		  wb_agent_h.run();
		  i2c_agent_h.run();
		join_none
	endtask
	
	//report task is used to print the final scoreboard result
	//proy9
	function void report();
		if (configuration.enable_scoreboard)
		begin
			scoreboard.report();
		end
	endfunction

endclass



