`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:06:06 11/01/2023 
// Design Name: 
// Module Name:    full_adder 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
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
