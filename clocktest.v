`include "clockgenerator.v"

module clocktest;
	wire clk1, clk2;
	clock clk(clk1, clk2);	

	always @(*) begin
		$display("c1: %b -- c2: %b", clk1, clk2);
	end
endmodule
