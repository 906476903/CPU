module hilo_reg(clk, rst, fg_write, in_reg_hi, in_reg_lo, out_reg_hi, out_reg_lo);

input wire clk, rst, fg_write;
input wire[31:0] in_reg_hi, in_reg_lo;
output reg[31:0] out_reg_hi, out_reg_lo;

	always @(posedge clk)
	begin
		if(rst == 1'b1) begin out_reg_hi <= 32'h00000000; out_reg_lo <= 32'h00000000; end
		else if(fg_write == 1'b1) begin out_reg_hi <= in_reg_hi; out_reg_lo <= in_reg_lo; end
	end

endmodule