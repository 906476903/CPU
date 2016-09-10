module register(clk, rst, fg_write, write_addr, write_data, sg1, raddr1, rdata1, sg2, raddr2, rdata2);
input wire clk, rst, fg_write, sg1, sg2;
input wire[4:0] write_addr, raddr1, raddr2;
input wire[31:0] write_data;
output reg[31:0] rdata1, rdata2;
reg[31:0] regs[0:31];

	always @(posedge clk)
	begin
		if((rst == 1'b0) && (fg_write == 1'b1) && (write_addr != 5'h0)) begin regs[write_addr] <= write_data; end
	end
	
	
	always @(*)
	begin
		if(rst == 1'b1) begin rdata1 <= 32'h00000000; end
		else if(raddr1 == 5'h0) begin rdata1 <= 32'h00000000; end
		else if((raddr1 == write_addr) && (fg_write == 1'b1) && (sg1 == 1'b1))
		begin rdata1 <= write_data; end
		else if(sg1 == 1'b1)
		begin rdata1 <= regs[raddr1]; end
		else begin rdata1 <= 32'h00000000; end
	end

	always @(*)
	begin
		if(rst == 1'b1) begin rdata2 <= 32'h00000000; end
		else if(raddr2 == 5'h0) 
		begin rdata2 <= 32'h00000000; end
		else if((raddr2 == write_addr) && (fg_write == 1'b1) && (sg2 == 1'b1))
		begin rdata2 <= write_data; end
		else if(sg2 == 1'b1) begin rdata2 <= regs[raddr2]; end
		else begin rdata2 <= 32'h00000000; end
	end

endmodule