//i2cmb_coverage created as an extended class from ncsu_component
class i2cmb_coverage extends ncsu_component #(.T(i2c_transaction));

	i2cmb_env_configuration configuration;
	
	//these are the fields to be extracted from each transaction
	i2c_transaction::i2c_op_t op;
	bit [6:0] addr;
	int       i2c_num_of_bytes;
	
	//these are required for wb_coverage_cg
	bit [2:0] cmdr_cmd;
	bit [3:0] cmdr_status;
	bit       csr_e_bit;
	bit       csr_ie_bit;
	bit       csr_bc_bit;
	bit       csr_bb_bit;
	bit [7:0] dpr_value;
	bit       irq_state;
	
	//this is required for fsm_byte_level_cg
	bit [3:0] fsm_byte_level_state;
	
	//these are required for i2c_timing_cg
	bit start_type;
	bit stop_generated;
	bit ack_nak;
	
	//This is my top level cover group of I2C transaction coverage
	covergroup i2cmb_op_cg;
		option.per_instance = 1;
		option.name         = get_full_name();
		
		//I used coverpoint to track the read and write operations during simulation
		cp_op: coverpoint op 
		{
		  bins WRITE = {i2c_transaction::I2C_WRITE};
		  bins READ  = {i2c_transaction::I2C_READ};
		}
		
		//I used coverpoint here to track slave addresses during simulation
		cp_addr: coverpoint addr 
		{
		  bins low_addr  = {[7'h00 : 7'h3F]};
		  bins high_addr = {[7'h40 : 7'h7F]};
		}
		
		//I used coverpoint here to check the number of data bytes per transaction
		cp_i2c_num_of_bytes: coverpoint i2c_num_of_bytes 
		{
		  bins one_byte   = {1};
		  bins multi_byte = {[2:8]};
		  bins large_trans = {[9:32]};
		}
		
		//I used cross here to track all possible combinations of cp_op, cp_addr
		//and cp_op and cp_i2c_num_of_bytes
		cx_op_addr: cross cp_op, cp_addr;
		cx_op_size: cross cp_op, cp_i2c_num_of_bytes;
	endgroup
	
	//this is my top level wishbone register access covergroup
	covergroup wb_coverage_cg;
		option.per_instance = 1;
		option.name         = get_full_name();
		
		cp_command_reg: coverpoint cmdr_cmd 
		{
		  bins WAIT    = {3'b000};
		  bins WRITE   = {3'b001};
		  bins RD_ACK  = {3'b010};
		  bins RD_NAK  = {3'b011};
		  bins START   = {3'b100};
		  bins STOP    = {3'b101};
		  bins SET_BUS = {3'b110};
		}
		
		cp_command_reg_status: coverpoint cmdr_status 
		{
		  bins DON = {4'b1000};
		  bins NAK = {4'b0100};
		  ignore_bins AL  = {4'b0010};
    		  ignore_bins ERR = {4'b0001};
		}
		
		cp_control_status_reg_e_bit: coverpoint csr_e_bit 
		{
		  bins E_DISABLED = {1'b0};
		  bins E_ENABLED  = {1'b1};
		}
		
		cp_control_status_reg_ie_bit: coverpoint csr_ie_bit 
		{
		  bins IE_DISABLED = {1'b0};
		  bins IE_ENABLED  = {1'b1};
		}
		
		cp_data_param_value: coverpoint dpr_value 
		{
		  bins low_val  = {[8'h00 : 8'h3F]};
		  bins mid_val  = {[8'h40 : 8'h7F]};
		  bins high_val = {[8'h80 : 8'hBF]};
		  bins top_val  = {[8'hC0 : 8'hFF]};
		}
		
		cp_interrupt_req_state: coverpoint irq_state 
		{
		  bins IRQ_DEASSERTED = {1'b0};
		  bins IRQ_ASSERTED   = {1'b1};
		}
		
		cp_control_status_reg_bc_bit: coverpoint csr_bc_bit 
		{
		  bins BC_NOT_CAPTURED = {1'b0};
		  bins BC_CAPTURED     = {1'b1};
		}
		
		cp_control_status_reg_bb_bit: coverpoint csr_bb_bit 
		{
		  bins BB_NOT_BUSY = {1'b0};
		  bins BB_BUSY     = {1'b1};
		}
		

		cx_cmd_status: cross cp_command_reg, cp_command_reg_status
		{
    			//NAK is only possible on WRITE(slave not acknowledging)
    			//all other commands physically cannot produce NAK
    			ignore_bins inv_start_nak   = binsof(cp_command_reg.START)   && binsof(cp_command_reg_status.NAK);
    			ignore_bins inv_stop_nak    = binsof(cp_command_reg.STOP)    && binsof(cp_command_reg_status.NAK);
    			ignore_bins inv_rdack_nak   = binsof(cp_command_reg.RD_ACK)  && binsof(cp_command_reg_status.NAK);
    			ignore_bins inv_rdnak_nak   = binsof(cp_command_reg.RD_NAK)  && binsof(cp_command_reg_status.NAK);
    			ignore_bins inv_setbus_nak  = binsof(cp_command_reg.SET_BUS) && binsof(cp_command_reg_status.NAK);
    			ignore_bins inv_wait_nak    = binsof(cp_command_reg.WAIT)    && binsof(cp_command_reg_status.NAK);
		}

		cx_bc_bb:      cross cp_control_status_reg_bc_bit, cp_control_status_reg_bb_bit {
    			ignore_bins bc_without_bb = binsof(cp_control_status_reg_bc_bit.BC_CAPTURED) && binsof(cp_control_status_reg_bb_bit.BB_NOT_BUSY);
}
	endgroup
	
	//this is my top level for byte level fsm covergroup
	covergroup fsm_byte_level_cg;
		option.per_instance = 1;
		option.name         = get_full_name();
		
		cp_fsm_byte_level_state: coverpoint fsm_byte_level_state
		{
		    bins IDLE          = {4'h0};
		    bins BUS_TAKEN     = {4'h1};
		    bins START_PENDING = {4'h2};
		    bins START         = {4'h3};
		    bins STOP          = {4'h4};
		    bins WRITE_BYTE    = {4'h5};
		    bins READ_BYTE     = {4'h6};
		    bins WAIT_STATE    = {4'h7};
		
		    bins idle_to_start_pending  = (4'h0 => 4'h2);
		    bins start_pending_to_start = (4'h2 => 4'h3);
		    bins start_to_bus_taken     = (4'h3 => 4'h1);
		    bins bus_taken_to_write     = (4'h1 => 4'h5);
		    bins bus_taken_to_read      = (4'h1 => 4'h6);
		    bins bus_taken_to_stop      = (4'h1 => 4'h4);
		    bins bus_taken_to_start     = (4'h1 => 4'h3);
		    bins write_to_bus_taken     = (4'h5 => 4'h1);
		    bins read_to_bus_taken      = (4'h6 => 4'h1);
		    bins stop_to_idle           = (4'h4 => 4'h0);
		    bins idle_to_wait           = (4'h0 => 4'h7);
		    bins wait_to_idle           = (4'h7 => 4'h0);
		}
	endgroup
	
	//this is my top level for i2c bus condition cover group
	covergroup i2c_timing_cg;
		option.per_instance = 1;
		option.name         = get_full_name();
		
		cp_start_type: coverpoint start_type 
		{
		  bins INITIAL_START  = {1'b0};
		  bins REPEATED_START = {1'b1};
		}
		
		cp_stop_seen: coverpoint stop_generated 
		{
		  bins STOP_NOT_SEEN = {1'b0};
		  bins STOP_SEEN     = {1'b1};
		}
		
		cp_ack_nak_sent: coverpoint ack_nak 
		{
		  bins ACK_SENT = {1'b0};
		  bins NAK_SENT = {1'b1};
		}
	endgroup
	
	function new(string name = "", ncsu_component_base parent = null);
		super.new(name, parent);
		i2cmb_op_cg    = new;
		wb_coverage_cg = new;
		fsm_byte_level_cg    = new;
		i2c_timing_cg  = new;
	endfunction
	
	function void set_configuration(i2cmb_env_configuration cfg);
		configuration = cfg;
	endfunction
	
	virtual function void nb_put(T trans);
		op               = trans.op;
		addr             = trans.addr;
		i2c_num_of_bytes = trans.data.size();
		i2cmb_op_cg.sample();
		
		//since every i2c transaction should end with stop bit
		stop_generated = 1'b1;
		i2c_timing_cg.sample();
		
		//I added debug prints if required
		//ncsu_info("i2cmb_coverage::nb_put()",$sformatf("%s sampled op:%s addr:0x%02x bytes:%0d",get_full_name(), op.name(), addr, i2c_num_of_bytes),NCSU_HIGH);
	endfunction
	
	//this is called by wb_monitor along with the register access data
	virtual function void sample_wb(bit [2:0] cmd,bit [3:0] status,bit e_bit,bit ie_bit,bit bc_bit,bit bb_bit,bit [7:0] dpr,bit irq);
		
		cmdr_cmd    = cmd;
		cmdr_status = status;
		csr_e_bit   = e_bit;
		csr_ie_bit  = ie_bit;
		csr_bc_bit  = bc_bit;
		csr_bb_bit  = bb_bit;
		dpr_value   = dpr;
		irq_state   = irq;
		wb_coverage_cg.sample();
	endfunction
	
	//this is called after every wait_for_done
	virtual function void sample_fsm(bit [3:0] fsm_state);
		fsm_byte_level_state = fsm_state;
		fsm_byte_level_cg.sample();
	endfunction
	
	//this is called by the generate to differentiate between initial and
	//repeated start
	virtual function void sample_start(bit is_repeated);
		start_type = is_repeated;
		i2c_timing_cg.sample();
	endfunction
	
	//this is called by i2c_monitor to sample ack/nak signals
	virtual function void sample_ack_nak(bit ack_nak_val);
		ack_nak = ack_nak_val;
		i2c_timing_cg.sample();
	endfunction

endclass


