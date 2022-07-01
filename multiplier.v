`ifndef MULTIPLIER
`define MULTIPLIER
module multiplier(input [31:0] m1, input[31:0] m2, output reg[63:0] o);
	always @(*) begin
		o = m1 * m2;
	end
endmodule
`endif
