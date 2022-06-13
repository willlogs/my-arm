module W_AND32(input [31:0] a, input [31:0] b, output [31:0] o);
	genvar i;

	generate
		for(i = 0; i < 32; i = i + 1) begin
			W_AND w_and(o[i], a[i], b[i]);
		end
	endgenerate
endmodule

module W_OR32(input[31:0] a, input [31:0] b, output [31:0] o);
	genvar i;

	generate
		for(i = 0; i < 32; i = i + 1) begin
			W_OR w_or(o[i], a[i], b[i]);
		end
	endgenerate
endmodule
