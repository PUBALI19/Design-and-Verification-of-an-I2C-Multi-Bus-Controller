//i2c_agent as an extension of ncsu_component class
class i2c_agent extends ncsu_component #(.T(i2c_transaction));

	i2c_configuration  configuration;
	i2c_driver         driver;
	i2c_monitor        monitor;
	
	//this is the queue for the subscriber which connects all the
	//components of the testbench
	ncsu_component #(T) subscribers[$];
	
	virtual i2c_if #() bus;
	
	function new(string name = "", ncsu_component_base parent = null);
		super.new(name, parent);
		
		if (!ncsu_config_db #(virtual i2c_if #())::get(get_full_name(), this.bus)) 
		begin
			//debug print
		  	$display("FAILED: i2c_agent: ncsu_config_db::get() failed for i2c_if, name: %s",get_full_name());
		  	$finish;
		end
	endfunction
	
	function void set_configuration(i2c_configuration cfg);
	  	configuration = cfg;
	endfunction
	
	//this build constructs the driver and monitor
	virtual function void build();
		super.build();
		
		//driver will only instantiate if it is actively driving
		if (configuration.enable_driver) 
		begin
			driver = new("driver", this);
			driver.set_configuration(configuration);
			driver.build();
			driver.bus = this.bus;
		end
		
		//monitor will be always present
		monitor = new("monitor", this);
		monitor.set_configuration(configuration);
		monitor.set_agent(this);
		monitor.enable_transaction_viewing = 1;
		monitor.build();
		monitor.bus = this.bus;
	endfunction
	
	virtual task run();
		fork
			monitor.run();
		join_none
	endtask
	
	//this is called by the generator to drive the read data back to the
	//master
	virtual task bl_put(T trans);
		if (configuration.enable_driver)
		begin
		  	driver.bl_put(trans);
		end
		else
		begin
		  	ncsu_warning("i2c_agent::bl_put()","bl_put called but enable_driver is 0");
		end
	endtask
	
	//this is used to fan out all the subscribers
	virtual function void nb_put(T trans);
	  	foreach (subscribers[i])
	    		subscribers[i].nb_put(trans);
	endfunction
	
	virtual function void connect_subscriber(ncsu_component #(T) subscriber);
	  	subscribers.push_back(subscriber);
	endfunction

endclass
