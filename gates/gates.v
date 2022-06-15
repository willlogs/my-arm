`ifndef GATES
`define GATES
module W_AND(output o, input i1, input i2);
	assign o = i1 & i2;
endmodule

module W_OR(output o, input i1, input i2);
	assign o = i1 | i2;
endmodule

module W_XOR(output o, input i1, input i2);
	assign o = ~(i1 & i2) & (i1 | i2);
endmodule

module W_NOT(output o, input i);
	assign o = ~i;
endmodule
`endif
