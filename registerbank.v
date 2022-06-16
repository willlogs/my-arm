module registerbank(
  input [31:0] write,
  input [31:0] pc_write,
  input [4:0] address1,
  input [4:0] address2,
  input w,
  input pc_w,
  input clk,
  output reg[31:0] read1,
  output reg[31:0] read2,
  output reg[31:0] pc_read
);
	// 37 registers total. The mapping is like this:
	// 0 - 15 are the general registers
	// 16 - 22 are fiq registers
	// 23 - 24 are svc
	// 25 - 26 are abt
	// 27 - 29 are irq
	// 30 - 31 are und
	reg[31:0] bank[0:36];

	always @(*) begin
	  	if(clk) begin
			if(w) begin		
			  	$display("writing %h to %h", write, address1);
				bank[address1] = write;			
			end
			else begin
				read1 = bank[address1];
				$display("reading %h from %h", read1, address1);
				read2 = bank[address2];	
			end

			if(pc_w) begin
				$display("writing %h to pc", pc_write);
				bank[15] = pc_write;
			end
			else begin
			  	pc_read = bank[15];
				$display("reading %h from pc", pc_read);
			end
	  	end
	end
endmodule
