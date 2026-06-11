class i2c_transaction extends ncsu_transaction;
	`ncsu_register_object(i2c_transaction)
	typedef enum logic { I2C_WRITE = 1'b0, I2C_READ = 1'b1 } i2c_op_t;
	
	//the address and aoperation of i2c
	rand bit [6:0]  addr;
	rand i2c_op_t   op;
	
	//this is for variable length data payload
	rand bit [7:0]  data[];
	
	constraint data_size_c { data.size() > 0; data.size() <= 32; }
	
	function new(string name = "");
		super.new(name);
	endfunction
	
	virtual function string convert2string();
		string s;
		s = super.convert2string();
		s = {s, $sformatf(" addr:0x%02x op:%s data:", addr, op.name())};
		foreach (data[i])
			s = {s, $sformatf("0x%02x ", data[i])};
		return s;
	endfunction
	
	//this is used by scoreboard
	function bit compare(i2c_transaction rhs);
		if (this.addr != rhs.addr) 
			return 0;
		if (this.op   != rhs.op)   
			return 0;
		if (this.data.size() != rhs.data.size()) 
			return 0;
		foreach (this.data[i])
		  	if (this.data[i] != rhs.data[i]) 
			 	return 0;
		return 1;
	endfunction

endclass

