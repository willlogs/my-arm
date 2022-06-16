`include "barrelshifter.v"
module shifttest;
	reg[31:0] i;
	reg[4:0] count;
	reg[2:0] mode;
	wire[31:0] o;

	barrelshifter bs(i, mode, count, o);

	initial begin
		i = 32'hfffffffe;
		count = 4;
		mode = 0;
		#10 $display("%h", o);
		mode = 1;
		#10 $display("%h", o);
		mode = 2;
		#10 $display("%h", o);
		mode = 3;
		#10 $display("%h", o);
		mode = 4;
		#10 $display("%h", o);
		mode = 5;
		#10 $display("%h", o);
	end
endmodule;
