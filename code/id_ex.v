`include "instruction.v"

module id_ex(clk, rst, stall, id_aluop, id_alusel, id_reg1, id_reg2, id_wd, id_wreg, id_link_address, id_is_in_delayslot, next_inst_in_delayslot_i, id_inst, ex_aluop, ex_alusel, ex_reg1, ex_reg2, ex_wd, ex_wreg, ex_link_address, ex_is_in_delayslot, is_in_delayslot_o, ex_inst);
input wire clk, rst, id_wreg, id_is_in_delayslot, next_inst_in_delayslot_i;
input wire[5:0] stall;
input wire[7:0] id_aluop;
input wire[2:0] id_alusel;
input wire[31:0] id_reg1, id_reg2, id_link_address, id_inst;
input wire[4:0] id_wd;
output reg[7:0] ex_aluop;
output reg[2:0] ex_alusel;
output reg[31:0] ex_reg1, ex_reg2, ex_link_address, ex_inst;
output reg[4:0] ex_wd;
output reg ex_wreg, ex_is_in_delayslot, is_in_delayslot_o;

	always @(posedge clk)
	begin
		if((rst == 1'b1) || (stall[2] == 1'b1 && stall[3] == 1'b0))
		begin
			ex_aluop <= `EXE_NOP_OP; ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= 32'h00000000; ex_reg2 <= 32'h00000000;
			ex_wd <= 5'b00000; ex_wreg <= 1'b0;
			ex_link_address <= 32'h00000000;
			ex_is_in_delayslot <= 1'b0;
			ex_inst <= 32'h00000000;	
			if(rst == 1'b1) is_in_delayslot_o <= 1'b0;
		end
		else if(stall[2] == 1'b0)
		begin		
			ex_aluop <= id_aluop; ex_alusel <= id_alusel;
			ex_reg1 <= id_reg1; ex_reg2 <= id_reg2;
			ex_wd <= id_wd; ex_wreg <= id_wreg;		
			ex_link_address <= id_link_address;
			ex_is_in_delayslot <= id_is_in_delayslot;
			is_in_delayslot_o <= next_inst_in_delayslot_i;
			ex_inst <= id_inst;				
		end
	end
	
endmodule