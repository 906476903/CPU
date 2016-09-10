`include "defines.v"

module ex_mem(clk, rst, stall, ex_wd, ex_wreg, ex_wdata, ex_hi, ex_lo, ex_whilo, ex_aluop, ex_mem_addr, ex_reg2, hilo_i, cnt_i, mem_wd, mem_wreg, mem_wdata, mem_hi, mem_lo, mem_whilo, mem_aluop, mem_mem_addr, mem_reg2, hilo_o, cnt_o);

input wire clk, rst, ex_wreg, ex_whilo;
input wire[5:0] stall;	
input wire[4:0] ex_wd;
input wire[31:0] ex_wdata, ex_hi, ex_lo, ex_mem_addr, ex_reg2;
input wire[7:0] ex_aluop;
input wire[63:0] hilo_i;
input wire[1:0] cnt_i;
output reg[4:0] mem_wd;
output reg mem_wreg, mem_whilo;
output reg[31:0] mem_wdata, mem_hi, mem_lo;
output reg[7:0] mem_aluop;
output reg[31:0] mem_mem_addr, mem_reg2;
output reg[63:0] hilo_o;
output reg[1:0] cnt_o;


	always @(posedge clk)
	begin
		if(rst == 1'b1)
		begin
			mem_wd <= 5'b00000; mem_wreg <= 1'b0; mem_wdata <= 32'h00000000;	
			mem_hi <= 32'h00000000; mem_lo <= 32'h00000000;
			mem_whilo <= 1'b0;		
			hilo_o <= {32'h00000000, 32'h00000000};
			cnt_o <= 2'b00;	
			mem_aluop <= `EXE_NOP_OP; mem_mem_addr <= 32'h00000000; mem_reg2 <= 32'h00000000;			
		end
		else if(stall[3] == 1'b1 && stall[4] == 1'b0)
		begin
			mem_wd <= 5'b00000; mem_wreg <= 1'b0; mem_wdata <= 32'h00000000;
			mem_hi <= 32'h00000000; mem_lo <= 32'h00000000;
			mem_whilo <= 1'b0;
			hilo_o <= hilo_i;
			cnt_o <= cnt_i;	
			mem_aluop <= `EXE_NOP_OP; mem_mem_addr <= 32'h00000000; mem_reg2 <= 32'h00000000;
		end
		else if(stall[3] == 1'b0)
		begin
			mem_wd <= ex_wd; mem_wreg <= ex_wreg; mem_wdata <= ex_wdata;	
			mem_hi <= ex_hi; mem_lo <= ex_lo;
			mem_whilo <= ex_whilo;	
			hilo_o <= {32'h00000000, 32'h00000000};
			cnt_o <= 2'b00;	
			mem_aluop <= ex_aluop; mem_mem_addr <= ex_mem_addr; mem_reg2 <= ex_reg2;
		end
		else
		begin
			hilo_o <= hilo_i;
			cnt_o <= cnt_i;											
		end
	end
	
endmodule