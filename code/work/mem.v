`include "defines.v"

module mem(rst, wd_i, wreg_i, wdata_i, hi_i, lo_i, whilo_i, aluop_i, mem_addr_i, reg2_i, mem_data_i, LLbit_i, wb_LLbit_we_i, wb_LLbit_value_i, LLbit_we_o, LLbit_value_o, wd_o, wreg_o, wdata_o, hi_o, lo_o, whilo_o, mem_addr_o, mem_we_o, mem_sel_o, mem_data_o, mem_ce_o);
input wire rst, wreg_i, whilo_i, LLbit_i, wb_LLbit_we_i, wb_LLbit_value_i;
input wire[4:0] wd_i;
input wire[31:0] wdata_i, hi_i, lo_i, mem_addr_i, reg2_i, mem_data_i;
input wire[7:0] aluop_i;
output reg[4:0] wd_o;
output reg wreg_o, whilo_o, LLbit_we_o, LLbit_value_o, mem_ce_o;
output reg[31:0] wdata_o, hi_o, lo_o, mem_addr_o, mem_data_o;
output wire mem_we_o;
output reg[3:0] mem_sel_o;
reg LLbit;
wire[31:0] zero32;
reg mem_we;

	assign mem_we_o = mem_we ;
	assign zero32 = 32'h00000000;

	always @(*)
	begin
		if(rst == 1'b1) begin LLbit <= 1'b0; end
		else
		begin
			if(wb_LLbit_we_i == 1'b1) begin LLbit <= wb_LLbit_value_i; end
			else begin LLbit <= LLbit_i; end
		end
	end
	
	always @(*)
	begin
		if(rst == 1'b1)
		begin
			wd_o <= 5'b00000; wreg_o <= 1'b0;
			wdata_o <= 32'h00000000;
			hi_o <= 32'h00000000; lo_o <= 32'h00000000;
			whilo_o <= 1'b0;		
			mem_addr_o <= 32'h00000000; mem_we <= 1'b0;
			mem_sel_o <= 4'b0000; mem_data_o <= 32'h00000000;
			mem_ce_o <= 1'b0;		
			LLbit_we_o <= 1'b0; LLbit_value_o <= 1'b0;		      
		end
		else
		begin
			wd_o <= wd_i; wreg_o <= wreg_i;
			wdata_o <= wdata_i;
			hi_o <= hi_i; lo_o <= lo_i;
			whilo_o <= whilo_i;
			mem_addr_o <= 32'h00000000; mem_sel_o <= 4'b1111;
			mem_ce_o <= 1'b1;
			LLbit_we_o <= 1'b0; LLbit_value_o <= 1'b0;
			mem_we <= 1'b0;
			
			case (aluop_i)
				`EXE_LB_OP:
				begin
					mem_addr_o <= mem_addr_i;
					case (mem_addr_i[1:0])
						2'b00: begin wdata_o <= {{24{mem_data_i[31]}},mem_data_i[31:24]}; mem_sel_o <= 4'b1000; end
						2'b01: begin wdata_o <= {{24{mem_data_i[23]}},mem_data_i[23:16]}; mem_sel_o <= 4'b0100; end
						2'b10: begin wdata_o <= {{24{mem_data_i[15]}},mem_data_i[15:8]}; mem_sel_o <= 4'b0010; end
						2'b11: begin wdata_o <= {{24{mem_data_i[7]}},mem_data_i[7:0]}; mem_sel_o <= 4'b0001; end
						default: begin wdata_o <= 32'h00000000; end
					endcase
				end
				`EXE_LBU_OP:
				begin
					mem_addr_o <= mem_addr_i;
					case (mem_addr_i[1:0])
						2'b00: begin wdata_o <= {{24{1'b0}},mem_data_i[31:24]}; mem_sel_o <= 4'b1000; end
						2'b01: begin wdata_o <= {{24{1'b0}},mem_data_i[23:16]}; mem_sel_o <= 4'b0100; end
						2'b10: begin wdata_o <= {{24{1'b0}},mem_data_i[15:8]}; mem_sel_o <= 4'b0010; end
						2'b11: begin wdata_o <= {{24{1'b0}},mem_data_i[7:0]}; mem_sel_o <= 4'b0001; end
						default: begin wdata_o <= 32'h00000000; end
					endcase				
				end
				`EXE_LH_OP:
				begin
					mem_addr_o <= mem_addr_i;
					case (mem_addr_i[1:0])
						2'b00: begin wdata_o <= {{16{mem_data_i[31]}},mem_data_i[31:16]}; mem_sel_o <= 4'b1100; end
						2'b10: begin wdata_o <= {{16{mem_data_i[15]}},mem_data_i[15:0]}; mem_sel_o <= 4'b0011; end
						default: begin wdata_o <= 32'h00000000; end
					endcase
				end
				`EXE_LHU_OP:
				begin
					mem_addr_o <= mem_addr_i;
					case (mem_addr_i[1:0])
						2'b00: begin wdata_o <= {{16{1'b0}},mem_data_i[31:16]}; mem_sel_o <= 4'b1100; end
						2'b10: begin wdata_o <= {{16{1'b0}},mem_data_i[15:0]}; mem_sel_o <= 4'b0011; end
						default: begin wdata_o <= 32'h00000000; end
					endcase				
				end
				`EXE_LW_OP:
				begin
					mem_addr_o <= mem_addr_i;
					wdata_o <= mem_data_i;
					mem_sel_o <= 4'b1111;
				end
				`EXE_LWL_OP:
				begin
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_sel_o <= 4'b1111;
					case (mem_addr_i[1:0])
						2'b00: begin wdata_o <= mem_data_i[31:0]; end
						2'b01: begin wdata_o <= {mem_data_i[23:0],reg2_i[7:0]}; end
						2'b10: begin wdata_o <= {mem_data_i[15:0],reg2_i[15:0]}; end
						2'b11: begin wdata_o <= {mem_data_i[7:0],reg2_i[23:0]}; end
						default: begin wdata_o <= 32'h00000000; end
					endcase
				end
				`EXE_LWR_OP:
				begin
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_sel_o <= 4'b1111;
					case (mem_addr_i[1:0])
						2'b00: begin wdata_o <= {reg2_i[31:8],mem_data_i[31:24]}; end
						2'b01: begin wdata_o <= {reg2_i[31:16],mem_data_i[31:16]}; end
						2'b10: begin wdata_o <= {reg2_i[31:24],mem_data_i[31:8]}; end
						2'b11: begin wdata_o <= mem_data_i; end
						default: begin wdata_o <= 32'h00000000; end
					endcase					
				end
				`EXE_LL_OP:
				begin
					mem_addr_o <= mem_addr_i;
					wdata_o <= mem_data_i;	
					LLbit_we_o <= 1'b1;
					LLbit_value_o <= 1'b1;
					mem_sel_o <= 4'b1111;					
				end
				`EXE_SB_OP:
				begin
					mem_addr_o <= mem_addr_i;
					mem_we <= 1'b1;
					mem_data_o <= {reg2_i[7:0],reg2_i[7:0],reg2_i[7:0],reg2_i[7:0]};
					case (mem_addr_i[1:0])
						2'b00: begin mem_sel_o <= 4'b1000; end
						2'b01: begin mem_sel_o <= 4'b0100; end
						2'b10: begin mem_sel_o <= 4'b0010; end
						2'b11: begin mem_sel_o <= 4'b0001; end
						default: begin mem_sel_o <= 4'b0000; end
					endcase
				end
				`EXE_SH_OP:
				begin
					mem_addr_o <= mem_addr_i;
					mem_we <= 1'b1;
					mem_data_o <= {reg2_i[15:0],reg2_i[15:0]};
					case (mem_addr_i[1:0])
						2'b00: begin mem_sel_o <= 4'b1100; end
						2'b10: begin mem_sel_o <= 4'b0011; end
						default: begin mem_sel_o <= 4'b0000; end
					endcase						
				end
				`EXE_SW_OP:
				begin
					mem_addr_o <= mem_addr_i;
					mem_we <= 1'b1;
					mem_data_o <= reg2_i;
					mem_sel_o <= 4'b1111;
				end
				`EXE_SWL_OP:
				begin
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= 1'b1;
					case (mem_addr_i[1:0])
						2'b00: begin mem_sel_o <= 4'b1111; mem_data_o <= reg2_i; end
						2'b01: begin mem_sel_o <= 4'b0111; mem_data_o <= {zero32[7:0],reg2_i[31:8]}; end
						2'b10: begin mem_sel_o <= 4'b0011; mem_data_o <= {zero32[15:0],reg2_i[31:16]}; end
						2'b11: begin mem_sel_o <= 4'b0001; mem_data_o <= {zero32[23:0],reg2_i[31:24]}; end
						default: begin mem_sel_o <= 4'b0000; end
					endcase
				end
				`EXE_SWR_OP:
				begin
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= 1'b1;
					case (mem_addr_i[1:0])
						2'b00: begin mem_sel_o <= 4'b1000; mem_data_o <= {reg2_i[7:0],zero32[23:0]}; end
						2'b01: begin mem_sel_o <= 4'b1100; mem_data_o <= {reg2_i[15:0],zero32[15:0]}; end
						2'b10: begin mem_sel_o <= 4'b1110; mem_data_o <= {reg2_i[23:0],zero32[7:0]}; end
						2'b11: begin mem_sel_o <= 4'b1111; mem_data_o <= reg2_i[31:0]; end
						default: begin mem_sel_o <= 4'b0000; end
					endcase											
				end 
				`EXE_SC_OP:
				begin
					if(LLbit == 1'b1)
					begin
						LLbit_we_o <= 1'b1;
						LLbit_value_o <= 1'b0;
						mem_addr_o <= mem_addr_i;
						mem_we <= 1'b1;
						mem_data_o <= reg2_i;
						wdata_o <= 32'b1;
						mem_sel_o <= 4'b1111;					
					end
					else
					begin
						mem_we <= 1'b0;
						mem_ce_o <= 1'b0;
						wdata_o <= 32'b0;
					end
				end				
				default:
				begin
					mem_we <= 1'b0;
					mem_ce_o <= 1'b0;
				end
			endcase							
		end
	end

endmodule