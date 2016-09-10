`define Size 131070
`define Size_log2 17
module main_mem(clk, ce, wr_fg, addr, sel, in_data, out_data);
input wire clk, ce, wr_fg;
input wire[31:0] addr, in_data;
input wire[3:0] sel;
output reg[31:0] out_data;
wire addr_;
reg[7:0]  data_mem0[0:`Size], data_mem1[0:`Size], data_mem2[0:`Size], data_mem3[0:`Size];

	always @(posedge clk)
	begin
		if(wr_fg == 1'b1)
		begin
			if(sel[3] == 1'b1)
			begin
				data_mem3[addr[`Size_log2+1:2]] <= in_data[31:24];
			end
			if(sel[2] == 1'b1)
			begin
				data_mem2[addr[`Size_log2+1:2]] <= in_data[23:16];
			end
			if(sel[1] == 1'b1)
			begin
				data_mem1[addr[`Size_log2+1:2]] <= in_data[15:8];
			end
			if(sel[0] == 1'b1)
			begin
				data_mem0[addr[`Size_log2+1:2]] <= in_data[7:0];
			end			   	    
		end
	end
	
	always @(*)
	begin
		if(ce == 1'b0) begin out_data <= 32'h00000000; end
		else if(wr_fg == 1'b0)
		begin
		    out_data <= {data_mem3[addr[`Size_log2+1:2]], data_mem2[addr[`Size_log2+1:2]], data_mem1[addr[`Size_log2+1:2]], data_mem0[addr[`Size_log2+1:2]]};
		end else begin out_data <= 32'h00000000; end
	end		

endmodule