`ifndef PROCESSORMODES
`define PROCESSORMODES

`define mode_mult_mul				1
`define mode_mult_mla				2
`define mode_mult_umull			3
`define mode_mult_smull			4
`define mode_skip_alu				15

`endif

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
	// Setup
	// clk
	reg clk1, clk2;

	// mem
	reg[31:0] mem_address, mem_write, mem_mask;
	reg mem_w;
	wire[31:0] mem_read;

	memory mem_module(
		mem_address,
		mem_write,
		mem_mask,
		clk1,
		clk2,
		mem_w,
		mem_read
	);

	// register bank
	reg[31:0] rb_write, rb_pc_write, rb_cpsr_write, rb_cpsr_mask;
	reg[4:0] rb_addresses[0:2];
	reg rb_is_active, rb_w, rb_pc_w, rb_pc_increment, rb_cpsr_w;
	wire[31:0] rb_reads[0:2], rb_pc_read;

	registerbank registerbank_module(
		rb_write,
		rb_pc_write,
		rb_cpsr_write,
		rb_cpsr_mask,
		rb_addresses[0],
		rb_addresses[1],
		rb_addresses[2],
		rb_is_active,
		rb_w,
		rb_pc_w,
		rb_pc_increment,
		rb_cpsr_w,
		clk1,
		clk2,
		rb_reads[0],
		rb_reads[1],
		rb_reads[2],
		rb_pc_read
	);

	// initialization
	reg[31:0] instruction;

	initial begin
		clk1 = 0;
		clk2 = 0;
		
		$display("initialization");

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
		clk2 = 1;
		#10 clk2 = 0;

		// reg addressing with immediate shift
		instruction[31:28] = 0; // condition
		instruction[27:26] = 0; // instruction group
		instruction[25] = 0; // #
		instruction[24:21] = 4'b0100; // opcode: add
		instruction[20] = 1; // S
		instruction[19:16] = 0; // first operand reg
		instruction[15:12] = 0; // destination reg
		instruction[11:8] = 1; // Rn
		instruction[7] = 0; // 0
		instruction[6:5] = 0; // shift type
		instruction[4] =1; // immediate shift
		instruction[3:0] = 1; // Rm

		mem_address = 4;
		mem_write = instruction;
		mem_w = 1;
		clk2 = 1;
		#10 clk2 = 0;

		// reg addressing with reg shift
		instruction[31:28] = 0; // condition
		instruction[27:26] = 0; // instruction group
		instruction[25] = 0; // #
		instruction[24:21] = 4'b0000; // opcode: and
		instruction[20] = 1; // S
		instruction[19:16] = 0; // first operand reg
		instruction[15:12] = 0; // destination reg
		instruction[11:8] = 1; // Rs
		instruction[7] = 0; // just for alignment
		instruction[6:5] = 1; // shift type
		instruction[4] = 1; // immediate shift
		instruction[3:0] = 1; // Rm

		mem_address = 8;
		mem_write = instruction;
		mem_w = 1;
		clk2 = 1;
		#10 clk2 = 0;

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
		clk2 = 1;
		#10 clk2 = 0;

		instruction = 0;
		mem_w = 0;

		// test clocks
		#5 clk1 = 1;
		#10 clk1 = 0;
		#5 clk2 = 1;
		#10 clk2 = 0;

		#5 clk1 = 1;
		#10 clk1 = 0;
		#5 clk2 = 1;
		#10 clk2 = 0;

		#5 clk1 = 1;
		#10 clk1 = 0;
		#5 clk2 = 1;
		#10 clk2 = 0;

		#5 clk1 = 1;
		#10 clk1 = 0;
		#5 clk2 = 1;
		#10 clk2 = 0;

		#5 clk1 = 1;
		#10 clk1 = 0;
		#5 clk2 = 1;
		#10 clk2 = 0;

		#5 clk1 = 1;
		#10 clk1 = 0;
		#5 clk2 = 1;
		#10 clk2 = 0;

		#5 clk1 = 1;
		#10 clk1 = 0;
		#5 clk2 = 1;
		#10 clk2 = 0;

		$finish();
	end

	// BUFFERS:
	// input - updated when someone updates it
	// real value - it doesn't get updated until the user tells the buffer it's ready to be updated
	// updatable boolean

	// 1. Fetch
	reg[31:0] f_pc, f_instruction;
	reg f_mustincrement;

	always @(posedge clk1) begin
	// starting on c1
		// 1. read PC
		#2 f_pc = rb_pc_read;

		// 2. read mem[PC] (next instruction)
		mem_address = f_pc;
		#2 f_instruction = mem_read;

		// 3. check if it'll be able to increment PC
		f_mustincrement = 1;

		// 4. update the decoder's buffers
	end

	always @(posedge clk2) begin
		// increment PC on cb
		if(f_mustincrement) begin
			rb_pc_increment = 1;
			#2 rb_pc_increment = 0;
		end
	end

	// 2. Decode
	always @(posedge clk1) begin
	// starting on c1
		// 1. generate signals based on the instruction
		// 2. update the buffers
	end

	// 3. Execute
	always @(posedge clk1) begin
	// read on c1
	end

	always @(posedge clk2) begin
	// write back on c2
		// 1. read from registers/memory
		// 2. multiply / shift
		// 3. ALU
		// 4. write back to reg/memory
	end
endmodule
`endif