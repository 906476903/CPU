module if_id(clk, rst, sign_stall, if_pc, if_inst, id_pc, id_inst);
input wire clk, rst;
input wire[5:0] sign_stall;
input wire[31:0] if_pc, if_inst;
output reg[31:0] id_pc, id_inst;

	always @ (posedge clk)
	begin
		if (rst == 1'b1 || (sign_stall[1] == 1'b1 && sign_stall[2] == 1'b0))
		begin
			id_pc <= 32'h00000000;
			id_inst <= 32'h00000000;
		end
		else if(sign_stall[1] == 1'b0)
		begin
			id_pc <= if_pc;
			id_inst <= if_inst;
		end
	end

endmodule