class i2cmb_generator extends ncsu_component #(.T(wb_transaction));

	i2cmb_env_configuration configuration;
	wb_agent  wb_agent_h;
	i2c_agent i2c_agent_h;
	
	localparam bit [31:0] ADDR_CSR  = 32'h00;
	localparam bit [31:0] ADDR_DPR  = 32'h01;
	localparam bit [31:0] ADDR_CMDR = 32'h02;
	localparam bit [31:0] ADDR_FSMR = 32'h03;
	
	localparam bit [7:0] CMD_WAIT     = 8'h00;
	localparam bit [7:0] CMD_WRITE    = 8'h01;  
	localparam bit [7:0] CMD_READ_ACK = 8'h02;  
	localparam bit [7:0] CMD_READ_NAK = 8'h03;  
	localparam bit [7:0] CMD_START    = 8'h04;  
	localparam bit [7:0] CMD_STOP     = 8'h05;  
	localparam bit [7:0] CMD_SET_BUS  = 8'h06;  
	
	localparam bit [7:0] CSR_ENABLE_IE = 8'hC0; //enable = 1 and interrupt enable = 1  
	localparam bit [7:0] I2C_BUS_ID    = 8'h00;
	localparam bit [6:0] I2C_SLAVE_ADDR = 7'h22;
	localparam bit [6:0] I2C_SLAVE_ADDR_HIGH  = 7'h55;
	
	//I have implemented both ways; one by using polling and polling the
	//CMDR DON bit and not using polling and waiting for the interrupt
	bit use_polling = 0;
	
	function new(string name = "", ncsu_component_base parent = null);
		super.new(name, parent);
	endfunction
	
	i2cmb_predictor predictor_h;
	i2cmb_coverage  coverage_h;

	i2cmb_scoreboard scoreboard_h;
	function void set_scoreboard(i2cmb_scoreboard sb);
    		scoreboard_h = sb;
	endfunction
	function void set_wb_agent(wb_agent agent);  
	       	wb_agent_h  = agent; 
	endfunction

	function void set_i2c_agent(i2c_agent agent); 
		i2c_agent_h = agent; 
	endfunction

	function void set_configuration(i2cmb_env_configuration cfg); 
		configuration = cfg; 
	endfunction

	function void set_predictor(i2cmb_predictor p); 
		predictor_h = p; 
	endfunction

	function void set_coverage(i2cmb_coverage c);
		coverage_h = c;
	endfunction

	virtual task wait_for_done();
	    bit [15:0] cmdr_val;
	    bit [15:0] csr_val;

    	    if (use_polling) 
	    begin
    		do begin
        		wb_agent_h.read(ADDR_CMDR, cmdr_val);
    		end while (!cmdr_val[7]);
    		//for sampling FSM in polling mode
    		if (coverage_h != null)
        		coverage_h.sample_fsm(wb_agent_h.bus.fsm_state_i);
	    end 
	    else 
	    begin
    		if (coverage_h != null)
    		    coverage_h.sample_fsm(wb_agent_h.bus.fsm_state_i);
    		wb_agent_h.bus.wait_for_interrupt();
    		if (coverage_h != null) 
		begin
    		    bit [15:0] csr_early;
    		    wb_agent_h.read(ADDR_CSR, csr_early);
    		    coverage_h.sample_wb(
    		        cmdr_val[2:0],
    		        4'b1000,
    		        csr_early[7],
    		        csr_early[6],
    		        csr_early[4],
    		        csr_early[5],
    		        8'h00,
    		        1'b1        
    		    );
    		end
    		wb_agent_h.read(ADDR_CMDR, cmdr_val);
	    end
	
	    //sampling again after completion for catching post command state
	    wb_agent_h.read(ADDR_CSR, csr_val);
	    if (coverage_h != null) 
	    begin
	        coverage_h.sample_fsm(wb_agent_h.bus.fsm_state_i);
	        coverage_h.sample_wb(
	            cmdr_val[2:0],
	            cmdr_val[7:4],
	            csr_val[7],
	            csr_val[6],
	            csr_val[4],
	            csr_val[5],
	            8'h00,
	            wb_agent_h.bus.irq_i
	        );
	    end
	endtask	
	
	//this task is used to write WB register and then wait for the command
	//to complete
	virtual task wb_write_and_wait(bit [31:0] addr, bit [7:0] data);
		wb_agent_h.write(addr, {8'h00, data});
		wait_for_done();
	endtask
	
	virtual task init_dut();
		begin
    			bit [15:0] csr_reset;
    			wb_agent_h.read(ADDR_CSR, csr_reset);
    			if (coverage_h != null)
        			coverage_h.sample_wb(3'b000, 4'b0000, csr_reset[7], csr_reset[6], csr_reset[4], csr_reset[5], 8'h00, 1'b0);
		end
		wb_agent_h.write(ADDR_CSR, {8'h00, CSR_ENABLE_IE});
		wb_agent_h.write(ADDR_DPR, {8'h00, I2C_BUS_ID});
		wb_write_and_wait(ADDR_CMDR, CMD_SET_BUS);
	endtask

	//for reading DPR and sampling into coverage after read commands
	virtual task sample_dpr();
		bit [15:0] dpr_val;
		bit [15:0] csr_val;
		wb_agent_h.read(ADDR_DPR, dpr_val);
		wb_agent_h.read(ADDR_CSR,  csr_val);
		if (coverage_h != null) 
		begin
			coverage_h.sample_wb(
				3'b000,             //no command
				4'b1000,            //DON
				csr_val[7],
				csr_val[6],
				csr_val[4],
				csr_val[5],
				dpr_val[7:0],       //real DPR value
				wb_agent_h.bus.irq_i
			);
		end
	endtask

	//i2c_write function on the slave side
	virtual task i2c_write(bit [6:0] slave_addr, bit [7:0] write_data[]);
		fork 
		begin
			bit       op_raw;
			bit [7:0] captured[];
			i2c_transaction trans = new("i2c_write_trans");
			i2c_agent_h.bus.wait_for_i2c_transfer(op_raw, captured);
			 //the package captures the write data so that it is visible to
                        //scoreboard
			trans.op   = i2c_transaction::I2C_WRITE;
			trans.addr = slave_addr;
			trans.data = new[captured.size()](captured);
		end 
		join_none
		
		//sample coverage for start
		if (coverage_h != null)
		begin
			coverage_h.sample_start(1'b0);
		end

		//write on the master side
		wb_write_and_wait(ADDR_CMDR, CMD_START);
		wb_agent_h.write(ADDR_DPR, {8'h00, slave_addr, 1'b0});
		wb_write_and_wait(ADDR_CMDR, CMD_WRITE);

		foreach (write_data[i]) 
		begin
			wb_agent_h.write(ADDR_DPR, {8'h00, write_data[i]});
			wb_write_and_wait(ADDR_CMDR, CMD_WRITE);
		end

		wb_write_and_wait(ADDR_CMDR, CMD_STOP);
		if (coverage_h != null) 
			coverage_h.sample_ack_nak(1'b0);
	endtask
	
	virtual task i2c_read(bit [6:0]  slave_addr,input  bit [7:0] provide_data[],output bit [7:0] read_data[]);
		//bit transfer_complete;
		//slave side read
                //I wait for wait_for_i2c_transfer and then provide the read data
                //sequentially
		if (predictor_h != null)
		begin
			predictor_h.push_expected_read(provide_data);
		end

		fork 
		begin
			automatic bit [7:0] data_to_provide[] = provide_data;
			bit       op_raw;
			bit [7:0] captured[];

			i2c_agent_h.bus.wait_for_i2c_transfer(op_raw, captured);

			begin
				i2c_transaction trans = new("i2c_read_trans");
				trans.op   = i2c_transaction::I2C_READ;
				trans.addr = slave_addr;
				trans.data = new[data_to_provide.size()](data_to_provide);
				i2c_agent_h.bl_put(trans);
			end
		end join_none
		
		//sample coverage for start
		if (coverage_h != null)
		begin
			coverage_h.sample_start(1'b0);
		end

		//master side read
		wb_write_and_wait(ADDR_CMDR, CMD_START);

		wb_agent_h.write(ADDR_DPR, {8'h00, slave_addr, 1'b1});
		wb_write_and_wait(ADDR_CMDR, CMD_WRITE);
		
		read_data = new[provide_data.size()];

		for (int i = 0; i < provide_data.size(); i++) 
		begin
			bit [15:0] rdata;

			if (i == provide_data.size() - 1)
			begin
				wb_write_and_wait(ADDR_CMDR, CMD_READ_NAK);
      				if (coverage_h != null) 
					coverage_h.sample_ack_nak(1'b1); // NAK
			end
			else
			begin
			  	wb_write_and_wait(ADDR_CMDR, CMD_READ_ACK);
        			if (coverage_h != null) 
					coverage_h.sample_ack_nak(1'b0); // ACK
			end

			wb_agent_h.read(ADDR_DPR, rdata);
			read_data[i] = rdata[7:0];
		end
		sample_dpr();
		
		wb_write_and_wait(ADDR_CMDR, CMD_STOP);
	endtask

	//for issuing two writes with repeated START between them
	virtual task i2c_write_repeated_start(bit [6:0] slave_addr,bit [7:0] data1[],bit [7:0] data2[]);
	        bit [15:0] f;
    		fork begin
    		    bit op_raw; bit [7:0] cap[];
    		    i2c_agent_h.bus.wait_for_i2c_transfer(op_raw, cap);
    		end join_none

    		if (coverage_h != null) coverage_h.sample_start(1'b0);
    		wb_write_and_wait(ADDR_CMDR, CMD_START);
    		wb_agent_h.write(ADDR_DPR, {8'h00, slave_addr, 1'b0});
    		wb_write_and_wait(ADDR_CMDR, CMD_WRITE);
    		foreach (data1[i]) 
		begin
    		    wb_agent_h.write(ADDR_DPR, {8'h00, data1[i]});
    		    wb_write_and_wait(ADDR_CMDR, CMD_WRITE);
    		end

    		fork 
		begin
    		    bit op_raw; bit [7:0] cap[];
    		    i2c_agent_h.bus.wait_for_i2c_transfer(op_raw, cap);
    		end join_none


    		if (coverage_h != null) coverage_h.sample_start(1'b1);
    		wb_write_and_wait(ADDR_CMDR, CMD_START);
    		

		wb_agent_h.write(ADDR_DPR, {8'h00, slave_addr, 1'b0});
    		wb_write_and_wait(ADDR_CMDR, CMD_WRITE);
    		foreach (data2[i]) 
		begin
    		    wb_agent_h.write(ADDR_DPR, {8'h00, data2[i]});
    		    wb_write_and_wait(ADDR_CMDR, CMD_WRITE);
    		end

    		wb_write_and_wait(ADDR_CMDR, CMD_STOP);
    		if (coverage_h != null) coverage_h.sample_ack_nak(1'b0);
	endtask
	
        
        virtual task run();
		bit [7:0] write_payload[];
    		bit [7:0] received_data[];
    		string test_mode;
    		bit saved_polling;
    		int num_writes;
    		int num_reads;
    		int num_alt;
    		int unsigned write_val;
    		int unsigned read_val;
		bit [7:0] provide[];
		//for ensuring different counts even within same test type
		begin
		    int unsigned sim_seed;
		    int dummy;
		    if (!$value$plusargs("ntb_random_seed=%d", sim_seed))
		        sim_seed = 1;
		    //for consuming seed dependent number of random values to shift RNG
		    repeat(sim_seed % 17) dummy = $urandom();
		end
		if (!$value$plusargs("TESTNAME=%s", test_mode))
		    test_mode = "base";
    		
		//for sampling CSR before enabling hits E_DISABLED and IE_DISABLED bins
    		begin
    			bit [15:0] csr_val;
    			wb_agent_h.read(ADDR_CSR, csr_val);
    			if (coverage_h != null)
    			    coverage_h.sample_wb(3'b000, 4'b0000,csr_val[7], csr_val[6], csr_val[4], csr_val[5],8'h00, 1'b0);
    		end
    		init_dut();
		$display("\n========================================");
		$display("TEST BEGIN");
		$display("========================================");
	        if (coverage_h != null) coverage_h.sample_start(1'b1);	
		//repeated START directed test
		//disable scoreboard for repeated START
		if (scoreboard_h != null) scoreboard_h.disable_check = 1;
		fork 
		begin
			bit op_raw; bit [7:0] cap[];
			i2c_agent_h.bus.wait_for_i2c_transfer(op_raw, cap);
		end join_none
		
		wb_write_and_wait(ADDR_CMDR, CMD_START);
		wb_agent_h.write(ADDR_DPR, {8'h00, I2C_SLAVE_ADDR, 1'b0});
		wb_write_and_wait(ADDR_CMDR, CMD_WRITE);
		
		//first wait_for_i2c_transfer will detect repeated START and exit
		//for forking second listener before issuing repeated START
		fork begin
			bit op_raw; bit [7:0] cap[];
			i2c_agent_h.bus.wait_for_i2c_transfer(op_raw, cap);
		end join_none
		
		if (coverage_h != null) coverage_h.sample_start(1'b1);
		wb_write_and_wait(ADDR_CMDR, CMD_START); // repeated START
		wb_agent_h.write(ADDR_DPR, {8'h00, I2C_SLAVE_ADDR, 1'b0});
		wb_write_and_wait(ADDR_CMDR, CMD_WRITE);
		wb_write_and_wait(ADDR_CMDR, CMD_STOP);
		//re-enable scoreboard after repeated START

		if (scoreboard_h != null) scoreboard_h.disable_check = 0;
		//for clearing any expected transactions queued during repeated START
		if (scoreboard_h != null) scoreboard_h.expected_q = {};

		//Phase 1: 32 incrementing writes (fixed)
		$display("\n--- Phase 1: 32 Fixed Writes ---");
		write_payload = new[1];
		for (int i = 0; i < 32; i++) 
		begin
		    write_payload[0] = 8'(i);
		    i2c_write(I2C_SLAVE_ADDR, write_payload);
		end
		
		//Phase 2: 32 incrementing reads (fixed)
		$display("--- Phase 2: 32 Fixed Reads ---");
		for (int i = 0; i < 32; i++) 
		begin
		    provide    = new[1];
		    provide[0] = 8'(100 + i);
		    i2c_read(I2C_SLAVE_ADDR, provide, received_data);
		end
		
		//Phase 3: 128 alternating write/read (fixed)
		$display("--- Phase 3: 128 Fixed Alternating Write/Read ---");
		begin
		    write_val = 64;
		    read_val  = 63;
		    write_payload = new[1];
		    for (int i = 0; i < 128; i++) 
		    begin
		        if (i % 2 == 0) 
			begin
		            write_payload[0] = 8'(write_val);
		            i2c_write(I2C_SLAVE_ADDR, write_payload);
		            write_val++;
		        end 
			else 
			begin
		            provide    = new[1];
		            provide[0] = 8'(read_val);
		            i2c_read(I2C_SLAVE_ADDR, provide, received_data);
		            read_val--;
		        end
		    end
		end

		//waiting for the phase 3 forked to settle
		repeat(10) @(posedge wb_agent_h.bus.clk_i);
	
		//for running randomized phases for additional coverage
		num_writes = $urandom_range(16, 48);
		$display("\n--- Random Phase: %0d Writes ---", num_writes);
		write_payload = new[1];
		for (int i = 0; i < num_writes; i++) 
		begin
			write_payload[0] = 8'(i);
			i2c_write(I2C_SLAVE_ADDR, write_payload);
		end
		
		num_reads = $urandom_range(16, 48);
		$display("--- Random Phase: %0d Reads ---", num_reads);
		for (int i = 0; i < num_reads; i++) 
		begin
			provide    = new[1];
			provide[0] = 8'(100 + i);
			i2c_read(I2C_SLAVE_ADDR, provide, received_data);
		end
		
		num_alt = $urandom_range(64, 192);
		$display("--- Random Phase: %0d Alternating ---", num_alt);
		begin
			write_val = 64;
			read_val  = 63;
			write_payload = new[1];
			for (int i = 0; i < num_alt; i++) 
			begin
				if (i % 2 == 0) 
				begin
				    write_payload[0] = 8'(write_val);
				    i2c_write(I2C_SLAVE_ADDR, write_payload);
				    write_val++;
				end 
				else 
				begin
				    provide    = new[1];
				    provide[0] = 8'(read_val);
				    i2c_read(I2C_SLAVE_ADDR, provide, received_data);
				    read_val--;
				end
			end
		end
		
		//for letting the threads to settle
		repeat(10) @(posedge wb_agent_h.bus.clk_i);	
		
		$display("\n--- Directed Tests ---");
		//DPR high-value reads
		$display("  [1] DPR high-value reads");
		begin
			bit [7:0] p[];
			p = new[1];
			p[0] = 8'h90;
			i2c_read(I2C_SLAVE_ADDR, p, received_data);
			p[0] = 8'hD0;
			i2c_read(I2C_SLAVE_ADDR, p, received_data);
		end
		
		//WAIT command
		$display("  [2] WAIT command");
		wb_agent_h.write(ADDR_DPR, {8'h00, 8'($urandom_range(0, 3))});
		wb_write_and_wait(ADDR_CMDR, CMD_WAIT);
		
		//NAK directed test
		$display("  [3] NAK directed test");
		wb_write_and_wait(ADDR_CMDR, CMD_START);
		wb_agent_h.write(ADDR_DPR, {8'h00, $urandom_range(7'h60, 7'h7F), 1'b0});

		wb_write_and_wait(ADDR_CMDR, CMD_WRITE);
		wb_write_and_wait(ADDR_CMDR, CMD_STOP);
		
		//Disable/re-enable DUT
		$display("  [4] Disable/re-enable DUT");
		begin
			bit [15:0] csr_val;
			wb_agent_h.write(ADDR_CSR, 8'h00);
			wb_agent_h.read(ADDR_CSR, csr_val);
			if (coverage_h != null)
			    coverage_h.sample_wb(3'b000, 4'b0000,
			        csr_val[7], csr_val[6], csr_val[4], csr_val[5],
			        8'h00, 1'b0);
			wb_agent_h.write(ADDR_CSR, {8'h00, CSR_ENABLE_IE});
			wb_agent_h.write(ADDR_DPR, {8'h00, I2C_BUS_ID});
			wb_write_and_wait(ADDR_CMDR, CMD_SET_BUS);
		end

		//Write to CMDR while E=0 - covers regblock disabled write path
		$display("  [5] CMDR write while E=0");
		wb_agent_h.write(ADDR_CSR, 8'h00); 
		wb_agent_h.write(ADDR_CMDR, 8'h04); 
		wb_agent_h.write(ADDR_CSR, {8'h00, CSR_ENABLE_IE});
		wb_agent_h.write(ADDR_DPR, {8'h00, I2C_BUS_ID});
		wb_write_and_wait(ADDR_CMDR, CMD_SET_BUS);

		//Read FSMR explicitly - covers regblock FSMR read path
		$display("  [6] FSMR reads");
		begin
			bit [15:0] fsmr;
			wb_agent_h.read(ADDR_FSMR, fsmr);
			wb_agent_h.read(ADDR_FSMR, fsmr); //read twice to hit both branches
		end

		//SET_BUS with invalid bus_id - hits ERR response path in
		//mbyte and covers regblock ERR register path
		$display("  [7] SET_BUS invalid bus_id");
		wb_agent_h.write(ADDR_DPR, {8'h00, 8'hFF});
		wb_write_and_wait(ADDR_CMDR, CMD_SET_BUS);
		
		wb_agent_h.write(ADDR_DPR, {8'h00, I2C_BUS_ID});
		wb_write_and_wait(ADDR_CMDR, CMD_SET_BUS);
		
		//WAIT with non-zero count - covers s_wait counting loop in mbyte
		$display("  [8] WAIT non-zero count");
		wb_agent_h.write(ADDR_DPR, {8'h00, 8'h01}); // 1ms wait
		wb_write_and_wait(ADDR_CMDR, CMD_WAIT);
		
		//for multiple FSMR reads in different states
		//read FSMR right after SET_BUS (s_idle state)
		begin 
			bit [15:0] f; wb_agent_h.read(ADDR_FSMR, f); 
		end
	
		//read FSMR after START completes (s_bus_taken state)
		fork begin
			bit op; bit [7:0] cap[];
			i2c_agent_h.bus.wait_for_i2c_transfer(op, cap);
		end join_none
		wb_write_and_wait(ADDR_CMDR, CMD_START);
		begin 
			bit [15:0] f; wb_agent_h.read(ADDR_FSMR, f); 
		end
		wb_agent_h.write(ADDR_DPR, {8'h00, I2C_SLAVE_ADDR, 1'b0});
		wb_write_and_wait(ADDR_CMDR, CMD_WRITE);
		begin 
			bit [15:0] f; wb_agent_h.read(ADDR_FSMR, f); 
		end
		wb_write_and_wait(ADDR_CMDR, CMD_STOP);
		begin 
			bit [15:0] f; wb_agent_h.read(ADDR_FSMR, f); 
		end	

		$display("\n--- RANDOM TEST PHASE ---");
		case (test_mode)
			"base": 
			begin    
				$display("  Mode: base");
				run_random($urandom_range(20, 60));
			end


    			"multi": 
			begin
    			    bit [7:0] d[];
			    $display("  Mode: multi");
    			    d = new[8];
    			    foreach(d[i]) d[i] = $urandom_range(0, 255);
    			    i2c_write(I2C_SLAVE_ADDR, d);
    			    i2c_read(I2C_SLAVE_ADDR, d, received_data);
    			    run_random($urandom_range(20, 40));
    			end
    			"high_addr": 
			begin
    			    bit [7:0] p[];
			    $display("  Mode: high_addr");
    			    p = new[1];
    			    p[0] = $urandom_range(0, 255);
    			    i2c_write(I2C_SLAVE_ADDR_HIGH, p);
    			    i2c_read(I2C_SLAVE_ADDR_HIGH, p, received_data);
    			    run_random($urandom_range(20, 40));
    			end
    			"nak": 
			begin
			    $display("  Mode: nak | Extra NAK tests: 3");
    			    repeat(3) 
		    	    begin
    			        wb_write_and_wait(ADDR_CMDR, CMD_START);
    			        wb_agent_h.write(ADDR_DPR, {8'h00, 7'h7F, 1'b0});
    			        wb_write_and_wait(ADDR_CMDR, CMD_WRITE);
    			        wb_write_and_wait(ADDR_CMDR, CMD_STOP);
    			    end
    			    run_random($urandom_range(20, 40));
    			end
    			default: run_random($urandom_range(20, 40));
		endcase
		$display("\n========================================");
		$display("TEST COMPLETE: %s", test_mode);
		$display("========================================\n");
	endtask	
	virtual task run_random(int num_transfers = 50);
    		bit [7:0] write_payload[];
    		bit [7:0] received_data[];

    		bit rand_op;
    		bit [6:0] rand_addr;
    		int rand_size;
    		bit [7:0] rand_data[];
    		
		repeat(num_transfers)
    		begin
    			rand_op = $urandom_range(0, 1);

    			//constrain address for covering both low_addr [0x00-0x3F]
    			//and high_addr [0x40-0x7F] bins equally
    			if ($urandom_range(0, 1))
    			    rand_addr = $urandom_range(7'h00, 7'h3F);
    			else
    			    rand_addr = $urandom_range(7'h40, 7'h7F);

    			case ($urandom_range(0, 2))
    			    0: rand_size = 1;
    			    1: rand_size = $urandom_range(2, 8);
    			    2: rand_size = $urandom_range(9, 12);
    			endcase

    			rand_data = new[rand_size];
    			foreach (rand_data[i])
    			    rand_data[i] = $urandom_range(0, 255);

			if (rand_op == 0) 
			begin
    			    i2c_write(rand_addr, rand_data);
			end 
			else 
			begin
    			    i2c_read(rand_addr, rand_data, received_data);
			end
    		end
	endtask

endclass
