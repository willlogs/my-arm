`ifndef PROCESSORMODES
`define PROCESSORMODES

`define mode_mult_mul				1
`define mode_mult_umull			2
`define mode_mult_smull			3
`define mode_skip_alu				15

`endif

// TODO: is this an actual pipeline? since we're using always blocks, tasks can
// run concurrently. The pipeline should make sure that the last task of module was
// completed before assigning it a new task
// so we should have mutex locks and inbetween-the-moduesl-registers

// TODO: remove redundant decoder outputs / replace with mode

// TODO: instruction should be stored in another reg because it'll change (pipeline)

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
	// =========
	// Variables
	// =========
	reg[31:0] reg_write,
		pc_write,
		alubus,
		busA,
		busB,
		data_read,
		data_write,
		instruction,
		cpsr_write,
		cpsr_mask;
	reg [31:0] one = 32'hffffffff;
	reg [31:0] zero = 0; 
	reg[4:0] address1, address2;
	reg reg_w, pc_w, ale, abe, w, cpsr_w, regbank_active;
	reg t_clk1, t_clk2;
	reg[31:0] mult_input_1, mult_input_2;
	reg[2:0] shifter_mode;
	reg[4:0] shifter_count;
	reg alu_active;
	reg[31:0] instructions[31:0]; // 32 test instructions

	wire clk1, clk2;
	wire[1:0] do_special_input;
	wire[31:0] read1, read2, pc_read, incrementerbus, ar;
	wire[63:0] mult_output;
	wire[31:0] shifter_output;
	wire do_reg_w, do_pc_w, do_ale, do_abe, is_immediate, do_immediate_shift, do_S, do_aluhot,
	do_mult_hot;
	wire[2:0] do_shifter_mode;
	wire[4:0] do_shifter_count;
	wire[3:0] do_Rn, do_Rd, do_Rm, do_Rs;
	wire alu_invert_a, alu_invert_b, alu_is_logic, alu_cin;
	wire[2:0] alu_logic_idx;
	wire[31:0] alu_result;
	wire alu_N, alu_Z, alu_C, alu_V;
	wire[3:0] do_mode;

	// =============
	// Modules Instantiation
	// =============
	// clock
	clock clkmodule(clk1, clk2);

	// register bank
	registerbank rbmodule(
		reg_write,
		pc_write,
		cpsr_write,
		cpsr_mask,
		address1,
		address2,
		regbank_active,
		reg_w,
		pc_w,
		cpsr_w,
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
	multiplier multipliermodule(mult_input_1, mult_input_2, mult_output);

	// barrelshifter
	barrelshifter shiftermodule(busB, shifter_mode, shifter_count, shifter_output);

	// decoder - do means decoder output
	decoder decodermodule(
		instruction,
		t_clk1,
		do_reg_w,
		do_pc_w,
		do_ale,
		do_abe,
		is_immediate,
		do_S,
		do_aluhot,
		do_mult_hot,
		do_mode,
		do_special_input,
		do_shifter_mode,
		alu_logic_idx,
		do_shifter_count,
		do_Rn,
		do_Rd,
		do_Rm,
		do_Rs,
		alu_invert_a,
		alu_invert_b,
		alu_is_logic,
		alu_cin,
		do_immediate_shift
	);

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
		regbank_active = 0;
		/*
		===========================
		===========================
		===========================
								TEST
		===========================
		===========================
		===========================
		*/
		regbank_active = 1;
		// fill in reg[0]
		address1 = 0;
		reg_write = 5;
		reg_w = 1;
		t_clk2 = 1;
		#10 t_clk2 = 0;

		// fill in reg[1]
		address1 = 1;
		reg_write = 3;
		reg_w = 1;
		t_clk2 = 1;
		#10 t_clk2 = 0;
		reg_w = 0;
		regbank_active = 0;

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
		instructions[2][24:21] = 4'b0000; // opcode: and
		instructions[2][20] = 1; // S
		instructions[2][19:16] = 0; // first operand reg
		instructions[2][15:12] = 0; // destination reg
		instructions[2][11:8] = 2; // Rs
		instructions[2][7] = 0; // just for alignment
		instructions[2][6:5] = 0; // shift type
		instructions[2][4] = 1; // immediate shift
		instructions[2][3:0] = 1; // Rm

		// multiply test
		instructions[3][31:28] = 0; // condition	
		instructions[3][27:24] = 0; // indicator
		instructions[3][23:21] = 3'b100; // mul (simple MUL)
		instructions[3][20] = 0; // S
		instructions[3][19:16] = 2; // Rd
		instructions[3][15:12] = 0; // Rn
		instructions[3][11:8] = 0; // Rs
		instructions[3][7:4] = 4'b1001; // mul signature
		instructions[3][3:0] = 1; // Rm
		// TODO: add multiplication

		$display("\n\nCLOCK1 UP\n\n");
		t_clk1 = 1;
		#100 $display("\n\nCLOCK1 DOWN\n\n");
		t_clk1 = 0;

		#10 $display("\n\nCLOCK2 UP\n\n");
		t_clk2 = 1;
		#100 $display("\n\nCLOCK2 DOWN\n\n");
		t_clk2 = 0;

		$finish();
	end

	reg do_availabe = 0;
	always @(posedge t_clk1) begin
		/*
		===========================
		===========================
		===========================
						FETCH/DECODE
						CONTROL PIPELINE
		===========================
		===========================
		===========================
		*/
		// decoder output signal off
		do_availabe = 0;

		// fetch
		$display("\n\n===> fetch");
		instruction = instructions[3]; // for testing purposes

		// decode
		$display("\n\n===> decode");

		// #10 decoder output on end
		#10 do_availabe = 1;
	end
	
	reg regbank_donereading = 0;
	always @(posedge do_availabe) begin
		/*
		===========================
		===========================
		===========================
							REG READ
							AND
							SHIFTING
		===========================
		===========================
		===========================
		*/
		regbank_donereading = 0;

		regbank_active = 1;
		if(is_immediate) begin
			$display("\n\n===> immediate addressing");
			address1 = do_Rn;

			#5 busA = read1;

			// calculate operand 2
			busB = instruction[7:0];
			shifter_count = do_shifter_count;
			shifter_mode = do_shifter_mode;
			#5 $display("immedate addressing %h", shifter_output);
		end
		else begin
			$display("\n\n===> non-immediate addressing");
			if(do_mult_hot) begin
				address1 = instruction[3:0];
			end
			else address1 = do_Rn;

			address2 = instruction[11:8];
			reg_w = 0;
			$display("reading from regs %h & %h", address1, address2);

			#5 busA = read1;
			busB = read2;

			if(!do_mult_hot) begin
				// shift
				if(do_immediate_shift) begin
					shifter_count = do_shifter_count;
				end
				else begin
					// bypass -- I don't want a double clock instruction
					// TODO: solution: put Rs and Rm in shifter then read Rn while waiting for shifter and do the rest
					shifter_count = 0;
				end
				shifter_mode = do_shifter_mode;
				#5 $display("shifter output %h", shifter_output);
			end
		end

		// special input mode
		if(do_special_input[1]) begin
			if(do_special_input[0] == 0) busA = one;
			else busA = zero;
		end
		regbank_active = 0;
		#5 regbank_donereading = 1;
	end

	reg alu_done = 0;
	always @(posedge regbank_donereading) begin
		/*
		===========================
		===========================
		===========================
						ALU STAGE
		===========================
		===========================
		===========================
		*/
		alu_done = 0;

		if(do_mult_hot) begin
			$display("\n\n===> multiplication");
			case(do_mode)
				`mode_mult_mul: begin
					mult_input_1 = busA;
					mult_input_2 = busB;
					#5 $display("mult output:%d x %d = %d", mult_input_1, mult_input_2, mult_output);
					reg_write = mult_output;
				end
				
				`mode_mult_umull, `mode_mult_smull: begin
					mult_input_1 = busA;
					mult_input_2 = busB;
					#5 $display("mult output:%d x %d = %d", mult_input_1, mult_input_2, mult_output);
					$display("%h", mult_output);
					reg_write = mult_output[63:32];
				end
			endcase
		end

		if(do_aluhot) begin
			$display("\n\n===> ALU opertation");
			// alu hot spot
			alu_active = 1;
			#36 $display("alu inputs busA : %h busB: %h, output: %h", busA, shifter_output, alu_result);
			alu_active = 0;
			reg_write = alu_result;
		end
		
		if(do_mode == `mode_skip_alu) begin
			reg_write = shifter_output;
		end

		#5 alu_done = 1;
	end

	reg mem_done = 0; 
	always @(posedge t_clk2) begin
		/*
		===========================
		===========================
		===========================
						MEM / WR
		===========================
		===========================
		===========================
		*/
		mem_done = 0;


		#5 mem_done = 1;
	end

	reg doubleregsave = 0;
	always @(posedge mem_done) begin
		/*
		===========================
		===========================
		===========================
						REG WRITE BACK
		===========================
		===========================
		===========================
		*/
		if(do_reg_w) begin
			$display("\n\n===> write back to register");
			case(do_mode)
				0: address1 = instruction[15:12]; 
				`mode_mult_mul: address1 = instruction[19:16];
				`mode_mult_smull, `mode_mult_umull: begin
					doubleregsave = 1;
					address1 = instruction[19:16];
				end
			endcase

			reg_w = 1;
			$display("writing %d to %h", reg_write, address1);
			#5 if(doubleregsave) begin
				reg_w = 0;
				address1 = instruction[15:12];
				reg_write = mult_output[31:0];
				reg_w = 1;
			end

			#5 reg_w = 0;
		end

		// Set conditions
		if(do_S) begin
			cpsr_write =  {alu_N, alu_Z, alu_C, alu_V, zero[27:0]};
			cpsr_mask = one;
			cpsr_w = 1;
		end
	end
endmodule
`endif