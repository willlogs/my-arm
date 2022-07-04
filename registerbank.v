module registerbank(
  input [31:0] write,
  input [31:0] pc_write,
	input [31:0] cpsr_write, cpsr_mask,
  input [4:0] address1,
  input [4:0] address2,
  input [4:0] address3,
	input is_active,
  input w,
  input pc_w,
	input cpsr_w,
  input clk1, clk2,
  output reg[31:0] read1,
  output reg[31:0] read2,
  output reg[31:0] read3,
  output reg[31:0] pc_read
);
	// 37 registers total. The mapping is like this:
	// 0 - 15 are the general registers
	// 16 - 22 are fiq registers
	// 23 - 24 are svc
	// 25 - 26 are abt
	// 27 - 28 are irq
	// 29 - 30 are und
	// 31 cpsr
	// 32 SPSR_fiq
	// 33 SPSR_svc
	// 34 SPSR_abt
	// 35 SPSR_irq
	// 36 SPSR_und
	reg[31:0] bank[0:36];

	always @(*) begin
	  	if(clk1 && is_active) begin
				$display("accessing regbank w: %b", w);
				if(!w) begin
					read1 = bank[address1];
					$display("reading %h from %h", read1, address1);
					read2 = bank[address2];	
					$display("reading %h from %h", read2, address2);
					read3 = bank[address3];	
					$display("reading %h from %h", read3, address3);
				end

				pc_read = bank[15];
				$display("reading %h from pc", pc_read);
	  	end

			if(clk2) begin
				if(w) begin		
					$display("writing %h to %h", write, address1);
					bank[address1] = write;			
				end

				if(pc_w) begin
					$display("writing %h to pc", pc_write);
					bank[15] = pc_write;
				end

				if(cpsr_w) begin
					$display("writing CPSR %b", cpsr_write);
					bank[31] = (bank[31] & ~cpsr_mask) | (cpsr_write & cpsr_mask); 
				end
			end
	end
endmodule
