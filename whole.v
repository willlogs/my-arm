`ifndef PROCESSORMODES
`define PROCESSORMODES

`define mode_mult_mul				1
`define mode_mult_mla				2
`define mode_mult_umull			3
`define mode_mult_smull			4
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
`include "memory.v"

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
		cpsr_mask,
		mem_address,
		mem_write,
		mem_mask;
	reg [31:0] one = 32'hffffffff;
	reg [31:0] zero = 0; 
	reg[4:0] address1, address2, address3;
	reg reg_w, pc_w, ale, abe, w, cpsr_w, regbank_active;
	reg t_clk1, t_clk2;
	reg[31:0] mult_input_1, mult_input_2;
	reg[2:0] shifter_mode;
	reg[4:0] shifter_count;
	reg alu_active, mem_w;
	reg clockgen_active = 1, pc_increment = 0;

	wire clk1, clk2;
	wire[1:0] do_special_input;
	wire[31:0] read1, read2, read3, pc_read, incrementerbus, ar, mem_read;
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
	clock clkmodule(clockgen_active, clk1, clk2);

	// register bank
	registerbank rbmodule(
		reg_write,
		pc_write,
		cpsr_write,
		cpsr_mask,
		address1,
		address2,
		address3,
		regbank_active,
		reg_w,
		pc_w,
		pc_increment,
		cpsr_w,
		t_clk1,
		t_clk2,
		read1,
		read2,
		read3,
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
		decoder_active,
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

	memory memorymodule(
		mem_address,
		mem_write,
		mem_mask,
		t_clk1,
		t_clk2,
		mem_w,
		mem_read
	);

	initial begin
		#1000 $display("setting up processor");
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

		address1 = 2;
		reg_write = 15;
		reg_w = 1;
		t_clk2 = 1;
		#10 t_clk2 = 0;
		reg_w = 0;
		regbank_active = 0;

		// Data Processing operand2 addressing types
		// immediate addressing
		instruction[31:28] = 0; // condition
		instruction[27:26] = 0; // instruction group
		instruction[25] = 1; // #
		instruction[24:21] = 4'b0100; // opcode: add
		instruction[20] = 1; // S
		instruction[19:16] = 0; // first operand reg
		instruction[15:12] = 0; // destination reg
		instruction[11:8] = 0; // #rot
		instruction[7:0] = 8'h0f; // immediate

		mem_address = 0;
		mem_write = instruction;
		mem_w = 1;
		t_clk2 = 1;
		#10 t_clk2 = 0;

		// reg addressing with immediate shift
		instruction[31:28] = 0; // condition
		instruction[27:26] = 0; // instruction group
		instruction[25] = 0; // #
		instruction[24:21] = 4'b0100; // opcode: add
		instruction[20] = 1; // S
		instruction[19:16] = 0; // first operand reg
		instruction[15:12] = 0; // destination reg
		instruction[11:7] = 0; // immediate shift length
		instruction[6:5] = 0; // shift type
		instruction[4] = 0; // immediate shift
		instruction[3:0] = 1; // Rm

		mem_address = 4;
		mem_write = instruction;
		mem_w = 1;
		t_clk2 = 1;
		#10 t_clk2 = 0;

		// reg addressing with reg shift
		instruction[31:28] = 0; // condition
		instruction[27:26] = 0; // instruction group
		instruction[25] = 0; // #
		instruction[24:21] = 4'b0000; // opcode: and
		instruction[20] = 1; // S
		instruction[19:16] = 0; // first operand reg
		instruction[15:12] = 0; // destination reg
		instruction[11:8] = 2; // Rs
		instruction[7] = 0; // just for alignment
		instruction[6:5] = 0; // shift type
		instruction[4] = 1; // immediate shift
		instruction[3:0] = 1; // Rm

		mem_address = 8;
		mem_write = instruction;
		mem_w = 1;
		t_clk2 = 1;
		#10 t_clk2 = 0;

		// multiply test
		instruction[31:28] = 0; // condition	
		instruction[27:24] = 0; // indicator
		instruction[23:21] = 3'b001; // mul (simple MUL)
		instruction[20] = 0; // S
		instruction[19:16] = 0; // Rd
		instruction[15:12] = 2; // Rn
		instruction[11:8] = 0; // Rs
		instruction[7:4] = 4'b1001; // mul signature
		instruction[3:0] = 1; // Rm

		mem_address = 12;
		mem_write = instruction;
		mem_w = 1;
		t_clk2 = 1;
		#10 t_clk2 = 0;

		instruction = 0;
		test_clkactive = 1;
		mem_w = 0;
	end

	// test
	reg test_clkactive = 0;
	always @(*) begin
		if(test_clkactive) begin
			t_clk1 = clk1;
			t_clk2 = clk2;
		end
	end

	reg fetch_done = 0;
	always @(posedge t_clk1) begin
		/*
		===========================
		===========================
		===========================
							FETCH
		===========================
		===========================
		===========================
		*/
		// decoder output signal off
		fetch_done = 0;
		regbank_active = 1;
		pc_increment = 1;

		// fetch
		#1 mem_address = pc_read;
		#1 regbank_active = 0;

		#5 $display("\n\n===> fetch %h -> %h", mem_address, mem_read);
		instruction = mem_read;
		pc_increment = 0;
		fetch_done = 1;
	end

	reg do_availabe = 0, decoder_active = 0;
	always @(posedge fetch_done) begin
		/*
		===========================
		===========================
		===========================
							DECODE
		===========================
		===========================
		===========================
		*/
		do_availabe = 0;
		decoder_active = 1;
		// decode
		$display("\n\n===> decode");
		if(instruction == 0) begin
			$display("halt");
			$finish(0);
		end

		// #10 decoder output on end
		#10 do_availabe = 1;
		decoder_active = 0;
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
			
			if(do_mode == `mode_mult_mla) begin
				address3 = instruction[15:12];
			end

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
					busA = mult_output;
					busB = 0;
				end

				`mode_mult_mla: begin
					mult_input_1 = busA;
					mult_input_2 = busB;
					#5 $display("mult output:%d x %d = %d", mult_input_1, mult_input_2, mult_output);
					busA = read3;
					busB = mult_output;
					shifter_count = 0;
					shifter_mode = 0;
					#5 $display("shifter output %h", shifter_output);
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