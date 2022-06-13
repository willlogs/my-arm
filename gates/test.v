module gatetest;
	reg a = 1;
	reg b = 1;

	wire o;
	wire i1;
	wire i2;

	assign i1 = a;
	assign i2 = b;

	W_XOR andgate(o, i1, i2);

	integer i;

	reg[31:0] a32 = 32'hFFFFFFFF;
   	reg[31:0] b32 = 0;
	wire[31:0] wo32;

	//W_AND32 and32(a32, b32, wo32);
	W_OR32 or32(a32, b32, wo32);

	initial begin
		for(i = 0; i < 4; i = i +1) begin
		  	a = i[0];
			b = i[1];
			#10 $display("%d, %d, o:%d", a, b, o);
	  	end

		#100 $display("%h", wo32);	
	end
endmodule
