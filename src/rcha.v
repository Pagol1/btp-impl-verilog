`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:36:41 11/01/2023 
// Design Name: 
// Module Name:    rcha 
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
module rcha #(
	parameter N=2
)(
	input [N-1:0] A,
	input C_IN,
	output [N-1:0] SUM
);
	wire [N-1:0] carry;
	wire [N-1:0] imm;
	
	genvar j;
	generate
		for (j=0; j<N; j=j+1) begin : rca_chain
			if (j==0) begin
				assign SUM[0] = A[0] ^ C_IN;
				assign carry[0] = A[0] & C_IN; 
			end	
			else begin
				assign SUM[j] = A[j] ^ carry[j-1];
				assign carry[j] = (A[j] & carry[j-1]);
			end
		end
	endgenerate
	
endmodule
