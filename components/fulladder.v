`ifndef FULLADDER
`define FULLADDER
`include "gates.v"

module fulladder(input a, input b, input c, output result, output cout);
	wire xorout;
	wire and1out;
	wire and2out;
	
	W_XOR w_xor(xorout, a, b);
	W_XOR w_xor2(result, xorout, c);

	W_AND w_and1(and1out, a, b);
	W_AND w_and2(and2out, c, xorout);

	W_OR w_or(cout, and1out, and2out);
endmodule
`endif
