`include "instruction.v"

module mem(rst, in_wd, in_wreg, in_wdata, in_reg_hi, in_reg_lo, in_hilo, in_code, mem_in_addr, in_reg2, mem_in_data, in_llbit, in_wb_we, in_wb_val, out_llbit, out_val, out_wd, out_wreg, out_wdata, out_reg_hi, out_reg_lo, out_hilo, out_mem_addr, out_mem_we, out_mem_sel, out_mm_data, out_mem_ce);
input wire rst, in_wreg, in_hilo, in_llbit, in_wb_we, in_wb_val;
input wire[4:0] in_wd;
input wire[31:0] in_wdata, in_reg_hi, in_reg_lo, mem_in_addr, in_reg2, mem_in_data;
input wire[7:0] in_code;
output reg[4:0] out_wd;
output reg out_wreg, out_hilo, out_llbit, out_val, out_mem_ce;
output reg[31:0] out_wdata, out_reg_hi, out_reg_lo, out_mem_addr, out_mm_data;
output wire out_mem_we;
output reg[3:0] out_mem_sel;
reg LLbit;
wire[31:0] zero32;
reg mem_we;

	assign out_mem_we = mem_we ;
	assign zero32 = 32'h00000000;

	always @(*)
	begin
		if(rst == 1'b1) begin LLbit <= 1'b0; end
		else
		begin
			if(in_wb_we == 1'b1) begin LLbit <= in_wb_val; end
			else begin LLbit <= in_llbit; end
		end
	end
	
	always @(*)
	begin
		if(rst == 1'b1)
		begin
			out_wd <= 5'b00000; out_wreg <= 1'b0;
			out_wdata <= 32'h00000000;
			out_reg_hi <= 32'h00000000; out_reg_lo <= 32'h00000000;
			out_hilo <= 1'b0;		
			out_mem_addr <= 32'h00000000; mem_we <= 1'b0;
			out_mem_sel <= 4'b0000; out_mm_data <= 32'h00000000;
			out_mem_ce <= 1'b0;		
			out_llbit <= 1'b0; out_val <= 1'b0;		      
		end
		else
		begin
			out_wd <= in_wd; out_wreg <= in_wreg;
			out_wdata <= in_wdata;
			out_reg_hi <= in_reg_hi; out_reg_lo <= in_reg_lo;
			out_hilo <= in_hilo;
			out_mem_addr <= 32'h00000000; out_mem_sel <= 4'b1111;
			out_mem_ce <= 1'b1;
			out_llbit <= 1'b0; out_val <= 1'b0;
			mem_we <= 1'b0;
			
			case (in_code)
				`EXE_LB_OP:
				begin
					out_mem_addr <= mem_in_addr;
					case (mem_in_addr[1:0])
						2'b00: begin out_wdata <= {{24{mem_in_data[31]}},mem_in_data[31:24]}; out_mem_sel <= 4'b1000; end
						2'b01: begin out_wdata <= {{24{mem_in_data[23]}},mem_in_data[23:16]}; out_mem_sel <= 4'b0100; end
						2'b10: begin out_wdata <= {{24{mem_in_data[15]}},mem_in_data[15:8]}; out_mem_sel <= 4'b0010; end
						2'b11: begin out_wdata <= {{24{mem_in_data[7]}},mem_in_data[7:0]}; out_mem_sel <= 4'b0001; end
						default: begin out_wdata <= 32'h00000000; end
					endcase
				end
				`EXE_LBU_OP:
				begin
					out_mem_addr <= mem_in_addr;
					case (mem_in_addr[1:0])
						2'b00: begin out_wdata <= {{24{1'b0}},mem_in_data[31:24]}; out_mem_sel <= 4'b1000; end
						2'b01: begin out_wdata <= {{24{1'b0}},mem_in_data[23:16]}; out_mem_sel <= 4'b0100; end
						2'b10: begin out_wdata <= {{24{1'b0}},mem_in_data[15:8]}; out_mem_sel <= 4'b0010; end
						2'b11: begin out_wdata <= {{24{1'b0}},mem_in_data[7:0]}; out_mem_sel <= 4'b0001; end
						default: begin out_wdata <= 32'h00000000; end
					endcase				
				end
				`EXE_LH_OP:
				begin
					out_mem_addr <= mem_in_addr;
					case (mem_in_addr[1:0])
						2'b00: begin out_wdata <= {{16{mem_in_data[31]}},mem_in_data[31:16]}; out_mem_sel <= 4'b1100; end
						2'b10: begin out_wdata <= {{16{mem_in_data[15]}},mem_in_data[15:0]}; out_mem_sel <= 4'b0011; end
						default: begin out_wdata <= 32'h00000000; end
					endcase
				end
				`EXE_LHU_OP:
				begin
					out_mem_addr <= mem_in_addr;
					case (mem_in_addr[1:0])
						2'b00: begin out_wdata <= {{16{1'b0}},mem_in_data[31:16]}; out_mem_sel <= 4'b1100; end
						2'b10: begin out_wdata <= {{16{1'b0}},mem_in_data[15:0]}; out_mem_sel <= 4'b0011; end
						default: begin out_wdata <= 32'h00000000; end
					endcase				
				end
				`EXE_LW_OP:
				begin
					out_mem_addr <= mem_in_addr;
					out_wdata <= mem_in_data;
					out_mem_sel <= 4'b1111;
				end
				`EXE_LWL_OP:
				begin
					out_mem_addr <= {mem_in_addr[31:2], 2'b00};
					out_mem_sel <= 4'b1111;
					case (mem_in_addr[1:0])
						2'b00: begin out_wdata <= mem_in_data[31:0]; end
						2'b01: begin out_wdata <= {mem_in_data[23:0],in_reg2[7:0]}; end
						2'b10: begin out_wdata <= {mem_in_data[15:0],in_reg2[15:0]}; end
						2'b11: begin out_wdata <= {mem_in_data[7:0],in_reg2[23:0]}; end
						default: begin out_wdata <= 32'h00000000; end
					endcase
				end
				`EXE_LWR_OP:
				begin
					out_mem_addr <= {mem_in_addr[31:2], 2'b00};
					out_mem_sel <= 4'b1111;
					case (mem_in_addr[1:0])
						2'b00: begin out_wdata <= {in_reg2[31:8],mem_in_data[31:24]}; end
						2'b01: begin out_wdata <= {in_reg2[31:16],mem_in_data[31:16]}; end
						2'b10: begin out_wdata <= {in_reg2[31:24],mem_in_data[31:8]}; end
						2'b11: begin out_wdata <= mem_in_data; end
						default: begin out_wdata <= 32'h00000000; end
					endcase					
				end
				`EXE_LL_OP:
				begin
					out_mem_addr <= mem_in_addr;
					out_wdata <= mem_in_data;	
					out_llbit <= 1'b1;
					out_val <= 1'b1;
					out_mem_sel <= 4'b1111;					
				end
				`EXE_SB_OP:
				begin
					out_mem_addr <= mem_in_addr;
					mem_we <= 1'b1;
					out_mm_data <= {in_reg2[7:0],in_reg2[7:0],in_reg2[7:0],in_reg2[7:0]};
					case (mem_in_addr[1:0])
						2'b00: begin out_mem_sel <= 4'b1000; end
						2'b01: begin out_mem_sel <= 4'b0100; end
						2'b10: begin out_mem_sel <= 4'b0010; end
						2'b11: begin out_mem_sel <= 4'b0001; end
						default: begin out_mem_sel <= 4'b0000; end
					endcase
				end
				`EXE_SH_OP:
				begin
					out_mem_addr <= mem_in_addr;
					mem_we <= 1'b1;
					out_mm_data <= {in_reg2[15:0],in_reg2[15:0]};
					case (mem_in_addr[1:0])
						2'b00: begin out_mem_sel <= 4'b1100; end
						2'b10: begin out_mem_sel <= 4'b0011; end
						default: begin out_mem_sel <= 4'b0000; end
					endcase						
				end
				`EXE_SW_OP:
				begin
					out_mem_addr <= mem_in_addr;
					mem_we <= 1'b1;
					out_mm_data <= in_reg2;
					out_mem_sel <= 4'b1111;
				end
				`EXE_SWL_OP:
				begin
					out_mem_addr <= {mem_in_addr[31:2], 2'b00};
					mem_we <= 1'b1;
					case (mem_in_addr[1:0])
						2'b00: begin out_mem_sel <= 4'b1111; out_mm_data <= in_reg2; end
						2'b01: begin out_mem_sel <= 4'b0111; out_mm_data <= {zero32[7:0],in_reg2[31:8]}; end
						2'b10: begin out_mem_sel <= 4'b0011; out_mm_data <= {zero32[15:0],in_reg2[31:16]}; end
						2'b11: begin out_mem_sel <= 4'b0001; out_mm_data <= {zero32[23:0],in_reg2[31:24]}; end
						default: begin out_mem_sel <= 4'b0000; end
					endcase
				end
				`EXE_SWR_OP:
				begin
					out_mem_addr <= {mem_in_addr[31:2], 2'b00};
					mem_we <= 1'b1;
					case (mem_in_addr[1:0])
						2'b00: begin out_mem_sel <= 4'b1000; out_mm_data <= {in_reg2[7:0],zero32[23:0]}; end
						2'b01: begin out_mem_sel <= 4'b1100; out_mm_data <= {in_reg2[15:0],zero32[15:0]}; end
						2'b10: begin out_mem_sel <= 4'b1110; out_mm_data <= {in_reg2[23:0],zero32[7:0]}; end
						2'b11: begin out_mem_sel <= 4'b1111; out_mm_data <= in_reg2[31:0]; end
						default: begin out_mem_sel <= 4'b0000; end
					endcase											
				end 
				`EXE_SC_OP:
				begin
					if(LLbit == 1'b1)
					begin
						out_llbit <= 1'b1;
						out_val <= 1'b0;
						out_mem_addr <= mem_in_addr;
						mem_we <= 1'b1;
						out_mm_data <= in_reg2;
						out_wdata <= 32'b1;
						out_mem_sel <= 4'b1111;					
					end
					else
					begin
						mem_we <= 1'b0;
						out_mem_ce <= 1'b0;
						out_wdata <= 32'b0;
					end
				end				
				default:
				begin
					mem_we <= 1'b0;
					out_mem_ce <= 1'b0;
				end
			endcase							
		end
	end

endmodule