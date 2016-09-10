`include "instruction.v"

module id(rst, in_pc, in_instr, ex_in_code, reg1_in_data, reg2_in_data, ex_in_wreg, ex_in_wdata, ex_in_wd, mem_in_wreg, mem_in_wdata, mem_in_wd, is_in_delayslot, reg1_out_read, reg2_out_read, reg1_out_addr, reg2_out_addr, out_code, out_sel, out_reg1, out_reg2, out_wd, out_wreg, out_instr, next_instr_in_delayslot, fg_b, b_addr, link_addr, is_in_delayslot_, sg_stall);

input wire rst, ex_in_wreg, mem_in_wreg, is_in_delayslot;
input wire[31:0] in_pc, in_instr, ex_in_wdata, mem_in_wdata, reg1_in_data, reg2_in_data;
input wire[7:0] ex_in_code;
input wire[4:0] ex_in_wd, mem_in_wd;

output reg reg1_out_read, reg2_out_read, out_wreg, next_instr_in_delayslot, fg_b, is_in_delayslot_;
output reg[4:0] reg1_out_addr, reg2_out_addr, out_wd;
output reg[7:0] out_code;
output reg[2:0] out_sel;
output reg[31:0] out_reg1, out_reg2, b_addr, link_addr;
output wire[31:0] out_instr;
output wire sg_stall;
	
wire[5:0] code = in_instr[31:26], code2 = in_instr[5:0];
wire[4:0] code3 = in_instr[10:6], code4 = in_instr[20:16];
reg[31:0] imm;
wire[31:0] pc_plus_8, pc_plus_4, imm_sll2_signedext;
reg instvalid,  stall1, stall2;
wire pre_inst_is_load;

assign pc_plus_8 = in_pc + 8;
assign pc_plus_4 = in_pc + 4;
assign imm_sll2_signedext = {{14{in_instr[15]}}, in_instr[15:0], 2'b00 };  
assign sg_stall = stall1 | stall2;
assign pre_inst_is_load = ((ex_in_code == `EXE_LB_OP) || (ex_in_code == `EXE_LBU_OP)|| (ex_in_code == `EXE_LH_OP) || (ex_in_code == `EXE_LHU_OP)|| (ex_in_code == `EXE_LW_OP) || (ex_in_code == `EXE_LWR_OP)|| (ex_in_code == `EXE_LWL_OP)|| (ex_in_code == `EXE_LL_OP) || (ex_in_code == `EXE_SC_OP)) ? 1'b1 : 1'b0;

assign out_instr = in_instr;

	always @ (*)
	begin	
		if(rst == 1'b0)
		begin
			out_code <= `EXE_NOP_OP; out_sel <= `EXE_RES_NOP;
			out_wd <= in_instr[15:11]; out_wreg <= 1'b0; instvalid <= 1'b1;
			reg1_out_read <= 1'b0; reg2_out_read <= 1'b0;
			reg1_out_addr <= in_instr[25:21]; reg2_out_addr <= in_instr[20:16];
			imm <= 32'h00000000; link_addr <= 32'h00000000;
			b_addr <= 32'h00000000; fg_b <= 1'b0;
			next_instr_in_delayslot <= 1'b0;
			
			
		    if(code == `EXE_SPECIAL_INST)
			begin
		    	case (code3)
		    	5'b00000:
					begin
						if((code2 == `EXE_MTHI) || (code2 == `EXE_MTLO) || (code2 == `EXE_SYNC) || (code2 == `EXE_MULT) || (code2 == `EXE_MULTU) || (code2 == `EXE_DIV) || (code2 == `EXE_DIVU) || (code2 == `EXE_JR))
						begin
							out_wreg <= 1'b0;instvalid <= 1'b0;
							case (code2)
							`EXE_MTHI:
								begin
									out_code <= `EXE_MTHI_OP; reg1_out_read <= 1'b1; reg2_out_read <= 1'b0;
								end
							`EXE_MTLO:
								begin
									out_code <= `EXE_MTLO_OP; reg1_out_read <= 1'b1; reg2_out_read <= 1'b0;
								end
							`EXE_SYNC:
								begin
									out_code <= `EXE_NOP_OP; out_sel <= `EXE_RES_NOP; reg1_out_read <= 1'b0; reg2_out_read <= 1'b1;
								end		
							`EXE_MULT:
								begin
									out_code <= `EXE_MULT_OP; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
								end
							`EXE_MULTU:
								begin
									out_code <= `EXE_MULTU_OP; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
								end
							`EXE_DIV:
								begin
									out_code <= `EXE_DIV_OP; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
								end
							`EXE_DIVU:
								begin
									out_code <= `EXE_DIVU_OP; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
								end			
							`EXE_JR:
								begin
									out_code <= `EXE_JR_OP; out_sel <= `EXE_RES_JUMP_BRANCH;   reg1_out_read <= 1'b1;	reg2_out_read <= 1'b0; link_addr <= 32'h00000000;
									b_addr <= out_reg1;
									fg_b <= 1'b1;
									next_instr_in_delayslot <= 1'b1;
								end
							default:	begin end
							endcase
						end
						
						else if((code2 == `EXE_MOVN) || (code2 == `EXE_MOVZ))
						begin
							instvalid <= 1'b0;
							case(code2)
							`EXE_MOVN:
								begin
									out_code <= `EXE_MOVN_OP;
									out_sel <= `EXE_RES_MOVE;   reg1_out_read <= 1'b1;	reg2_out_read <= 1'b1;
										if(out_reg2 != 32'h00000000) begin
											out_wreg <= 1'b1;
									end else begin
											out_wreg <= 1'b0;
									end
								end
							`EXE_MOVZ:
								begin
									out_code <= `EXE_MOVZ_OP;
									out_sel <= `EXE_RES_MOVE;   reg1_out_read <= 1'b1;	reg2_out_read <= 1'b1;
										if(out_reg2 == 32'h00000000) begin
											out_wreg <= 1'b1;
									end else begin
											out_wreg <= 1'b0;
									end		  							
								end
							default:	begin end
							endcase
						end
						
						else if((code2 == `EXE_OR) || (code2 == `EXE_AND) || (code2 == `EXE_XOR) || (code2 == `EXE_NOR) || (code2 == `EXE_SLLV) || (code2 == `EXE_SRLV) || (code2 == `EXE_SRAV) || (code2 == `EXE_MFHI) || (code2 == `EXE_MFLO) || (code2 == `EXE_SLT) || (code2 == `EXE_SLTU) || (code2 == `EXE_ADD) || (code2 == `EXE_ADDU) || (code2 == `EXE_SUB) || (code2 == `EXE_SUBU) || (code2 == `EXE_JALR))
						begin
							out_wreg <= 1'b1;instvalid <= 1'b0;
							case (code2)
							`EXE_OR:
								begin
									out_code <= `EXE_OR_OP; out_sel <= `EXE_RES_LOGIC;  reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
								end  
							`EXE_AND:
								begin
									out_code <= `EXE_AND_OP; out_sel <= `EXE_RES_LOGIC; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
								end  	
							`EXE_XOR:
								begin
									out_code <= `EXE_XOR_OP; out_sel <= `EXE_RES_LOGIC; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
								end  				
							`EXE_NOR:
								begin
									out_code <= `EXE_NOR_OP; out_sel <= `EXE_RES_LOGIC;	 reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
								end 
							`EXE_SLLV:
								begin
									out_code <= `EXE_SLL_OP; out_sel <= `EXE_RES_SHIFT; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
								end 
							`EXE_SRLV:
								begin
									out_code <= `EXE_SRL_OP; out_sel <= `EXE_RES_SHIFT; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
								end 					
							`EXE_SRAV:
								begin
									out_code <= `EXE_SRA_OP; out_sel <= `EXE_RES_SHIFT; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
								end
							`EXE_MFHI:
								begin
									out_code <= `EXE_MFHI_OP; out_sel <= `EXE_RES_MOVE;  reg1_out_read <= 1'b0; reg2_out_read <= 1'b0;
								end
							`EXE_MFLO:
								begin
									out_code <= `EXE_MFLO_OP; out_sel <= `EXE_RES_MOVE; reg1_out_read <= 1'b0; reg2_out_read <= 1'b0;
								end
							`EXE_SLT:
								begin
									out_code <= `EXE_SLT_OP; out_sel <= `EXE_RES_ARITHMETIC; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
								end
							`EXE_SLTU:
								begin
									out_code <= `EXE_SLTU_OP; out_sel <= `EXE_RES_ARITHMETIC; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
								end			
							`EXE_ADD:
								begin
									out_code <= `EXE_ADD_OP; out_sel <= `EXE_RES_ARITHMETIC; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
								end
							`EXE_ADDU:
								begin
									out_code <= `EXE_ADDU_OP; out_sel <= `EXE_RES_ARITHMETIC; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
								end
							`EXE_SUB:
								begin
									out_code <= `EXE_SUB_OP; out_sel <= `EXE_RES_ARITHMETIC; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
								end
							`EXE_SUBU:
								begin
									out_code <= `EXE_SUBU_OP; out_sel <= `EXE_RES_ARITHMETIC; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
									
								end
							`EXE_JALR:
								begin
									out_code <= `EXE_JALR_OP; out_sel <= `EXE_RES_JUMP_BRANCH; reg1_out_read <= 1'b1; reg2_out_read <= 1'b0;
									out_wd <= in_instr[15:11];
									link_addr <= pc_plus_8;
									b_addr <= out_reg1;
									fg_b <= 1'b1;
									next_instr_in_delayslot <= 1'b1;
								end
							default:	begin end
							endcase
						end
					end
				default: begin end
				endcase
			end									  
		  	else if((code == `EXE_ORI) || (code == `EXE_ANDI) || (code == `EXE_XORI) || (code == `EXE_LUI) || (code == `EXE_SLTI) || (code == `EXE_SLTIU) || (code == `EXE_ADDI) || (code == `EXE_ADDIU) || (code == `EXE_SC) || (code == `EXE_JAL) || (code == `EXE_LB) || (code == `EXE_LBU) || (code == `EXE_LH) || (code == `EXE_LHU) || (code == `EXE_LW) || (code == `EXE_LL) || (code == `EXE_LWL) || (code == `EXE_LWR))
			begin
				out_wreg <= 1'b1;instvalid <= 1'b0;
				case (code)
				`EXE_ORI:
				begin
					out_code <= `EXE_OR_OP; out_sel <= `EXE_RES_LOGIC; reg1_out_read <= 1'b1; reg2_out_read <= 1'b0;
					imm <= {16'h0, in_instr[15:0]}; out_wd <= in_instr[20:16];
				end
				`EXE_ANDI:
				begin
					out_code <= `EXE_AND_OP; out_sel <= `EXE_RES_LOGIC;	reg1_out_read <= 1'b1; reg2_out_read <= 1'b0;
					imm <= {16'h0, in_instr[15:0]}; out_wd <= in_instr[20:16];
				end	 	
				`EXE_XORI:
				begin
					out_code <= `EXE_XOR_OP; out_sel <= `EXE_RES_LOGIC; reg1_out_read <= 1'b1; reg2_out_read <= 1'b0;
					imm <= {16'h0, in_instr[15:0]}; out_wd <= in_instr[20:16];
				end	 		
				`EXE_LUI:
				begin
					out_code <= `EXE_OR_OP; out_sel <= `EXE_RES_LOGIC; reg1_out_read <= 1'b1; reg2_out_read <= 1'b0;
					imm <= {in_instr[15:0], 16'h0}; out_wd <= in_instr[20:16];
				end			
				`EXE_SLTI:
				begin
					out_code <= `EXE_SLT_OP; out_sel <= `EXE_RES_ARITHMETIC; reg1_out_read <= 1'b1; reg2_out_read <= 1'b0;
					imm <= {{16{in_instr[15]}}, in_instr[15:0]}; out_wd <= in_instr[20:16];
				end
				`EXE_SLTIU:
				begin
					out_code <= `EXE_SLTU_OP; out_sel <= `EXE_RES_ARITHMETIC; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b0;
					imm <= {{16{in_instr[15]}}, in_instr[15:0]}; out_wd <= in_instr[20:16];
				end
				`EXE_ADDI:
				begin
					out_code <= `EXE_ADDI_OP; out_sel <= `EXE_RES_ARITHMETIC; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b0;
					imm <= {{16{in_instr[15]}}, in_instr[15:0]}; out_wd  <= in_instr[20:16];
				end
				`EXE_ADDIU:
				begin
					out_code <= `EXE_ADDIU_OP; out_sel <= `EXE_RES_ARITHMETIC; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b0;
					imm <= {{16{in_instr[15]}}, in_instr[15:0]}; out_wd  <= in_instr[20:16];
				end
				`EXE_SC:
				begin
					out_code <= `EXE_SC_OP; out_sel <= `EXE_RES_LOAD_STORE; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b1;	  	
					out_wd <= in_instr[20:16]; out_sel <= `EXE_RES_LOAD_STORE; 
				end	
				`EXE_JAL:
				begin
					out_code <= `EXE_JAL_OP; out_sel <= `EXE_RES_JUMP_BRANCH; reg1_out_read <= 1'b0;	reg2_out_read <= 1'b0;
					out_wd <= 5'b11111; link_addr <= pc_plus_8 ;
					b_addr <= {pc_plus_4[31:28], in_instr[25:0], 2'b00}; fg_b <= 1'b1; next_instr_in_delayslot <= 1'b1;
				end
				`EXE_LB:
				begin
					out_code <= `EXE_LB_OP; out_sel <= `EXE_RES_LOAD_STORE; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b0;	  	
					out_wd <= in_instr[20:16];
				end
				`EXE_LBU:
				begin
					out_code <= `EXE_LBU_OP; out_sel <= `EXE_RES_LOAD_STORE; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b0;	  	
					out_wd <= in_instr[20:16];
				end
				`EXE_LH:
				begin
					out_code <= `EXE_LH_OP; out_sel <= `EXE_RES_LOAD_STORE; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b0;	  	
					out_wd <= in_instr[20:16];
				end
				`EXE_LHU:
				begin
					out_code <= `EXE_LHU_OP; out_sel <= `EXE_RES_LOAD_STORE; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b0;	  	
					out_wd <= in_instr[20:16];
				end
				`EXE_LW:
				begin
					out_code <= `EXE_LW_OP; out_sel <= `EXE_RES_LOAD_STORE; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b0;	  	
					out_wd <= in_instr[20:16];
				end
				`EXE_LL:
				begin
					out_code <= `EXE_LL_OP; out_sel <= `EXE_RES_LOAD_STORE; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b0;	  	
					out_wd <= in_instr[20:16];
				end
				`EXE_LWL:
				begin
					out_code <= `EXE_LWL_OP; out_sel <= `EXE_RES_LOAD_STORE; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b1;	  	
					out_wd <= in_instr[20:16];
				end
				`EXE_LWR:
				begin
					out_code <= `EXE_LWR_OP; out_sel <= `EXE_RES_LOAD_STORE; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b1;	  	
					out_wd <= in_instr[20:16];
				end
				default: begin end
				endcase
			end
			else if((code == `EXE_PREF) || (code == `EXE_J) || (code == `EXE_BEQ) || (code == `EXE_BGTZ) || (code == `EXE_BLEZ) || (code == `EXE_BNE) || (code == `EXE_SB) || (code == `EXE_SH) || (code == `EXE_SW) || (code == `EXE_SWL) || (code == `EXE_SWR))
			begin
				out_wreg <= 1'b0;instvalid <= 1'b0;
				case(code)
				`EXE_PREF:
				begin
					out_code <= `EXE_NOP_OP; out_sel <= `EXE_RES_NOP; reg1_out_read <= 1'b0;	reg2_out_read <= 1'b0;
				end						
				`EXE_J:
				begin
					out_code <= `EXE_J_OP; out_sel <= `EXE_RES_JUMP_BRANCH; reg1_out_read <= 1'b0;	reg2_out_read <= 1'b0;
					link_addr <= 32'h00000000;
					b_addr <= {pc_plus_4[31:28], in_instr[25:0], 2'b00}; fg_b <= 1'b1;
					next_instr_in_delayslot <= 1'b1;
				end
				`EXE_BEQ:
				begin
					out_code <= `EXE_BEQ_OP; out_sel <= `EXE_RES_JUMP_BRANCH; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b1;
					if(out_reg1 == out_reg2)
					begin
						b_addr <= pc_plus_4 + imm_sll2_signedext; fg_b <= 1'b1;
						next_instr_in_delayslot <= 1'b1;		  	
					end
				end
				`EXE_BGTZ:
				begin
					out_code <= `EXE_BGTZ_OP; out_sel <= `EXE_RES_JUMP_BRANCH; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b0;
					if((out_reg1[31] == 1'b0) && (out_reg1 != 32'h00000000))
					begin
						b_addr <= pc_plus_4 + imm_sll2_signedext; fg_b <= 1'b1;
						next_instr_in_delayslot <= 1'b1;		  	
					end
				end
				`EXE_BLEZ:
				begin
					out_code <= `EXE_BLEZ_OP; out_sel <= `EXE_RES_JUMP_BRANCH; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b0;
					if((out_reg1[31] == 1'b1) || (out_reg1 == 32'h00000000))
					begin
						b_addr <= pc_plus_4 + imm_sll2_signedext; fg_b <= 1'b1;
						next_instr_in_delayslot <= 1'b1;		  	
					end
				end
				`EXE_BNE:
				begin
					out_code <= `EXE_BLEZ_OP; out_sel <= `EXE_RES_JUMP_BRANCH; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b1;
					if(out_reg1 != out_reg2)
					begin
						b_addr <= pc_plus_4 + imm_sll2_signedext; fg_b <= 1'b1;
						next_instr_in_delayslot <= 1'b1;		  	
					end
				end		
				`EXE_SB:
				begin
					out_code <= `EXE_SB_OP; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1; out_sel <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SH:
				begin
					out_code <= `EXE_SH_OP; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1; out_sel <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SW:
				begin
					out_code <= `EXE_SW_OP; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1; out_sel <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SWL:
				begin
					out_code <= `EXE_SWL_OP; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1; out_sel <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SWR:
				begin
					out_code <= `EXE_SWR_OP; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1; out_sel <= `EXE_RES_LOAD_STORE; 
				end
				default: begin end
				endcase
			end
			else if(code == `EXE_REGIMM_INST)
			begin
				instvalid <= 1'b0;
				case (code4)
				`EXE_BGEZ:
				begin
					out_wreg <= 1'b0;		out_code <= `EXE_BGEZ_OP;
					out_sel <= `EXE_RES_JUMP_BRANCH; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b0;
					if(out_reg1[31] == 1'b0)
					begin
						b_addr <= pc_plus_4 + imm_sll2_signedext; fg_b <= 1'b1;
						next_instr_in_delayslot <= 1'b1;		  	
					end
				end
				`EXE_BGEZAL:
				begin
					out_wreg <= 1'b1; out_code <= `EXE_BGEZAL_OP; out_sel <= `EXE_RES_JUMP_BRANCH; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b0;
					link_addr <= pc_plus_8; 
					out_wd <= 5'b11111;
					if(out_reg1[31] == 1'b0)
					begin
						b_addr <= pc_plus_4 + imm_sll2_signedext; fg_b <= 1'b1;
						next_instr_in_delayslot <= 1'b1;
					end
				end
				`EXE_BLTZ:
				begin
					out_wreg <= 1'b0; out_code <= `EXE_BGEZAL_OP; out_sel <= `EXE_RES_JUMP_BRANCH; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b0;
					if(out_reg1[31] == 1'b1)
					begin
						b_addr <= pc_plus_4 + imm_sll2_signedext; fg_b <= 1'b1;
						next_instr_in_delayslot <= 1'b1;		  	
					end
				end
				`EXE_BLTZAL:
				begin
					out_wreg <= 1'b1; out_code <= `EXE_BGEZAL_OP; out_sel <= `EXE_RES_JUMP_BRANCH; reg1_out_read <= 1'b1; reg2_out_read <= 1'b0; link_addr <= pc_plus_8; out_wd <= 5'b11111;
					if(out_reg1[31] == 1'b1)
					begin
						b_addr <= pc_plus_4 + imm_sll2_signedext;
						fg_b <= 1'b1;
						next_instr_in_delayslot <= 1'b1;
					end
				end
				default: begin end
			endcase
			end							
			else if(code == `EXE_SPECIAL2_INST)
			begin
				instvalid <= 1'b0;
				case (code2)
				`EXE_CLZ:
				begin
					out_wreg <= 1'b1; out_code <= `EXE_CLZ_OP; out_sel <= `EXE_RES_ARITHMETIC; reg1_out_read <= 1'b1; reg2_out_read <= 1'b0;
				end
				`EXE_CLO:
				begin
					out_wreg <= 1'b1; out_code <= `EXE_CLO_OP; out_sel <= `EXE_RES_ARITHMETIC; reg1_out_read <= 1'b1; reg2_out_read <= 1'b0;
				end
				`EXE_MUL:
				begin
					out_wreg <= 1'b1; out_code <= `EXE_MUL_OP; out_sel <= `EXE_RES_MUL; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
				end
				`EXE_MADD:
				begin
					out_wreg <= 1'b0; out_code <= `EXE_MADD_OP; out_sel <= `EXE_RES_MUL; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b1;
				end
				`EXE_MADDU:
				begin
					out_wreg <= 1'b0; out_code <= `EXE_MADDU_OP; out_sel <= `EXE_RES_MUL; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
				end
				`EXE_MSUB:
				begin
					out_wreg <= 1'b0; out_code <= `EXE_MSUB_OP; out_sel <= `EXE_RES_MUL; reg1_out_read <= 1'b1;	reg2_out_read <= 1'b1;
				end
				`EXE_MSUBU:
				begin
					out_wreg <= 1'b0; out_code <= `EXE_MSUBU_OP; out_sel <= `EXE_RES_MUL; reg1_out_read <= 1'b1; reg2_out_read <= 1'b1;
				end
				default:	begin end
				endcase
			end
		  
		  if(in_instr[31:21] == 11'b00000000000)
		  begin
		  	if(code2 == `EXE_SLL)
			begin
		  		out_wreg <= 1'b1; out_code <= `EXE_SLL_OP; out_sel <= `EXE_RES_SHIFT; reg1_out_read <= 1'b0; reg2_out_read <= 1'b1;	  	
				imm[4:0] <= in_instr[10:6]; out_wd <= in_instr[15:11]; instvalid <= 1'b0;	
			end
			else if( code2 == `EXE_SRL )
			begin
		  		out_wreg <= 1'b1; out_code <= `EXE_SRL_OP;
		  		out_sel <= `EXE_RES_SHIFT; reg1_out_read <= 1'b0; reg2_out_read <= 1'b1;	  	
				imm[4:0] <= in_instr[10:6]; out_wd <= in_instr[15:11]; instvalid <= 1'b0;	
			end
			else if( code2 == `EXE_SRA )
			begin
		  		out_wreg <= 1'b1; out_code <= `EXE_SRA_OP;
		  		out_sel <= `EXE_RES_SHIFT; reg1_out_read <= 1'b0; reg2_out_read <= 1'b1;	  	
				imm[4:0] <= in_instr[10:6]; out_wd <= in_instr[15:11]; instvalid <= 1'b0;	
				end
			end		  
		  
		end
		else
		begin
			out_code <= `EXE_NOP_OP; out_sel <= `EXE_RES_NOP;
			out_wd <= 5'b00000;
			out_wreg <= 1'b0; instvalid <= 1'b0;
			reg1_out_read <= 1'b0; reg2_out_read <= 1'b0;
			reg1_out_addr <= 5'b00000; reg2_out_addr <= 5'b00000;
			imm <= 32'h0; link_addr <= 32'h00000000;
			b_addr <= 32'h00000000; fg_b <= 1'b0;
			next_instr_in_delayslot <= 1'b0;					
		end
	end
	
	always @ (*)
	begin
		stall1 <= 1'b0;	
		if(rst == 1'b1) begin out_reg1 <= 32'h00000000; end
		else if(pre_inst_is_load == 1'b1 && ex_in_wd == reg1_out_addr && reg1_out_read == 1'b1 ) begin
			stall1 <= 1'b1; end
		else if((reg1_out_read == 1'b1) && (ex_in_wreg == 1'b1) && (ex_in_wd == reg1_out_addr)) begin
			out_reg1 <= ex_in_wdata; end
		else if((reg1_out_read == 1'b1) && (mem_in_wreg == 1'b1) && (mem_in_wd == reg1_out_addr)) begin
			out_reg1 <= mem_in_wdata; end
		else if(reg1_out_read == 1'b1) begin out_reg1 <= reg1_in_data; end
		else if(reg1_out_read == 1'b0) begin out_reg1 <= imm; end
		else begin out_reg1 <= 32'h00000000; end
	end
	
	always @ (*)
	begin
		stall2 <= 1'b0;
		if(rst == 1'b1) begin out_reg2 <= 32'h00000000; end
		else if(pre_inst_is_load == 1'b1 && ex_in_wd == reg2_out_addr && reg2_out_read == 1'b1 ) begin
			stall2 <= 1'b1;			
		end
		else if((reg2_out_read == 1'b1) && (ex_in_wreg == 1'b1) && (ex_in_wd == reg2_out_addr)) begin
			out_reg2 <= ex_in_wdata; 
		end
		else if((reg2_out_read == 1'b1) && (mem_in_wreg == 1'b1) && (mem_in_wd == reg2_out_addr)) begin
			out_reg2 <= mem_in_wdata;			
		end
		else if(reg2_out_read == 1'b1) begin out_reg2 <= reg2_in_data; end
		else if(reg2_out_read == 1'b0) begin out_reg2 <= imm; end
		else begin out_reg2 <= 32'h00000000; end
	end

	
	always @ (*) begin
		if(rst == 1'b1) begin is_in_delayslot_ <= 1'b0; end
		else begin is_in_delayslot_ <= is_in_delayslot; end
	end

endmodule