// IO Params
`define FXP24S_ADDR 23:0
`define FXP24S_WIDTH 24
`define FXP24S_SIGN 23
`define FXP24S_MAG 22:0
`define FXP24S_LSB_POW -24

module fxp24s_var_shifter(
	input clk,
	input rstn,
	// Input Stream
	input [`FXP24S_ADDR] in_data,
	input [`FXP24S_ADDR] in_shift,
	input shift_sign, // 0: LS | 1: RS
	// Output Stream
	output [`FXP24S_ADDR] out_data
);
	wire [23:0] sat_val;
	wire saturate;
	wire [4:0] shift_val;
	assign saturate = ~|in_shift[23:5];
	assign shift_val = in_shift[4:0];
	// Stages
	wire [23:0] stage_val [5:0];
	assign stage_val[0] = in_data;
	assign stage_val[1] = shift_val[0] ? (shift_sign ? {{1{in_data[23]}}, stage_val[0][23:1]} : { stage_val[0][22:0], {1{1'b0}} }) : stage_val[0];
	assign stage_val[2] = shift_val[1] ? (shift_sign ? {{2{in_data[23]}}, stage_val[1][23:2]} : { stage_val[1][21:0], {2{1'b0}} }) : stage_val[1];
	assign stage_val[3] = shift_val[2] ? (shift_sign ? {{4{in_data[23]}}, stage_val[2][23:4]} : { stage_val[2][19:0], {4{1'b0}} }) : stage_val[2];
	assign stage_val[4] = shift_val[3] ? (shift_sign ? {{8{in_data[23]}}, stage_val[3][23:8]} : { stage_val[3][15:0], {8{1'b0}} }) : stage_val[3];
	assign stage_val[5] = shift_val[4] ? (shift_sign ? {{16{in_data[23]}}, stage_val[4][23:16]} : { stage_val[4][7:0], {16{1'b0}} }) : stage_val[4];
	assign out_data[23] = in_data[23] & saturate;
	assign out_data[22:0] = stage_val[5][22:0] & {23{saturate}};

endmodule
