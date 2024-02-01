// IO Params
`define FXP64S_ADDR 63:0
`define FXP64S_WIDTH 64
`define FXP64S_SIGN 63
`define FXP64S_MAG 62:0
`define FXP64S_LSB_POW -48

module fxp64s_div(
	input clk,
	input rstn,
	input [`FXP64S_ADDR] in_n,		// Sign-Mag
	input [`FXP64S_ADDR] in_d,		// Sign-Mag
	output [`FXP64S_ADDR] out_q,
	output div_by_zero
);
	
	genvar i;
	wire [13:0] div_q_mask;
	assign div_q_mask[0] = in_d[62];
	generate
		for (i=1; i<14; i=i+1) begin : DIV_MASK
			assign div_q_mask[i] = div_q_mask[i-1] | in_d[62-i];
		end
	endgenerate
	// Stage 0 : 2^14
	wire [48:0] div_st0_s;
	wire [48:0] div_st0_b;
	wire [48:0] div_st0_q;
	restoring_subtractor RS_lEnd_0(in_n[62], in_d[48], div_st0_b[47], out_q[62], div_st0_s[48], div_st0_b[48], div_st0_q[48]);
	generate
		for (i=47; i>=1; i=i-1) begin : RS_ROW_N_NEW_0
			restoring_subtractor RS_0(in_n[i+14], in_d[i], div_st0_b[i-1], div_st0_q[i+1], div_st0_s[i], div_st0_b[i], div_st0_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_0(in_n[14], in_d[0], 1'b0, div_st0_q[1], div_st0_s[0], div_st0_b[0], div_st0_q[0]);
	assign out_q[62] = ~(div_q_mask[13] | div_st0_b[48]);
	// Stage 1 : 2^13
	wire [49:0] div_st1_s;
	wire [49:0] div_st1_b;
	wire [49:0] div_st1_q;
	restoring_subtractor RS_lEnd_1(div_st0_s[48], in_d[49], div_st1_b[48], out_q[61], div_st1_s[49], div_st1_b[49], div_st1_q[49]);
	generate
		for (i=48; i>=1; i=i-1) begin : RS_ROW_N_USED_1
			restoring_subtractor RS_1(div_st0_s[i-1], in_d[i], div_st1_b[i-1], div_st1_q[i+1], div_st1_s[i], div_st1_b[i], div_st1_q[i]);
		end
	endgenerate
	generate
		for (i=0; i>=1; i=i-1) begin : RS_ROW_N_NEW_1
			restoring_subtractor RS_1(in_n[i+13], in_d[i], div_st1_b[i-1], div_st1_q[i+1], div_st1_s[i], div_st1_b[i], div_st1_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_1(in_n[13], in_d[0], 1'b0, div_st1_q[1], div_st1_s[0], div_st1_b[0], div_st1_q[0]);
	assign out_q[61] = ~(div_q_mask[12] | div_st1_b[49]);
	// Stage 2 : 2^12
	wire [50:0] div_st2_s;
	wire [50:0] div_st2_b;
	wire [50:0] div_st2_q;
	restoring_subtractor RS_lEnd_2(div_st1_s[49], in_d[50], div_st2_b[49], out_q[60], div_st2_s[50], div_st2_b[50], div_st2_q[50]);
	generate
		for (i=49; i>=1; i=i-1) begin : RS_ROW_N_USED_2
			restoring_subtractor RS_2(div_st1_s[i-1], in_d[i], div_st2_b[i-1], div_st2_q[i+1], div_st2_s[i], div_st2_b[i], div_st2_q[i]);
		end
	endgenerate
	generate
		for (i=0; i>=1; i=i-1) begin : RS_ROW_N_NEW_2
			restoring_subtractor RS_2(in_n[i+12], in_d[i], div_st2_b[i-1], div_st2_q[i+1], div_st2_s[i], div_st2_b[i], div_st2_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_2(in_n[12], in_d[0], 1'b0, div_st2_q[1], div_st2_s[0], div_st2_b[0], div_st2_q[0]);
	assign out_q[60] = ~(div_q_mask[11] | div_st2_b[50]);
	// Stage 3 : 2^11
	wire [51:0] div_st3_s;
	wire [51:0] div_st3_b;
	wire [51:0] div_st3_q;
	restoring_subtractor RS_lEnd_3(div_st2_s[50], in_d[51], div_st3_b[50], out_q[59], div_st3_s[51], div_st3_b[51], div_st3_q[51]);
	generate
		for (i=50; i>=1; i=i-1) begin : RS_ROW_N_USED_3
			restoring_subtractor RS_3(div_st2_s[i-1], in_d[i], div_st3_b[i-1], div_st3_q[i+1], div_st3_s[i], div_st3_b[i], div_st3_q[i]);
		end
	endgenerate
	generate
		for (i=0; i>=1; i=i-1) begin : RS_ROW_N_NEW_3
			restoring_subtractor RS_3(in_n[i+11], in_d[i], div_st3_b[i-1], div_st3_q[i+1], div_st3_s[i], div_st3_b[i], div_st3_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_3(in_n[11], in_d[0], 1'b0, div_st3_q[1], div_st3_s[0], div_st3_b[0], div_st3_q[0]);
	assign out_q[59] = ~(div_q_mask[10] | div_st3_b[51]);
	// Stage 4 : 2^10
	wire [52:0] div_st4_s;
	wire [52:0] div_st4_b;
	wire [52:0] div_st4_q;
	restoring_subtractor RS_lEnd_4(div_st3_s[51], in_d[52], div_st4_b[51], out_q[58], div_st4_s[52], div_st4_b[52], div_st4_q[52]);
	generate
		for (i=51; i>=1; i=i-1) begin : RS_ROW_N_USED_4
			restoring_subtractor RS_4(div_st3_s[i-1], in_d[i], div_st4_b[i-1], div_st4_q[i+1], div_st4_s[i], div_st4_b[i], div_st4_q[i]);
		end
	endgenerate
	generate
		for (i=0; i>=1; i=i-1) begin : RS_ROW_N_NEW_4
			restoring_subtractor RS_4(in_n[i+10], in_d[i], div_st4_b[i-1], div_st4_q[i+1], div_st4_s[i], div_st4_b[i], div_st4_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_4(in_n[10], in_d[0], 1'b0, div_st4_q[1], div_st4_s[0], div_st4_b[0], div_st4_q[0]);
	assign out_q[58] = ~(div_q_mask[9] | div_st4_b[52]);
	// Stage 5 : 2^9
	wire [53:0] div_st5_s;
	wire [53:0] div_st5_b;
	wire [53:0] div_st5_q;
	restoring_subtractor RS_lEnd_5(div_st4_s[52], in_d[53], div_st5_b[52], out_q[57], div_st5_s[53], div_st5_b[53], div_st5_q[53]);
	generate
		for (i=52; i>=1; i=i-1) begin : RS_ROW_N_USED_5
			restoring_subtractor RS_5(div_st4_s[i-1], in_d[i], div_st5_b[i-1], div_st5_q[i+1], div_st5_s[i], div_st5_b[i], div_st5_q[i]);
		end
	endgenerate
	generate
		for (i=0; i>=1; i=i-1) begin : RS_ROW_N_NEW_5
			restoring_subtractor RS_5(in_n[i+9], in_d[i], div_st5_b[i-1], div_st5_q[i+1], div_st5_s[i], div_st5_b[i], div_st5_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_5(in_n[9], in_d[0], 1'b0, div_st5_q[1], div_st5_s[0], div_st5_b[0], div_st5_q[0]);
	assign out_q[57] = ~(div_q_mask[8] | div_st5_b[53]);
	// Stage 6 : 2^8
	wire [54:0] div_st6_s;
	wire [54:0] div_st6_b;
	wire [54:0] div_st6_q;
	restoring_subtractor RS_lEnd_6(div_st5_s[53], in_d[54], div_st6_b[53], out_q[56], div_st6_s[54], div_st6_b[54], div_st6_q[54]);
	generate
		for (i=53; i>=1; i=i-1) begin : RS_ROW_N_USED_6
			restoring_subtractor RS_6(div_st5_s[i-1], in_d[i], div_st6_b[i-1], div_st6_q[i+1], div_st6_s[i], div_st6_b[i], div_st6_q[i]);
		end
	endgenerate
	generate
		for (i=0; i>=1; i=i-1) begin : RS_ROW_N_NEW_6
			restoring_subtractor RS_6(in_n[i+8], in_d[i], div_st6_b[i-1], div_st6_q[i+1], div_st6_s[i], div_st6_b[i], div_st6_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_6(in_n[8], in_d[0], 1'b0, div_st6_q[1], div_st6_s[0], div_st6_b[0], div_st6_q[0]);
	assign out_q[56] = ~(div_q_mask[7] | div_st6_b[54]);
	// Stage 7 : 2^7
	wire [55:0] div_st7_s;
	wire [55:0] div_st7_b;
	wire [55:0] div_st7_q;
	restoring_subtractor RS_lEnd_7(div_st6_s[54], in_d[55], div_st7_b[54], out_q[55], div_st7_s[55], div_st7_b[55], div_st7_q[55]);
	generate
		for (i=54; i>=1; i=i-1) begin : RS_ROW_N_USED_7
			restoring_subtractor RS_7(div_st6_s[i-1], in_d[i], div_st7_b[i-1], div_st7_q[i+1], div_st7_s[i], div_st7_b[i], div_st7_q[i]);
		end
	endgenerate
	generate
		for (i=0; i>=1; i=i-1) begin : RS_ROW_N_NEW_7
			restoring_subtractor RS_7(in_n[i+7], in_d[i], div_st7_b[i-1], div_st7_q[i+1], div_st7_s[i], div_st7_b[i], div_st7_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_7(in_n[7], in_d[0], 1'b0, div_st7_q[1], div_st7_s[0], div_st7_b[0], div_st7_q[0]);
	assign out_q[55] = ~(div_q_mask[6] | div_st7_b[55]);
	// Stage 8 : 2^6
	wire [56:0] div_st8_s;
	wire [56:0] div_st8_b;
	wire [56:0] div_st8_q;
	restoring_subtractor RS_lEnd_8(div_st7_s[55], in_d[56], div_st8_b[55], out_q[54], div_st8_s[56], div_st8_b[56], div_st8_q[56]);
	generate
		for (i=55; i>=1; i=i-1) begin : RS_ROW_N_USED_8
			restoring_subtractor RS_8(div_st7_s[i-1], in_d[i], div_st8_b[i-1], div_st8_q[i+1], div_st8_s[i], div_st8_b[i], div_st8_q[i]);
		end
	endgenerate
	generate
		for (i=0; i>=1; i=i-1) begin : RS_ROW_N_NEW_8
			restoring_subtractor RS_8(in_n[i+6], in_d[i], div_st8_b[i-1], div_st8_q[i+1], div_st8_s[i], div_st8_b[i], div_st8_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_8(in_n[6], in_d[0], 1'b0, div_st8_q[1], div_st8_s[0], div_st8_b[0], div_st8_q[0]);
	assign out_q[54] = ~(div_q_mask[5] | div_st8_b[56]);
	// Stage 9 : 2^5
	wire [57:0] div_st9_s;
	wire [57:0] div_st9_b;
	wire [57:0] div_st9_q;
	restoring_subtractor RS_lEnd_9(div_st8_s[56], in_d[57], div_st9_b[56], out_q[53], div_st9_s[57], div_st9_b[57], div_st9_q[57]);
	generate
		for (i=56; i>=1; i=i-1) begin : RS_ROW_N_USED_9
			restoring_subtractor RS_9(div_st8_s[i-1], in_d[i], div_st9_b[i-1], div_st9_q[i+1], div_st9_s[i], div_st9_b[i], div_st9_q[i]);
		end
	endgenerate
	generate
		for (i=0; i>=1; i=i-1) begin : RS_ROW_N_NEW_9
			restoring_subtractor RS_9(in_n[i+5], in_d[i], div_st9_b[i-1], div_st9_q[i+1], div_st9_s[i], div_st9_b[i], div_st9_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_9(in_n[5], in_d[0], 1'b0, div_st9_q[1], div_st9_s[0], div_st9_b[0], div_st9_q[0]);
	assign out_q[53] = ~(div_q_mask[4] | div_st9_b[57]);
	// Stage 10 : 2^4
	wire [58:0] div_st10_s;
	wire [58:0] div_st10_b;
	wire [58:0] div_st10_q;
	restoring_subtractor RS_lEnd_10(div_st9_s[57], in_d[58], div_st10_b[57], out_q[52], div_st10_s[58], div_st10_b[58], div_st10_q[58]);
	generate
		for (i=57; i>=1; i=i-1) begin : RS_ROW_N_USED_10
			restoring_subtractor RS_10(div_st9_s[i-1], in_d[i], div_st10_b[i-1], div_st10_q[i+1], div_st10_s[i], div_st10_b[i], div_st10_q[i]);
		end
	endgenerate
	generate
		for (i=0; i>=1; i=i-1) begin : RS_ROW_N_NEW_10
			restoring_subtractor RS_10(in_n[i+4], in_d[i], div_st10_b[i-1], div_st10_q[i+1], div_st10_s[i], div_st10_b[i], div_st10_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_10(in_n[4], in_d[0], 1'b0, div_st10_q[1], div_st10_s[0], div_st10_b[0], div_st10_q[0]);
	assign out_q[52] = ~(div_q_mask[3] | div_st10_b[58]);
	// Stage 11 : 2^3
	wire [59:0] div_st11_s;
	wire [59:0] div_st11_b;
	wire [59:0] div_st11_q;
	restoring_subtractor RS_lEnd_11(div_st10_s[58], in_d[59], div_st11_b[58], out_q[51], div_st11_s[59], div_st11_b[59], div_st11_q[59]);
	generate
		for (i=58; i>=1; i=i-1) begin : RS_ROW_N_USED_11
			restoring_subtractor RS_11(div_st10_s[i-1], in_d[i], div_st11_b[i-1], div_st11_q[i+1], div_st11_s[i], div_st11_b[i], div_st11_q[i]);
		end
	endgenerate
	generate
		for (i=0; i>=1; i=i-1) begin : RS_ROW_N_NEW_11
			restoring_subtractor RS_11(in_n[i+3], in_d[i], div_st11_b[i-1], div_st11_q[i+1], div_st11_s[i], div_st11_b[i], div_st11_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_11(in_n[3], in_d[0], 1'b0, div_st11_q[1], div_st11_s[0], div_st11_b[0], div_st11_q[0]);
	assign out_q[51] = ~(div_q_mask[2] | div_st11_b[59]);
	// Stage 12 : 2^2
	wire [60:0] div_st12_s;
	wire [60:0] div_st12_b;
	wire [60:0] div_st12_q;
	restoring_subtractor RS_lEnd_12(div_st11_s[59], in_d[60], div_st12_b[59], out_q[50], div_st12_s[60], div_st12_b[60], div_st12_q[60]);
	generate
		for (i=59; i>=1; i=i-1) begin : RS_ROW_N_USED_12
			restoring_subtractor RS_12(div_st11_s[i-1], in_d[i], div_st12_b[i-1], div_st12_q[i+1], div_st12_s[i], div_st12_b[i], div_st12_q[i]);
		end
	endgenerate
	generate
		for (i=0; i>=1; i=i-1) begin : RS_ROW_N_NEW_12
			restoring_subtractor RS_12(in_n[i+2], in_d[i], div_st12_b[i-1], div_st12_q[i+1], div_st12_s[i], div_st12_b[i], div_st12_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_12(in_n[2], in_d[0], 1'b0, div_st12_q[1], div_st12_s[0], div_st12_b[0], div_st12_q[0]);
	assign out_q[50] = ~(div_q_mask[1] | div_st12_b[60]);
	// Stage 13 : 2^1
	wire [61:0] div_st13_s;
	wire [61:0] div_st13_b;
	wire [61:0] div_st13_q;
	restoring_subtractor RS_lEnd_13(div_st12_s[60], in_d[61], div_st13_b[60], out_q[49], div_st13_s[61], div_st13_b[61], div_st13_q[61]);
	generate
		for (i=60; i>=1; i=i-1) begin : RS_ROW_N_USED_13
			restoring_subtractor RS_13(div_st12_s[i-1], in_d[i], div_st13_b[i-1], div_st13_q[i+1], div_st13_s[i], div_st13_b[i], div_st13_q[i]);
		end
	endgenerate
	generate
		for (i=0; i>=1; i=i-1) begin : RS_ROW_N_NEW_13
			restoring_subtractor RS_13(in_n[i+1], in_d[i], div_st13_b[i-1], div_st13_q[i+1], div_st13_s[i], div_st13_b[i], div_st13_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_13(in_n[1], in_d[0], 1'b0, div_st13_q[1], div_st13_s[0], div_st13_b[0], div_st13_q[0]);
	assign out_q[49] = ~(div_q_mask[0] | div_st13_b[61]);
	// Stage 14 : 2^0
	wire [62:0] div_st14_s;
	wire [62:0] div_st14_b;
	wire [62:0] div_st14_q;
	restoring_subtractor RS_lEnd_14(div_st13_s[61], in_d[62], div_st14_b[61], out_q[48], div_st14_s[62], div_st14_b[62], div_st14_q[62]);
	generate
		for (i=61; i>=1; i=i-1) begin : RS_ROW_N_USED_14
			restoring_subtractor RS_14(div_st13_s[i-1], in_d[i], div_st14_b[i-1], div_st14_q[i+1], div_st14_s[i], div_st14_b[i], div_st14_q[i]);
		end
	endgenerate
	generate
		for (i=0; i>=1; i=i-1) begin : RS_ROW_N_NEW_14
			restoring_subtractor RS_14(in_n[i+0], in_d[i], div_st14_b[i-1], div_st14_q[i+1], div_st14_s[i], div_st14_b[i], div_st14_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_14(in_n[0], in_d[0], 1'b0, div_st14_q[1], div_st14_s[0], div_st14_b[0], div_st14_q[0]);
	assign out_q[48] = ~div_st14_b[62];
	// Stage 15 : 2^-1
	wire [63:0] div_st15_s;
	wire [63:0] div_st15_b;
	wire [63:0] div_st15_q;
	restoring_subtractor RS_lEnd_15(div_st14_s[62], 1'b0, div_st15_b[62], out_q[47], div_st15_s[63], div_st15_b[63], div_st15_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_15
			restoring_subtractor RS_15(div_st14_s[i-1], in_d[i], div_st15_b[i-1], div_st15_q[i+1], div_st15_s[i], div_st15_b[i], div_st15_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_15(1'b0, in_d[0], 1'b0, div_st15_q[1], div_st15_s[0], div_st15_b[0], div_st15_q[0]);
	assign out_q[47] = ~div_st15_b[63];
	// Stage 16 : 2^-2
	wire [63:0] div_st16_s;
	wire [63:0] div_st16_b;
	wire [63:0] div_st16_q;
	restoring_subtractor RS_lEnd_16(div_st15_s[62], 1'b0, div_st16_b[62], out_q[46], div_st16_s[63], div_st16_b[63], div_st16_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_16
			restoring_subtractor RS_16(div_st15_s[i-1], in_d[i], div_st16_b[i-1], div_st16_q[i+1], div_st16_s[i], div_st16_b[i], div_st16_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_16(1'b0, in_d[0], 1'b0, div_st16_q[1], div_st16_s[0], div_st16_b[0], div_st16_q[0]);
	assign out_q[46] = ~div_st16_b[63];
	// Stage 17 : 2^-3
	wire [63:0] div_st17_s;
	wire [63:0] div_st17_b;
	wire [63:0] div_st17_q;
	restoring_subtractor RS_lEnd_17(div_st16_s[62], 1'b0, div_st17_b[62], out_q[45], div_st17_s[63], div_st17_b[63], div_st17_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_17
			restoring_subtractor RS_17(div_st16_s[i-1], in_d[i], div_st17_b[i-1], div_st17_q[i+1], div_st17_s[i], div_st17_b[i], div_st17_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_17(1'b0, in_d[0], 1'b0, div_st17_q[1], div_st17_s[0], div_st17_b[0], div_st17_q[0]);
	assign out_q[45] = ~div_st17_b[63];
	// Stage 18 : 2^-4
	wire [63:0] div_st18_s;
	wire [63:0] div_st18_b;
	wire [63:0] div_st18_q;
	restoring_subtractor RS_lEnd_18(div_st17_s[62], 1'b0, div_st18_b[62], out_q[44], div_st18_s[63], div_st18_b[63], div_st18_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_18
			restoring_subtractor RS_18(div_st17_s[i-1], in_d[i], div_st18_b[i-1], div_st18_q[i+1], div_st18_s[i], div_st18_b[i], div_st18_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_18(1'b0, in_d[0], 1'b0, div_st18_q[1], div_st18_s[0], div_st18_b[0], div_st18_q[0]);
	assign out_q[44] = ~div_st18_b[63];
	// Stage 19 : 2^-5
	wire [63:0] div_st19_s;
	wire [63:0] div_st19_b;
	wire [63:0] div_st19_q;
	restoring_subtractor RS_lEnd_19(div_st18_s[62], 1'b0, div_st19_b[62], out_q[43], div_st19_s[63], div_st19_b[63], div_st19_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_19
			restoring_subtractor RS_19(div_st18_s[i-1], in_d[i], div_st19_b[i-1], div_st19_q[i+1], div_st19_s[i], div_st19_b[i], div_st19_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_19(1'b0, in_d[0], 1'b0, div_st19_q[1], div_st19_s[0], div_st19_b[0], div_st19_q[0]);
	assign out_q[43] = ~div_st19_b[63];
	// Stage 20 : 2^-6
	wire [63:0] div_st20_s;
	wire [63:0] div_st20_b;
	wire [63:0] div_st20_q;
	restoring_subtractor RS_lEnd_20(div_st19_s[62], 1'b0, div_st20_b[62], out_q[42], div_st20_s[63], div_st20_b[63], div_st20_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_20
			restoring_subtractor RS_20(div_st19_s[i-1], in_d[i], div_st20_b[i-1], div_st20_q[i+1], div_st20_s[i], div_st20_b[i], div_st20_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_20(1'b0, in_d[0], 1'b0, div_st20_q[1], div_st20_s[0], div_st20_b[0], div_st20_q[0]);
	assign out_q[42] = ~div_st20_b[63];
	// Stage 21 : 2^-7
	wire [63:0] div_st21_s;
	wire [63:0] div_st21_b;
	wire [63:0] div_st21_q;
	restoring_subtractor RS_lEnd_21(div_st20_s[62], 1'b0, div_st21_b[62], out_q[41], div_st21_s[63], div_st21_b[63], div_st21_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_21
			restoring_subtractor RS_21(div_st20_s[i-1], in_d[i], div_st21_b[i-1], div_st21_q[i+1], div_st21_s[i], div_st21_b[i], div_st21_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_21(1'b0, in_d[0], 1'b0, div_st21_q[1], div_st21_s[0], div_st21_b[0], div_st21_q[0]);
	assign out_q[41] = ~div_st21_b[63];
	// Stage 22 : 2^-8
	wire [63:0] div_st22_s;
	wire [63:0] div_st22_b;
	wire [63:0] div_st22_q;
	restoring_subtractor RS_lEnd_22(div_st21_s[62], 1'b0, div_st22_b[62], out_q[40], div_st22_s[63], div_st22_b[63], div_st22_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_22
			restoring_subtractor RS_22(div_st21_s[i-1], in_d[i], div_st22_b[i-1], div_st22_q[i+1], div_st22_s[i], div_st22_b[i], div_st22_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_22(1'b0, in_d[0], 1'b0, div_st22_q[1], div_st22_s[0], div_st22_b[0], div_st22_q[0]);
	assign out_q[40] = ~div_st22_b[63];
	// Stage 23 : 2^-9
	wire [63:0] div_st23_s;
	wire [63:0] div_st23_b;
	wire [63:0] div_st23_q;
	restoring_subtractor RS_lEnd_23(div_st22_s[62], 1'b0, div_st23_b[62], out_q[39], div_st23_s[63], div_st23_b[63], div_st23_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_23
			restoring_subtractor RS_23(div_st22_s[i-1], in_d[i], div_st23_b[i-1], div_st23_q[i+1], div_st23_s[i], div_st23_b[i], div_st23_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_23(1'b0, in_d[0], 1'b0, div_st23_q[1], div_st23_s[0], div_st23_b[0], div_st23_q[0]);
	assign out_q[39] = ~div_st23_b[63];
	// Stage 24 : 2^-10
	wire [63:0] div_st24_s;
	wire [63:0] div_st24_b;
	wire [63:0] div_st24_q;
	restoring_subtractor RS_lEnd_24(div_st23_s[62], 1'b0, div_st24_b[62], out_q[38], div_st24_s[63], div_st24_b[63], div_st24_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_24
			restoring_subtractor RS_24(div_st23_s[i-1], in_d[i], div_st24_b[i-1], div_st24_q[i+1], div_st24_s[i], div_st24_b[i], div_st24_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_24(1'b0, in_d[0], 1'b0, div_st24_q[1], div_st24_s[0], div_st24_b[0], div_st24_q[0]);
	assign out_q[38] = ~div_st24_b[63];
	// Stage 25 : 2^-11
	wire [63:0] div_st25_s;
	wire [63:0] div_st25_b;
	wire [63:0] div_st25_q;
	restoring_subtractor RS_lEnd_25(div_st24_s[62], 1'b0, div_st25_b[62], out_q[37], div_st25_s[63], div_st25_b[63], div_st25_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_25
			restoring_subtractor RS_25(div_st24_s[i-1], in_d[i], div_st25_b[i-1], div_st25_q[i+1], div_st25_s[i], div_st25_b[i], div_st25_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_25(1'b0, in_d[0], 1'b0, div_st25_q[1], div_st25_s[0], div_st25_b[0], div_st25_q[0]);
	assign out_q[37] = ~div_st25_b[63];
	// Stage 26 : 2^-12
	wire [63:0] div_st26_s;
	wire [63:0] div_st26_b;
	wire [63:0] div_st26_q;
	restoring_subtractor RS_lEnd_26(div_st25_s[62], 1'b0, div_st26_b[62], out_q[36], div_st26_s[63], div_st26_b[63], div_st26_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_26
			restoring_subtractor RS_26(div_st25_s[i-1], in_d[i], div_st26_b[i-1], div_st26_q[i+1], div_st26_s[i], div_st26_b[i], div_st26_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_26(1'b0, in_d[0], 1'b0, div_st26_q[1], div_st26_s[0], div_st26_b[0], div_st26_q[0]);
	assign out_q[36] = ~div_st26_b[63];
	// Stage 27 : 2^-13
	wire [63:0] div_st27_s;
	wire [63:0] div_st27_b;
	wire [63:0] div_st27_q;
	restoring_subtractor RS_lEnd_27(div_st26_s[62], 1'b0, div_st27_b[62], out_q[35], div_st27_s[63], div_st27_b[63], div_st27_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_27
			restoring_subtractor RS_27(div_st26_s[i-1], in_d[i], div_st27_b[i-1], div_st27_q[i+1], div_st27_s[i], div_st27_b[i], div_st27_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_27(1'b0, in_d[0], 1'b0, div_st27_q[1], div_st27_s[0], div_st27_b[0], div_st27_q[0]);
	assign out_q[35] = ~div_st27_b[63];
	// Stage 28 : 2^-14
	wire [63:0] div_st28_s;
	wire [63:0] div_st28_b;
	wire [63:0] div_st28_q;
	restoring_subtractor RS_lEnd_28(div_st27_s[62], 1'b0, div_st28_b[62], out_q[34], div_st28_s[63], div_st28_b[63], div_st28_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_28
			restoring_subtractor RS_28(div_st27_s[i-1], in_d[i], div_st28_b[i-1], div_st28_q[i+1], div_st28_s[i], div_st28_b[i], div_st28_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_28(1'b0, in_d[0], 1'b0, div_st28_q[1], div_st28_s[0], div_st28_b[0], div_st28_q[0]);
	assign out_q[34] = ~div_st28_b[63];
	// Stage 29 : 2^-15
	wire [63:0] div_st29_s;
	wire [63:0] div_st29_b;
	wire [63:0] div_st29_q;
	restoring_subtractor RS_lEnd_29(div_st28_s[62], 1'b0, div_st29_b[62], out_q[33], div_st29_s[63], div_st29_b[63], div_st29_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_29
			restoring_subtractor RS_29(div_st28_s[i-1], in_d[i], div_st29_b[i-1], div_st29_q[i+1], div_st29_s[i], div_st29_b[i], div_st29_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_29(1'b0, in_d[0], 1'b0, div_st29_q[1], div_st29_s[0], div_st29_b[0], div_st29_q[0]);
	assign out_q[33] = ~div_st29_b[63];
	// Stage 30 : 2^-16
	wire [63:0] div_st30_s;
	wire [63:0] div_st30_b;
	wire [63:0] div_st30_q;
	restoring_subtractor RS_lEnd_30(div_st29_s[62], 1'b0, div_st30_b[62], out_q[32], div_st30_s[63], div_st30_b[63], div_st30_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_30
			restoring_subtractor RS_30(div_st29_s[i-1], in_d[i], div_st30_b[i-1], div_st30_q[i+1], div_st30_s[i], div_st30_b[i], div_st30_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_30(1'b0, in_d[0], 1'b0, div_st30_q[1], div_st30_s[0], div_st30_b[0], div_st30_q[0]);
	assign out_q[32] = ~div_st30_b[63];
	// Stage 31 : 2^-17
	wire [63:0] div_st31_s;
	wire [63:0] div_st31_b;
	wire [63:0] div_st31_q;
	restoring_subtractor RS_lEnd_31(div_st30_s[62], 1'b0, div_st31_b[62], out_q[31], div_st31_s[63], div_st31_b[63], div_st31_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_31
			restoring_subtractor RS_31(div_st30_s[i-1], in_d[i], div_st31_b[i-1], div_st31_q[i+1], div_st31_s[i], div_st31_b[i], div_st31_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_31(1'b0, in_d[0], 1'b0, div_st31_q[1], div_st31_s[0], div_st31_b[0], div_st31_q[0]);
	assign out_q[31] = ~div_st31_b[63];
	// Stage 32 : 2^-18
	wire [63:0] div_st32_s;
	wire [63:0] div_st32_b;
	wire [63:0] div_st32_q;
	restoring_subtractor RS_lEnd_32(div_st31_s[62], 1'b0, div_st32_b[62], out_q[30], div_st32_s[63], div_st32_b[63], div_st32_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_32
			restoring_subtractor RS_32(div_st31_s[i-1], in_d[i], div_st32_b[i-1], div_st32_q[i+1], div_st32_s[i], div_st32_b[i], div_st32_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_32(1'b0, in_d[0], 1'b0, div_st32_q[1], div_st32_s[0], div_st32_b[0], div_st32_q[0]);
	assign out_q[30] = ~div_st32_b[63];
	// Stage 33 : 2^-19
	wire [63:0] div_st33_s;
	wire [63:0] div_st33_b;
	wire [63:0] div_st33_q;
	restoring_subtractor RS_lEnd_33(div_st32_s[62], 1'b0, div_st33_b[62], out_q[29], div_st33_s[63], div_st33_b[63], div_st33_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_33
			restoring_subtractor RS_33(div_st32_s[i-1], in_d[i], div_st33_b[i-1], div_st33_q[i+1], div_st33_s[i], div_st33_b[i], div_st33_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_33(1'b0, in_d[0], 1'b0, div_st33_q[1], div_st33_s[0], div_st33_b[0], div_st33_q[0]);
	assign out_q[29] = ~div_st33_b[63];
	// Stage 34 : 2^-20
	wire [63:0] div_st34_s;
	wire [63:0] div_st34_b;
	wire [63:0] div_st34_q;
	restoring_subtractor RS_lEnd_34(div_st33_s[62], 1'b0, div_st34_b[62], out_q[28], div_st34_s[63], div_st34_b[63], div_st34_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_34
			restoring_subtractor RS_34(div_st33_s[i-1], in_d[i], div_st34_b[i-1], div_st34_q[i+1], div_st34_s[i], div_st34_b[i], div_st34_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_34(1'b0, in_d[0], 1'b0, div_st34_q[1], div_st34_s[0], div_st34_b[0], div_st34_q[0]);
	assign out_q[28] = ~div_st34_b[63];
	// Stage 35 : 2^-21
	wire [63:0] div_st35_s;
	wire [63:0] div_st35_b;
	wire [63:0] div_st35_q;
	restoring_subtractor RS_lEnd_35(div_st34_s[62], 1'b0, div_st35_b[62], out_q[27], div_st35_s[63], div_st35_b[63], div_st35_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_35
			restoring_subtractor RS_35(div_st34_s[i-1], in_d[i], div_st35_b[i-1], div_st35_q[i+1], div_st35_s[i], div_st35_b[i], div_st35_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_35(1'b0, in_d[0], 1'b0, div_st35_q[1], div_st35_s[0], div_st35_b[0], div_st35_q[0]);
	assign out_q[27] = ~div_st35_b[63];
	// Stage 36 : 2^-22
	wire [63:0] div_st36_s;
	wire [63:0] div_st36_b;
	wire [63:0] div_st36_q;
	restoring_subtractor RS_lEnd_36(div_st35_s[62], 1'b0, div_st36_b[62], out_q[26], div_st36_s[63], div_st36_b[63], div_st36_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_36
			restoring_subtractor RS_36(div_st35_s[i-1], in_d[i], div_st36_b[i-1], div_st36_q[i+1], div_st36_s[i], div_st36_b[i], div_st36_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_36(1'b0, in_d[0], 1'b0, div_st36_q[1], div_st36_s[0], div_st36_b[0], div_st36_q[0]);
	assign out_q[26] = ~div_st36_b[63];
	// Stage 37 : 2^-23
	wire [63:0] div_st37_s;
	wire [63:0] div_st37_b;
	wire [63:0] div_st37_q;
	restoring_subtractor RS_lEnd_37(div_st36_s[62], 1'b0, div_st37_b[62], out_q[25], div_st37_s[63], div_st37_b[63], div_st37_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_37
			restoring_subtractor RS_37(div_st36_s[i-1], in_d[i], div_st37_b[i-1], div_st37_q[i+1], div_st37_s[i], div_st37_b[i], div_st37_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_37(1'b0, in_d[0], 1'b0, div_st37_q[1], div_st37_s[0], div_st37_b[0], div_st37_q[0]);
	assign out_q[25] = ~div_st37_b[63];
	// Stage 38 : 2^-24
	wire [63:0] div_st38_s;
	wire [63:0] div_st38_b;
	wire [63:0] div_st38_q;
	restoring_subtractor RS_lEnd_38(div_st37_s[62], 1'b0, div_st38_b[62], out_q[24], div_st38_s[63], div_st38_b[63], div_st38_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_38
			restoring_subtractor RS_38(div_st37_s[i-1], in_d[i], div_st38_b[i-1], div_st38_q[i+1], div_st38_s[i], div_st38_b[i], div_st38_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_38(1'b0, in_d[0], 1'b0, div_st38_q[1], div_st38_s[0], div_st38_b[0], div_st38_q[0]);
	assign out_q[24] = ~div_st38_b[63];
	// Stage 39 : 2^-25
	wire [63:0] div_st39_s;
	wire [63:0] div_st39_b;
	wire [63:0] div_st39_q;
	restoring_subtractor RS_lEnd_39(div_st38_s[62], 1'b0, div_st39_b[62], out_q[23], div_st39_s[63], div_st39_b[63], div_st39_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_39
			restoring_subtractor RS_39(div_st38_s[i-1], in_d[i], div_st39_b[i-1], div_st39_q[i+1], div_st39_s[i], div_st39_b[i], div_st39_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_39(1'b0, in_d[0], 1'b0, div_st39_q[1], div_st39_s[0], div_st39_b[0], div_st39_q[0]);
	assign out_q[23] = ~div_st39_b[63];
	// Stage 40 : 2^-26
	wire [63:0] div_st40_s;
	wire [63:0] div_st40_b;
	wire [63:0] div_st40_q;
	restoring_subtractor RS_lEnd_40(div_st39_s[62], 1'b0, div_st40_b[62], out_q[22], div_st40_s[63], div_st40_b[63], div_st40_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_40
			restoring_subtractor RS_40(div_st39_s[i-1], in_d[i], div_st40_b[i-1], div_st40_q[i+1], div_st40_s[i], div_st40_b[i], div_st40_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_40(1'b0, in_d[0], 1'b0, div_st40_q[1], div_st40_s[0], div_st40_b[0], div_st40_q[0]);
	assign out_q[22] = ~div_st40_b[63];
	// Stage 41 : 2^-27
	wire [63:0] div_st41_s;
	wire [63:0] div_st41_b;
	wire [63:0] div_st41_q;
	restoring_subtractor RS_lEnd_41(div_st40_s[62], 1'b0, div_st41_b[62], out_q[21], div_st41_s[63], div_st41_b[63], div_st41_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_41
			restoring_subtractor RS_41(div_st40_s[i-1], in_d[i], div_st41_b[i-1], div_st41_q[i+1], div_st41_s[i], div_st41_b[i], div_st41_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_41(1'b0, in_d[0], 1'b0, div_st41_q[1], div_st41_s[0], div_st41_b[0], div_st41_q[0]);
	assign out_q[21] = ~div_st41_b[63];
	// Stage 42 : 2^-28
	wire [63:0] div_st42_s;
	wire [63:0] div_st42_b;
	wire [63:0] div_st42_q;
	restoring_subtractor RS_lEnd_42(div_st41_s[62], 1'b0, div_st42_b[62], out_q[20], div_st42_s[63], div_st42_b[63], div_st42_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_42
			restoring_subtractor RS_42(div_st41_s[i-1], in_d[i], div_st42_b[i-1], div_st42_q[i+1], div_st42_s[i], div_st42_b[i], div_st42_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_42(1'b0, in_d[0], 1'b0, div_st42_q[1], div_st42_s[0], div_st42_b[0], div_st42_q[0]);
	assign out_q[20] = ~div_st42_b[63];
	// Stage 43 : 2^-29
	wire [63:0] div_st43_s;
	wire [63:0] div_st43_b;
	wire [63:0] div_st43_q;
	restoring_subtractor RS_lEnd_43(div_st42_s[62], 1'b0, div_st43_b[62], out_q[19], div_st43_s[63], div_st43_b[63], div_st43_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_43
			restoring_subtractor RS_43(div_st42_s[i-1], in_d[i], div_st43_b[i-1], div_st43_q[i+1], div_st43_s[i], div_st43_b[i], div_st43_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_43(1'b0, in_d[0], 1'b0, div_st43_q[1], div_st43_s[0], div_st43_b[0], div_st43_q[0]);
	assign out_q[19] = ~div_st43_b[63];
	// Stage 44 : 2^-30
	wire [63:0] div_st44_s;
	wire [63:0] div_st44_b;
	wire [63:0] div_st44_q;
	restoring_subtractor RS_lEnd_44(div_st43_s[62], 1'b0, div_st44_b[62], out_q[18], div_st44_s[63], div_st44_b[63], div_st44_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_44
			restoring_subtractor RS_44(div_st43_s[i-1], in_d[i], div_st44_b[i-1], div_st44_q[i+1], div_st44_s[i], div_st44_b[i], div_st44_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_44(1'b0, in_d[0], 1'b0, div_st44_q[1], div_st44_s[0], div_st44_b[0], div_st44_q[0]);
	assign out_q[18] = ~div_st44_b[63];
	// Stage 45 : 2^-31
	wire [63:0] div_st45_s;
	wire [63:0] div_st45_b;
	wire [63:0] div_st45_q;
	restoring_subtractor RS_lEnd_45(div_st44_s[62], 1'b0, div_st45_b[62], out_q[17], div_st45_s[63], div_st45_b[63], div_st45_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_45
			restoring_subtractor RS_45(div_st44_s[i-1], in_d[i], div_st45_b[i-1], div_st45_q[i+1], div_st45_s[i], div_st45_b[i], div_st45_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_45(1'b0, in_d[0], 1'b0, div_st45_q[1], div_st45_s[0], div_st45_b[0], div_st45_q[0]);
	assign out_q[17] = ~div_st45_b[63];
	// Stage 46 : 2^-32
	wire [63:0] div_st46_s;
	wire [63:0] div_st46_b;
	wire [63:0] div_st46_q;
	restoring_subtractor RS_lEnd_46(div_st45_s[62], 1'b0, div_st46_b[62], out_q[16], div_st46_s[63], div_st46_b[63], div_st46_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_46
			restoring_subtractor RS_46(div_st45_s[i-1], in_d[i], div_st46_b[i-1], div_st46_q[i+1], div_st46_s[i], div_st46_b[i], div_st46_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_46(1'b0, in_d[0], 1'b0, div_st46_q[1], div_st46_s[0], div_st46_b[0], div_st46_q[0]);
	assign out_q[16] = ~div_st46_b[63];
	// Stage 47 : 2^-33
	wire [63:0] div_st47_s;
	wire [63:0] div_st47_b;
	wire [63:0] div_st47_q;
	restoring_subtractor RS_lEnd_47(div_st46_s[62], 1'b0, div_st47_b[62], out_q[15], div_st47_s[63], div_st47_b[63], div_st47_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_47
			restoring_subtractor RS_47(div_st46_s[i-1], in_d[i], div_st47_b[i-1], div_st47_q[i+1], div_st47_s[i], div_st47_b[i], div_st47_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_47(1'b0, in_d[0], 1'b0, div_st47_q[1], div_st47_s[0], div_st47_b[0], div_st47_q[0]);
	assign out_q[15] = ~div_st47_b[63];
	// Stage 48 : 2^-34
	wire [63:0] div_st48_s;
	wire [63:0] div_st48_b;
	wire [63:0] div_st48_q;
	restoring_subtractor RS_lEnd_48(div_st47_s[62], 1'b0, div_st48_b[62], out_q[14], div_st48_s[63], div_st48_b[63], div_st48_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_48
			restoring_subtractor RS_48(div_st47_s[i-1], in_d[i], div_st48_b[i-1], div_st48_q[i+1], div_st48_s[i], div_st48_b[i], div_st48_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_48(1'b0, in_d[0], 1'b0, div_st48_q[1], div_st48_s[0], div_st48_b[0], div_st48_q[0]);
	assign out_q[14] = ~div_st48_b[63];
	// Stage 49 : 2^-35
	wire [63:0] div_st49_s;
	wire [63:0] div_st49_b;
	wire [63:0] div_st49_q;
	restoring_subtractor RS_lEnd_49(div_st48_s[62], 1'b0, div_st49_b[62], out_q[13], div_st49_s[63], div_st49_b[63], div_st49_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_49
			restoring_subtractor RS_49(div_st48_s[i-1], in_d[i], div_st49_b[i-1], div_st49_q[i+1], div_st49_s[i], div_st49_b[i], div_st49_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_49(1'b0, in_d[0], 1'b0, div_st49_q[1], div_st49_s[0], div_st49_b[0], div_st49_q[0]);
	assign out_q[13] = ~div_st49_b[63];
	// Stage 50 : 2^-36
	wire [63:0] div_st50_s;
	wire [63:0] div_st50_b;
	wire [63:0] div_st50_q;
	restoring_subtractor RS_lEnd_50(div_st49_s[62], 1'b0, div_st50_b[62], out_q[12], div_st50_s[63], div_st50_b[63], div_st50_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_50
			restoring_subtractor RS_50(div_st49_s[i-1], in_d[i], div_st50_b[i-1], div_st50_q[i+1], div_st50_s[i], div_st50_b[i], div_st50_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_50(1'b0, in_d[0], 1'b0, div_st50_q[1], div_st50_s[0], div_st50_b[0], div_st50_q[0]);
	assign out_q[12] = ~div_st50_b[63];
	// Stage 51 : 2^-37
	wire [63:0] div_st51_s;
	wire [63:0] div_st51_b;
	wire [63:0] div_st51_q;
	restoring_subtractor RS_lEnd_51(div_st50_s[62], 1'b0, div_st51_b[62], out_q[11], div_st51_s[63], div_st51_b[63], div_st51_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_51
			restoring_subtractor RS_51(div_st50_s[i-1], in_d[i], div_st51_b[i-1], div_st51_q[i+1], div_st51_s[i], div_st51_b[i], div_st51_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_51(1'b0, in_d[0], 1'b0, div_st51_q[1], div_st51_s[0], div_st51_b[0], div_st51_q[0]);
	assign out_q[11] = ~div_st51_b[63];
	// Stage 52 : 2^-38
	wire [63:0] div_st52_s;
	wire [63:0] div_st52_b;
	wire [63:0] div_st52_q;
	restoring_subtractor RS_lEnd_52(div_st51_s[62], 1'b0, div_st52_b[62], out_q[10], div_st52_s[63], div_st52_b[63], div_st52_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_52
			restoring_subtractor RS_52(div_st51_s[i-1], in_d[i], div_st52_b[i-1], div_st52_q[i+1], div_st52_s[i], div_st52_b[i], div_st52_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_52(1'b0, in_d[0], 1'b0, div_st52_q[1], div_st52_s[0], div_st52_b[0], div_st52_q[0]);
	assign out_q[10] = ~div_st52_b[63];
	// Stage 53 : 2^-39
	wire [63:0] div_st53_s;
	wire [63:0] div_st53_b;
	wire [63:0] div_st53_q;
	restoring_subtractor RS_lEnd_53(div_st52_s[62], 1'b0, div_st53_b[62], out_q[9], div_st53_s[63], div_st53_b[63], div_st53_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_53
			restoring_subtractor RS_53(div_st52_s[i-1], in_d[i], div_st53_b[i-1], div_st53_q[i+1], div_st53_s[i], div_st53_b[i], div_st53_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_53(1'b0, in_d[0], 1'b0, div_st53_q[1], div_st53_s[0], div_st53_b[0], div_st53_q[0]);
	assign out_q[9] = ~div_st53_b[63];
	// Stage 54 : 2^-40
	wire [63:0] div_st54_s;
	wire [63:0] div_st54_b;
	wire [63:0] div_st54_q;
	restoring_subtractor RS_lEnd_54(div_st53_s[62], 1'b0, div_st54_b[62], out_q[8], div_st54_s[63], div_st54_b[63], div_st54_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_54
			restoring_subtractor RS_54(div_st53_s[i-1], in_d[i], div_st54_b[i-1], div_st54_q[i+1], div_st54_s[i], div_st54_b[i], div_st54_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_54(1'b0, in_d[0], 1'b0, div_st54_q[1], div_st54_s[0], div_st54_b[0], div_st54_q[0]);
	assign out_q[8] = ~div_st54_b[63];
	// Stage 55 : 2^-41
	wire [63:0] div_st55_s;
	wire [63:0] div_st55_b;
	wire [63:0] div_st55_q;
	restoring_subtractor RS_lEnd_55(div_st54_s[62], 1'b0, div_st55_b[62], out_q[7], div_st55_s[63], div_st55_b[63], div_st55_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_55
			restoring_subtractor RS_55(div_st54_s[i-1], in_d[i], div_st55_b[i-1], div_st55_q[i+1], div_st55_s[i], div_st55_b[i], div_st55_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_55(1'b0, in_d[0], 1'b0, div_st55_q[1], div_st55_s[0], div_st55_b[0], div_st55_q[0]);
	assign out_q[7] = ~div_st55_b[63];
	// Stage 56 : 2^-42
	wire [63:0] div_st56_s;
	wire [63:0] div_st56_b;
	wire [63:0] div_st56_q;
	restoring_subtractor RS_lEnd_56(div_st55_s[62], 1'b0, div_st56_b[62], out_q[6], div_st56_s[63], div_st56_b[63], div_st56_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_56
			restoring_subtractor RS_56(div_st55_s[i-1], in_d[i], div_st56_b[i-1], div_st56_q[i+1], div_st56_s[i], div_st56_b[i], div_st56_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_56(1'b0, in_d[0], 1'b0, div_st56_q[1], div_st56_s[0], div_st56_b[0], div_st56_q[0]);
	assign out_q[6] = ~div_st56_b[63];
	// Stage 57 : 2^-43
	wire [63:0] div_st57_s;
	wire [63:0] div_st57_b;
	wire [63:0] div_st57_q;
	restoring_subtractor RS_lEnd_57(div_st56_s[62], 1'b0, div_st57_b[62], out_q[5], div_st57_s[63], div_st57_b[63], div_st57_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_57
			restoring_subtractor RS_57(div_st56_s[i-1], in_d[i], div_st57_b[i-1], div_st57_q[i+1], div_st57_s[i], div_st57_b[i], div_st57_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_57(1'b0, in_d[0], 1'b0, div_st57_q[1], div_st57_s[0], div_st57_b[0], div_st57_q[0]);
	assign out_q[5] = ~div_st57_b[63];
	// Stage 58 : 2^-44
	wire [63:0] div_st58_s;
	wire [63:0] div_st58_b;
	wire [63:0] div_st58_q;
	restoring_subtractor RS_lEnd_58(div_st57_s[62], 1'b0, div_st58_b[62], out_q[4], div_st58_s[63], div_st58_b[63], div_st58_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_58
			restoring_subtractor RS_58(div_st57_s[i-1], in_d[i], div_st58_b[i-1], div_st58_q[i+1], div_st58_s[i], div_st58_b[i], div_st58_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_58(1'b0, in_d[0], 1'b0, div_st58_q[1], div_st58_s[0], div_st58_b[0], div_st58_q[0]);
	assign out_q[4] = ~div_st58_b[63];
	// Stage 59 : 2^-45
	wire [63:0] div_st59_s;
	wire [63:0] div_st59_b;
	wire [63:0] div_st59_q;
	restoring_subtractor RS_lEnd_59(div_st58_s[62], 1'b0, div_st59_b[62], out_q[3], div_st59_s[63], div_st59_b[63], div_st59_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_59
			restoring_subtractor RS_59(div_st58_s[i-1], in_d[i], div_st59_b[i-1], div_st59_q[i+1], div_st59_s[i], div_st59_b[i], div_st59_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_59(1'b0, in_d[0], 1'b0, div_st59_q[1], div_st59_s[0], div_st59_b[0], div_st59_q[0]);
	assign out_q[3] = ~div_st59_b[63];
	// Stage 60 : 2^-46
	wire [63:0] div_st60_s;
	wire [63:0] div_st60_b;
	wire [63:0] div_st60_q;
	restoring_subtractor RS_lEnd_60(div_st59_s[62], 1'b0, div_st60_b[62], out_q[2], div_st60_s[63], div_st60_b[63], div_st60_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_60
			restoring_subtractor RS_60(div_st59_s[i-1], in_d[i], div_st60_b[i-1], div_st60_q[i+1], div_st60_s[i], div_st60_b[i], div_st60_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_60(1'b0, in_d[0], 1'b0, div_st60_q[1], div_st60_s[0], div_st60_b[0], div_st60_q[0]);
	assign out_q[2] = ~div_st60_b[63];
	// Stage 61 : 2^-47
	wire [63:0] div_st61_s;
	wire [63:0] div_st61_b;
	wire [63:0] div_st61_q;
	restoring_subtractor RS_lEnd_61(div_st60_s[62], 1'b0, div_st61_b[62], out_q[1], div_st61_s[63], div_st61_b[63], div_st61_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_61
			restoring_subtractor RS_61(div_st60_s[i-1], in_d[i], div_st61_b[i-1], div_st61_q[i+1], div_st61_s[i], div_st61_b[i], div_st61_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_61(1'b0, in_d[0], 1'b0, div_st61_q[1], div_st61_s[0], div_st61_b[0], div_st61_q[0]);
	assign out_q[1] = ~div_st61_b[63];
	// Stage 62 : 2^-48
	wire [63:0] div_st62_s;
	wire [63:0] div_st62_b;
	wire [63:0] div_st62_q;
	restoring_subtractor RS_lEnd_62(div_st61_s[62], 1'b0, div_st62_b[62], out_q[0], div_st62_s[63], div_st62_b[63], div_st62_q[63]);
	generate
		for (i=62; i>0; i=i-1) begin : RS_ROW_N_USED_62
			restoring_subtractor RS_62(div_st61_s[i-1], in_d[i], div_st62_b[i-1], div_st62_q[i+1], div_st62_s[i], div_st62_b[i], div_st62_q[i]);
		end
	endgenerate
	restoring_subtractor RS_rEnd_62(1'b0, in_d[0], 1'b0, div_st62_q[1], div_st62_s[0], div_st62_b[0], div_st62_q[0]);
	assign out_q[0] = ~div_st62_b[63];
	assign div_by_zero = ~|in_d;
	assign out_q[63] = in_n[63] ^ in_d[63];

endmodule
