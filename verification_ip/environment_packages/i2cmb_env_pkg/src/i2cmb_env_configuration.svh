//i2cmb_env_configuration created as an extended class of ncsu_configuration
class i2cmb_env_configuration extends ncsu_configuration;

	//each agent will have a sub configuration
	wb_configuration  wb_cfg;
	i2c_configuration i2c_cfg;
	
	bit enable_scoreboard;
	bit enable_coverage;
	
	function new(string name = "");
		super.new(name);
	
		//institaing the sub configurations
		wb_cfg  = new("wb_cfg");
		i2c_cfg = new("i2c_cfg");
	
		enable_scoreboard = 1;
		enable_coverage   = 1;
	endfunction
	
	//I am using covert2string as my debug purposes
	virtual function string convert2string();
		return {super.convert2string(),$sformatf(" enable_scoreboard:%0b enable_coverage:%0b\n  wb_cfg:[%s]\n  i2c_cfg:[%s]",enable_scoreboard, enable_coverage,wb_cfg.convert2string(),i2c_cfg.convert2string())};
	endfunction

endclass

