module LLbit_reg(clk, rst, sg, in_llbit, fg_write, out_llbit);
input wire clk, rst, sg, in_llbit, fg_write;
output reg out_llbit;

	always @(posedge clk)
	begin
		if((rst == 1'b1) || (sg == 1'b1)) begin out_llbit <= 1'b0;
		end else if(fg_write == 1'b1) begin out_llbit <= in_llbit; end
	end

endmodule