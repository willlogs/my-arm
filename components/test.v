`include "bitwisegates.v"
`include "gates.v"
`include "fulladder.v"
`include "rpadder32.v"

module test;
	reg[31:0] a = 32'hffffffff;
	reg[31:0] b = 0;
	reg cin = 1;
	wire[31:0] result;
	wire cout;

	rpadder32 rpa32(a, b, cin, result, cout);

	initial begin
		#100 $display("%d + %d = %d -- cin: %b cout:%b", a, b, result, cin, cout);	
	end
endmodule
