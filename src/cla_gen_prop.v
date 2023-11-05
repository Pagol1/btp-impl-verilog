`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:03:04 10/29/2023 
// Design Name: 
// Module Name:    cla_gen_prop 
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
module cla_gen_prop(
	input gen_i_j,
	input gen_j_k,
	input prop_i_j,
	input prop_j_k,
	output gen_i_k,
	output prop_i_k
);
	assign gen_i_k = gen_i_j | (prop_i_j & gen_j_k);
	assign prop_i_k = prop_i_j & prop_j_k;
endmodule
