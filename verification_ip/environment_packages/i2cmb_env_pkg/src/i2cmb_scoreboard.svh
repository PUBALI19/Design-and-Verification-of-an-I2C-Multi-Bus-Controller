//i2cmb_scoreboard as an extension of class ncsu_component
class i2cmb_scoreboard extends ncsu_component #(.T(i2c_transaction));

	i2cmb_env_configuration configuration;
	
	//this is the transaction queue which is filled by the predictor
	i2c_transaction expected_q[$];

	bit disable_check = 0;	
	//counters for number of test cases passed and failed
	int unsigned num_passed;
	int unsigned num_failed;
	
	function new(string name = "", ncsu_component_base parent = null);
		super.new(name, parent);
		num_passed = 0;
		num_failed = 0;
	endfunction
	
	function void set_configuration(i2cmb_env_configuration cfg);
		configuration = cfg;
	endfunction
	
	function void nb_put_expected(i2c_transaction trans);
		expected_q.push_back(trans);
		//debug print if required
		//ncsu_info("i2cmb_scoreboard::nb_put_expected()",$sformatf("Queued expected [%0d]: %s",expected_q.size(), trans.convert2string()),NCSU_HIGH);
	endfunction
	
	//this is called by the i2c_agent monitor with the present transactions
	//which are seen on the i2c bus
	virtual function void nb_put(T trans);
		i2c_transaction expected;
		if (disable_check) return; 
		
		if (expected_q.size() == 0) 
		begin
			//debug print if required
			//ncsu_error("i2cmb_scoreboard",$sformatf("Actual transaction arrived but expected queue is empty!\n  Actual: %s",trans.convert2string()));
			num_failed++;
			return;
		end
		
		expected = expected_q.pop_front();
		
		if (trans.op == i2c_transaction::I2C_WRITE) 
		begin
			//this is where the full comparison of writes happen 
			if (trans.compare(expected)) 
			begin
			  num_passed++;
			  begin
			    string data_str;
			    //$display("i2cmb_scoreboard RESULT");
			    foreach (trans.data[i])
			      data_str = {data_str, $sformatf("0x%02x ", trans.data[i])};
			    ncsu_info("",$sformatf("PASS [op:%s] Addr:0x%02x Data:%s",trans.op.name(), trans.addr, data_str),NCSU_MEDIUM);
			  end
			end 
			else 
			begin
			  num_failed++;
			  //ncsu_error("i2cmb_scoreboard",$sformatf("FAIL [write]\n  Expected: %s\n  Actual:   %s",expected.convert2string(), trans.convert2string()));
			end
		
		end 
		else 
		begin
			//this is where read check happens but I check only the address and
			//operation (write or read)
			if (trans.addr == expected.addr && trans.op == expected.op) 
			begin
				num_passed++;
				begin
				  string data_str;
				  //$display("i2cmb_scoreboard RESULT");
				  foreach (trans.data[i])
				    data_str = {data_str, $sformatf("0x%02x ", trans.data[i])};
				  ncsu_info("",$sformatf("PASS [op:%s] Addr:0x%02x Data:%s",trans.op.name(),trans.addr,data_str),NCSU_MEDIUM);
				end
			end 
			else 
			begin
				num_failed++;
				//ncsu_error("i2cmb_scoreboard",$sformatf("FAIL [read] addr/op mismatch\n  Expected: %s\n  Actual:   %s",expected.convert2string(), trans.convert2string()));
			end
		end
	endfunction
	
	//final report
	function void report();
		$display("#####################################################");
		$display("FINAL i2cmb_scoreboard REPORT");
		$display("  Transactions PASSED : %0d", num_passed);
		$display("  Transactions FAILED : %0d", num_failed);
		if (expected_q.size() > 0)
		  $display("  WARNING: %0d expected transactions never matched",expected_q.size());
		if (num_failed == 0 && expected_q.size() == 0)
		  $display("  RESULT : TEST PASSED");
		else
		  $display("  RESULT : TEST FAILED");
		$display("#####################################################");
	endfunction

endclass


