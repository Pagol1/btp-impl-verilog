// IO Params
`define FXP8S_ADDR 7:0
`define FXP8S_WIDTH 8
`define FXP8S_SIGN 7
`define FXP8S_MAG 6:0
`define FXP8S_LSB_POW -3

module fxp8s_var_shifter(
	input clk,
	input rstn,
	// Input Stream
	input [`FXP8S_ADDR] in_data,
	input [`FXP8S_ADDR] in_shift,
	// Output Stream
	output [`FXP8S_ADDR] out_data
);
	wire [7:0] sat_val;
	wire saturate;
	wire shift_sign;
	wire [2:0] shift_val;
	assign shift_sign = in_shift[7];
	assign sat_val = in_data + shift_sign;
	assign saturate = ~|sat_val[7:3];
	assign shift_val = sat_val;
	// Stages
	wire [7:0] stage_val [3:0];
	assign stage_val[0] = in_data;
	assign stage_val[1] = shift_val[0] ? (shift_sign ? {1{1'b0}, stage_val[0][7:1]} : {stage_val[0][0:0], , 1{1'b0}}) : stage_val[0];
	assign stage_val[2] = shift_val[1] ? (shift_sign ? {2{1'b0}, stage_val[1][7:2]} : {stage_val[1][1:0], , 2{1'b0}}) : stage_val[1];
	assign stage_val[3] = shift_val[2] ? (shift_sign ? {4{1'b0}, stage_val[2][7:4]} : {stage_val[2][3:0], , 4{1'b0}}) : stage_val[2];
	assign out_data[7] = in_data[7] & saturate;
	assign out_data[6:0] = stage_val[3][6:0] & {7{saturate}};

endmodule
