module cpu_mips32(clk, rst, in_instr, out_instr_addr, instr_ce, in_data, out_addr, out_data, fg_write, out_sel, out_ce);

input wire rst, clk;
input wire[31:0] in_instr, in_data;
output wire[31:0] out_instr_addr;
output wire instr_ce, fg_write;
output wire[31:0] out_addr, out_data;
output wire[3:0] out_sel, out_ce;
wire[31:0] pc;
wire[31:0] id_pc_i;
wire[31:0] id_inst_i;

wire[7:0] id_aluop_o;
wire[7:0] id_alusel_o;
wire[31:0] id_reg1_o;
wire[31:0] id_reg2_o;
wire id_wreg_o;
wire[4:0] id_wd_o;
wire id_is_in_delayslot_o;
wire[31:0] id_link_address_o;	
wire[31:0] id_inst_o;

wire[7:0] ex_aluop_i;
wire[7:0] ex_alusel_i;
wire[31:0] ex_reg1_i;
wire[31:0] ex_reg2_i;
wire ex_wreg_i;
wire[4:0] ex_wd_i;
wire ex_is_in_delayslot_i;	
wire[31:0] ex_link_address_i;	
wire[31:0] ex_inst_i;

wire ex_wreg_o;
wire[4:0] ex_wd_o;
wire[31:0] ex_wdata_o;
wire[31:0] ex_hi_o;
wire[31:0] ex_lo_o;
wire ex_whilo_o;
wire[7:0] ex_aluop_o;
wire[31:0] ex_mem_addr_o;
wire[31:0] ex_reg1_o;
wire[31:0] ex_reg2_o;	

wire mem_wreg_i;
wire[4:0] mem_wd_i;
wire[31:0] mem_wdata_i;
wire[31:0] mem_hi_i;
wire[31:0] mem_lo_i;
wire mem_whilo_i;		
wire[7:0] mem_aluop_i;
wire[31:0] mem_mem_addr_i;
wire[31:0] mem_reg1_i;
wire[31:0] mem_reg2_i;		

wire mem_wreg_o;
wire[4:0] mem_wd_o;
wire[31:0] mem_wdata_o;
wire[31:0] mem_hi_o;
wire[31:0] mem_lo_o;
wire mem_whilo_o;	
wire mem_LLbit_value_o;
wire mem_LLbit_we_o;		

wire wb_wreg_i;
wire[4:0] wb_wd_i;
wire[31:0] wb_wdata_i;
wire[31:0] wb_hi_i;
wire[31:0] wb_lo_i;
wire wb_whilo_i;	
wire wb_LLbit_value_i;
wire wb_LLbit_we_i;	

wire reg1_read;
wire reg2_read;
wire[31:0] reg1_data;
wire[31:0] reg2_data;
wire[4:0] reg1_addr;
wire[4:0] reg2_addr;

wire[31:0] 	hi;
wire[31:0]   lo;

wire[63:0] hilo_temp_o;
wire[1:0] cnt_o;

wire[63:0] hilo_temp_i;
wire[1:0] cnt_i;

wire[63:0] div_result;
wire div_ready;
wire[31:0] div_opdata1;
wire[31:0] div_opdata2;
wire div_start;
wire div_annul;
wire signed_div;

wire is_in_delayslot_i;
wire is_in_delayslot_o;
wire next_inst_in_delayslot_o;
wire id_branch_flag_o;
wire[31:0] branch_target_address;

wire[5:0] stall;
wire stallreq_from_id;	
wire stallreq_from_ex;

wire LLbit_o;

	pc_reg pc_reg0(clk, rst, stall, id_branch_flag_o, branch_target_address, pc, instr_ce);
	
	assign out_instr_addr = pc;

	if_id if_id0(clk, rst, stall, pc, in_instr, id_pc_i, id_inst_i);

	id id0(rst, id_pc_i, id_inst_i, ex_aluop_o, reg1_data, reg2_data, ex_wreg_o, ex_wdata_o, ex_wd_o, mem_wreg_o, mem_wdata_o, mem_wd_o, is_in_delayslot_i, reg1_read, reg2_read, reg1_addr, reg2_addr, id_aluop_o, id_alusel_o, id_reg1_o, id_reg2_o, id_wd_o, id_wreg_o, id_inst_o, next_inst_in_delayslot_o, id_branch_flag_o, branch_target_address, id_link_address_o, id_is_in_delayslot_o, stallreq_from_id);


	register register_(clk, rst, wb_wreg_i, wb_wd_i, wb_wdata_i, reg1_read, reg1_addr, reg1_data, reg2_read, reg2_addr, reg2_data);


	id_ex id_ex0(clk, rst, stall, id_aluop_o, id_alusel_o, id_reg1_o, id_reg2_o, id_wd_o, id_wreg_o, id_link_address_o, id_is_in_delayslot_o, next_inst_in_delayslot_o, id_inst_o, ex_aluop_i, ex_alusel_i, ex_reg1_i, ex_reg2_i, ex_wd_i, ex_wreg_i, ex_link_address_i, ex_is_in_delayslot_i, is_in_delayslot_i, ex_inst_i);
	

	ex ex0(rst, ex_aluop_i, ex_alusel_i, ex_reg1_i, ex_reg2_i, ex_wd_i, ex_wreg_i, hi, lo, ex_inst_i, wb_hi_i, wb_lo_i, wb_whilo_i, mem_hi_o, mem_lo_o, mem_whilo_o, hilo_temp_i, cnt_i, div_result, div_ready, ex_link_address_i, ex_is_in_delayslot_i, ex_wd_o, ex_wreg_o, ex_wdata_o, ex_hi_o, ex_lo_o, ex_whilo_o, hilo_temp_o, cnt_o, div_opdata1, div_opdata2, div_start, signed_div, ex_aluop_o, ex_mem_addr_o, ex_reg2_o, stallreq_from_ex);


	ex_mem ex_mem0(clk, rst, stall, ex_wd_o, ex_wreg_o, ex_wdata_o, ex_hi_o, ex_lo_o, ex_whilo_o, ex_aluop_o, ex_mem_addr_o, ex_reg2_o, hilo_temp_o, cnt_o, mem_wd_i, mem_wreg_i, mem_wdata_i, mem_hi_i, mem_lo_i, mem_whilo_i, mem_aluop_i, mem_mem_addr_i, mem_reg2_i, hilo_temp_i, cnt_i);

	mem mem0(rst, mem_wd_i, mem_wreg_i, mem_wdata_i, mem_hi_i, mem_lo_i, mem_whilo_i, mem_aluop_i, mem_mem_addr_i, mem_reg2_i, in_data, LLbit_o, wb_LLbit_we_i, wb_LLbit_value_i, mem_LLbit_we_o, mem_LLbit_value_o, mem_wd_o, mem_wreg_o, mem_wdata_o, mem_hi_o, mem_lo_o, mem_whilo_o, out_addr, fg_write, out_sel, out_data, out_ce);

	mem_wb mem_wb0(clk, rst, stall, mem_wd_o, mem_wreg_o, mem_wdata_o, mem_hi_o, mem_lo_o, mem_whilo_o, mem_LLbit_we_o, mem_LLbit_value_o, wb_wd_i, wb_wreg_i, wb_wdata_i, wb_hi_i, wb_lo_i, wb_whilo_i, wb_LLbit_we_i, wb_LLbit_value_i);

	hilo_reg hilo_reg0(clk, rst, wb_whilo_i, wb_hi_i, wb_lo_i, hi, lo);
	
	ctrl ctrl0(rst, stallreq_from_id, stallreq_from_ex, stall);

	div div0(clk, rst, signed_div, div_opdata1, div_opdata2, div_start, 1'b0, div_result, div_ready);

	LLbit_reg LLbit_reg0(clk, rst, 1'b0, wb_LLbit_value_i, wb_LLbit_we_i, LLbit_o);
	
endmodule