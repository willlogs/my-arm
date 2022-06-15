`include "ALU.v"

module alutest;
	reg[31:0] a, b;
	reg ia, ib, il, lfidx, cin;
	wire[31:0] result;
	wire N, Z, C, V;

	ALU my_alu(a, b, ia, ib, il, lfidx, cin, result, N, Z, C, V);
	
	initial begin
	  	a = 32'hffffffff;
		b = 1;
		ia = 0;
		ib = 1;
		il = 0;
		cin = 1;
		#210 $display("a:%h, b:%h, result:%h, c:%b", a, b, result, C);
	end
endmodule;
