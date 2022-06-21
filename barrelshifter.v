`ifndef BARRELSHIFTER
`define BARRELSHIFTER
module barrelshifter(input [31:0] i, input[2:0] mode, input[4:0] count, output reg[31:0] o);
	integer counter;
	reg[31:0] tmp;
	always @(*) begin
		case(mode)
		  	// left shift logical
			3'b000: begin
			  	$display("lsl");
				o = i << count;
			end
			// right shift logical
			3'b001: begin
			  	$display("rsl");
			  	o = i >> count;
			end
			// left shift arithmatic
			3'b010: begin
			  	$display("lsa");
			  	o = i <<< count;
			end
			// right shift arithmatic
			3'b011: begin
			  	$display("rsa");
			  	tmp = i;
			  	for(counter = 0; counter < count; counter = counter + 1) begin
				  	tmp = {tmp[31], tmp[31:1]};
				end
				o = tmp;
			end
			// left shift circular
			3'b100: begin
			  	$display("lsc");
			  	tmp = i;
			  	for(counter = 0; counter < count; counter = counter + 1) begin
					tmp = {tmp[30:0], tmp[31]};	
				end
				o = tmp;
			end
			// right shift circular
			3'b101: begin
			  	$display("rsc");
			  	tmp = i;
			  	for(counter = 0; counter < count; counter = counter + 1) begin
					tmp = {tmp[0], tmp[31:1]};	
				end
				o = tmp;
			end
		endcase
	end
endmodule
`endif
