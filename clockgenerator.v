`ifndef CLOCKGENERATOR
`define CLOCKGENERATOR
module clock(output reg c1, output reg c2);
	integer phase = 0;

	always #40 begin
	  	if(phase == 0) c1 = 1;
		if(phase == 8) c1 = 0;

		if(phase == 10) c2 = 1;
		if(phase == 18) c2 = 0;
		if(phase == 20) phase = -1;
		 
		phase = phase + 1;
	end
endmodule
`endif