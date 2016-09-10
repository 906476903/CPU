`include "defines.v"

module ex(rst, in_code, in_sel, in_reg1, in_reg2, in_data, in_reg, hi_i, lo_i, inst_i, wb_hi_i, wb_lo_i, wb_whilo_i, mem_hi_i, mem_lo_i, mem_whilo_i, hilo_temp_i, cnt_i, div_result_i, div_ready_i, link_address_i, is_in_delayslot_i, wd_o, wreg_o, wdata_o, hi_o, lo_o, whilo_o, hilo_temp_o, cnt_o, div_opdata1_o, div_opdata2_o, div_start_o, signed_div_o, aluop_o, mem_addr_o, reg2_o, stallreq);

input wire rst, in_reg, wb_whilo_i, mem_whilo_i, div_ready_i, is_in_delayslot_i;
input wire[7:0] in_code;
input wire[2:0] in_sel;
input wire[31:0] in_reg1, in_reg2, inst_i, hi_i, lo_i, wb_hi_i, wb_lo_i, mem_hi_i, mem_lo_i,link_address_i;
input wire[4:0] in_data;
input wire[63:0] hilo_temp_i, div_result_i;
input wire[1:0] cnt_i;
output reg[4:0] wd_o;
output reg wreg_o, whilo_o, div_start_o, signed_div_o, stallreq;
output reg[31:0] wdata_o, hi_o, lo_o, div_opdata1_o, div_opdata2_o;
output reg[63:0] hilo_temp_o;
output reg[1:0] cnt_o;
output wire[7:0] aluop_o;
output wire[31:0] mem_addr_o, reg2_o;
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


	assign aluop_o = in_code;
	assign mem_addr_o = in_reg1 + {{16{inst_i[15]}},inst_i[15:0]};
	assign reg2_o = in_reg2;
	
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

	assign in_reg2_mux = ((in_code == `EXE_SUB_OP) || (in_code == `EXE_SUBU_OP) || (in_code == `EXE_SLT_OP)) ? (~in_reg2)+1 : in_reg2;

	assign result_sum = in_reg1 + in_reg2_mux;										 

	assign ov_sum = ((!in_reg1[31] && !in_reg2_mux[31]) && result_sum[31]) || ((in_reg1[31] && in_reg2_mux[31]) && (!result_sum[31]));  
									
	assign reg1_lt_reg2 = ((in_code == `EXE_SLT_OP)) ? ((in_reg1[31] && !in_reg2[31]) || (!in_reg1[31] && !in_reg2[31] && result_sum[31])|| (in_reg1[31] && in_reg2[31] && result_sum[31])) : (in_reg1 < in_reg2);
  
	assign in_reg1_not = ~in_reg1;
							
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
		else if(mem_whilo_i == 1'b1) begin {HI,LO} <= {mem_hi_i,mem_lo_i}; end
		else if(wb_whilo_i == 1'b1) begin {HI,LO} <= {wb_hi_i,wb_lo_i}; end
		else begin {HI,LO} <= {hi_i,lo_i}; end
	end	

	always @(*)
	begin stallreq = stallreq_for_madd_msub || stallreq_for_div; end

	always @(*)
	begin
		if(rst == 1'b1)
		begin
			hilo_temp_o <= {32'h00000000,32'h00000000};
			cnt_o <= 2'b00;
			stallreq_for_madd_msub <= 1'b0;
		end
		else
		begin
			case (in_code) 
				`EXE_MADD_OP, `EXE_MADDU_OP:
				begin
					if(cnt_i == 2'b00)
					begin
						hilo_temp_o <= mulres;
						cnt_o <= 2'b01;
						stallreq_for_madd_msub <= 1'b1;
						hilo_temp1 <= {32'h00000000,32'h00000000};
					end
					else if(cnt_i == 2'b01)
					begin
						hilo_temp_o <= {32'h00000000,32'h00000000};						
						cnt_o <= 2'b10;
						hilo_temp1 <= hilo_temp_i + {HI,LO};
						stallreq_for_madd_msub <= 1'b0;
					end
				end
				`EXE_MSUB_OP, `EXE_MSUBU_OP:
				begin
					if(cnt_i == 2'b00)
					begin
						hilo_temp_o <=  ~mulres + 1 ;
						cnt_o <= 2'b01;
						stallreq_for_madd_msub <= 1'b1;
					end
					else if(cnt_i == 2'b01)
					begin
						hilo_temp_o <= {32'h00000000,32'h00000000};						
						cnt_o <= 2'b10;
						hilo_temp1 <= hilo_temp_i + {HI,LO};
						stallreq_for_madd_msub <= 1'b0;
					end				
				end
				default:
				begin
					hilo_temp_o <= {32'h00000000,32'h00000000};
					cnt_o <= 2'b00;
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
			div_opdata1_o <= 32'h00000000;
			div_opdata2_o <= 32'h00000000;
			div_start_o <= 1'b0;
			signed_div_o <= 1'b0;
		end
		else
		begin
			stallreq_for_div <= 1'b0;
			div_opdata1_o <= 32'h00000000;
			div_opdata2_o <= 32'h00000000;
			div_start_o <= 1'b0;
			signed_div_o <= 1'b0;	
			case (in_code) 
				`EXE_DIV_OP:
				begin
					if(div_ready_i == 1'b0)
					begin
						div_opdata1_o <= in_reg1;
						div_opdata2_o <= in_reg2;
						div_start_o <= 1'b1;
						signed_div_o <= 1'b1;
						stallreq_for_div <= 1'b1;
					end
					else if(div_ready_i == 1'b1)
					begin
						div_opdata1_o <= in_reg1;
						div_opdata2_o <= in_reg2;
						div_start_o <= 1'b0;
						signed_div_o <= 1'b1;
						stallreq_for_div <= 1'b0;
					end
					else
					begin						
						div_opdata1_o <= 32'h00000000;
						div_opdata2_o <= 32'h00000000;
						div_start_o <= 1'b0;
						signed_div_o <= 1'b0;
						stallreq_for_div <= 1'b0;
					end					
				end
				`EXE_DIVU_OP:
				begin
					if(div_ready_i == 1'b0)
					begin
						div_opdata1_o <= in_reg1;
						div_opdata2_o <= in_reg2;
						div_start_o <= 1'b1;
						signed_div_o <= 1'b0;
						stallreq_for_div <= 1'b1;
					end
					else if(div_ready_i == 1'b1)
					begin
						div_opdata1_o <= in_reg1;
						div_opdata2_o <= in_reg2;
						div_start_o <= 1'b0;
						signed_div_o <= 1'b0;
						stallreq_for_div <= 1'b0;
					end
					else
					begin						
						div_opdata1_o <= 32'h00000000;
						div_opdata2_o <= 32'h00000000;
						div_start_o <= 1'b0;
						signed_div_o <= 1'b0;
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
	 wd_o <= in_data;
	 	 	 	
	 if(((in_code == `EXE_ADD_OP) || (in_code == `EXE_ADDI_OP) || (in_code == `EXE_SUB_OP)) && (ov_sum == 1'b1))
	 begin wreg_o <= 1'b0; end
	 else begin wreg_o <= in_reg; end
	 
	 case(in_sel) 
	 	`EXE_RES_LOGIC: begin wdata_o <= logicout; end
	 	`EXE_RES_SHIFT: begin wdata_o <= shiftres; end	 	
	 	`EXE_RES_MOVE: begin wdata_o <= moveres; end	 	
	 	`EXE_RES_ARITHMETIC: begin wdata_o <= arithmeticres; end
	 	`EXE_RES_MUL: begin wdata_o <= mulres[31:0]; end	 	
	 	`EXE_RES_JUMP_BRANCH: begin wdata_o <= link_address_i; end	 	
	 	default: begin wdata_o <= 32'h00000000; end
	 endcase
 end	

	always @(*)
	begin
		if(rst == 1'b1)
		begin
			whilo_o <= 1'b0;
			hi_o <= 32'h00000000;
			lo_o <= 32'h00000000;		
		end
		else if((in_code == `EXE_MULT_OP) || (in_code == `EXE_MULTU_OP))
		begin
			whilo_o <= 1'b1;
			hi_o <= mulres[63:32'h00000000];
			lo_o <= mulres[31:0];			
		end
		else if((in_code == `EXE_MADD_OP) || (in_code == `EXE_MADDU_OP))
		begin
			whilo_o <= 1'b1;
			hi_o <= hilo_temp1[63:32'h00000000];
			lo_o <= hilo_temp1[31:0];
		end
		else if((in_code == `EXE_MSUB_OP) || (in_code == `EXE_MSUBU_OP))
		begin
			whilo_o <= 1'b1;
			hi_o <= hilo_temp1[63:32'h00000000];
			lo_o <= hilo_temp1[31:0];		
		end
		else if((in_code == `EXE_DIV_OP) || (in_code == `EXE_DIVU_OP))
		begin
			whilo_o <= 1'b1;
			hi_o <= div_result_i[63:32'h00000000];
			lo_o <= div_result_i[31:0];							
		end
		else if(in_code == `EXE_MTHI_OP)
		begin
			whilo_o <= 1'b1;
			hi_o <= in_reg1;
			lo_o <= LO;
		end
		else if(in_code == `EXE_MTLO_OP)
		begin
			whilo_o <= 1'b1;
			hi_o <= HI;
			lo_o <= in_reg1;
		end
		else
		begin
			whilo_o <= 1'b0;
			hi_o <= 32'h00000000;
			lo_o <= 32'h00000000;
		end				
	end			

endmodule