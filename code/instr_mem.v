`include "main_mem.v"

module instr_mem(ce, addr, inst);
input wire ce;
input wire[31:0] addr;
output reg[31:0] inst;
reg[31:0] inst_mem[0:`Size-1];

	initial $readmemh ( "data.data", inst_mem );

	always @(*)
	begin
		if(ce == 1'b0) begin inst <= 32'h00000000; end
		else begin inst <= inst_mem[addr[`Size_log2+1:2]]; end
	end

endmodule