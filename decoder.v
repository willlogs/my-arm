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
	S_on,
	alu_hot,
	mult_hot,
	output reg [1:0] special_input, // 0 all zero, 1 all one, second bit is on/off
	output reg [2:0] shifter_mode, logicidx,
	output reg [4:0] shifter_count,
	output reg [3:0] Rn, Rd, Rm, Rs,
	output reg invert_a, invert_b, islogic, alu_cin, immediate_shift
);
	// these only apply if it's a data processing instruction
	reg[3:0] cond;
	reg[1:0] indicator; // p130 wtf is actually this ?? when it's 00 means data processing
	reg operandmode;
	reg[3:0] opcode;
	reg[2:0] mul;
	reg S;
	reg[11:0] operand2;
	
	always @(*) begin
		if(clk) begin
			$display("decoding instruction %b", instruction);

			alu_hot = 1;
			special_input = 0;

			if(instruction[27:24] == 0 && instruction[7:4] == 4'b1001) begin
				// multiplication
				mul = instruction[23:21];	
				mult_hot = 1;
				alu_hot = 0;

				case(mul)
					3'b000: begin
						$display("MUL");
						Rm = instruction[3:0];
						Rs = instruction[11:8];
					end
					3'b001: begin
						$display("MLA");
					end
					3'b100: begin
						$display("UMULL");
					end
					3'b101: begin
						$display("UMLAL");
					end
					3'b110: begin
						$display("SMULL");
					end
					3'b111: begin
						$display("SMLAL");
					end
				endcase
			end
			else if(instruction[27:26] == 0) begin
				// data processing
				cond = instruction[31:28];
				indicator = instruction[27:26];
				operandmode = instruction[25];
				opcode = instruction[24:21];
				S = instruction[20];
				Rn = instruction[19:16];
				Rd = instruction[15:12];
				operand2 = instruction[11:0];

				case(opcode)
					4'b0000: begin
						$display("AND");
						invert_a = 0;
						invert_b = 0;
						islogic = 1;
						logicidx = 0; 
						alu_cin = 0;
						reg_w = 1;	
					end
					4'b0001: begin
						$display("EOR");
						invert_a = 0;
						invert_b = 0;
						islogic = 1;
						logicidx = 1;
						alu_cin = 0;
						reg_w = 1;	
					end
					4'b0010: begin
						$display("SUB");
						invert_a = 0;
						invert_b = 1;
						islogic = 0;
						logicidx = 0;
						alu_cin = 1;
						reg_w = 1;	
					end
					4'b0011: begin
						$display("RSB");
						invert_a = 1;
						invert_b = 0;
						islogic = 0;
						logicidx = 0;
						alu_cin = 1;
						reg_w = 1;	
					end
					4'b0100: begin
						$display("ADD");
						invert_a = 0;
						invert_b = 0;
						islogic = 0;
						logicidx = 0;
						alu_cin = 0;
						reg_w = 1;	
					end
					4'b0101: begin
						$display("ADC");
						invert_a = 0;
						invert_b = 0;
						islogic = 0;
						logicidx = 0;
						alu_cin = 1;
						reg_w = 1;	
					end
					4'b0110: begin
						// ?!
						$display("SBC");
						invert_a = 0;
						invert_b = 1;
						islogic = 0;
						logicidx = 0;
						alu_cin = 0;
						reg_w = 1;	
					end
					4'b0111: begin
						$display("RSC");
						invert_a = 1;
						invert_b = 0;
						islogic = 0;
						logicidx = 0;
						alu_cin = 0;
						reg_w = 1;	
					end
					4'b1000: begin
						$display("TST");
						invert_a = 0;
						invert_b = 0;
						islogic = 1;
						logicidx = 0;
						alu_cin = 0;
						reg_w = 0;
					end
					4'b1001: begin
						$display("TEQ");
						invert_a = 0;
						invert_b = 0;
						islogic = 1;
						logicidx = 2;
						alu_cin = 0;
						reg_w = 0;
					end
					4'b1010: begin
						$display("CMP");
						invert_a = 0;
						invert_b = 1;
						islogic = 0;
						logicidx = 0;
						alu_cin = 1;
						reg_w = 0;
					end
					4'b1011: begin
						$display("CMN");
						invert_a = 0;
						invert_b = 0;
						islogic = 0;
						logicidx = 0;
						alu_cin = 0;
						reg_w = 0;
					end
					4'b1100: begin
						$display("ORR");
						invert_a = 0;
						invert_b = 0;
						islogic = 0;
						logicidx = 1;
						alu_cin = 0;
						reg_w = 1;	
					end
					4'b1101: begin
						$display("MOV");	
						alu_hot = 0;
					end
					4'b1110: begin
						$display("BIC");
						invert_a = 0;
						invert_b = 1;
						islogic = 1;
						logicidx = 0;
						alu_cin = 0;
						reg_w = 1;
					end
					4'b1111: begin
						$display("MVN");
						invert_a = 0;
						invert_b = 1;
						islogic = 0;
						logicidx = 0;
						alu_cin = 0;
						reg_w = 1;
						special_input[1] = 1;
					end
				endcase
			end

			if(operandmode == 1) begin
				shifter_mode = 3'b100; // left shift circular
				shifter_count = operand2[11:8];
				is_immediate = 1;
				immediate_shift = 1;
			end
			else begin
				shifter_mode = operand2[6:5];
				shifter_count = operand2[11:7];
				is_immediate = 0;
				Rm = operand2[3:0];

				if(operand2[4] == 0) begin
					immediate_shift = 1;
				end
				else begin
					immediate_shift = 0;
					Rs = operand2[11:8];
				end
			end	

			S_on = S;
		end
	end
endmodule
`endif