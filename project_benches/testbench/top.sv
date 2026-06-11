`timescale 1ns / 10ps

module top();

//paramters
parameter int WB_ADDR_WIDTH  = 2;
parameter int WB_DATA_WIDTH  = 8;
parameter int NUM_I2C_BUSSES = 1;
parameter int I2C_ADDR_WIDTH = 7;
parameter int I2C_DATA_WIDTH = 8;

bit  clk;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
logic wb_we;
tri1 ack;
wire [WB_ADDR_WIDTH-1:0]  adr;
logic [WB_ADDR_WIDTH-1:0] wb_addr;
wire [WB_DATA_WIDTH-1:0]  dat_wr_o;
wire [WB_DATA_WIDTH-1:0]  dat_rd_i;
logic [WB_DATA_WIDTH-1:0] wb_data;
logic [WB_DATA_WIDTH-1:0] rd_data;
wire irq;
tri     [NUM_I2C_BUSSES-1:0] scl;
triand  [NUM_I2C_BUSSES-1:0] sda;
wire [3:0] byte_fsm_state;
assign byte_fsm_state = DUT.iicmb_m_inst0.byte_state;

//I have imported all the necessary packages
import ncsu_pkg::*;
import wb_pkg::*;
import i2c_pkg::*;
import i2cmb_env_pkg::*;

//instantiating the wishbone BFM
wb_if #(
    .ADDR_WIDTH(WB_ADDR_WIDTH),
    .DATA_WIDTH(WB_DATA_WIDTH)
) wb_bus (
    .clk_i(clk),
    .rst_i(rst),
    .irq_i(irq),
    .cyc_o(cyc),
    .stb_o(stb),
    .ack_i(ack),
    .adr_o(adr),
    .we_o(we),
    .cyc_i(),
    .stb_i(),
    .ack_o(),
    .adr_i(),
    .we_i(),
    .dat_o(dat_wr_o),
    .dat_i(dat_rd_i),
    .fsm_state_i(byte_fsm_state)
);

//instantiating the i2c BFM
i2c_if #(
    .I2C_ADDR_WIDTH(I2C_ADDR_WIDTH),
    .I2C_DATA_WIDTH(I2C_DATA_WIDTH)
) i2c_bus (
    .i2c_scl(scl),
    .i2c_sda(sda)
);

//instantiating the DUT - I2C Multi Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT (
    .clk_i(clk),
    .rst_i(rst),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(ack),
    .adr_i(adr),
    .we_i(we),
    .dat_i(dat_wr_o),
    .dat_o(dat_rd_i),
    .irq(irq),
    .scl_i(scl),
    .sda_i(sda),
    .scl_o(scl),
    .sda_o(sda)
);
i2cmb_test test;

// Continuous FSM state sampling for transition coverage
// Samples on every clock edge so covergroup sees full state sequence
//always @(posedge clk) begin
//    if (test != null && 
//        test.environment != null && 
//        test.environment.coverage != null) begin
//        test.environment.coverage.sample_fsm(byte_fsm_state);
//    end
//end

// Only sample when FSM state actually changes - gives clean transitions
logic [3:0] prev_fsm_state = 4'hF;
always @(posedge clk) begin
    if (byte_fsm_state != prev_fsm_state) begin
        prev_fsm_state <= byte_fsm_state;
        if (test != null &&
            test.environment != null &&
            test.environment.coverage != null) begin
            test.environment.coverage.sample_fsm(byte_fsm_state);
        end
    end
end


// ============================================================================
// Clock generator
// ============================================================================
initial begin : clk_gen
    clk = 1'b0;
    forever #5 clk = ~clk;
end

// ============================================================================
// Reset generator
// ============================================================================
initial begin : rst_gen
    #113 rst = 1'b0;
end

initial begin : test_flow

    //I have registered the interface handles BEFORE build() is called
    ncsu_config_db #(virtual wb_if  #(2,8))::set("test.environment.wb_agent",  wb_bus);
    ncsu_config_db #(virtual i2c_if #())::set("test.environment.i2c_agent", i2c_bus);

    //I have constructed the build the full testbench
    test = new("test", null);
    test.build();
    
    //This is included to wire the coverage handle
    test.generator.set_coverage(test.environment.coverage);

    //I wait for reset and then run the test sequence
    wb_bus.wait_for_reset();
    @(posedge clk);
    test.run();

    //end simulation
    #100;
    $finish;
end

endmodule

