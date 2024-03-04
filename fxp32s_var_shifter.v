// IO Params
`define FXP32S_ADDR 31:0
`define FXP32S_WIDTH 32
`define FXP32S_SIGN 31
`define FXP32S_MAG 30:0
`define FXP32S_LSB_POW -24

module fxp32s_var_shifter(
	input clk,
	input rstn,
	// Input Stream
	input [`FXP32S_ADDR] in_data,
	input [`FXP32S_ADDR] in_shift,
	input shift_sign, // 0: LS | 1: RS
	// Output Stream
	output [`FXP32S_ADDR] out_data
);
	wire [31:0] sat_val;
	wire saturate;
	wire [4:0] shift_val;
	assign saturate = ~|in_shift[31:5];
	assign shift_val = in_shift[4:0];
	// Stages
	wire [31:0] stage_val [5:0];
	assign stage_val[0] = in_data;
	assign stage_val[1] = shift_val[0] ? (shift_sign ? {{1{in_data[31]}}, stage_val[0][31:1]} : { stage_val[0][30:0], {1{1'b0}} }) : stage_val[0];
	assign stage_val[2] = shift_val[1] ? (shift_sign ? {{2{in_data[31]}}, stage_val[1][31:2]} : { stage_val[1][29:0], {2{1'b0}} }) : stage_val[1];
	assign stage_val[3] = shift_val[2] ? (shift_sign ? {{4{in_data[31]}}, stage_val[2][31:4]} : { stage_val[2][27:0], {4{1'b0}} }) : stage_val[2];
	assign stage_val[4] = shift_val[3] ? (shift_sign ? {{8{in_data[31]}}, stage_val[3][31:8]} : { stage_val[3][23:0], {8{1'b0}} }) : stage_val[3];
	assign stage_val[5] = shift_val[4] ? (shift_sign ? {{16{in_data[31]}}, stage_val[4][31:16]} : { stage_val[4][15:0], {16{1'b0}} }) : stage_val[4];
	assign out_data[31] = in_data[31] & saturate;
	assign out_data[30:0] = stage_val[5][30:0] & {31{saturate}};

endmodule
