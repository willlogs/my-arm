`include "bitwisegates.v"
`include "rpadder32.v"
`include "logicfunctions.v"

module ALU(
  input [31:0] a,
  input [31:0] b,
  input invert_a,
  input invert_b,
  input is_logic,
  input [2:0] logic_func_idx,
  input cin,
	input isactive,
  output [31:0] result,
  output reg N,
  output reg Z,
  output C,
  output reg V
);
	wire[31:0] inverted_a, inverted_b, adderresult, lfresult;
	reg[31:0] adder_a, adder_b, lf_a, lf_b, result; // inputs for different modules
	
	reg [31:0] inverter = 32'hffffffff;
	W_XOR32 a_inverter(a, inverter, inverted_a);
	W_XOR32 b_inverter(b, inverter, inverted_b);

	rpadder32 adder(adder_a, adder_b, cin, adderresult, C);
	logicfunctions lf(lf_a, lf_b, logic_func_idx, lfresult);
	
	always @(*) begin
		if(isactive) begin
			#15 if(invert_a) begin
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
			
			#15 if(is_logic) result = lfresult;
			else result = adderresult;	
			#5 if(result == 0) Z = 1;
			else Z = 0;

			if(result < 0) N = 1;
			else N = 0;

			if(!is_logic || (a > 0 && b > 0 && result < 0) || (a < 0 && b < 0 && result > 0)) V = 1;
			else V = 0;
		end
	end
endmodule
