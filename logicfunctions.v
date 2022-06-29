`ifndef LOGICFUNCTIONS
`define LOGICFUNCTIONS
module logicfunctions(
	input [31:0] a, b,
	input [2:0] logicidx,
	input active,
	output reg[31:0] o
);
	always @(*) begin
		if(active) begin
			case(logicidx)
				3'b000: begin
					$display("and logic");
					o = a & b;
				end	
				3'b001: begin
					$display("or logic");
					o = a | b;
				end
				3'b010: begin
					$display("xor logic");
					o = a ^ b;
				end
				3'b011: begin
					$display("nand logic");
					o = ~(a & b);
				end
				3'b100: begin
					$display("nor logic");
					o = ~(a | b);
				end
			endcase
		end
	end
endmodule
`endif