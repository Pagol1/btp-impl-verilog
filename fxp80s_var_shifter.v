// IO Params
`define FXP64S_ADDR 79:0
`define FXP64S_WIDTH 80
`define FXP64S_SIGN 79
`define FXP64S_MAG 78:0
`define FXP64S_LSB_POW -48

module fxp80s_var_shifter(
	input clk,
	input rstn,
	// Input Stream
	input [`FXP64S_ADDR] in_data,
	input [`FXP64S_ADDR] in_shift,
	input shift_sign, // 0: LS | 1: RS
	// Output Stream
	output [`FXP64S_ADDR] out_data
);
	wire [79:0] sat_val;
	wire saturate;
	wire [6:0] shift_val;
	assign saturate = ~|in_shift[79:7];
	assign shift_val = in_shift[6:0];
	// Stages
	wire [79:0] stage_val [7:0];
	assign stage_val[0] = in_data;
	assign stage_val[1] = shift_val[0] ? (shift_sign ? {{1{in_data[79]}}, stage_val[0][79:1]} : { stage_val[0][78:0], {1{1'b0}} }) : stage_val[0];
	assign stage_val[2] = shift_val[1] ? (shift_sign ? {{2{in_data[79]}}, stage_val[1][79:2]} : { stage_val[1][77:0], {2{1'b0}} }) : stage_val[1];
	assign stage_val[3] = shift_val[2] ? (shift_sign ? {{4{in_data[79]}}, stage_val[2][79:4]} : { stage_val[2][75:0], {4{1'b0}} }) : stage_val[2];
	assign stage_val[4] = shift_val[3] ? (shift_sign ? {{8{in_data[79]}}, stage_val[3][79:8]} : { stage_val[3][71:0], {8{1'b0}} }) : stage_val[3];
	assign stage_val[5] = shift_val[4] ? (shift_sign ? {{16{in_data[79]}}, stage_val[4][79:16]} : { stage_val[4][63:0], {16{1'b0}} }) : stage_val[4];
	assign stage_val[6] = shift_val[5] ? (shift_sign ? {{32{in_data[79]}}, stage_val[5][79:32]} : { stage_val[5][47:0], {32{1'b0}} }) : stage_val[5];
	assign stage_val[7] = shift_val[6] ? (shift_sign ? {{64{in_data[79]}}, stage_val[6][79:64]} : { stage_val[6][15:0], {64{1'b0}} }) : stage_val[6];
	assign out_data[79] = in_data[79] & saturate;
	assign out_data[78:0] = stage_val[7][78:0] & {79{saturate}};

endmodule
