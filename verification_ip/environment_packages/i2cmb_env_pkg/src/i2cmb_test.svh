class i2cmb_test extends ncsu_component #(.T(wb_transaction));

	i2cmb_env_configuration configuration;
	i2cmb_environment        environment;
	i2cmb_generator          generator;
	
	function new(string name = "", ncsu_component_base parent = null);
		super.new(name, parent);
	endfunction
	
	//this stitches the environment and generator together
	virtual function void build();
		super.build();
		
		configuration = new("i2cmb_env_configuration");

		//building the environment
		environment = new("environment", this);
		environment.set_configuration(configuration);
		environment.build();
		
		//building the generator
		generator = new("generator", this);
		generator.set_configuration(configuration);
		generator.set_wb_agent(environment.wb_agent_h);
		generator.set_i2c_agent(environment.i2c_agent_h);
		generator.build();
		generator.set_predictor(environment.predictor);
		generator.set_coverage(environment.coverage);
		generator.set_scoreboard(environment.scoreboard);
	endfunction
	
	virtual task run();
    		string test_name;
    		environment.run();

    		if (!$value$plusargs("TESTNAME=%s", test_name))
    		    test_name = "base";

    		generator.run();

    		environment.report();
	endtask

endclass
