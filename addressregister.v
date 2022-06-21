`ifndef ADDRESSREGISTER
`define ADDRESSREGISTER
module addressregister(input clk, ale, abe, input[31:0] alubus, output reg[31:0] incrementerbus, addressregister);
	always @(posedge clk) begin
		if(ale) begin
			addressregister = alubus;	
		end
		else if(abe) begin
			addressregister = addressregister + 4;
		end
	end
endmodule
`endif
