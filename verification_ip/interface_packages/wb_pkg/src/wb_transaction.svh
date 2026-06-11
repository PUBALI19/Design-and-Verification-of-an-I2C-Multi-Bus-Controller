//wb_transaction as an extension to ncsu_transaction
class wb_transaction extends ncsu_transaction;
	`ncsu_register_object(wb_transaction)
	
	typedef enum bit { WB_READ = 1'b0, WB_WRITE = 1'b1 } wb_op_t;
	
	rand bit [31:0] addr;
	rand bit [15:0] data;
	rand wb_op_t    op;
	
	function new(string name = "");
		super.new(name);
	endfunction
	
	virtual function string convert2string();
		return {super.convert2string(), $sformatf(" op:%s addr:0x%08x data:0x%04x", op.name(), addr, data)};
	endfunction
	
	function bit compare(wb_transaction rhs);
		return ((this.addr == rhs.addr) && (this.data == rhs.data) && (this.op   == rhs.op));
	endfunction

endclass

