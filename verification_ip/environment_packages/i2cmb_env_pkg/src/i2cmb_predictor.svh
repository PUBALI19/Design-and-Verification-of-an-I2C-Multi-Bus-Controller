class i2cmb_predictor extends ncsu_component #(.T(wb_transaction));

	i2cmb_env_configuration configuration;
	
	i2cmb_scoreboard scoreboard;
  	i2cmb_coverage   coverage_h;
	
	function new(string name = "", ncsu_component_base parent = null);
		super.new(name, parent);
	endfunction
	
	function void set_configuration(i2cmb_env_configuration cfg);
		configuration = cfg;
	endfunction
	
	function void set_scoreboard(i2cmb_scoreboard sb);
		scoreboard = sb;
	endfunction
	
  	function void set_coverage(i2cmb_coverage c);
  	  	coverage_h = c;
  	endfunction

	bit [7:0] expected_read_q[$][$];
	function void push_expected_read(bit [7:0] data[]);
		expected_read_q.push_back(data);
	endfunction
	
	localparam bit [2:0] CMD_WRITE    = 3'b001;
	localparam bit [2:0] CMD_READ_ACK = 3'b010;
	localparam bit [2:0] CMD_READ_NAK = 3'b011;
	localparam bit [2:0] CMD_START    = 3'b100;
	localparam bit [2:0] CMD_STOP     = 3'b101;
	localparam bit [2:0] CMD_SET_BUS  = 3'b110;
	
	localparam bit [31:0] ADDR_CSR  = 32'h00;
	localparam bit [31:0] ADDR_DPR  = 32'h01;
	localparam bit [31:0] ADDR_CMDR = 32'h02;
	
	//this state machine is the same as i2cmb byte-level state machine
	typedef enum {IDLE, STARTED, WRITING, READING} predictor_state_t;
	predictor_state_t state = IDLE;
	
	//this is the last byte written to dpr
	bit [7:0] last_byte_dpr;
	//whether it is a read operation or not
	bit       read_op;
	//slave address
	bit [6:0] i2c_addr;
	//this is the collected data in the current transaction
	bit [7:0] i2c_collected_data[$];
	
	//I have defined this such that it receives every wb_transaction from
	//wb_monitor
	virtual function void nb_put(T trans);
		if (trans.op != wb_transaction::WB_WRITE) 
		        return;
		
		case (trans.addr)
			//this will capture all the bytes  
			ADDR_DPR: 
			begin
				last_byte_dpr = trans.data[7:0];
        			if (coverage_h != null)
				begin
        			  	coverage_h.sample_wb(3'b000, 4'b0000, 1'b1, 1'b1, 1'b0, 1'b0, last_byte_dpr, 1'b0);
				end
			end
		
			//this will break the command and update the prediction state
			ADDR_CMDR: 
			begin
				case (trans.data[2:0])
					CMD_START: 
					begin
						state = STARTED;
						i2c_collected_data = {};
					end
					CMD_WRITE: 
					begin
						if (state == STARTED) 
						begin
							i2c_addr   = last_byte_dpr[7:1];
							//0 = write operation, 1 = read operation
							read_op = last_byte_dpr[0];
							state      = read_op ? READING : WRITING;
						end 
						else if (state == WRITING) 
						begin
							i2c_collected_data.push_back(last_byte_dpr);
						end
					end
		
					CMD_READ_ACK,CMD_READ_NAK: 
					begin
						if (state == READING)
		      			begin
						  	i2c_collected_data.push_back(8'h00);
		      			end
					end
		
					CMD_STOP: 
					begin
						//once the transfer complete I will shift the predicted
						//i2c_transaction to scoreboard
						if (state == WRITING || state == READING) 
						begin
							i2c_transaction predicted_trans = new("predicted_trans");
							predicted_trans.addr = i2c_addr;
							predicted_trans.op   = i2c_transaction::i2c_op_t'(read_op);
							if (read_op && expected_read_q.size() > 0) 
							begin
								bit [7:0] edata[] = expected_read_q.pop_front();
								predicted_trans.data = new[edata.size()](edata);
							end 
							else
		      				begin
								predicted_trans.data = new[i2c_collected_data.size()](i2c_collected_data);
		      				end
							if (scoreboard != null)
		      				begin
							  	scoreboard.nb_put_expected(predicted_trans);
		      				end
						end
						state = IDLE;
					end
				endcase
				//for sampling wb_coverage_cg at every cmdr
				//write
        			if (coverage_h != null)
				begin
          				coverage_h.sample_wb(trans.data[2:0], 4'b0000, 1'b1, 1'b1, 1'b0, 1'b0, last_byte_dpr, 1'b0);
				end
			end
		endcase
	endfunction
endclass


