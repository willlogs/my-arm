`ifndef ARM
`define ARM
`include "registerbank.v"
`include "clockgenerator.v"
module whole;
	reg[31:0] write, pc_write;
	reg[4:0] address1, address2;
	reg w, pc_w;

	wire[31:0] read1, read2, pc_read;

	wire clk1, clk2;
	clock clk(clk1, clk2);

	registerbank rb(write, pc_write, address1, address2, w, pc_w, clk1, read1, read2, pc_read);

	initial begin
		w = 1;
		address1 = 5'h01;
		write = 32'hffffffff;

		#100 w = 0;
		#40 $display("read1: %h", read1);
		$finish();
	end
endmodule
`endif
