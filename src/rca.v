`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:40:03 10/29/2023 
// Design Name: 
// Module Name:    rca 
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
module rca #(
	parameter N=2
)(
	input [N-1:0] A,
	input [N-1:0] B,
	input C_IN,
	output [N-1:0] SUM
);
	wire [N-1:0] carry;
	wire [N-1:0] imm;
	
	genvar j;
	generate
		for (j=0; j<N; j=j+1) begin : rca_chain
			assign imm[j] = A[j] ^ B[j];
			if (j==0) begin
				assign SUM[0] = imm[0] ^ C_IN;
				assign carry[0] = (imm[0] & C_IN) | (A[0] & B[0]); 
			end	
			else begin
				assign SUM[j] = A[j] ^ B[j] ^ carry[j-1];
				assign carry[j] = (A[j] & B[j]) | (imm[j] & carry[j-1]);
			end
		end
	endgenerate
	
endmodule
