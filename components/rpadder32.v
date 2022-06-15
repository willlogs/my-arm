`ifndef RPADDER32
`define RPADDER32
`include "fulladder.v"

module rpadder32(input [31:0] a, input [31:0] b, input cin, output [31:0] result, output cout);
	wire[31:0] carries;

	fulladder fa0(a[0], b[0], cin, result[0], carries[1]);

	generate
		genvar i;
		for(i = 1; i < 31; i = i + 1) begin
			fulladder fa(a[i], b[i], carries[i], result[i], carries[i+1]);
		end
	endgenerate

	fulladder fa31(a[31], b[31], carries[31], result[31], cout);
endmodule
`endif
