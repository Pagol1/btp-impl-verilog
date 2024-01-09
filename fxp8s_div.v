// IO Params
`define FXP8S_ADDR 7:0
`define FXP8S_WIDTH 8
`define FXP8S_SIGN 7
`define FXP8S_MAG 6:0
`define FXP8S_LSB_POW -3

module fxp8s_div(
	input clk,
	input rstn,
	input [`FXP8S_ADDR] in_n,		// Sign-Mag
	input [`FXP8S_ADDR] in_d,		// Sign-Mag
	output [`FXP8S_ADDR] out_q,
	output div_by_zero
);
	
	genvar i;
	wire [2:0] div_q_mask;
	assign div_q_mask[0] = in_d[6];
	generate
		for (i=1; i<3; i=i+1) begin : DIV_MASK
			assign div_q_mask[i] = div_q_mask[i-1] | in_d[6-i];
		end
	endgenerate
	// Stage 0 : 2^3
	wire [3:0] div_st0_s;
	wire [3:0] div_st0_b;
	wire [3:0] div_st0_q;
	restoring_subtractor RS_lEnd_0(in_n[6], in_d[3], div_st0_b[2], out_q[6], div_st0_s[3], div_st0_b[3], div_st0_q[3]);
	generate
		for (i=2; i>=1; i=i-1) begin : RS_ROW_N_NEW_0
			restoring_subtractor RS_0(in_n[i+3], in_d[i], div_st0_b[i-1], div_st0_q[i+1], div_st0_s[i], div_st0_b[i], div_st0_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_0(in_n[3], in_d[0], 1'b0, div_st0_q[1], div_st0_s[0], div_st0_b[0], div_st0_q[0]);
	assign out_q[6] = ~(div_q_mask[2] | div_st0_b[3]);
	// Stage 1 : 2^2
	wire [4:0] div_st1_s;
	wire [4:0] div_st1_b;
	wire [4:0] div_st1_q;
	restoring_subtractor RS_lEnd_1(div_st0_s[3], in_d[4], div_st1_b[3], out_q[5], div_st1_s[4], div_st1_b[4], div_st1_q[4]);
	generate
		for (i=3; i>=1; i=i-1) begin : RS_ROW_N_USED_1
			restoring_subtractor RS_1(div_st0_s[i-1], in_d[i], div_st1_b[i-1], div_st1_q[i+1], div_st1_s[i], div_st1_b[i], div_st1_q[i]);
		end
	endgenerate
	generate
		for (i=0; i>=1; i=i-1) begin : RS_ROW_N_NEW_1
			restoring_subtractor RS_1(in_n[i+2], in_d[i], div_st1_b[i-1], div_st1_q[i+1], div_st1_s[i], div_st1_b[i], div_st1_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_1(in_n[2], in_d[0], 1'b0, div_st1_q[1], div_st1_s[0], div_st1_b[0], div_st1_q[0]);
	assign out_q[5] = ~(div_q_mask[1] | div_st1_b[4]);
	// Stage 2 : 2^1
	wire [5:0] div_st2_s;
	wire [5:0] div_st2_b;
	wire [5:0] div_st2_q;
	restoring_subtractor RS_lEnd_2(div_st1_s[4], in_d[5], div_st2_b[4], out_q[4], div_st2_s[5], div_st2_b[5], div_st2_q[5]);
	generate
		for (i=4; i>=1; i=i-1) begin : RS_ROW_N_USED_2
			restoring_subtractor RS_2(div_st1_s[i-1], in_d[i], div_st2_b[i-1], div_st2_q[i+1], div_st2_s[i], div_st2_b[i], div_st2_q[i]);
		end
	endgenerate
	generate
		for (i=0; i>=1; i=i-1) begin : RS_ROW_N_NEW_2
			restoring_subtractor RS_2(in_n[i+1], in_d[i], div_st2_b[i-1], div_st2_q[i+1], div_st2_s[i], div_st2_b[i], div_st2_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_2(in_n[1], in_d[0], 1'b0, div_st2_q[1], div_st2_s[0], div_st2_b[0], div_st2_q[0]);
	assign out_q[4] = ~(div_q_mask[0] | div_st2_b[5]);
	// Stage 3 : 2^0
	wire [6:0] div_st3_s;
	wire [6:0] div_st3_b;
	wire [6:0] div_st3_q;
	restoring_subtractor RS_lEnd_3(div_st2_s[5], in_d[6], div_st3_b[5], out_q[3], div_st3_s[6], div_st3_b[6], div_st3_q[6]);
	generate
		for (i=5; i>=1; i=i-1) begin : RS_ROW_N_USED_3
			restoring_subtractor RS_3(div_st2_s[i-1], in_d[i], div_st3_b[i-1], div_st3_q[i+1], div_st3_s[i], div_st3_b[i], div_st3_q[i]);
		end
	endgenerate
	generate
		for (i=0; i>=1; i=i-1) begin : RS_ROW_N_NEW_3
			restoring_subtractor RS_3(in_n[i+0], in_d[i], div_st3_b[i-1], div_st3_q[i+1], div_st3_s[i], div_st3_b[i], div_st3_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_3(in_n[0], in_d[0], 1'b0, div_st3_q[1], div_st3_s[0], div_st3_b[0], div_st3_q[0]);
	assign out_q[3] = ~div_st3_b[6];
	// Stage 4 : 2^-1
	wire [7:0] div_st4_s;
	wire [7:0] div_st4_b;
	wire [7:0] div_st4_q;
	restoring_subtractor RS_lEnd_4(div_st3_s[6], 1'b0, div_st4_b[6], out_q[2], div_st4_s[7], div_st4_b[7], div_st4_q[7]);
	generate
		for (i=6; i>0; i=i-1) begin : RS_ROW_N_USED_4
			restoring_subtractor RS_4(div_st3_s[i-1], in_d[i], div_st4_b[i-1], div_st4_q[i+1], div_st4_s[i], div_st4_b[i], div_st4_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_4(1'b0, in_d[0], 1'b0, div_st4_q[1], div_st4_s[0], div_st4_b[0], div_st4_q[0]);
	assign out_q[2] = ~div_st4_b[7];
	// Stage 5 : 2^-2
	wire [7:0] div_st5_s;
	wire [7:0] div_st5_b;
	wire [7:0] div_st5_q;
	restoring_subtractor RS_lEnd_5(div_st4_s[6], 1'b0, div_st5_b[6], out_q[1], div_st5_s[7], div_st5_b[7], div_st5_q[7]);
	generate
		for (i=6; i>0; i=i-1) begin : RS_ROW_N_USED_5
			restoring_subtractor RS_5(div_st4_s[i-1], in_d[i], div_st5_b[i-1], div_st5_q[i+1], div_st5_s[i], div_st5_b[i], div_st5_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_5(1'b0, in_d[0], 1'b0, div_st5_q[1], div_st5_s[0], div_st5_b[0], div_st5_q[0]);
	assign out_q[1] = ~div_st5_b[7];
	// Stage 6 : 2^-3
	wire [7:0] div_st6_s;
	wire [7:0] div_st6_b;
	wire [7:0] div_st6_q;
	restoring_subtractor RS_lEnd_6(div_st5_s[6], 1'b0, div_st6_b[6], out_q[0], div_st6_s[7], div_st6_b[7], div_st6_q[7]);
	generate
		for (i=6; i>0; i=i-1) begin : RS_ROW_N_USED_6
			restoring_subtractor RS_6(div_st5_s[i-1], in_d[i], div_st6_b[i-1], div_st6_q[i+1], div_st6_s[i], div_st6_b[i], div_st6_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_6(1'b0, in_d[0], 1'b0, div_st6_q[1], div_st6_s[0], div_st6_b[0], div_st6_q[0]);
	assign out_q[0] = ~div_st6_b[7];
	assign div_by_zero = ~|in_d;
	assign out_q[7] = in_n[7] ^ in_d[7];

endmodule
