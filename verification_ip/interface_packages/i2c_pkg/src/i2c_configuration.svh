//i2c_configuration as an extension of ncsu_configuration class
class i2c_configuration extends ncsu_configuration;

	bit [6:0]  i2c_address;
	bit        enable_driver;
	
	//this is used to enable functional coverage collection
	bit        collect_coverage;
	
	function new(string name = "");
		super.new(name);
		//I have chosen a default slave address
		i2c_address     = 7'h22;
		enable_driver   = 1;
		collect_coverage = 1;
	endfunction
	
	virtual function string convert2string();
		return {super.convert2string(), $sformatf(" i2c_addr:0x%02x enable_driver:%0b collect_coverage:%0b", i2c_address, enable_driver, collect_coverage)};
	endfunction

endclass
