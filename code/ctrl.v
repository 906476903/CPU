module ctrl(rst, fg_id, fg_ex, sign_stall);
input wire rst, fg_id, fg_ex;
output reg[5:0] sign_stall;

	always @(*)
	begin
		if(fg_ex == 1'b1) begin sign_stall <= 6'b001111; end
		else if(fg_id == 1'b1) begin sign_stall <= 6'b000111; end
		else begin sign_stall <= 6'b000000; end
	end
			

endmodule