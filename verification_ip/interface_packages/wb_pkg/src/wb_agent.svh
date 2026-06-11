//wb_agent as an extension to ncsu_component class
class wb_agent extends ncsu_component #(.T(wb_transaction));

	wb_configuration    configuration;
	wb_driver           driver;
	wb_monitor          monitor;
	
	//this is the subscriber queue
	ncsu_component #(T) subscribers[$];
	
	virtual wb_if #(2,8) bus;
	
	function new(string name = "", ncsu_component_base parent = null);
		super.new(name, parent);
		
		//the virtual interface handle is pulled from config_db
		if (!ncsu_config_db #(virtual wb_if #(2,8))::get(get_full_name(), this.bus)) 
		begin
			//debug print if required
		  	//$display("wb_agent: ncsu_config_db::get() failed for wb_if, name: %s",get_full_name());
		  	$finish;
		end
	endfunction
	
	function void set_configuration(wb_configuration cfg);
		configuration = cfg;
	endfunction
	
	//this will construct driver and monitor
	virtual function void build();
		super.build();
		
		driver = new("driver", this);
		driver.set_configuration(configuration);
		driver.build();
		driver.bus = this.bus;
		
		monitor = new("monitor", this);
		monitor.set_configuration(configuration);
		monitor.set_agent(this);
		monitor.enable_transaction_viewing = 1;
		monitor.build();
		monitor.bus = this.bus;
	endfunction
	
	//this will fork the monitor as a background thread
	virtual task run();
		fork
			monitor.run();
		join_none
	endtask
	
	//this is used to pass through the driver and used by generator to
	//issue wishbone regitser reads and writes
	virtual task bl_put(T trans);
	  	driver.bl_put(trans);
	endtask
	
	//this is used to fanout to all the subscribers
	virtual function void nb_put(T trans);
	  	foreach (subscribers[i])
	    		subscribers[i].nb_put(trans);
	endfunction
	
	virtual function void connect_subscriber(ncsu_component #(T) subscriber);
	  	subscribers.push_back(subscriber);
	endfunction
	
	virtual task write(input bit [31:0] addr, input bit [15:0] data);
		wb_transaction trans = new("wb_write_trans");
		trans.op   = wb_transaction::WB_WRITE;
		trans.addr = addr;
		trans.data = data;
		bl_put(trans);
	endtask
	
	virtual task read(input bit [31:0] addr, output bit [15:0] data);
		wb_transaction trans = new("wb_read_trans");
		trans.op   = wb_transaction::WB_READ;
		trans.addr = addr;
		bl_put(trans);
		//this will enable the driver to write the read result back
		//into the trans.data
		data = trans.data;
	endtask

endclass


