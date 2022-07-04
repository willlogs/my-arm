`ifndef MEMORY
`define MEMORY
module memory(
	input [31:0] address,
	input [31:0] write,
	input [31:0] mask,
	input clk1, clk2,
	input w,
	output reg[31:0] read
);

	reg[7:0] mem[1023:0]; // 4MB ram
	integer i;

	initial begin
		for(i = 0; i < 1024; i += 1) begin
			mem[i] = 0;
		end
	end

	always @(*) begin
		if(clk1) begin
			if(address > 1023) begin
				$display("memory address out of bounds");
			end
			else begin
				read = {mem[address], mem[address + 1], mem[address + 2], mem[address + 3]};
				$display("mem-reading %h from %h", read, address);
			end
		end

		if(clk2 && w) begin
			if(address > 1023) begin
				$display("memory address out of bounds");
			end
			else begin
				mem[address] = write[31:24];
				mem[address + 1] = write[23:16];
				mem[address + 2] = write[15:8];
				mem[address + 3] = write[7:0];
				$display("mem-writing %h to %h", write, address);
			end
		end
	end

endmodule
`endif