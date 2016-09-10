`include "instruction.v"

module ex(rst, in_code, in_sel, in_reg1, in_reg2, in_data, in_reg, in_reg_hi, in_reg_lo, in_instr, wb_in_hi, wb_in_lo, wb_sg_hilo, mem_in_hi, mem_in_lo, mem_sg_hilo, hilo, in_count, in_ans, in_sg, in_link_addr, is_in_delayslot, fg_write, fg_reg, fg_data, out_reg_hi, out_reg_lo, out_sg_hilo, out_hilo, out_cnt, out_data1, out_data2, out_sg, fg_sign, out_code, mem_out_addr, out_reg2, sg_stall);

input wire rst, in_reg, wb_sg_hilo, mem_sg_hilo, in_sg, is_in_delayslot;
input wire[7:0] in_code;
input wire[2:0] in_sel;
input wire[31:0] in_reg1, in_reg2, in_instr, in_reg_hi, in_reg_lo, wb_in_hi, wb_in_lo, mem_in_hi, mem_in_lo,in_link_addr;
input wire[4:0] in_data;
input wire[63:0] hilo, in_ans;
input wire[1:0] in_count;
output reg[4:0] fg_write;
output reg fg_reg, out_sg_hilo, out_sg, fg_sign, sg_stall;
output reg[31:0] fg_data, out_reg_hi, out_reg_lo, out_data1, out_data2;
output reg[63:0] out_hilo;
output reg[1:0] out_cnt;
output wire[7:0] out_code;
output wire[31:0] mem_out_addr, out_reg2;
reg[31:0] logicout, shiftres, moveres, arithmeticres, HI, LO;
reg[63:0] mulres;	

wire[31:0] in_reg2_mux, in_reg1_not, result_sum;
wire ov_sum;
wire reg1_eq_reg2;
wire reg1_lt_reg2;
wire[31:0] opdata1_mult;
wire[31:0] opdata2_mult;
wire[63:0] hilo_temp;
reg[63:0] hilo_temp1;
reg stallreq_for_madd_msub;			
reg stallreq_for_div;


	
	
	assign mem_out_addr = in_reg1 + {{16{in_instr[15]}},in_instr[15:0]};
	
	assign out_reg2 = in_reg2;
	
	assign in_reg2_mux = ((in_code == `EXE_SUB_OP) || (in_code == `EXE_SUBU_OP) || (in_code == `EXE_SLT_OP)) ? (~in_reg2)+1 : in_reg2;

	assign result_sum = in_reg1 + in_reg2_mux;
	
	assign ov_sum = ((!in_reg1[31] && !in_reg2_mux[31]) && result_sum[31]) || ((in_reg1[31] && in_reg2_mux[31]) && (!result_sum[31]));
	
	assign reg1_lt_reg2 = ((in_code == `EXE_SLT_OP)) ? ((in_reg1[31] && !in_reg2[31]) || (!in_reg1[31] && !in_reg2[31] && result_sum[31])|| (in_reg1[31] && in_reg2[31] && result_sum[31])) : (in_reg1 < in_reg2);
  
	assign in_reg1_not = ~in_reg1;
	
	assign out_code = in_code;
	
	always @(*)
	begin
		if(rst == 1'b1) begin logicout <= 32'h00000000; end
		else
		begin
			case (in_code)
				`EXE_OR_OP: begin logicout <= in_reg1 | in_reg2; end
				`EXE_AND_OP: begin logicout <= in_reg1 & in_reg2; end
				`EXE_NOR_OP: begin logicout <= ~(in_reg1 |in_reg2); end
				`EXE_XOR_OP: begin logicout <= in_reg1 ^ in_reg2; end
				default: begin logicout <= 32'h00000000; end
			endcase
		end
	end

	always @(*)
	begin
		if(rst == 1'b1) begin shiftres <= 32'h00000000; end
		else
		begin
			case (in_code)
				`EXE_SLL_OP: begin shiftres <= in_reg2 << in_reg1[4:0]; end
				`EXE_SRL_OP: begin shiftres <= in_reg2 >> in_reg1[4:0]; end
				`EXE_SRA_OP: begin shiftres <= ({32{in_reg2[31]}} << (6'd32-{1'b0, in_reg1[4:0]})) | in_reg2 >> in_reg1[4:0]; end
				default: begin shiftres <= 32'h00000000; end
			endcase
		end
	end


	always @(*)
	begin
		if(rst == 1'b1) begin arithmeticres <= 32'h00000000; end
		else
		begin
			case (in_code)
				`EXE_SLT_OP, `EXE_SLTU_OP: begin arithmeticres <= reg1_lt_reg2; end
				`EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP: begin arithmeticres <= result_sum; end
				`EXE_SUB_OP, `EXE_SUBU_OP: begin arithmeticres <= result_sum; end		
				`EXE_CLZ_OP:
				begin
					arithmeticres <= in_reg1[31] ? 0 : in_reg1[30] ? 1 : in_reg1[29] ? 2 :
													 in_reg1[28] ? 3 : in_reg1[27] ? 4 : in_reg1[26] ? 5 :
													 in_reg1[25] ? 6 : in_reg1[24] ? 7 : in_reg1[23] ? 8 : 
													 in_reg1[22] ? 9 : in_reg1[21] ? 10 : in_reg1[20] ? 11 :
													 in_reg1[19] ? 12 : in_reg1[18] ? 13 : in_reg1[17] ? 14 : 
													 in_reg1[16] ? 15 : in_reg1[15] ? 16 : in_reg1[14] ? 17 : 
													 in_reg1[13] ? 18 : in_reg1[12] ? 19 : in_reg1[11] ? 20 :
													 in_reg1[10] ? 21 : in_reg1[9] ? 22 : in_reg1[8] ? 23 : 
													 in_reg1[7] ? 24 : in_reg1[6] ? 25 : in_reg1[5] ? 26 : 
													 in_reg1[4] ? 27 : in_reg1[3] ? 28 : in_reg1[2] ? 29 : 
													 in_reg1[1] ? 30 : in_reg1[0] ? 31 : 32'h00000000 ;
				end
				`EXE_CLO_OP:
				begin
					arithmeticres <= (in_reg1_not[31] ? 0 : in_reg1_not[30] ? 1 : in_reg1_not[29] ? 2 :
													 in_reg1_not[28] ? 3 : in_reg1_not[27] ? 4 : in_reg1_not[26] ? 5 :
													 in_reg1_not[25] ? 6 : in_reg1_not[24] ? 7 : in_reg1_not[23] ? 8 : 
													 in_reg1_not[22] ? 9 : in_reg1_not[21] ? 10 : in_reg1_not[20] ? 11 :
													 in_reg1_not[19] ? 12 : in_reg1_not[18] ? 13 : in_reg1_not[17] ? 14 : 
													 in_reg1_not[16] ? 15 : in_reg1_not[15] ? 16 : in_reg1_not[14] ? 17 : 
													 in_reg1_not[13] ? 18 : in_reg1_not[12] ? 19 : in_reg1_not[11] ? 20 :
													 in_reg1_not[10] ? 21 : in_reg1_not[9] ? 22 : in_reg1_not[8] ? 23 : 
													 in_reg1_not[7] ? 24 : in_reg1_not[6] ? 25 : in_reg1_not[5] ? 26 : 
													 in_reg1_not[4] ? 27 : in_reg1_not[3] ? 28 : in_reg1_not[2] ? 29 : 
													 in_reg1_not[1] ? 30 : in_reg1_not[0] ? 31 : 32'h00000000) ;
				end
				default:
				begin
					arithmeticres <= 32'h00000000;
				end
			endcase
		end
	end

  
	assign opdata1_mult = (((in_code == `EXE_MUL_OP) || (in_code == `EXE_MULT_OP) || (in_code == `EXE_MADD_OP) || (in_code == `EXE_MSUB_OP)) && (in_reg1[31] == 1'b1)) ? (~in_reg1 + 1) : in_reg1;

	assign opdata2_mult = (((in_code == `EXE_MUL_OP) || (in_code == `EXE_MULT_OP) || (in_code == `EXE_MADD_OP) || (in_code == `EXE_MSUB_OP)) && (in_reg2[31] == 1'b1)) ? (~in_reg2 + 1) : in_reg2;	

	assign hilo_temp = opdata1_mult * opdata2_mult;																				

	always @(*)
	begin
		if(rst == 1'b1) begin mulres <= {32'h00000000,32'h00000000}; end
		else if((in_code == `EXE_MULT_OP) || (in_code == `EXE_MUL_OP) || (in_code == `EXE_MADD_OP) || (in_code == `EXE_MSUB_OP))
		begin
			if(in_reg1[31] ^ in_reg2[31] == 1'b1) begin mulres <= ~hilo_temp + 1; end
			else begin mulres <= hilo_temp; end
		end
		else begin mulres <= hilo_temp; end
	end

	always @(*)
	begin
		if(rst == 1'b1) begin {HI,LO} <= {32'h00000000,32'h00000000}; end
		else if(mem_sg_hilo == 1'b1) begin {HI,LO} <= {mem_in_hi,mem_in_lo}; end
		else if(wb_sg_hilo == 1'b1) begin {HI,LO} <= {wb_in_hi,wb_in_lo}; end
		else begin {HI,LO} <= {in_reg_hi,in_reg_lo}; end
	end	

	always @(*)
	begin sg_stall = stallreq_for_madd_msub || stallreq_for_div; end

	always @(*)
	begin
		if(rst == 1'b1)
		begin
			out_hilo <= {32'h00000000,32'h00000000};
			out_cnt <= 2'b00;
			stallreq_for_madd_msub <= 1'b0;
		end
		else
		begin
			case (in_code) 
				`EXE_MADD_OP, `EXE_MADDU_OP:
				begin
					if(in_count == 2'b00)
					begin
						out_hilo <= mulres;
						out_cnt <= 2'b01;
						stallreq_for_madd_msub <= 1'b1;
						hilo_temp1 <= {32'h00000000,32'h00000000};
					end
					else if(in_count == 2'b01)
					begin
						out_hilo <= {32'h00000000,32'h00000000};						
						out_cnt <= 2'b10;
						hilo_temp1 <= hilo + {HI,LO};
						stallreq_for_madd_msub <= 1'b0;
					end
				end
				`EXE_MSUB_OP, `EXE_MSUBU_OP:
				begin
					if(in_count == 2'b00)
					begin
						out_hilo <=  ~mulres + 1 ;
						out_cnt <= 2'b01;
						stallreq_for_madd_msub <= 1'b1;
					end
					else if(in_count == 2'b01)
					begin
						out_hilo <= {32'h00000000,32'h00000000};						
						out_cnt <= 2'b10;
						hilo_temp1 <= hilo + {HI,LO};
						stallreq_for_madd_msub <= 1'b0;
					end				
				end
				default:
				begin
					out_hilo <= {32'h00000000,32'h00000000};
					out_cnt <= 2'b00;
					stallreq_for_madd_msub <= 1'b0;				
				end
			endcase
		end
	end	
	
	always @(*)
	begin
		if(rst == 1'b1)
		begin
			stallreq_for_div <= 1'b0;
			out_data1 <= 32'h00000000;
			out_data2 <= 32'h00000000;
			out_sg <= 1'b0;
			fg_sign <= 1'b0;
		end
		else
		begin
			stallreq_for_div <= 1'b0;
			out_data1 <= 32'h00000000;
			out_data2 <= 32'h00000000;
			out_sg <= 1'b0;
			fg_sign <= 1'b0;	
			case (in_code) 
				`EXE_DIV_OP:
				begin
					if(in_sg == 1'b0)
					begin
						out_data1 <= in_reg1;
						out_data2 <= in_reg2;
						out_sg <= 1'b1;
						fg_sign <= 1'b1;
						stallreq_for_div <= 1'b1;
					end
					else if(in_sg == 1'b1)
					begin
						out_data1 <= in_reg1;
						out_data2 <= in_reg2;
						out_sg <= 1'b0;
						fg_sign <= 1'b1;
						stallreq_for_div <= 1'b0;
					end
					else
					begin						
						out_data1 <= 32'h00000000;
						out_data2 <= 32'h00000000;
						out_sg <= 1'b0;
						fg_sign <= 1'b0;
						stallreq_for_div <= 1'b0;
					end					
				end
				`EXE_DIVU_OP:
				begin
					if(in_sg == 1'b0)
					begin
						out_data1 <= in_reg1;
						out_data2 <= in_reg2;
						out_sg <= 1'b1;
						fg_sign <= 1'b0;
						stallreq_for_div <= 1'b1;
					end
					else if(in_sg == 1'b1)
					begin
						out_data1 <= in_reg1;
						out_data2 <= in_reg2;
						out_sg <= 1'b0;
						fg_sign <= 1'b0;
						stallreq_for_div <= 1'b0;
					end
					else
					begin						
						out_data1 <= 32'h00000000;
						out_data2 <= 32'h00000000;
						out_sg <= 1'b0;
						fg_sign <= 1'b0;
						stallreq_for_div <= 1'b0;
					end					
				end
				default: begin end
			endcase
		end
	end	

	always @(*)
	begin
		if(rst == 1'b1) begin moveres <= 32'h00000000; end
		else
		begin
			moveres <= 32'h00000000;
			case (in_code)
			`EXE_MFHI_OP: begin moveres <= HI; end
			`EXE_MFLO_OP: begin moveres <= LO; end
			`EXE_MOVZ_OP: begin moveres <= in_reg1; end
			`EXE_MOVN_OP: begin moveres <= in_reg1; end
			default : begin end
			endcase
		end
	end	 

 always @(*)
 begin
	 fg_write <= in_data;
	 	 	 	
	 if(((in_code == `EXE_ADD_OP) || (in_code == `EXE_ADDI_OP) || (in_code == `EXE_SUB_OP)) && (ov_sum == 1'b1))
	 begin fg_reg <= 1'b0; end
	 else begin fg_reg <= in_reg; end
	 
	 case(in_sel) 
	 	`EXE_RES_LOGIC: begin fg_data <= logicout; end
	 	`EXE_RES_SHIFT: begin fg_data <= shiftres; end	 	
	 	`EXE_RES_MOVE: begin fg_data <= moveres; end	 	
	 	`EXE_RES_ARITHMETIC: begin fg_data <= arithmeticres; end
	 	`EXE_RES_MUL: begin fg_data <= mulres[31:0]; end	 	
	 	`EXE_RES_JUMP_BRANCH: begin fg_data <= in_link_addr; end	 	
	 	default: begin fg_data <= 32'h00000000; end
	 endcase
 end	

	always @(*)
	begin
		if(rst == 1'b1)
		begin
			out_sg_hilo <= 1'b0;
			out_reg_hi <= 32'h00000000;
			out_reg_lo <= 32'h00000000;		
		end
		else if((in_code == `EXE_MULT_OP) || (in_code == `EXE_MULTU_OP))
		begin
			out_sg_hilo <= 1'b1;
			out_reg_hi <= mulres[63:32'h00000000];
			out_reg_lo <= mulres[31:0];			
		end
		else if((in_code == `EXE_MADD_OP) || (in_code == `EXE_MADDU_OP))
		begin
			out_sg_hilo <= 1'b1;
			out_reg_hi <= hilo_temp1[63:32'h00000000];
			out_reg_lo <= hilo_temp1[31:0];
		end
		else if((in_code == `EXE_MSUB_OP) || (in_code == `EXE_MSUBU_OP))
		begin
			out_sg_hilo <= 1'b1;
			out_reg_hi <= hilo_temp1[63:32'h00000000];
			out_reg_lo <= hilo_temp1[31:0];		
		end
		else if((in_code == `EXE_DIV_OP) || (in_code == `EXE_DIVU_OP))
		begin
			out_sg_hilo <= 1'b1;
			out_reg_hi <= in_ans[63:32'h00000000];
			out_reg_lo <= in_ans[31:0];							
		end
		else if(in_code == `EXE_MTHI_OP)
		begin
			out_sg_hilo <= 1'b1;
			out_reg_hi <= in_reg1;
			out_reg_lo <= LO;
		end
		else if(in_code == `EXE_MTLO_OP)
		begin
			out_sg_hilo <= 1'b1;
			out_reg_hi <= HI;
			out_reg_lo <= in_reg1;
		end
		else
		begin
			out_sg_hilo <= 1'b0;
			out_reg_hi <= 32'h00000000;
			out_reg_lo <= 32'h00000000;
		end				
	end			

endmodule