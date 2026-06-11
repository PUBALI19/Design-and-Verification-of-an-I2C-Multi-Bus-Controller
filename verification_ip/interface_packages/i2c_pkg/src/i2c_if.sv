`timescale 1ns / 10ps

interface i2c_if #(
    parameter int I2C_ADDR_WIDTH = 7,
    parameter int I2C_DATA_WIDTH = 8
) 
(
    input           i2c_scl,
    inout   triand  i2c_sda
);
//enum declaration to identify whether I2C is doing a read/write operation
typedef enum logic { I2C_WRITE = 1'b0, I2C_READ = 1'b1 } i2c_op_t;
//signal declaration
logic ack_sda   = 0;
//holds the value of on sda when ack_sda = 1
logic sda_ack_drive = 0;
        
assign i2c_sda = ack_sda ? sda_ack_drive : 'bz;

//TASK 1: wait_for_i2c_transfer: waits for and captures transfer data
task wait_for_i2c_transfer 
( 
    output bit op, 
    output bit [I2C_DATA_WIDTH-1:0] write_data []
);
	//captures the first byte after start condition
	bit [7:0] first_byte;
	//queue for accomodating data during write transfer
	bit [I2C_DATA_WIDTH-1:0] data_fifo[$];
	//for stopping the write transfer
	bit stop_bit;
	bit [7:0] received_byte;
	bit repeated_start;	
	
	@(negedge i2c_sda iff (i2c_scl == 1'b1));
	
	for (int i = 7; i >= 0; i--) 
	begin
	    @(posedge i2c_scl);
	    first_byte[i] = i2c_sda;
	end
	op = i2c_op_t'(first_byte[0]);
	
	//I am driving sda sck through the negedge so that through posedge
	//the master can sample it
	@(negedge i2c_scl);
	ack_sda = 1; 
	sda_ack_drive = 0;
	@(posedge i2c_scl);
	
	//I release the sda ack in the next negedge
	//For write I continue collecting the data but for read I return the control so
	//that provide_read_data can drive bit[7] immediately
	@(negedge i2c_scl);
	ack_sda = 0;
	
	if (op == I2C_WRITE) 
	begin
	    stop_bit = 0;
	    while (!stop_bit) 
    	    begin
	        fork 
	        begin
			//take in data
	        	for (int i = 7; i >= 0; i--) 
			begin
	        	    @(posedge i2c_scl);
	        	    received_byte[i] = i2c_sda;
	        	end
	        	data_fifo.push_back(received_byte);
	        	@(negedge i2c_scl);
	        	ack_sda = 1; sda_ack_drive = 0;
	        	@(posedge i2c_scl);
	        	@(negedge i2c_scl);
	        	ack_sda = 0;
	        end
	        begin 
			//detect write stop
	                @(posedge i2c_sda iff (i2c_scl == 1'b1));
	                stop_bit = 1;
	        end
		//for repeated start
		begin
                	@(posedge i2c_scl);
                	@(negedge i2c_sda iff (i2c_scl == 1'b1));
                	repeated_start = 1;
                	ack_sda = 0;
            	end
	        join_any
	        disable fork;
	    end
	    write_data = new[data_fifo.size()](data_fifo);
	end
endtask

// TASK 2: provide_read_data: provides data for read operation
task provide_read_data 
( 
    input bit [I2C_DATA_WIDTH-1:0] read_data [], 
    output bit transfer_complete
);
    transfer_complete = 0;
    foreach (read_data[j]) 
    begin
        automatic bit [7:0] present_byte = read_data[j];
        
        for (int i = 7; i >= 0; i--) 
	begin
	    //for bit[6] to bit[0], I wait for negedge
            if (i < 7) @(negedge i2c_scl);
            ack_sda = 1; 
            sda_ack_drive = present_byte[i];
        end
        
	//I made sda acknowledgment signal 0 for master's ack/nack
        @(negedge i2c_scl);
        ack_sda = 0; 

        @(posedge i2c_scl);
        if (i2c_sda == 1'b1) 
	begin
            transfer_complete = 1;
            return;
        end

	//I don't wait for negedge and immediately drive bit[7] on next loop
	//iteration
        @(negedge i2c_scl);
    end
    transfer_complete = 1;
endtask

// TASK 3: monitor: returns data observed
task monitor 
( 
    output bit [I2C_ADDR_WIDTH-1:0] addr, 
    output bit op, 
    output bit [I2C_DATA_WIDTH-1:0] data []
);
    //for collecting the data bitwise on the bus and store it in data_fifo
    bit [7:0] input_data;
    //queue for data collection
    bit [I2C_DATA_WIDTH-1:0] data_fifo[$];
    //to control when it should start and stop the monitor task
    bit contrl_mon;

    //I clear the data queue each time
    data_fifo = {}; 

    @(negedge i2c_sda iff (i2c_scl == 1'b1)); 
    
    for (int i = 7; i >= 0; i--) 
    begin
        @(posedge i2c_scl);
        input_data[i] = i2c_sda;
    end
    addr = input_data[7:1];
    op = i2c_op_t'(input_data[0]);
    
    @(posedge i2c_scl);

    contrl_mon = 0;
    while (!contrl_mon) 
    begin
        fork
        begin 
		//byte collection
                for (int i = 7; i >= 0; i--) 
		begin
                    @(posedge i2c_scl);
                    input_data[i] = i2c_sda;
                end
                data_fifo.push_back(input_data);
        end
        begin
		//stop collection
                @(posedge i2c_sda iff (i2c_scl == 1'b1));
                contrl_mon = 1;
        end
        join_any
        disable fork;

        if (!contrl_mon) 
	begin
            fork
            begin
		    //ack clk
                    @(posedge i2c_scl);
            end
            begin
		    //stop using ack clk
                    @(posedge i2c_sda iff (i2c_scl == 1'b1));
                    contrl_mon = 1;
            end
            join_any
            disable fork;
        end
    end
    data = new[data_fifo.size()](data_fifo);
endtask

endinterface
