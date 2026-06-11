//wb_configuration as an extension to ncsu_configuration class
class wb_configuration extends ncsu_configuration;

	//for enabling the functional coverage
	bit collect_coverage;
	int unsigned addr_width;
	int unsigned data_width;
	
	function new(string name = "");
		super.new(name);
		collect_coverage = 1;
		addr_width       = 32;
		data_width       = 16;
	endfunction
	
	virtual function string convert2string();
	  	return {super.convert2string(),$sformatf(" addr_width:%0d data_width:%0d collect_coverage:%0b",addr_width, data_width, collect_coverage)};
	endfunction

endclass

