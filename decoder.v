`ifndef DECODER
`define DECODER
module decoder(
	input [31:0] instruction,
	input clk,
	output reg reg_w,
	pc_w,
	ale,
	abe,
	is_immediate,
	output reg [2:0] shifter_mode,
	output reg [4:0] shifter_count,
	output reg [3:0] Rn, Rd, Rm, Rs,
	output reg invert_a, invert_b, islogic, logicidx, alu_cin, immediate_shift
);
	// these only apply if it's a data processing instruction
	reg[3:0] cond;
	reg[1:0] indicator; // p130 wtf is actually this ?? when it's 00 means data processing
	reg operandmode;
	reg[3:0] opcode;
	reg S;
	reg[11:0] operand2;
	
	always @(*) begin
		if(clk) begin
			$display("decoding instruction %b", instruction);

			cond = instruction[31:28];
			indicator = instruction[27:26];
			operandmode = instruction[25];
			opcode = instruction[24:21];
			S = instruction[20];
			Rn = instruction[19:16];
			Rd = instruction[15:12];
			operand2 = instruction[11:0];

			case(opcode)
				4'b0000: $display("AND");
				4'b0001: $display("EOR");
				4'b0010: $display("SUB");
				4'b0011: $display("RSB");
				4'b0100: begin
					$display("ADD");
					invert_a = 0;
					invert_b = 0;
					islogic = 0;
					logicidx = 0;
					alu_cin = 0;
				end
				4'b0101: $display("ADC");
			endcase

			if(operandmode == 1) begin
				shifter_mode = 3'b100; // left shift circular
				shifter_count = operand2[11:8];
				reg_w = 0;	
				is_immediate = 1;
				immediate_shift = 1;
			end
			else begin
				shifter_mode = operand2[6:5];
				shifter_count = operand2[11:7];
				is_immediate = 0;
				Rm = operand2[3:0];
				reg_w = 0;

				if(operand2[4] == 0) begin
					immediate_shift = 1;
				end
				else begin
					immediate_shift = 0;
					Rs = operand2[11:8];
				end
			end	
		end
	end
endmodule
`endif