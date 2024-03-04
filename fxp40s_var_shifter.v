// IO Params
`define FXP40S_ADDR 39:0
`define FXP40S_WIDTH 40
`define FXP40S_SIGN 39
`define FXP40S_MAG 38:0
`define FXP40S_LSB_POW -24

module fxp40s_var_shifter(
	input clk,
	input rstn,
	// Input Stream
	input [`FXP40S_ADDR] in_data,
	input [`FXP40S_ADDR] in_shift,
	input shift_sign, // 0: LS | 1: RS
	// Output Stream
	output [`FXP40S_ADDR] out_data
);
	wire [39:0] sat_val;
	wire saturate;
	wire [5:0] shift_val;
	assign saturate = ~|in_shift[39:6];
	assign shift_val = in_shift[5:0];
	// Stages
	wire [39:0] stage_val [6:0];
	assign stage_val[0] = in_data;
	assign stage_val[1] = shift_val[0] ? (shift_sign ? {{1{in_data[39]}}, stage_val[0][39:1]} : { stage_val[0][38:0], {1{1'b0}} }) : stage_val[0];
	assign stage_val[2] = shift_val[1] ? (shift_sign ? {{2{in_data[39]}}, stage_val[1][39:2]} : { stage_val[1][37:0], {2{1'b0}} }) : stage_val[1];
	assign stage_val[3] = shift_val[2] ? (shift_sign ? {{4{in_data[39]}}, stage_val[2][39:4]} : { stage_val[2][35:0], {4{1'b0}} }) : stage_val[2];
	assign stage_val[4] = shift_val[3] ? (shift_sign ? {{8{in_data[39]}}, stage_val[3][39:8]} : { stage_val[3][31:0], {8{1'b0}} }) : stage_val[3];
	assign stage_val[5] = shift_val[4] ? (shift_sign ? {{16{in_data[39]}}, stage_val[4][39:16]} : { stage_val[4][23:0], {16{1'b0}} }) : stage_val[4];
	assign stage_val[6] = shift_val[5] ? (shift_sign ? {{32{in_data[39]}}, stage_val[5][39:32]} : { stage_val[5][7:0], {32{1'b0}} }) : stage_val[5];
	assign out_data[39] = in_data[39] & saturate;
	assign out_data[38:0] = stage_val[6][38:0] & {39{saturate}};

endmodule
