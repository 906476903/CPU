module div(clk, rst, div_sg, in_data1, in_data2, fg, wrp, out_data, fin);
input wire clk, rst, div_sg, fg, wrp;
input wire[31:0] in_data1, in_data2;
output reg[63:0] out_data;
output reg fin;
reg[1:0] auto_stage;
reg[5:0] k;
wire[32:0] tmp;
reg[64:0] dividend;
reg[31:0] divisor, ans0, ans1;


	assign tmp = {1'b0,dividend[63:32]} - {1'b0,divisor};

	always @(posedge clk)
	begin
		if(rst == 1'b1)
		begin
			fin <= 1'b0; auto_stage <= 2'b00;
			out_data <= {32'h00000000,32'h00000000};
		end
		else
		begin
		  case (auto_stage)
		  	2'b00:
			begin
		  		if(fg == 1'b1 && wrp == 1'b0)
				begin
		  			if(in_data2 == 32'h00000000) begin auto_stage <= 2'b01; end
					else
					begin
						k <= 6'b000000;
		  				auto_stage <= 2'b10;
		  				if(div_sg == 1'b1 && in_data1[31] == 1'b1 ) begin ans0 = ~in_data1 + 1; end
						else begin ans0 = in_data1; end
		  				if(div_sg == 1'b1 && in_data2[31] == 1'b1 ) begin ans1 = ~in_data2 + 1; end
						else begin ans1 = in_data2; end
		  				dividend <= {32'h00000000,32'h00000000};
						dividend[32:1] <= ans0; divisor <= ans1;
					end
				end
				else begin out_data <= {32'h00000000,32'h00000000}; fin <= 1'b0; end          	
		  	end
		  	2'b01: begin auto_stage <= 2'b11; dividend <= {32'h00000000,32'h00000000}; end
		  	2'b10:
			begin
		  		if(wrp == 1'b0)
				begin
		  			if(k != 6'b100000)
					begin
						k <= k + 1;
						if(tmp[32] == 1'b1) begin dividend <= {dividend[63:0] , 1'b0}; end
						else begin dividend <= {tmp[31:0] , dividend[31:0] , 1'b1}; end
					end
					else
					begin
						if((div_sg == 1'b1) && ((in_data1[31] ^ in_data2[31]) == 1'b1))
							begin dividend[31:0] <= (~dividend[31:0] + 1); end
						if((div_sg == 1'b1) && ((in_data1[31] ^ dividend[64]) == 1'b1))
							begin dividend[64:33] <= (~dividend[64:33] + 1); end
						auto_stage <= 2'b11;
						k <= 6'b000000;            	
					end
		  		end
				else begin auto_stage <= 2'b00; end	
		  	end
		  	2'b11:
			begin
				fin <= 1'b1; out_data <= {dividend[64:33], dividend[31:0]};
				if(fg == 1'b0)
				begin
					fin <= 1'b0; auto_stage <= 2'b00;
					out_data <= {32'h00000000,32'h00000000};       	
				end
		  	end
			default: begin end
			endcase
		end
	end

endmodule