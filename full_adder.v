module full_adder(
	input a,
	input b,
	input cin,
	output s,
	output cout
 );
	wire imm;
	assign imm = a ^ b;
	assign s = imm ^ cin;
	assign cout = (imm & cin) | (a & b);

endmodule
