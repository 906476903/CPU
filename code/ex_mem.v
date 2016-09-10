`include "instruction.v"

module ex_mem(clk, rst, sg_stall, ex_wd, ex_wreg, ex_wdata, ex_hi, ex_lo, ex_sg_hilo, ex_code, ex_mem_addr, ex_reg2, in_hilo, in_count, mem_wd, mem_wreg, mem_wdata, mem_hi, mem_lo, mem_sg_hilo, mem_code, mem_mem_addr, mem_reg2, out_hilo, out_count);

input wire clk, rst, ex_wreg, ex_sg_hilo;
input wire[5:0] sg_stall;	
input wire[4:0] ex_wd;
input wire[31:0] ex_wdata, ex_hi, ex_lo, ex_mem_addr, ex_reg2;
input wire[7:0] ex_code;
input wire[63:0] in_hilo;
input wire[1:0] in_count;
output reg[4:0] mem_wd;
output reg mem_wreg, mem_sg_hilo;
output reg[31:0] mem_wdata, mem_hi, mem_lo;
output reg[7:0] mem_code;
output reg[31:0] mem_mem_addr, mem_reg2;
output reg[63:0] out_hilo;
output reg[1:0] out_count;


	always @(posedge clk)
	begin
		if(rst == 1'b1)
		begin
			mem_wd <= 5'b00000; mem_wreg <= 1'b0; mem_wdata <= 32'h00000000;	
			mem_hi <= 32'h00000000; mem_lo <= 32'h00000000;
			mem_sg_hilo <= 1'b0;		
			out_hilo <= {32'h00000000, 32'h00000000};
			out_count <= 2'b00;	
			mem_code <= `EXE_NOP_OP; mem_mem_addr <= 32'h00000000; mem_reg2 <= 32'h00000000;			
		end
		else if(sg_stall[3] == 1'b1 && sg_stall[4] == 1'b0)
		begin
			mem_wd <= 5'b00000; mem_wreg <= 1'b0; mem_wdata <= 32'h00000000;
			mem_hi <= 32'h00000000; mem_lo <= 32'h00000000;
			mem_sg_hilo <= 1'b0;
			out_hilo <= in_hilo;
			out_count <= in_count;	
			mem_code <= `EXE_NOP_OP; mem_mem_addr <= 32'h00000000; mem_reg2 <= 32'h00000000;
		end
		else if(sg_stall[3] == 1'b0)
		begin
			mem_wd <= ex_wd; mem_wreg <= ex_wreg; mem_wdata <= ex_wdata;	
			mem_hi <= ex_hi; mem_lo <= ex_lo;
			mem_sg_hilo <= ex_sg_hilo;	
			out_hilo <= {32'h00000000, 32'h00000000};
			out_count <= 2'b00;	
			mem_code <= ex_code; mem_mem_addr <= ex_mem_addr; mem_reg2 <= ex_reg2;
		end
		else
		begin
			out_hilo <= in_hilo;
			out_count <= in_count;											
		end
	end
	
endmodule