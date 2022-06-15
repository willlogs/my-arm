`include "bitwisegates.v"
`include "rpadder32.v"

module ALU(
  input [31:0] a,
  input [31:0] b,
  input invert_a,
  input invert_b,
  input is_logic,
  input logic_func_idx,
  input cin,
  output [31:0] result,
  output N,
  output reg Z,
  output C,
  output V
);
	wire[31:0] inverted_a, inverted_b, adderresult;
	reg[31:0] adder_a, adder_b, lf_a, lf_b, lfresult, result; // inputs for different modules
	
	reg [31:0] inverter = 32'hffffffff;
	W_XOR32 a_inverter(a, inverter, inverted_a);
	W_XOR32 b_inverter(b, inverter, inverted_b);

	rpadder32 adder(adder_a, adder_b, cin, adderresult, C);
	// place lf
	
	always @(*) begin
	  	#20 if(invert_a) begin
			adder_a = inverted_a;
			lf_a = inverted_a;
	  	end
		else begin
		  	adder_a = a;
		  	lf_a = a;
		end

		if(invert_b) begin
			adder_b = inverted_b;
			lf_b = inverted_b;
		end
		else begin
			adder_b = b;
			lf_b = b;
		end	
		
	  	#20 if(is_logic) result = lfresult;
		else result = adderresult;	

		#10 if(result == 0) Z = 1;
	  	else Z = 0;
	end
endmodule
