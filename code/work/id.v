`include "defines.v"

module id(rst, pc_i, inst_i, ex_aluop_i, reg1_data_i, reg2_data_i, ex_wreg_i, ex_wdata_i, ex_wd_i, mem_wreg_i, mem_wdata_i, mem_wd_i, is_in_delayslot_i, reg1_read_o, reg2_read_o, reg1_addr_o, reg2_addr_o, aluop_o, alusel_o, reg1_o, reg2_o, wd_o, wreg_o, inst_o, next_inst_in_delayslot_o, branch_flag_o, branch_target_address_o, link_addr_o, is_in_delayslot_o, stallreq);

input wire rst, ex_wreg_i, mem_wreg_i, is_in_delayslot_i;
input wire[31:0] pc_i, inst_i, ex_wdata_i, mem_wdata_i, reg1_data_i, reg2_data_i;
input wire[7:0] ex_aluop_i;
input wire[4:0] ex_wd_i, mem_wd_i;

output reg reg1_read_o, reg2_read_o, wreg_o, next_inst_in_delayslot_o, branch_flag_o, is_in_delayslot_o;
output reg[4:0] reg1_addr_o, reg2_addr_o, wd_o;
output reg[7:0] aluop_o;
output reg[2:0] alusel_o;
output reg[31:0] reg1_o, reg2_o, branch_target_address_o, link_addr_o;
output wire[31:0] inst_o;
output wire stallreq;
	
wire[5:0] op = inst_i[31:26], op3 = inst_i[5:0];
wire[4:0] op2 = inst_i[10:6], op4 = inst_i[20:16];
reg[31:0]	imm;
wire[31:0] pc_plus_8, pc_plus_4, imm_sll2_signedext;
reg instvalid,  stallreq_for_reg1_loadrelate, stallreq_for_reg2_loadrelate;
wire pre_inst_is_load;

assign pc_plus_8 = pc_i + 8;
assign pc_plus_4 = pc_i +4;
assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00 };  
assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
assign pre_inst_is_load = ((ex_aluop_i == `EXE_LB_OP) || (ex_aluop_i == `EXE_LBU_OP)|| (ex_aluop_i == `EXE_LH_OP) || (ex_aluop_i == `EXE_LHU_OP)|| (ex_aluop_i == `EXE_LW_OP) || (ex_aluop_i == `EXE_LWR_OP)|| (ex_aluop_i == `EXE_LWL_OP)|| (ex_aluop_i == `EXE_LL_OP) || (ex_aluop_i == `EXE_SC_OP)) ? 1'b1 : 1'b0;

assign inst_o = inst_i;

	always @ (*)
	begin	
		if(rst == 1'b0)
		begin
			aluop_o <= `EXE_NOP_OP; alusel_o <= `EXE_RES_NOP;
			wd_o <= inst_i[15:11]; wreg_o <= 1'b0; instvalid <= 1'b1;
			reg1_read_o <= 1'b0; reg2_read_o <= 1'b0;
			reg1_addr_o <= inst_i[25:21]; reg2_addr_o <= inst_i[20:16];
			imm <= 32'h00000000; link_addr_o <= 32'h00000000;
			branch_target_address_o <= 32'h00000000; branch_flag_o <= 1'b0;
			next_inst_in_delayslot_o <= 1'b0;
			
			
		    if(op == `EXE_SPECIAL_INST)
			begin
		    	case (op2)
		    	5'b00000:
					begin
						if((op3 == `EXE_MTHI) || (op3 == `EXE_MTLO) || (op3 == `EXE_SYNC) || (op3 == `EXE_MULT) || (op3 == `EXE_MULTU) || (op3 == `EXE_DIV) || (op3 == `EXE_DIVU) || (op3 == `EXE_JR))
						begin
							wreg_o <= 1'b0;instvalid <= 1'b0;
							case (op3)
							`EXE_MTHI:
								begin
									aluop_o <= `EXE_MTHI_OP; reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
								end
							`EXE_MTLO:
								begin
									aluop_o <= `EXE_MTLO_OP; reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
								end
							`EXE_SYNC:
								begin
									aluop_o <= `EXE_NOP_OP; alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b0; reg2_read_o <= 1'b1;
								end		
							`EXE_MULT:
								begin
									aluop_o <= `EXE_MULT_OP; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
								end
							`EXE_MULTU:
								begin
									aluop_o <= `EXE_MULTU_OP; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
								end
							`EXE_DIV:
								begin
									aluop_o <= `EXE_DIV_OP; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
								end
							`EXE_DIVU:
								begin
									aluop_o <= `EXE_DIVU_OP; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
								end			
							`EXE_JR:
								begin
									aluop_o <= `EXE_JR_OP; alusel_o <= `EXE_RES_JUMP_BRANCH;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0; link_addr_o <= 32'h00000000;
									branch_target_address_o <= reg1_o;
									branch_flag_o <= 1'b1;
									next_inst_in_delayslot_o <= 1'b1;
								end
							default:	begin end
							endcase
						end
						
						else if((op3 == `EXE_MOVN) || (op3 == `EXE_MOVZ))
						begin
							instvalid <= 1'b0;
							case(op3)
							`EXE_MOVN:
								begin
									aluop_o <= `EXE_MOVN_OP;
									alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
										if(reg2_o != 32'h00000000) begin
											wreg_o <= 1'b1;
									end else begin
											wreg_o <= 1'b0;
									end
								end
							`EXE_MOVZ:
								begin
									aluop_o <= `EXE_MOVZ_OP;
									alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
										if(reg2_o == 32'h00000000) begin
											wreg_o <= 1'b1;
									end else begin
											wreg_o <= 1'b0;
									end		  							
								end
							default:	begin end
							endcase
						end
						
						else if((op3 == `EXE_OR) || (op3 == `EXE_AND) || (op3 == `EXE_XOR) || (op3 == `EXE_NOR) || (op3 == `EXE_SLLV) || (op3 == `EXE_SRLV) || (op3 == `EXE_SRAV) || (op3 == `EXE_MFHI) || (op3 == `EXE_MFLO) || (op3 == `EXE_SLT) || (op3 == `EXE_SLTU) || (op3 == `EXE_ADD) || (op3 == `EXE_ADDU) || (op3 == `EXE_SUB) || (op3 == `EXE_SUBU) || (op3 == `EXE_JALR))
						begin
							wreg_o <= 1'b1;instvalid <= 1'b0;
							case (op3)
							`EXE_OR:
								begin
									aluop_o <= `EXE_OR_OP; alusel_o <= `EXE_RES_LOGIC;  reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
								end  
							`EXE_AND:
								begin
									aluop_o <= `EXE_AND_OP; alusel_o <= `EXE_RES_LOGIC; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
								end  	
							`EXE_XOR:
								begin
									aluop_o <= `EXE_XOR_OP; alusel_o <= `EXE_RES_LOGIC; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
								end  				
							`EXE_NOR:
								begin
									aluop_o <= `EXE_NOR_OP; alusel_o <= `EXE_RES_LOGIC;	 reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
								end 
							`EXE_SLLV:
								begin
									aluop_o <= `EXE_SLL_OP; alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
								end 
							`EXE_SRLV:
								begin
									aluop_o <= `EXE_SRL_OP; alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
								end 					
							`EXE_SRAV:
								begin
									aluop_o <= `EXE_SRA_OP; alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
								end
							`EXE_MFHI:
								begin
									aluop_o <= `EXE_MFHI_OP; alusel_o <= `EXE_RES_MOVE;  reg1_read_o <= 1'b0; reg2_read_o <= 1'b0;
								end
							`EXE_MFLO:
								begin
									aluop_o <= `EXE_MFLO_OP; alusel_o <= `EXE_RES_MOVE; reg1_read_o <= 1'b0; reg2_read_o <= 1'b0;
								end
							`EXE_SLT:
								begin
									aluop_o <= `EXE_SLT_OP; alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
								end
							`EXE_SLTU:
								begin
									aluop_o <= `EXE_SLTU_OP; alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
								end			
							`EXE_ADD:
								begin
									aluop_o <= `EXE_ADD_OP; alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
								end
							`EXE_ADDU:
								begin
									aluop_o <= `EXE_ADDU_OP; alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
								end
							`EXE_SUB:
								begin
									aluop_o <= `EXE_SUB_OP; alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
								end
							`EXE_SUBU:
								begin
									aluop_o <= `EXE_SUBU_OP; alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
									
								end
							`EXE_JALR:
								begin
									aluop_o <= `EXE_JALR_OP; alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
									wd_o <= inst_i[15:11];
									link_addr_o <= pc_plus_8;
									branch_target_address_o <= reg1_o;
									branch_flag_o <= 1'b1;
									next_inst_in_delayslot_o <= 1'b1;
								end
							default:	begin end
							endcase
						end
					end
				default: begin end
				endcase
			end									  
		  	else if((op == `EXE_ORI) || (op == `EXE_ANDI) || (op == `EXE_XORI) || (op == `EXE_LUI) || (op == `EXE_SLTI) || (op == `EXE_SLTIU) || (op == `EXE_ADDI) || (op == `EXE_ADDIU) || (op == `EXE_SC) || (op == `EXE_JAL) || (op == `EXE_LB) || (op == `EXE_LBU) || (op == `EXE_LH) || (op == `EXE_LHU) || (op == `EXE_LW) || (op == `EXE_LL) || (op == `EXE_LWL) || (op == `EXE_LWR))
			begin
				wreg_o <= 1'b1;instvalid <= 1'b0;
				case (op)
				`EXE_ORI:
				begin
					aluop_o <= `EXE_OR_OP; alusel_o <= `EXE_RES_LOGIC; reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
					imm <= {16'h0, inst_i[15:0]}; wd_o <= inst_i[20:16];
				end
				`EXE_ANDI:
				begin
					aluop_o <= `EXE_AND_OP; alusel_o <= `EXE_RES_LOGIC;	reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
					imm <= {16'h0, inst_i[15:0]}; wd_o <= inst_i[20:16];
				end	 	
				`EXE_XORI:
				begin
					aluop_o <= `EXE_XOR_OP; alusel_o <= `EXE_RES_LOGIC; reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
					imm <= {16'h0, inst_i[15:0]}; wd_o <= inst_i[20:16];
				end	 		
				`EXE_LUI:
				begin
					aluop_o <= `EXE_OR_OP; alusel_o <= `EXE_RES_LOGIC; reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
					imm <= {inst_i[15:0], 16'h0}; wd_o <= inst_i[20:16];
				end			
				`EXE_SLTI:
				begin
					aluop_o <= `EXE_SLT_OP; alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]}; wd_o <= inst_i[20:16];
				end
				`EXE_SLTIU:
				begin
					aluop_o <= `EXE_SLTU_OP; alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]}; wd_o <= inst_i[20:16];
				end
				`EXE_ADDI:
				begin
					aluop_o <= `EXE_ADDI_OP; alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]}; wd_o  <= inst_i[20:16];
				end
				`EXE_ADDIU:
				begin
					aluop_o <= `EXE_ADDIU_OP; alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]}; wd_o  <= inst_i[20:16];
				end
				`EXE_SC:
				begin
					aluop_o <= `EXE_SC_OP; alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  	
					wd_o <= inst_i[20:16]; alusel_o <= `EXE_RES_LOAD_STORE; 
				end	
				`EXE_JAL:
				begin
					aluop_o <= `EXE_JAL_OP; alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
					wd_o <= 5'b11111; link_addr_o <= pc_plus_8 ;
					branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00}; branch_flag_o <= 1'b1; next_inst_in_delayslot_o <= 1'b1;
				end
				`EXE_LB:
				begin
					aluop_o <= `EXE_LB_OP; alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16];
				end
				`EXE_LBU:
				begin
					aluop_o <= `EXE_LBU_OP; alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16];
				end
				`EXE_LH:
				begin
					aluop_o <= `EXE_LH_OP; alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16];
				end
				`EXE_LHU:
				begin
					aluop_o <= `EXE_LHU_OP; alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16];
				end
				`EXE_LW:
				begin
					aluop_o <= `EXE_LW_OP; alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16];
				end
				`EXE_LL:
				begin
					aluop_o <= `EXE_LL_OP; alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16];
				end
				`EXE_LWL:
				begin
					aluop_o <= `EXE_LWL_OP; alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  	
					wd_o <= inst_i[20:16];
				end
				`EXE_LWR:
				begin
					aluop_o <= `EXE_LWR_OP; alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  	
					wd_o <= inst_i[20:16];
				end
				default: begin end
				endcase
			end
			else if((op == `EXE_PREF) || (op == `EXE_J) || (op == `EXE_BEQ) || (op == `EXE_BGTZ) || (op == `EXE_BLEZ) || (op == `EXE_BNE) || (op == `EXE_SB) || (op == `EXE_SH) || (op == `EXE_SW) || (op == `EXE_SWL) || (op == `EXE_SWR))
			begin
				wreg_o <= 1'b0;instvalid <= 1'b0;
				case(op)
				`EXE_PREF:
				begin
					aluop_o <= `EXE_NOP_OP; alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
				end						
				`EXE_J:
				begin
					aluop_o <= `EXE_J_OP; alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
					link_addr_o <= 32'h00000000;
					branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00}; branch_flag_o <= 1'b1;
					next_inst_in_delayslot_o <= 1'b1;
				end
				`EXE_BEQ:
				begin
					aluop_o <= `EXE_BEQ_OP; alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
					if(reg1_o == reg2_o)
					begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext; branch_flag_o <= 1'b1;
						next_inst_in_delayslot_o <= 1'b1;		  	
					end
				end
				`EXE_BGTZ:
				begin
					aluop_o <= `EXE_BGTZ_OP; alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
					if((reg1_o[31] == 1'b0) && (reg1_o != 32'h00000000))
					begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext; branch_flag_o <= 1'b1;
						next_inst_in_delayslot_o <= 1'b1;		  	
					end
				end
				`EXE_BLEZ:
				begin
					aluop_o <= `EXE_BLEZ_OP; alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
					if((reg1_o[31] == 1'b1) || (reg1_o == 32'h00000000))
					begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext; branch_flag_o <= 1'b1;
						next_inst_in_delayslot_o <= 1'b1;		  	
					end
				end
				`EXE_BNE:
				begin
					aluop_o <= `EXE_BLEZ_OP; alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
					if(reg1_o != reg2_o)
					begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext; branch_flag_o <= 1'b1;
						next_inst_in_delayslot_o <= 1'b1;		  	
					end
				end		
				`EXE_SB:
				begin
					aluop_o <= `EXE_SB_OP; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SH:
				begin
					aluop_o <= `EXE_SH_OP; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SW:
				begin
					aluop_o <= `EXE_SW_OP; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SWL:
				begin
					aluop_o <= `EXE_SWL_OP; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SWR:
				begin
					aluop_o <= `EXE_SWR_OP; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1; alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				default: begin end
				endcase
			end
			else if(op == `EXE_REGIMM_INST)
			begin
				instvalid <= 1'b0;
				case (op4)
				`EXE_BGEZ:
				begin
					wreg_o <= 1'b0;		aluop_o <= `EXE_BGEZ_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
					if(reg1_o[31] == 1'b0)
					begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext; branch_flag_o <= 1'b1;
						next_inst_in_delayslot_o <= 1'b1;		  	
					end
				end
				`EXE_BGEZAL:
				begin
					wreg_o <= 1'b1; aluop_o <= `EXE_BGEZAL_OP; alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
					link_addr_o <= pc_plus_8; 
					wd_o <= 5'b11111;
					if(reg1_o[31] == 1'b0)
					begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext; branch_flag_o <= 1'b1;
						next_inst_in_delayslot_o <= 1'b1;
					end
				end
				`EXE_BLTZ:
				begin
					wreg_o <= 1'b0; aluop_o <= `EXE_BGEZAL_OP; alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
					if(reg1_o[31] == 1'b1)
					begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext; branch_flag_o <= 1'b1;
						next_inst_in_delayslot_o <= 1'b1;		  	
					end
				end
				`EXE_BLTZAL:
				begin
					wreg_o <= 1'b1; aluop_o <= `EXE_BGEZAL_OP; alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1; reg2_read_o <= 1'b0; link_addr_o <= pc_plus_8; wd_o <= 5'b11111;
					if(reg1_o[31] == 1'b1)
					begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
						branch_flag_o <= 1'b1;
						next_inst_in_delayslot_o <= 1'b1;
					end
				end
				default: begin end
			endcase
			end							
			else if(op == `EXE_SPECIAL2_INST)
			begin
				instvalid <= 1'b0;
				case (op3)
				`EXE_CLZ:
				begin
					wreg_o <= 1'b1; aluop_o <= `EXE_CLZ_OP; alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
				end
				`EXE_CLO:
				begin
					wreg_o <= 1'b1; aluop_o <= `EXE_CLO_OP; alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
				end
				`EXE_MUL:
				begin
					wreg_o <= 1'b1; aluop_o <= `EXE_MUL_OP; alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
				end
				`EXE_MADD:
				begin
					wreg_o <= 1'b0; aluop_o <= `EXE_MADD_OP; alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
				end
				`EXE_MADDU:
				begin
					wreg_o <= 1'b0; aluop_o <= `EXE_MADDU_OP; alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
				end
				`EXE_MSUB:
				begin
					wreg_o <= 1'b0; aluop_o <= `EXE_MSUB_OP; alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
				end
				`EXE_MSUBU:
				begin
					wreg_o <= 1'b0; aluop_o <= `EXE_MSUBU_OP; alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
				end
				default:	begin end
				endcase
			end
		  
		  if(inst_i[31:21] == 11'b00000000000)
		  begin
		  	if(op3 == `EXE_SLL)
			begin
		  		wreg_o <= 1'b1; aluop_o <= `EXE_SLL_OP; alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0; reg2_read_o <= 1'b1;	  	
				imm[4:0] <= inst_i[10:6]; wd_o <= inst_i[15:11]; instvalid <= 1'b0;	
			end
			else if( op3 == `EXE_SRL )
			begin
		  		wreg_o <= 1'b1; aluop_o <= `EXE_SRL_OP;
		  		alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0; reg2_read_o <= 1'b1;	  	
				imm[4:0] <= inst_i[10:6]; wd_o <= inst_i[15:11]; instvalid <= 1'b0;	
			end
			else if( op3 == `EXE_SRA )
			begin
		  		wreg_o <= 1'b1; aluop_o <= `EXE_SRA_OP;
		  		alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0; reg2_read_o <= 1'b1;	  	
				imm[4:0] <= inst_i[10:6]; wd_o <= inst_i[15:11]; instvalid <= 1'b0;	
				end
			end		  
		  
		end
		else
		begin
			aluop_o <= `EXE_NOP_OP; alusel_o <= `EXE_RES_NOP;
			wd_o <= 5'b00000;
			wreg_o <= 1'b0; instvalid <= 1'b0;
			reg1_read_o <= 1'b0; reg2_read_o <= 1'b0;
			reg1_addr_o <= 5'b00000; reg2_addr_o <= 5'b00000;
			imm <= 32'h0; link_addr_o <= 32'h00000000;
			branch_target_address_o <= 32'h00000000; branch_flag_o <= 1'b0;
			next_inst_in_delayslot_o <= 1'b0;					
		end
	end
	
	always @ (*)
	begin
		stallreq_for_reg1_loadrelate <= 1'b0;	
		if(rst == 1'b1) begin reg1_o <= 32'h00000000; end
		else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o && reg1_read_o == 1'b1 ) begin
			stallreq_for_reg1_loadrelate <= 1'b1; end
		else if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg1_addr_o)) begin
			reg1_o <= ex_wdata_i; end
		else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg1_addr_o)) begin
			reg1_o <= mem_wdata_i; end
		else if(reg1_read_o == 1'b1) begin reg1_o <= reg1_data_i; end
		else if(reg1_read_o == 1'b0) begin reg1_o <= imm; end
		else begin reg1_o <= 32'h00000000; end
	end
	
	always @ (*)
	begin
		stallreq_for_reg2_loadrelate <= 1'b0;
		if(rst == 1'b1) begin reg2_o <= 32'h00000000; end
		else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o && reg2_read_o == 1'b1 ) begin
			stallreq_for_reg2_loadrelate <= 1'b1;			
		end
		else if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg2_addr_o)) begin
			reg2_o <= ex_wdata_i; 
		end
		else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg2_addr_o)) begin
			reg2_o <= mem_wdata_i;			
		end
		else if(reg2_read_o == 1'b1) begin reg2_o <= reg2_data_i; end
		else if(reg2_read_o == 1'b0) begin reg2_o <= imm; end
		else begin reg2_o <= 32'h00000000; end
	end

	
	always @ (*) begin
		if(rst == 1'b1) begin is_in_delayslot_o <= 1'b0; end
		else begin is_in_delayslot_o <= is_in_delayslot_i; end
	end

endmodule