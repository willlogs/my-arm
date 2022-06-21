`ifndef MULTIPLIER
`define MULTIPLIER
module multiplier(input [31:0] m1, input[7:0] m2, output reg[31:0] o);
	always @(*) begin
		o = m1 * m2;
	end
endmodule
`endif
