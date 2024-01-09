// IO Params
`define FXP8S_ADDR 7:0
`define FXP8S_WIDTH 8
`define FXP8S_SIGN 7
`define FXP8S_MAG 6:0
`define FXP8S_LSB_POW -3

module fxp8s_dadda(
	input clk,
	input rstn,
	input [`FXP8S_ADDR] in_a,		// Sign-Mag
	input [`FXP8S_ADDR] in_b,		// Sign-Mag
	output [`FXP8S_ADDR] out_s,
	output out_overflow
);

	wire neg_out;
	assign neg_out = in_a[`FXP8S_SIGN] ^ in_b[`FXP8S_SIGN];
	wire [`FXP8S_ADDR] a, b;
	assign a[`FXP8S_SIGN] = 1'b0;
	assign a[`FXP8S_MAG] = in_a[`FXP8S_MAG];
	assign b[`FXP8S_SIGN] = 1'b0;
	assign b[`FXP8S_MAG] = in_b[`FXP8S_MAG];

	wire [0:0] dm_int_st0_0;
	wire [1:0] dm_int_st0_1;
	wire [2:0] dm_int_st0_2;
	wire [3:0] dm_int_st0_3;
	wire [4:0] dm_int_st0_4;
	wire [5:0] dm_int_st0_5;
	wire [6:0] dm_int_st0_6;
	wire [7:0] dm_int_st0_7;
	wire [6:0] dm_int_st0_8;
	wire [5:0] dm_int_st0_9;
	wire [4:0] dm_int_st0_10;
	wire [3:0] dm_int_st0_11;
	wire [2:0] dm_int_st0_12;
	wire [1:0] dm_int_st0_13;
	wire [0:0] dm_int_st0_14;

	assign dm_int_st0_0[0] = a[0] & b[0];
	assign dm_int_st0_1[0] = a[0] & b[1];
	assign dm_int_st0_2[0] = a[0] & b[2];
	assign dm_int_st0_3[0] = a[0] & b[3];
	assign dm_int_st0_4[0] = a[0] & b[4];
	assign dm_int_st0_5[0] = a[0] & b[5];
	assign dm_int_st0_6[0] = a[0] & b[6];
	assign dm_int_st0_7[0] = a[0] & b[7];
	assign dm_int_st0_1[1] = a[1] & b[0];
	assign dm_int_st0_2[1] = a[1] & b[1];
	assign dm_int_st0_3[1] = a[1] & b[2];
	assign dm_int_st0_4[1] = a[1] & b[3];
	assign dm_int_st0_5[1] = a[1] & b[4];
	assign dm_int_st0_6[1] = a[1] & b[5];
	assign dm_int_st0_7[1] = a[1] & b[6];
	assign dm_int_st0_8[0] = a[1] & b[7];
	assign dm_int_st0_2[2] = a[2] & b[0];
	assign dm_int_st0_3[2] = a[2] & b[1];
	assign dm_int_st0_4[2] = a[2] & b[2];
	assign dm_int_st0_5[2] = a[2] & b[3];
	assign dm_int_st0_6[2] = a[2] & b[4];
	assign dm_int_st0_7[2] = a[2] & b[5];
	assign dm_int_st0_8[1] = a[2] & b[6];
	assign dm_int_st0_9[0] = a[2] & b[7];
	assign dm_int_st0_3[3] = a[3] & b[0];
	assign dm_int_st0_4[3] = a[3] & b[1];
	assign dm_int_st0_5[3] = a[3] & b[2];
	assign dm_int_st0_6[3] = a[3] & b[3];
	assign dm_int_st0_7[3] = a[3] & b[4];
	assign dm_int_st0_8[2] = a[3] & b[5];
	assign dm_int_st0_9[1] = a[3] & b[6];
	assign dm_int_st0_10[0] = a[3] & b[7];
	assign dm_int_st0_4[4] = a[4] & b[0];
	assign dm_int_st0_5[4] = a[4] & b[1];
	assign dm_int_st0_6[4] = a[4] & b[2];
	assign dm_int_st0_7[4] = a[4] & b[3];
	assign dm_int_st0_8[3] = a[4] & b[4];
	assign dm_int_st0_9[2] = a[4] & b[5];
	assign dm_int_st0_10[1] = a[4] & b[6];
	assign dm_int_st0_11[0] = a[4] & b[7];
	assign dm_int_st0_5[5] = a[5] & b[0];
	assign dm_int_st0_6[5] = a[5] & b[1];
	assign dm_int_st0_7[5] = a[5] & b[2];
	assign dm_int_st0_8[4] = a[5] & b[3];
	assign dm_int_st0_9[3] = a[5] & b[4];
	assign dm_int_st0_10[2] = a[5] & b[5];
	assign dm_int_st0_11[1] = a[5] & b[6];
	assign dm_int_st0_12[0] = a[5] & b[7];
	assign dm_int_st0_6[6] = a[6] & b[0];
	assign dm_int_st0_7[6] = a[6] & b[1];
	assign dm_int_st0_8[5] = a[6] & b[2];
	assign dm_int_st0_9[4] = a[6] & b[3];
	assign dm_int_st0_10[3] = a[6] & b[4];
	assign dm_int_st0_11[2] = a[6] & b[5];
	assign dm_int_st0_12[1] = a[6] & b[6];
	assign dm_int_st0_13[0] = a[6] & b[7];
	assign dm_int_st0_7[7] = a[7] & b[0];
	assign dm_int_st0_8[6] = a[7] & b[1];
	assign dm_int_st0_9[5] = a[7] & b[2];
	assign dm_int_st0_10[4] = a[7] & b[3];
	assign dm_int_st0_11[3] = a[7] & b[4];
	assign dm_int_st0_12[2] = a[7] & b[5];
	assign dm_int_st0_13[1] = a[7] & b[6];
	assign dm_int_st0_14[0] = a[7] & b[7];

	//// Stage 1 ////
	wire [0:0] dm_int_st1_0;
	wire [1:0] dm_int_st1_1;
	wire [2:0] dm_int_st1_2;
	wire [3:0] dm_int_st1_3;
	wire [4:0] dm_int_st1_4;
	wire [5:0] dm_int_st1_5;
	wire [5:0] dm_int_st1_6;
	wire [5:0] dm_int_st1_7;
	wire [5:0] dm_int_st1_8;
	wire [5:0] dm_int_st1_9;
	wire [5:0] dm_int_st1_10;
	wire [3:0] dm_int_st1_11;
	wire [2:0] dm_int_st1_12;
	wire [1:0] dm_int_st1_13;
	wire [0:0] dm_int_st1_14;

	// Bit 0
	assign dm_int_st1_0[0] = dm_int_st0_0[0];
	// Bit 1
	assign dm_int_st1_1[0] = dm_int_st0_1[0];
	assign dm_int_st1_1[1] = dm_int_st0_1[1];
	// Bit 2
	assign dm_int_st1_2[0] = dm_int_st0_2[0];
	assign dm_int_st1_2[1] = dm_int_st0_2[1];
	assign dm_int_st1_2[2] = dm_int_st0_2[2];
	// Bit 3
	assign dm_int_st1_3[0] = dm_int_st0_3[0];
	assign dm_int_st1_3[1] = dm_int_st0_3[1];
	assign dm_int_st1_3[2] = dm_int_st0_3[2];
	assign dm_int_st1_3[3] = dm_int_st0_3[3];
	// Bit 4
	assign dm_int_st1_4[0] = dm_int_st0_4[0];
	assign dm_int_st1_4[1] = dm_int_st0_4[1];
	assign dm_int_st1_4[2] = dm_int_st0_4[2];
	assign dm_int_st1_4[3] = dm_int_st0_4[3];
	assign dm_int_st1_4[4] = dm_int_st0_4[4];
	// Bit 5
	assign dm_int_st1_5[0] = dm_int_st0_5[0];
	assign dm_int_st1_5[1] = dm_int_st0_5[1];
	assign dm_int_st1_5[2] = dm_int_st0_5[2];
	assign dm_int_st1_5[3] = dm_int_st0_5[3];
	assign dm_int_st1_5[4] = dm_int_st0_5[4];
	assign dm_int_st1_5[5] = dm_int_st0_5[5];
	// Bit 6
	half_adder HA0(.a(dm_int_st0_6[0]), .b(dm_int_st0_6[1]), .s(dm_int_st1_6[0]), .cout(dm_int_st1_7[0]));
	assign dm_int_st1_6[1] = dm_int_st0_6[2];
	assign dm_int_st1_6[2] = dm_int_st0_6[3];
	assign dm_int_st1_6[3] = dm_int_st0_6[4];
	assign dm_int_st1_6[4] = dm_int_st0_6[5];
	assign dm_int_st1_6[5] = dm_int_st0_6[6];
	// Bit 7
	full_adder FA0(.a(dm_int_st0_7[0]), .b(dm_int_st0_7[1]), .cin(dm_int_st0_7[2]), .s(dm_int_st1_7[1]), .cout(dm_int_st1_8[0]));
	half_adder HA1(.a(dm_int_st0_7[3]), .b(dm_int_st0_7[4]), .s(dm_int_st1_7[2]), .cout(dm_int_st1_8[1]));
	assign dm_int_st1_7[3] = dm_int_st0_7[5];
	assign dm_int_st1_7[4] = dm_int_st0_7[6];
	assign dm_int_st1_7[5] = dm_int_st0_7[7];
	// Bit 8
	full_adder FA1(.a(dm_int_st0_8[0]), .b(dm_int_st0_8[1]), .cin(dm_int_st0_8[2]), .s(dm_int_st1_8[2]), .cout(dm_int_st1_9[0]));
	half_adder HA2(.a(dm_int_st0_8[3]), .b(dm_int_st0_8[4]), .s(dm_int_st1_8[3]), .cout(dm_int_st1_9[1]));
	assign dm_int_st1_8[4] = dm_int_st0_8[5];
	assign dm_int_st1_8[5] = dm_int_st0_8[6];
	// Bit 9
	full_adder FA2(.a(dm_int_st0_9[0]), .b(dm_int_st0_9[1]), .cin(dm_int_st0_9[2]), .s(dm_int_st1_9[2]), .cout(dm_int_st1_10[0]));
	assign dm_int_st1_9[3] = dm_int_st0_9[3];
	assign dm_int_st1_9[4] = dm_int_st0_9[4];
	assign dm_int_st1_9[5] = dm_int_st0_9[5];
	// Bit 10
	assign dm_int_st1_10[1] = dm_int_st0_10[0];
	assign dm_int_st1_10[2] = dm_int_st0_10[1];
	assign dm_int_st1_10[3] = dm_int_st0_10[2];
	assign dm_int_st1_10[4] = dm_int_st0_10[3];
	assign dm_int_st1_10[5] = dm_int_st0_10[4];
	// Bit 11
	assign dm_int_st1_11[0] = dm_int_st0_11[0];
	assign dm_int_st1_11[1] = dm_int_st0_11[1];
	assign dm_int_st1_11[2] = dm_int_st0_11[2];
	assign dm_int_st1_11[3] = dm_int_st0_11[3];
	// Bit 12
	assign dm_int_st1_12[0] = dm_int_st0_12[0];
	assign dm_int_st1_12[1] = dm_int_st0_12[1];
	assign dm_int_st1_12[2] = dm_int_st0_12[2];
	// Bit 13
	assign dm_int_st1_13[0] = dm_int_st0_13[0];
	assign dm_int_st1_13[1] = dm_int_st0_13[1];
	// Bit 14
	assign dm_int_st1_14[0] = dm_int_st0_14[0];

	//// Stage 2 ////
	wire [0:0] dm_int_st2_0;
	wire [1:0] dm_int_st2_1;
	wire [2:0] dm_int_st2_2;
	wire [3:0] dm_int_st2_3;
	wire [3:0] dm_int_st2_4;
	wire [3:0] dm_int_st2_5;
	wire [3:0] dm_int_st2_6;
	wire [3:0] dm_int_st2_7;
	wire [3:0] dm_int_st2_8;
	wire [3:0] dm_int_st2_9;
	wire [3:0] dm_int_st2_10;
	wire [3:0] dm_int_st2_11;
	wire [3:0] dm_int_st2_12;
	wire [1:0] dm_int_st2_13;
	wire [0:0] dm_int_st2_14;

	// Bit 0
	assign dm_int_st2_0[0] = dm_int_st1_0[0];
	// Bit 1
	assign dm_int_st2_1[0] = dm_int_st1_1[0];
	assign dm_int_st2_1[1] = dm_int_st1_1[1];
	// Bit 2
	assign dm_int_st2_2[0] = dm_int_st1_2[0];
	assign dm_int_st2_2[1] = dm_int_st1_2[1];
	assign dm_int_st2_2[2] = dm_int_st1_2[2];
	// Bit 3
	assign dm_int_st2_3[0] = dm_int_st1_3[0];
	assign dm_int_st2_3[1] = dm_int_st1_3[1];
	assign dm_int_st2_3[2] = dm_int_st1_3[2];
	assign dm_int_st2_3[3] = dm_int_st1_3[3];
	// Bit 4
	half_adder HA3(.a(dm_int_st1_4[0]), .b(dm_int_st1_4[1]), .s(dm_int_st2_4[0]), .cout(dm_int_st2_5[0]));
	assign dm_int_st2_4[1] = dm_int_st1_4[2];
	assign dm_int_st2_4[2] = dm_int_st1_4[3];
	assign dm_int_st2_4[3] = dm_int_st1_4[4];
	// Bit 5
	full_adder FA3(.a(dm_int_st1_5[0]), .b(dm_int_st1_5[1]), .cin(dm_int_st1_5[2]), .s(dm_int_st2_5[1]), .cout(dm_int_st2_6[0]));
	half_adder HA4(.a(dm_int_st1_5[3]), .b(dm_int_st1_5[4]), .s(dm_int_st2_5[2]), .cout(dm_int_st2_6[1]));
	assign dm_int_st2_5[3] = dm_int_st1_5[5];
	// Bit 6
	full_adder FA4(.a(dm_int_st1_6[0]), .b(dm_int_st1_6[1]), .cin(dm_int_st1_6[2]), .s(dm_int_st2_6[2]), .cout(dm_int_st2_7[0]));
	full_adder FA5(.a(dm_int_st1_6[3]), .b(dm_int_st1_6[4]), .cin(dm_int_st1_6[5]), .s(dm_int_st2_6[3]), .cout(dm_int_st2_7[1]));
	// Bit 7
	full_adder FA6(.a(dm_int_st1_7[0]), .b(dm_int_st1_7[1]), .cin(dm_int_st1_7[2]), .s(dm_int_st2_7[2]), .cout(dm_int_st2_8[0]));
	full_adder FA7(.a(dm_int_st1_7[3]), .b(dm_int_st1_7[4]), .cin(dm_int_st1_7[5]), .s(dm_int_st2_7[3]), .cout(dm_int_st2_8[1]));
	// Bit 8
	full_adder FA8(.a(dm_int_st1_8[0]), .b(dm_int_st1_8[1]), .cin(dm_int_st1_8[2]), .s(dm_int_st2_8[2]), .cout(dm_int_st2_9[0]));
	full_adder FA9(.a(dm_int_st1_8[3]), .b(dm_int_st1_8[4]), .cin(dm_int_st1_8[5]), .s(dm_int_st2_8[3]), .cout(dm_int_st2_9[1]));
	// Bit 9
	full_adder FA10(.a(dm_int_st1_9[0]), .b(dm_int_st1_9[1]), .cin(dm_int_st1_9[2]), .s(dm_int_st2_9[2]), .cout(dm_int_st2_10[0]));
	full_adder FA11(.a(dm_int_st1_9[3]), .b(dm_int_st1_9[4]), .cin(dm_int_st1_9[5]), .s(dm_int_st2_9[3]), .cout(dm_int_st2_10[1]));
	// Bit 10
	full_adder FA12(.a(dm_int_st1_10[0]), .b(dm_int_st1_10[1]), .cin(dm_int_st1_10[2]), .s(dm_int_st2_10[2]), .cout(dm_int_st2_11[0]));
	full_adder FA13(.a(dm_int_st1_10[3]), .b(dm_int_st1_10[4]), .cin(dm_int_st1_10[5]), .s(dm_int_st2_10[3]), .cout(dm_int_st2_11[1]));
	// Bit 11
	full_adder FA14(.a(dm_int_st1_11[0]), .b(dm_int_st1_11[1]), .cin(dm_int_st1_11[2]), .s(dm_int_st2_11[2]), .cout(dm_int_st2_12[0]));
	assign dm_int_st2_11[3] = dm_int_st1_11[3];
	// Bit 12
	assign dm_int_st2_12[1] = dm_int_st1_12[0];
	assign dm_int_st2_12[2] = dm_int_st1_12[1];
	assign dm_int_st2_12[3] = dm_int_st1_12[2];
	// Bit 13
	assign dm_int_st2_13[0] = dm_int_st1_13[0];
	assign dm_int_st2_13[1] = dm_int_st1_13[1];
	// Bit 14
	assign dm_int_st2_14[0] = dm_int_st1_14[0];

	//// Stage 3 ////
	wire [0:0] dm_int_st3_0;
	wire [1:0] dm_int_st3_1;
	wire [2:0] dm_int_st3_2;
	wire [2:0] dm_int_st3_3;
	wire [2:0] dm_int_st3_4;
	wire [2:0] dm_int_st3_5;
	wire [2:0] dm_int_st3_6;
	wire [2:0] dm_int_st3_7;
	wire [2:0] dm_int_st3_8;
	wire [2:0] dm_int_st3_9;
	wire [2:0] dm_int_st3_10;
	wire [2:0] dm_int_st3_11;
	wire [2:0] dm_int_st3_12;
	wire [2:0] dm_int_st3_13;
	wire [0:0] dm_int_st3_14;

	// Bit 0
	assign dm_int_st3_0[0] = dm_int_st2_0[0];
	// Bit 1
	assign dm_int_st3_1[0] = dm_int_st2_1[0];
	assign dm_int_st3_1[1] = dm_int_st2_1[1];
	// Bit 2
	assign dm_int_st3_2[0] = dm_int_st2_2[0];
	assign dm_int_st3_2[1] = dm_int_st2_2[1];
	assign dm_int_st3_2[2] = dm_int_st2_2[2];
	// Bit 3
	half_adder HA5(.a(dm_int_st2_3[0]), .b(dm_int_st2_3[1]), .s(dm_int_st3_3[0]), .cout(dm_int_st3_4[0]));
	assign dm_int_st3_3[1] = dm_int_st2_3[2];
	assign dm_int_st3_3[2] = dm_int_st2_3[3];
	// Bit 4
	full_adder FA15(.a(dm_int_st2_4[0]), .b(dm_int_st2_4[1]), .cin(dm_int_st2_4[2]), .s(dm_int_st3_4[1]), .cout(dm_int_st3_5[0]));
	assign dm_int_st3_4[2] = dm_int_st2_4[3];
	// Bit 5
	full_adder FA16(.a(dm_int_st2_5[0]), .b(dm_int_st2_5[1]), .cin(dm_int_st2_5[2]), .s(dm_int_st3_5[1]), .cout(dm_int_st3_6[0]));
	assign dm_int_st3_5[2] = dm_int_st2_5[3];
	// Bit 6
	full_adder FA17(.a(dm_int_st2_6[0]), .b(dm_int_st2_6[1]), .cin(dm_int_st2_6[2]), .s(dm_int_st3_6[1]), .cout(dm_int_st3_7[0]));
	assign dm_int_st3_6[2] = dm_int_st2_6[3];
	// Bit 7
	full_adder FA18(.a(dm_int_st2_7[0]), .b(dm_int_st2_7[1]), .cin(dm_int_st2_7[2]), .s(dm_int_st3_7[1]), .cout(dm_int_st3_8[0]));
	assign dm_int_st3_7[2] = dm_int_st2_7[3];
	// Bit 8
	full_adder FA19(.a(dm_int_st2_8[0]), .b(dm_int_st2_8[1]), .cin(dm_int_st2_8[2]), .s(dm_int_st3_8[1]), .cout(dm_int_st3_9[0]));
	assign dm_int_st3_8[2] = dm_int_st2_8[3];
	// Bit 9
	full_adder FA20(.a(dm_int_st2_9[0]), .b(dm_int_st2_9[1]), .cin(dm_int_st2_9[2]), .s(dm_int_st3_9[1]), .cout(dm_int_st3_10[0]));
	assign dm_int_st3_9[2] = dm_int_st2_9[3];
	// Bit 10
	full_adder FA21(.a(dm_int_st2_10[0]), .b(dm_int_st2_10[1]), .cin(dm_int_st2_10[2]), .s(dm_int_st3_10[1]), .cout(dm_int_st3_11[0]));
	assign dm_int_st3_10[2] = dm_int_st2_10[3];
	// Bit 11
	full_adder FA22(.a(dm_int_st2_11[0]), .b(dm_int_st2_11[1]), .cin(dm_int_st2_11[2]), .s(dm_int_st3_11[1]), .cout(dm_int_st3_12[0]));
	assign dm_int_st3_11[2] = dm_int_st2_11[3];
	// Bit 12
	full_adder FA23(.a(dm_int_st2_12[0]), .b(dm_int_st2_12[1]), .cin(dm_int_st2_12[2]), .s(dm_int_st3_12[1]), .cout(dm_int_st3_13[0]));
	assign dm_int_st3_12[2] = dm_int_st2_12[3];
	// Bit 13
	assign dm_int_st3_13[1] = dm_int_st2_13[0];
	assign dm_int_st3_13[2] = dm_int_st2_13[1];
	// Bit 14
	assign dm_int_st3_14[0] = dm_int_st2_14[0];

	//// Stage 4 ////
	wire [0:0] dm_int_st4_0;
	wire [1:0] dm_int_st4_1;
	wire [1:0] dm_int_st4_2;
	wire [1:0] dm_int_st4_3;
	wire [1:0] dm_int_st4_4;
	wire [1:0] dm_int_st4_5;
	wire [1:0] dm_int_st4_6;
	wire [1:0] dm_int_st4_7;
	wire [1:0] dm_int_st4_8;
	wire [1:0] dm_int_st4_9;
	wire [1:0] dm_int_st4_10;
	wire [1:0] dm_int_st4_11;
	wire [1:0] dm_int_st4_12;
	wire [1:0] dm_int_st4_13;
	wire [1:0] dm_int_st4_14;

	// Bit 0
	assign dm_int_st4_0[0] = dm_int_st3_0[0];
	// Bit 1
	assign dm_int_st4_1[0] = dm_int_st3_1[0];
	assign dm_int_st4_1[1] = dm_int_st3_1[1];
	// Bit 2
	half_adder HA6(.a(dm_int_st3_2[0]), .b(dm_int_st3_2[1]), .s(dm_int_st4_2[0]), .cout(dm_int_st4_3[0]));
	assign dm_int_st4_2[1] = dm_int_st3_2[2];
	// Bit 3
	full_adder FA24(.a(dm_int_st3_3[0]), .b(dm_int_st3_3[1]), .cin(dm_int_st3_3[2]), .s(dm_int_st4_3[1]), .cout(dm_int_st4_4[0]));
	// Bit 4
	full_adder FA25(.a(dm_int_st3_4[0]), .b(dm_int_st3_4[1]), .cin(dm_int_st3_4[2]), .s(dm_int_st4_4[1]), .cout(dm_int_st4_5[0]));
	// Bit 5
	full_adder FA26(.a(dm_int_st3_5[0]), .b(dm_int_st3_5[1]), .cin(dm_int_st3_5[2]), .s(dm_int_st4_5[1]), .cout(dm_int_st4_6[0]));
	// Bit 6
	full_adder FA27(.a(dm_int_st3_6[0]), .b(dm_int_st3_6[1]), .cin(dm_int_st3_6[2]), .s(dm_int_st4_6[1]), .cout(dm_int_st4_7[0]));
	// Bit 7
	full_adder FA28(.a(dm_int_st3_7[0]), .b(dm_int_st3_7[1]), .cin(dm_int_st3_7[2]), .s(dm_int_st4_7[1]), .cout(dm_int_st4_8[0]));
	// Bit 8
	full_adder FA29(.a(dm_int_st3_8[0]), .b(dm_int_st3_8[1]), .cin(dm_int_st3_8[2]), .s(dm_int_st4_8[1]), .cout(dm_int_st4_9[0]));
	// Bit 9
	full_adder FA30(.a(dm_int_st3_9[0]), .b(dm_int_st3_9[1]), .cin(dm_int_st3_9[2]), .s(dm_int_st4_9[1]), .cout(dm_int_st4_10[0]));
	// Bit 10
	full_adder FA31(.a(dm_int_st3_10[0]), .b(dm_int_st3_10[1]), .cin(dm_int_st3_10[2]), .s(dm_int_st4_10[1]), .cout(dm_int_st4_11[0]));
	// Bit 11
	full_adder FA32(.a(dm_int_st3_11[0]), .b(dm_int_st3_11[1]), .cin(dm_int_st3_11[2]), .s(dm_int_st4_11[1]), .cout(dm_int_st4_12[0]));
	// Bit 12
	full_adder FA33(.a(dm_int_st3_12[0]), .b(dm_int_st3_12[1]), .cin(dm_int_st3_12[2]), .s(dm_int_st4_12[1]), .cout(dm_int_st4_13[0]));
	// Bit 13
	full_adder FA34(.a(dm_int_st3_13[0]), .b(dm_int_st3_13[1]), .cin(dm_int_st3_13[2]), .s(dm_int_st4_13[1]), .cout(dm_int_st4_14[0]));
	// Bit 14
	assign dm_int_st4_14[1] = dm_int_st3_14[0];

	// Adder Stage
	wire [15:0] cla_in_a, cla_in_b, sum;
	wire ovf;
	assign cla_in_a[0] = dm_int_st4_0[0];
	assign cla_in_b[0] = 1'b0;
	assign cla_in_a[1] = dm_int_st4_1[0];
	assign cla_in_b[1] = dm_int_st4_1[1];
	assign cla_in_a[2] = dm_int_st4_2[0];
	assign cla_in_b[2] = dm_int_st4_2[1];
	assign cla_in_a[3] = dm_int_st4_3[0];
	assign cla_in_b[3] = dm_int_st4_3[1];
	assign cla_in_a[4] = dm_int_st4_4[0];
	assign cla_in_b[4] = dm_int_st4_4[1];
	assign cla_in_a[5] = dm_int_st4_5[0];
	assign cla_in_b[5] = dm_int_st4_5[1];
	assign cla_in_a[6] = dm_int_st4_6[0];
	assign cla_in_b[6] = dm_int_st4_6[1];
	assign cla_in_a[7] = dm_int_st4_7[0];
	assign cla_in_b[7] = dm_int_st4_7[1];
	assign cla_in_a[8] = dm_int_st4_8[0];
	assign cla_in_b[8] = dm_int_st4_8[1];
	assign cla_in_a[9] = dm_int_st4_9[0];
	assign cla_in_b[9] = dm_int_st4_9[1];
	assign cla_in_a[10] = dm_int_st4_10[0];
	assign cla_in_b[10] = dm_int_st4_10[1];
	assign cla_in_a[11] = dm_int_st4_11[0];
	assign cla_in_b[11] = dm_int_st4_11[1];
	assign cla_in_a[12] = dm_int_st4_12[0];
	assign cla_in_b[12] = dm_int_st4_12[1];
	assign cla_in_a[13] = dm_int_st4_13[0];
	assign cla_in_b[13] = dm_int_st4_13[1];
	assign cla_in_a[14] = dm_int_st4_14[0];
	assign cla_in_b[14] = dm_int_st4_14[1];
	assign cla_in_a[15] = 1'b0;
	assign cla_in_b[15] = 1'b0;
	cla_16bit CLA(clk, rstn, cla_in_a, cla_in_b, 1'b0, sum, ovf);

	assign out_overflow = sum[10];
	assign out_s[`FXP8S_MAG] = sum[9:3] | {`FXP8S_WIDTH-1{out_overflow}};
	assign out_s[`FXP8S_SIGN] = neg_out;

endmodule
