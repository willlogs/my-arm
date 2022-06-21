`ifndef ARM
`define ARM
`include "clockgenerator.v"
`include "registerbank.v"
`include "addressregister.v"
`include "barrelshifter.v"
`include "multiplier.v"
`include "rpadder32.v"
`include "decoder.v"
`include "ALU.v"

module whole;
	reg[31:0] reg_write, pc_write, alubus, busA, busB, data_read, data_write, instruction;
	reg[4:0] address1, address2;
	reg reg_w, pc_w, ale, abe, w;

	wire[31:0] read1, read2, pc_read, incrementerbus, ar;

	// clock
	wire clk1, clk2;
	clock clkmodule(clk1, clk2);

	reg t_clk1, t_clk2;

	// register bank
	registerbank rbmodule(
		reg_write,
		pc_write,
		address1,
		address2,
		reg_w, pc_w,
		t_clk1,
		t_clk2,
		read1,
		read2,
		pc_read
	);

	// address register + incrementer
	addressregister armodule(
		t_clk2, // ?
		ale,
		abe,
		alubus,
		incrementerbus,
		ar
	);

	// multiplier
	reg[31:0] mult_input_1;
	wire[31:0] mult_output;
	reg[7:0] mult_input_2;
	multiplier multipliermodule(mult_input_1, mult_input_2, mult_output);

	// barrelshifter
	wire[31:0] shifter_output;
	reg[2:0] shifter_mode;
	reg[4:0] shifter_count;
	barrelshifter shiftermodule(busB, shifter_mode, shifter_count, shifter_output);

	// decoder - do means decoder output
	wire do_reg_w, do_pc_w, do_ale, do_abe, is_immediate, do_immediate_shift;
	wire[2:0] do_shifter_mode;
	wire[4:0] do_shifter_count;
	wire[3:0] do_Rn, do_Rd, do_Rm, do_Rs;

	decoder decodermodule(
		instruction,
		t_clk1,
		do_reg_w,
		do_pc_w,
		do_ale,
		do_abe,
		is_immediate,
		do_shifter_mode,
		do_shifter_count,
		do_Rn,
		do_Rd,
		do_Rm,
		do_Rs,
		alu_invert_a,
		alu_invert_b,
		alu_is_logic,
		alu_logic_idx,
		alu_cin,
		do_immediate_shift
	);

	reg[31:0] instructions[31:0]; // 32 test instructions
	wire alu_invert_a, alu_invert_b, alu_is_logic, alu_logic_idx, alu_cin;
	wire[31:0] alu_result;
	wire alu_N, alu_Z, alu_C, alu_V;
	reg alu_active;

	ALU alumodule(
		busA,
		shifter_output,
		alu_invert_a,
		alu_invert_b,
		alu_is_logic,
		alu_logic_idx,
		alu_cin,
		alu_active,
		alu_result,
		alu_N,
		alu_Z,
		alu_C,
		alu_V
	);

	initial begin
		// make instruction (test)
		address1 = 0;
		reg_write = 32'hfffffff0;
		reg_w = 1;
		t_clk2 = 1;
		#10 t_clk2 = 0;

		address1 = 1;
		reg_write = 32'h0000000f;
		t_clk2 = 1;
		#10 t_clk2 = 0;

		// Data Processing operand2 addressing types
		// immediate addressing
		instructions[0][31:28] = 0; // condition
		instructions[0][27:26] = 0; // instruction group
		instructions[0][25] = 1; // #
		instructions[0][24:21] = 4'b0100; // opcode: add
		instructions[0][20] = 1; // S
		instructions[0][19:16] = 0; // first operand reg
		instructions[0][15:12] = 0; // destination reg
		instructions[0][11:8] = 0; // #rot
		instructions[0][7:0] = 8'h0f; // immediate

		// reg addressing with immediate shift
		instructions[1][31:28] = 0; // condition
		instructions[1][27:26] = 0; // instruction group
		instructions[1][25] = 0; // #
		instructions[1][24:21] = 4'b0100; // opcode: add
		instructions[1][20] = 1; // S
		instructions[1][19:16] = 0; // first operand reg
		instructions[1][15:12] = 0; // destination reg
		instructions[1][11:7] = 0; // immediate shift length
		instructions[1][6:5] = 0; // shift type
		instructions[1][4] = 0; // immediate shift
		instructions[1][3:0] = 1; // Rm

		// reg addressing with reg shift
		instructions[2][31:28] = 0; // condition
		instructions[2][27:26] = 0; // instruction group
		instructions[2][25] = 0; // #
		instructions[2][24:21] = 4'b0100; // opcode: add
		instructions[2][20] = 1; // S
		instructions[2][19:16] = 0; // first operand reg
		instructions[2][15:12] = 0; // destination reg
		instructions[2][11:8] = 2; // Rs
		instructions[2][7] = 0; // just for alignment
		instructions[2][6:5] = 0; // shift type
		instructions[2][4] = 1; // immediate shift
		instructions[2][3:0] = 1; // Rm

		// fetch
		instruction = instructions[2];
		// decode
		t_clk1 = 1;
		#10 t_clk1 = 0;

		// execute
		// immediate addressing
		if(is_immediate == 1) begin
			// read Rn
			address1 = do_Rn;
			reg_w = do_reg_w;
			t_clk1 = 1;
			#10 t_clk1 = 0;
			busA = read1;

			// calculate operand 2
			busB = instruction[7:0];
			shifter_count = do_shifter_count;
			shifter_mode = do_shifter_mode;
			#10 $display("immedate addressing %h", shifter_output);

			// alu hotspot
			alu_active = 1;
			#36 $display("alu inputs busA : %h busB: %h, output: %h", busA, shifter_output, alu_result);
			alu_active = 0;

			// write result
			// might need to come out of clauses
			address1 = do_Rd;
			reg_w = 1;
			reg_write = alu_result;
			t_clk2 = 1;
			#10 t_clk2 = 0;
		end
		else begin
			// read from memory
			address1 = do_Rn;
			address2 = do_Rm;
			reg_w = do_reg_w;
			t_clk1 = 1;
			#5 t_clk1 = 0;
			busA = read1;
			busB = read2;

			// shift
			if(do_immediate_shift) begin
				shifter_count = do_shifter_count;
			end
			else begin
				// bypass -- I don't want a double clock instruction
				shifter_count = 0;
			end
			shifter_mode = do_shifter_mode;
			#5 $display("shifter output %h", shifter_output);

			// alu hotspot
			alu_active = 1;
			#36 $display("alu inputs busA : %h busB: %h, output: %h", busA, shifter_output, alu_result);
			alu_active = 0;

			// write back to memory
			address1 = do_Rd;
			reg_w = 1;
			reg_write = alu_result;
			t_clk2 = 1;
			#10 t_clk2 = 0;
		end
		$finish();
	end
endmodule
`endif