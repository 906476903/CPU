`timescale 1ns/1ps

module cpu_test();

reg CLOCK_50, rst_;
wire clk, rst;

wire[31:0] inst_addr;
wire[31:0] inst;
wire rom_ce;
wire mem_we_i;
wire[31:0] mem_addr_i;
wire[31:0] mem_data_i;
wire[31:0] mem_data_o;
wire[3:0] mem_sel_i;   
wire mem_ce_i; 
 
	assign clk = CLOCK_50;
	assign rst = rst_;
	
	initial
	begin
		CLOCK_50 = 1'b0;
		forever #10 CLOCK_50 = ~CLOCK_50;
	end
      
	initial
	begin
		rst_ = 1'b1;
		#195 rst_= 1'b0;
		#4100 $stop;
	end
	
	cpu_mips32 cpu_mips32_(clk, rst, inst, inst_addr, rom_ce, mem_data_o, mem_addr_i, mem_data_i, mem_we_i, mem_sel_i, mem_ce_i);
	
	instr_mem instr_mem_(rom_ce, inst_addr, inst);

	main_mem main_mem_(clk, mem_ce_i, mem_we_i, mem_addr_i, mem_sel_i, mem_data_i, mem_data_o);
	
endmodule