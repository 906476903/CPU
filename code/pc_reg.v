module pc_reg(clk, rst, stall, fg_b, b_addr, pc, ce);
input wire clk, rst, fg_b;
input wire[5:0] stall;
input wire[31:0] b_addr;
output reg[31:0] pc;
output reg ce;
	
	always @(posedge clk)
	begin
		if(ce == 1'b0) begin pc <= 32'h00000000; end
		else if(stall[0] == 1'b0)
		begin
			pc <= fg_b == 1'b1 ? 
b_addr : pc + 4'h4;

		end

		ce <= rst == 1'b1 ? 1'b0 : 1'b1;
	end

endmodule