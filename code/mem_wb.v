module mem_wb(clk, rst, stall, mem_wd, mem_wreg, mem_wdata, mem_hi, mem_lo, mem_whilo, mem_LLbit_we, mem_LLbit_value, wb_wd, wb_wreg, wb_wdata, wb_hi, wb_lo, wb_whilo, wb_LLbit_we, wb_LLbit_value);

input wire clk, rst, mem_wreg, mem_whilo, mem_LLbit_we, mem_LLbit_value;
input wire[5:0] stall;
input wire[4:0] mem_wd;
input wire[31:0] mem_wdata, mem_hi, mem_lo;
output reg[4:0] wb_wd;
output reg wb_wreg, wb_whilo,  wb_LLbit_we, wb_LLbit_value;
output reg[31:0] wb_wdata, wb_hi, wb_lo;

	always @(posedge clk)
	begin
		if((rst == 1'b1) || (stall[4] == 1'b1 && stall[5] == 1'b0))
		begin
			wb_wd <= 5'b00000; wb_wreg <= 1'b0;
			wb_wdata <= 32'h00000000;
			wb_hi <= 32'h00000000;
			wb_lo <= 32'h00000000;
			wb_whilo <= 1'b0;
			wb_LLbit_we <= 1'b0;
			wb_LLbit_value <= 1'b0;
		end
		else if(stall[4] == 1'b0)
		begin
			wb_wd <= mem_wd;
			wb_wreg <= mem_wreg;
			wb_wdata <= mem_wdata;
			wb_hi <= mem_hi;
			wb_lo <= mem_lo;
			wb_whilo <= mem_whilo;
			wb_LLbit_we <= mem_LLbit_we;
			wb_LLbit_value <= mem_LLbit_value;
		end
	end
	
endmodule