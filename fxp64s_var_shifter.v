// IO Params
`define FXP64S_ADDR 63:0
`define FXP64S_WIDTH 64
`define FXP64S_SIGN 63
`define FXP64S_MAG 62:0
`define FXP64S_LSB_POW -48

module fxp64s_var_shifter(
	input clk,
	input rstn,
	// Input Stream
	input [`FXP64S_ADDR] in_data,
	input [`FXP64S_ADDR] in_shift,
	// Output Stream
	output [`FXP64S_ADDR] out_data
);
	wire [63:0] sat_val;
	wire saturate;
	wire shift_sign;
	wire [5:0] shift_val;
	assign shift_sign = in_shift[63];
	assign sat_val = in_shift + shift_sign;
	assign saturate = ~|sat_val[63:6];
	assign shift_val = sat_val;
	// Stages
	wire [63:0] stage_val [6:0];
	assign stage_val[0] = in_data;
	assign stage_val[1] = shift_val[0] ? (shift_sign ? {1{in_data[63]}, stage_val[0][63:1]} : {stage_val[0][0:0], , 1{1'b0}}) : stage_val[0];
	assign stage_val[2] = shift_val[1] ? (shift_sign ? {2{in_data[63]}, stage_val[1][63:2]} : {stage_val[1][1:0], , 2{1'b0}}) : stage_val[1];
	assign stage_val[3] = shift_val[2] ? (shift_sign ? {4{in_data[63]}, stage_val[2][63:4]} : {stage_val[2][3:0], , 4{1'b0}}) : stage_val[2];
	assign stage_val[4] = shift_val[3] ? (shift_sign ? {8{in_data[63]}, stage_val[3][63:8]} : {stage_val[3][7:0], , 8{1'b0}}) : stage_val[3];
	assign stage_val[5] = shift_val[4] ? (shift_sign ? {16{in_data[63]}, stage_val[4][63:16]} : {stage_val[4][15:0], , 16{1'b0}}) : stage_val[4];
	assign stage_val[6] = shift_val[5] ? (shift_sign ? {32{in_data[63]}, stage_val[5][63:32]} : {stage_val[5][31:0], , 32{1'b0}}) : stage_val[5];
	assign out_data[63] = in_data[63] & saturate;
	assign out_data[62:0] = stage_val[6][62:0] & {63{saturate}};

endmodule
