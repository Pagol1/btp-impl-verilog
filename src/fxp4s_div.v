// IO Params
`define FXP4S_ADDR 3:0
`define FXP4S_WIDTH 4
`define FXP4S_SIGN 3
`define FXP4S_MAG 2:0
`define FXP4S_LSB_POW -30

module fxp4s_div(
	input clk,
	input rstn,
	input [`FXP4S_ADDR] in_n,		// Sign-Mag
	input [`FXP4S_ADDR] in_d,		// Sign-Mag
	output [`FXP4S_ADDR] out_q,
	output div_by_zero
);
	
	genvar i;
	// Stage 0
	wire [2:0] div_st0_s;
	wire [2:0] div_st0_b;
	wire [2:0] div_st0_q;
	restoring_subtractor RS_st_0(in_n[0], in_d[0], 1'b0, div_st0_q[1], div_st0_s[0], div_st0_b[0], div_st0_q[0]);
	generate
		for (i=1; i<2; i=i+1) begin : DIV_STAGE_0
			restoring_subtractor RS(in_n[i], in_d[i], div_st0_b[i-1], div_st0_q[i+1], div_st0_s[i], div_st0_b[i], div_st0_q[i]);
		end
	endgenerate
	restoring_subtractor RS_end_0(in_n[2], in_d[2], div_st0_b[1], out_q[2], div_st0_s[2], div_st0_b[2], div_st0_q[2]);
	assign out_q[2] = ~div_st0_b[2];
	// Stage 1
	wire [3:0] div_st1_s;
	wire [3:0] div_st1_b;
	wire [3:0] div_st1_q;
	restoring_subtractor RS_st_1(1'b0, in_d[0], 1'b0, div_st1_q[1], div_st1_s[0], div_st1_b[0], div_st1_q[0]);
	generate
		for (i=1; i<3; i=i+1) begin : DIV_STAGE_1
			restoring_subtractor RS(div_st0_s[i-1], in_d[i], div_st1_b[i-1], div_st1_q[i+1], div_st1_s[i], div_st1_b[i], div_st1_q[i]);
		end
	endgenerate
	restoring_subtractor RS_end_1(div_st0_s[2], 1'b0, div_st1_b[2], out_q[1], div_st1_s[3], div_st1_b[3], div_st1_q[3]);
	assign out_q[1] = ~div_st1_b[3];
	// Stage 2
	wire [3:0] div_st2_s;
	wire [3:0] div_st2_b;
	wire [3:0] div_st2_q;
	restoring_subtractor RS_st_2(1'b0, in_d[0], 1'b0, div_st2_q[1], div_st2_s[0], div_st2_b[0], div_st2_q[0]);
	generate
		for (i=1; i<3; i=i+1) begin : DIV_STAGE_2
			restoring_subtractor RS(div_st1_s[i-1], in_d[i], div_st2_b[i-1], div_st2_q[i+1], div_st2_s[i], div_st2_b[i], div_st2_q[i]);
		end
	endgenerate
	restoring_subtractor RS_end_2(div_st1_s[2], 1'b0, div_st2_b[2], out_q[0], div_st2_s[3], div_st2_b[3], div_st2_q[3]);
	assign out_q[0] = ~div_st2_b[3];
	assign div_by_zero = ~|in_d;
	assign out_q[3] = in_n[3] ^ in_d[3];

endmodule
