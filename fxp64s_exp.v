// IO Params
`define FXP64S_ADDR 63:0
`define FXP64S_WIDTH 64
`define FXP64S_SIGN 63
`define FXP64S_MAG 62:0
`define FXP64S_LSB_POW -48

module fxp64s_exp(
	input clk,
	input rstn,
	// Input Stream
	input en_in_data,
	output rdy_in_data,
	input [`FXP64S_ADDR] in_data,
	// Output Stream
	output en_out_data,
	input rdy_out_data,
	output [`FXP64S_ADDR] out_data
);
	wire wr_en;
	assign wr_en = en_in_data & rdy_in_data;
	wire wip;
	reg en_cntr;
	wire clr_cntr;
	reg [2:0] cntr;
	reg cntr_c;
	wire [63:0] in_x;
	assign in_x = (in_data ^ {64{in_data[63]}}) + in_data[63];
	reg x_sign;
	reg [15:0] x_int;
	wire [47:0] x_frac;
	assign rdy_in_data = en_in_data & ~wip;
	always @(posedge clk) begin
		en_cntr <= rstn & ~clr_cntr & (en_cntr | wr_en);
		{cntr_c, cntr} <= (cntr + en_cntr) & {4{rstn & ~clr_cntr}};
		x_sign <= rstn & (wr_en ? in_data[63] : x_sign);
		x_int <= (wr_en ? in_x[63:48] : x_int) & {16{rstn}};
	end
	assign x_frac = in_x[{POW_ZERO-1}:0];
	assign clr_cntr = (cntr == 3'b110);
	reg [63:0] x;
	reg [71:0] y;
	wire [63:0] x_nxt;
	wire [71:0] y_nxt;
	always @(posedge clk) begin
		x <= (wr_en ? {x_frac, 16'b0000000000000000} : (en_cntr ? x_nxt : x)) & {64{rstn}};
		y <= (wr_en ? {16'b0000000000000000, 1'b1, 55'b0000000000000000000000000000000000000000000000000000000} : (en_cntr ? y_nxt : y)) & {72{rstn}};
	end
	// CORDIC Stages //
	//// ROM blocks ////
	reg [63:0][5:0] log_rom0;
	always @(posedge clk) begin
		log_rom0[0] <= 64'b1001010111000000000110100011100111111011110101101000100000000000;
		log_rom0[1] <= 64'b0000000010111000011111000001111111111000010100111010101100101000;
		log_rom0[2] <= 64'b0000000000000000101110001010101000001100111111101101110010110001;
		log_rom0[3] <= 64'b0000000000000000000000001011100010101010001110101111101100110001;
		log_rom0[4] <= 64'b0000000000000000000000000000000010111000101010100011101100101001;
		log_rom0[5] <= 64'b0000000000000000000000000000000000000000101110001010101000111011;
	end
	reg [63:0][5:0] log_rom1;
	always @(posedge clk) begin
		log_rom1[0] <= 64'b0101001001101001111000010010111100110100011011100010110000000000;
		log_rom1[1] <= 64'b0000000001011100010010011001010011011101000011111101000101010000;
		log_rom1[2] <= 64'b0000000000000000010111000101010100010010000010100000110001000101;
		log_rom1[3] <= 64'b0000000000000000000000000101110001010101000111011000100100100011;
		log_rom1[4] <= 64'b0000000000000000000000000000000001011100010101010001110110010100;
		log_rom1[5] <= 64'b0000000000000000000000000000000000000000010111000101010100011101;
	end
	reg [63:0][5:0] log_rom2;
	always @(posedge clk) begin
		log_rom2[0] <= 64'b0010101110000000001101000111001111110111101011010001000000000000;
		log_rom2[1] <= 64'b0000000000101110001001111010110001011110111100101010111110000110;
		log_rom2[2] <= 64'b0000000000000000001011100010101010001011111001111010111001010110;
		log_rom2[3] <= 64'b0000000000000000000000000010111000101010100011101100011101110100;
		log_rom2[4] <= 64'b0000000000000000000000000000000000101110001010101000111011001010;
		log_rom2[5] <= 64'b0000000000000000000000000000000000000000001011100010101010001110;
	end
	reg [63:0][5:0] log_rom3;
	always @(posedge clk) begin
		log_rom3[0] <= 64'b0001011001100011111101101111101011001001000100110001011000000000;
		log_rom3[1] <= 64'b0000000000010111000101001000111011000010101000011011111111001001;
		log_rom3[2] <= 64'b0000000000000000000101110001010101000110101011001000000101001111;
		log_rom3[3] <= 64'b0000000000000000000000000001011100010101010001110110010001110010;
		log_rom3[4] <= 64'b0000000000000000000000000000000000010111000101010100011101100101;
		log_rom3[5] <= 64'b0000000000000000000000000000000000000000000101110001010101000111;
	end
	reg [63:0][5:0] log_rom4;
	always @(posedge clk) begin
		log_rom4[0] <= 64'b0000101101011101011010011011101011000111011111101100001110000000;
		log_rom4[1] <= 64'b0000000000001011100010100111010110001000111111010010100110110001;
		log_rom4[2] <= 64'b0000000000000000000010111000101010100011100001000110101100110011;
		log_rom4[3] <= 64'b0000000000000000000000000000101110001010101000111011001001100111;
		log_rom4[4] <= 64'b0000000000000000000000000000000000001011100010101010001110110010;
		log_rom4[5] <= 64'b0000000000000000000000000000000000000000000010111000101010100011;
	end
	reg [63:0][5:0] log_rom5;
	always @(posedge clk) begin
		log_rom5[0] <= 64'b0000010110111001111001011010000101110000101101001000101010000000;
		log_rom5[1] <= 64'b0000000000000101110001010100011001001110110001011111010011010111;
		log_rom5[2] <= 64'b0000000000000000000001011100010101010001110011011100000000111101;
		log_rom5[3] <= 64'b0000000000000000000000000000010111000101010100011101100100111111;
		log_rom5[4] <= 64'b0000000000000000000000000000000000000101110001010101000111011001;
		log_rom5[5] <= 64'b0000000000000000000000000000000000000000000001011100010101010001;
	end
	reg [63:0][5:0] log_rom6;
	always @(posedge clk) begin
		log_rom6[0] <= 64'b0000001011011111110010100001011011011101111000010000101000100000;
		log_rom6[1] <= 64'b0000000000000010111000101010011000001010000000000101110010010101;
		log_rom6[2] <= 64'b0000000000000000000000101110001010101000111010011100001011000111;
		log_rom6[3] <= 64'b0000000000000000000000000000001011100010101010001110110010100010;
		log_rom6[4] <= 64'b0000000000000000000000000000000000000010111000101010100011101100;
		log_rom6[5] <= 64'b0000000000000000000000000000000000000000000000101110001010101000;
	end
	reg [63:0][5:0] log_rom7;
	always @(posedge clk) begin
		log_rom7[0] <= 64'b0000000101110000100111000100011011010111101010101100011101110000;
		log_rom7[1] <= 64'b0000000000000001011100010101001110111101101010001111100000100010;
		log_rom7[2] <= 64'b0000000000000000000000010111000101010100011101011001101000001101;
		log_rom7[3] <= 64'b0000000000000000000000000000000101110001010101000111011001010001;
		log_rom7[4] <= 64'b0000000000000000000000000000000000000001011100010101010001110110;
		log_rom7[5] <= 64'b0000000000000000000000000000000000000000000000010111000101010100;
	end
	genvar i;
	//// Stage 0 ////
	// Master : X_Short
	wire st0_s;
	wire st0_ms_sn;
	wire [8:0] st0_ms_n;
	wire [8:0] st0_ms_d;
	wire [8:0] st0_ms_b;
	wire [8:0] st0_ms_q;
	wire [8:0] st0_ms_s;
	assign st0_ms_n = x[63-8*cntr:55-8*cntr];
	assign st0_ms_d = log_rom0[cntr][63-8*cntr:55-8*cntr];
	restoring_subtractor RS_0_0(st0_ms_n[0], st0_ms_d[0], 1'b0, st0_ms_q[1], st0_ms_s[0], st0_ms_b[0], st0_ms_q[0]);
	generate
		for (i=1; i<8; i=i+1) begin
			restoring_subtractor RS_0_i(st0_ms_n[i], st0_ms_d[i], st0_ms_b[i-1], st0_ms_q[i+1], st0_ms_s[i], st0_ms_b[i], st0_ms_q[i]);
		end
	endgenerate
	restoring_subtractor RS_0_8(st0_ms_n[8], st0_ms_d[8], st0_ms_sn, st0_s, st0_ms_s[8], st0_ms_b[8], st0_ms_q[8]);
	assign st0_s = ~st0_ms_sn;
	// Slave : X_Long
	wire [63:0] st0_sx_d;
	wire [63:0] st0_sx_s;
	wire [63:0] st0_sx_bo;
	assign {wsx}_d = log_rom{i}[cntr];
	generate
		for (i=0; i<64; i=i+1) begin
			full_subtractor FS_0_sx(x[i], st0_sx_d[i] & st0_s, 1'b0, st0_sx_s[i], st0_sx_bo[i]);
		end
	endgenerate
	// Slave : Y_Long
	wire [71:0] st0_sy_a;
	wire [71:0] st0_sy_a_;
	wire [71:0] st0_sy_s;
	wire [71:0] st0_sy_s_;
	assign st0_sy_a = y;
	assign st0_sy_a_[70-8*cntr:0] = st0_sy_a[71:1+8*cntr];
	assign st0_sy_a_[71:71-8*cntr] = 0;
	generate
		for (i=0; i<72; i=i+1) begin
			full_adder FA_0_sy(st0_sy_a[i], st0_sy_a_[i] & st0_s, 1'b0, st0_sy_s[i], st0_sy_s_[i]);
		end
	endgenerate
	//// Stage 1 ////
	// Master : X_Short
	wire st1_s;
	wire st1_ms_sn;
	wire [9:0] st1_ms_n;
	wire [9:0] st1_ms_d;
	wire [9:0] st1_ms_b;
	wire [9:0] st1_ms_q;
	wire [9:0] st1_ms_s;
	assign st1_ms_n[9:1] = st0_ms_s[8:0];
	assign st1_ms_n[0] = x[54-8*cntr];
	assign st1_ms_d[9] = 1'b0;
	assign st1_ms_d[8:0] = log_rom1[cntr][62-8*cntr:54-8*cntr];
	restoring_subtractor RS_1_0(st1_ms_n[0], st1_ms_d[0], 1'b0, st1_ms_q[1], st1_ms_s[0], st1_ms_b[0], st1_ms_q[0]);
	generate
		for (i=1; i<9; i=i+1) begin
			restoring_subtractor RS_1_i(st1_ms_n[i], st1_ms_d[i], st1_ms_b[i-1], st1_ms_q[i+1], st1_ms_s[i], st1_ms_b[i], st1_ms_q[i]);
		end
	endgenerate
	restoring_subtractor RS_1_9(st1_ms_n[9], st1_ms_d[9], st1_ms_sn, st1_s, st1_ms_s[9], st1_ms_b[9], st1_ms_q[9]);
	assign st1_s = ~st1_ms_sn;
	// Slave : X_Long
	wire [63:0] st1_sx_d;
	wire [63:0] st1_sx_s;
	wire [63:0] st1_sx_bo;
	wire [63:0] st1_sx_bi;
	assign st1_sx_bi[0] = 1'b0;
	assign st1_sx_bi[63:1] = st0_sx_bo[62:0];
	assign {wsx}_d = log_rom{i}[cntr];
	generate
		for (i=0; i<64; i=i+1) begin
			full_subtractor FS_1_sx(st0_sx_s[i], st1_sx_d[i] & st1_s, st1_sx_bi[i], st1_sx_s[i], st1_sx_bo[i]);
		end
	endgenerate
	// Slave : Y_Long
	wire [71:0] st1_sy_a;
	wire [71:0] st1_sy_a_;
	wire [71:0] st1_sy_s;
	wire [71:0] st1_sy_s_;
	wire [71:0] st1_sy_b;
	wire [71:0] st1_sy_b_;
	wire [71:0] st1_sy_t;
	wire [71:0] st1_sy_t_;
	assign st1_sy_a = st0_sy_s;
	assign st1_sy_b ={st0_sy_s_[70:0], 0};
	assign st1_sy_b_[69-8*cntr:0] = st1_sy_b[71:2+8*cntr];
	assign st1_sy_b_[71:70-8*cntr] = 0;
	assign st1_sy_a_[69-8*cntr:0] = st1_sy_a[71:2+8*cntr];
	assign st1_sy_a_[71:70-8*cntr] = 0;
	generate
		for (i=0; i<72; i=i+1) begin
			full_adder FA_1_sy(st1_sy_a[i], st1_sy_a_[i] & st1_s, st1_sy_b[i], st1_sy_t[i], st1_sy_t_[i]);
			full_adder FA_1_sy(st1_sy_t[i], st1_sy_b_[i] & st1_s, st1_sy_t_[i], st1_sy_s[i], st1_sy_s_[i]);
		end
	endgenerate
	//// Stage 2 ////
	// Master : X_Short
	wire st2_s;
	wire st2_ms_sn;
	wire [9:0] st2_ms_n;
	wire [9:0] st2_ms_d;
	wire [9:0] st2_ms_b;
	wire [9:0] st2_ms_q;
	wire [9:0] st2_ms_s;
	assign st2_ms_n[9:1] = st1_ms_s[8:0];
	assign st2_ms_n[0] = x[53-8*cntr];
	assign st2_ms_d[9] = 1'b0;
	assign st2_ms_d[8:0] = log_rom2[cntr][61-8*cntr:53-8*cntr];
	restoring_subtractor RS_2_0(st2_ms_n[0], st2_ms_d[0], 1'b0, st2_ms_q[1], st2_ms_s[0], st2_ms_b[0], st2_ms_q[0]);
	generate
		for (i=1; i<9; i=i+1) begin
			restoring_subtractor RS_2_i(st2_ms_n[i], st2_ms_d[i], st2_ms_b[i-1], st2_ms_q[i+1], st2_ms_s[i], st2_ms_b[i], st2_ms_q[i]);
		end
	endgenerate
	restoring_subtractor RS_2_9(st2_ms_n[9], st2_ms_d[9], st2_ms_sn, st2_s, st2_ms_s[9], st2_ms_b[9], st2_ms_q[9]);
	assign st2_s = ~st2_ms_sn;
	// Slave : X_Long
	wire [63:0] st2_sx_d;
	wire [63:0] st2_sx_s;
	wire [63:0] st2_sx_bo;
	wire [63:0] st2_sx_bi;
	assign st2_sx_bi[0] = 1'b0;
	assign st2_sx_bi[63:1] = st1_sx_bo[62:0];
	assign {wsx}_d = log_rom{i}[cntr];
	generate
		for (i=0; i<64; i=i+1) begin
			full_subtractor FS_2_sx(st1_sx_s[i], st2_sx_d[i] & st2_s, st2_sx_bi[i], st2_sx_s[i], st2_sx_bo[i]);
		end
	endgenerate
	// Slave : Y_Long
	wire [71:0] st2_sy_a;
	wire [71:0] st2_sy_a_;
	wire [71:0] st2_sy_s;
	wire [71:0] st2_sy_s_;
	wire [71:0] st2_sy_b;
	wire [71:0] st2_sy_b_;
	wire [71:0] st2_sy_t;
	wire [71:0] st2_sy_t_;
	assign st2_sy_a = st1_sy_s;
	assign st2_sy_b ={st1_sy_s_[70:0], 0};
	assign st2_sy_b_[68-8*cntr:0] = st2_sy_b[71:3+8*cntr];
	assign st2_sy_b_[71:69-8*cntr] = 0;
	assign st2_sy_a_[68-8*cntr:0] = st2_sy_a[71:3+8*cntr];
	assign st2_sy_a_[71:69-8*cntr] = 0;
	generate
		for (i=0; i<72; i=i+1) begin
			full_adder FA_2_sy(st2_sy_a[i], st2_sy_a_[i] & st2_s, st2_sy_b[i], st2_sy_t[i], st2_sy_t_[i]);
			full_adder FA_2_sy(st2_sy_t[i], st2_sy_b_[i] & st2_s, st2_sy_t_[i], st2_sy_s[i], st2_sy_s_[i]);
		end
	endgenerate
	//// Stage 3 ////
	// Master : X_Short
	wire st3_s;
	wire st3_ms_sn;
	wire [9:0] st3_ms_n;
	wire [9:0] st3_ms_d;
	wire [9:0] st3_ms_b;
	wire [9:0] st3_ms_q;
	wire [9:0] st3_ms_s;
	assign st3_ms_n[9:1] = st2_ms_s[8:0];
	assign st3_ms_n[0] = x[52-8*cntr];
	assign st3_ms_d[9] = 1'b0;
	assign st3_ms_d[8:0] = log_rom3[cntr][60-8*cntr:52-8*cntr];
	restoring_subtractor RS_3_0(st3_ms_n[0], st3_ms_d[0], 1'b0, st3_ms_q[1], st3_ms_s[0], st3_ms_b[0], st3_ms_q[0]);
	generate
		for (i=1; i<9; i=i+1) begin
			restoring_subtractor RS_3_i(st3_ms_n[i], st3_ms_d[i], st3_ms_b[i-1], st3_ms_q[i+1], st3_ms_s[i], st3_ms_b[i], st3_ms_q[i]);
		end
	endgenerate
	restoring_subtractor RS_3_9(st3_ms_n[9], st3_ms_d[9], st3_ms_sn, st3_s, st3_ms_s[9], st3_ms_b[9], st3_ms_q[9]);
	assign st3_s = ~st3_ms_sn;
	// Slave : X_Long
	wire [63:0] st3_sx_d;
	wire [63:0] st3_sx_s;
	wire [63:0] st3_sx_bo;
	wire [63:0] st3_sx_bi;
	assign st3_sx_bi[0] = 1'b0;
	assign st3_sx_bi[63:1] = st2_sx_bo[62:0];
	assign {wsx}_d = log_rom{i}[cntr];
	generate
		for (i=0; i<64; i=i+1) begin
			full_subtractor FS_3_sx(st2_sx_s[i], st3_sx_d[i] & st3_s, st3_sx_bi[i], st3_sx_s[i], st3_sx_bo[i]);
		end
	endgenerate
	// Slave : Y_Long
	wire [71:0] st3_sy_a;
	wire [71:0] st3_sy_a_;
	wire [71:0] st3_sy_s;
	wire [71:0] st3_sy_s_;
	wire [71:0] st3_sy_b;
	wire [71:0] st3_sy_b_;
	wire [71:0] st3_sy_t;
	wire [71:0] st3_sy_t_;
	assign st3_sy_a = st2_sy_s;
	assign st3_sy_b ={st2_sy_s_[70:0], 0};
	assign st3_sy_b_[67-8*cntr:0] = st3_sy_b[71:4+8*cntr];
	assign st3_sy_b_[71:68-8*cntr] = 0;
	assign st3_sy_a_[67-8*cntr:0] = st3_sy_a[71:4+8*cntr];
	assign st3_sy_a_[71:68-8*cntr] = 0;
	generate
		for (i=0; i<72; i=i+1) begin
			full_adder FA_3_sy(st3_sy_a[i], st3_sy_a_[i] & st3_s, st3_sy_b[i], st3_sy_t[i], st3_sy_t_[i]);
			full_adder FA_3_sy(st3_sy_t[i], st3_sy_b_[i] & st3_s, st3_sy_t_[i], st3_sy_s[i], st3_sy_s_[i]);
		end
	endgenerate
	//// Stage 4 ////
	// Master : X_Short
	wire st4_s;
	wire st4_ms_sn;
	wire [9:0] st4_ms_n;
	wire [9:0] st4_ms_d;
	wire [9:0] st4_ms_b;
	wire [9:0] st4_ms_q;
	wire [9:0] st4_ms_s;
	assign st4_ms_n[9:1] = st3_ms_s[8:0];
	assign st4_ms_n[0] = x[51-8*cntr];
	assign st4_ms_d[9] = 1'b0;
	assign st4_ms_d[8:0] = log_rom4[cntr][59-8*cntr:51-8*cntr];
	restoring_subtractor RS_4_0(st4_ms_n[0], st4_ms_d[0], 1'b0, st4_ms_q[1], st4_ms_s[0], st4_ms_b[0], st4_ms_q[0]);
	generate
		for (i=1; i<9; i=i+1) begin
			restoring_subtractor RS_4_i(st4_ms_n[i], st4_ms_d[i], st4_ms_b[i-1], st4_ms_q[i+1], st4_ms_s[i], st4_ms_b[i], st4_ms_q[i]);
		end
	endgenerate
	restoring_subtractor RS_4_9(st4_ms_n[9], st4_ms_d[9], st4_ms_sn, st4_s, st4_ms_s[9], st4_ms_b[9], st4_ms_q[9]);
	assign st4_s = ~st4_ms_sn;
	// Slave : X_Long
	wire [63:0] st4_sx_d;
	wire [63:0] st4_sx_s;
	wire [63:0] st4_sx_bo;
	wire [63:0] st4_sx_bi;
	assign st4_sx_bi[0] = 1'b0;
	assign st4_sx_bi[63:1] = st3_sx_bo[62:0];
	assign {wsx}_d = log_rom{i}[cntr];
	generate
		for (i=0; i<64; i=i+1) begin
			full_subtractor FS_4_sx(st3_sx_s[i], st4_sx_d[i] & st4_s, st4_sx_bi[i], st4_sx_s[i], st4_sx_bo[i]);
		end
	endgenerate
	// Slave : Y_Long
	wire [71:0] st4_sy_a;
	wire [71:0] st4_sy_a_;
	wire [71:0] st4_sy_s;
	wire [71:0] st4_sy_s_;
	wire [71:0] st4_sy_b;
	wire [71:0] st4_sy_b_;
	wire [71:0] st4_sy_t;
	wire [71:0] st4_sy_t_;
	assign st4_sy_a = st3_sy_s;
	assign st4_sy_b ={st3_sy_s_[70:0], 0};
	assign st4_sy_b_[66-8*cntr:0] = st4_sy_b[71:5+8*cntr];
	assign st4_sy_b_[71:67-8*cntr] = 0;
	assign st4_sy_a_[66-8*cntr:0] = st4_sy_a[71:5+8*cntr];
	assign st4_sy_a_[71:67-8*cntr] = 0;
	generate
		for (i=0; i<72; i=i+1) begin
			full_adder FA_4_sy(st4_sy_a[i], st4_sy_a_[i] & st4_s, st4_sy_b[i], st4_sy_t[i], st4_sy_t_[i]);
			full_adder FA_4_sy(st4_sy_t[i], st4_sy_b_[i] & st4_s, st4_sy_t_[i], st4_sy_s[i], st4_sy_s_[i]);
		end
	endgenerate
	//// Stage 5 ////
	// Master : X_Short
	wire st5_s;
	wire st5_ms_sn;
	wire [9:0] st5_ms_n;
	wire [9:0] st5_ms_d;
	wire [9:0] st5_ms_b;
	wire [9:0] st5_ms_q;
	wire [9:0] st5_ms_s;
	assign st5_ms_n[9:1] = st4_ms_s[8:0];
	assign st5_ms_n[0] = x[50-8*cntr];
	assign st5_ms_d[9] = 1'b0;
	assign st5_ms_d[8:0] = log_rom5[cntr][58-8*cntr:50-8*cntr];
	restoring_subtractor RS_5_0(st5_ms_n[0], st5_ms_d[0], 1'b0, st5_ms_q[1], st5_ms_s[0], st5_ms_b[0], st5_ms_q[0]);
	generate
		for (i=1; i<9; i=i+1) begin
			restoring_subtractor RS_5_i(st5_ms_n[i], st5_ms_d[i], st5_ms_b[i-1], st5_ms_q[i+1], st5_ms_s[i], st5_ms_b[i], st5_ms_q[i]);
		end
	endgenerate
	restoring_subtractor RS_5_9(st5_ms_n[9], st5_ms_d[9], st5_ms_sn, st5_s, st5_ms_s[9], st5_ms_b[9], st5_ms_q[9]);
	assign st5_s = ~st5_ms_sn;
	// Slave : X_Long
	wire [63:0] st5_sx_d;
	wire [63:0] st5_sx_s;
	wire [63:0] st5_sx_bo;
	wire [63:0] st5_sx_bi;
	assign st5_sx_bi[0] = 1'b0;
	assign st5_sx_bi[63:1] = st4_sx_bo[62:0];
	assign {wsx}_d = log_rom{i}[cntr];
	generate
		for (i=0; i<64; i=i+1) begin
			full_subtractor FS_5_sx(st4_sx_s[i], st5_sx_d[i] & st5_s, st5_sx_bi[i], st5_sx_s[i], st5_sx_bo[i]);
		end
	endgenerate
	// Slave : Y_Long
	wire [71:0] st5_sy_a;
	wire [71:0] st5_sy_a_;
	wire [71:0] st5_sy_s;
	wire [71:0] st5_sy_s_;
	wire [71:0] st5_sy_b;
	wire [71:0] st5_sy_b_;
	wire [71:0] st5_sy_t;
	wire [71:0] st5_sy_t_;
	assign st5_sy_a = st4_sy_s;
	assign st5_sy_b ={st4_sy_s_[70:0], 0};
	assign st5_sy_b_[65-8*cntr:0] = st5_sy_b[71:6+8*cntr];
	assign st5_sy_b_[71:66-8*cntr] = 0;
	assign st5_sy_a_[65-8*cntr:0] = st5_sy_a[71:6+8*cntr];
	assign st5_sy_a_[71:66-8*cntr] = 0;
	generate
		for (i=0; i<72; i=i+1) begin
			full_adder FA_5_sy(st5_sy_a[i], st5_sy_a_[i] & st5_s, st5_sy_b[i], st5_sy_t[i], st5_sy_t_[i]);
			full_adder FA_5_sy(st5_sy_t[i], st5_sy_b_[i] & st5_s, st5_sy_t_[i], st5_sy_s[i], st5_sy_s_[i]);
		end
	endgenerate
	//// Stage 6 ////
	// Master : X_Short
	wire st6_s;
	wire st6_ms_sn;
	wire [9:0] st6_ms_n;
	wire [9:0] st6_ms_d;
	wire [9:0] st6_ms_b;
	wire [9:0] st6_ms_q;
	wire [9:0] st6_ms_s;
	assign st6_ms_n[9:1] = st5_ms_s[8:0];
	assign st6_ms_n[0] = x[49-8*cntr];
	assign st6_ms_d[9] = 1'b0;
	assign st6_ms_d[8:0] = log_rom6[cntr][57-8*cntr:49-8*cntr];
	restoring_subtractor RS_6_0(st6_ms_n[0], st6_ms_d[0], 1'b0, st6_ms_q[1], st6_ms_s[0], st6_ms_b[0], st6_ms_q[0]);
	generate
		for (i=1; i<9; i=i+1) begin
			restoring_subtractor RS_6_i(st6_ms_n[i], st6_ms_d[i], st6_ms_b[i-1], st6_ms_q[i+1], st6_ms_s[i], st6_ms_b[i], st6_ms_q[i]);
		end
	endgenerate
	restoring_subtractor RS_6_9(st6_ms_n[9], st6_ms_d[9], st6_ms_sn, st6_s, st6_ms_s[9], st6_ms_b[9], st6_ms_q[9]);
	assign st6_s = ~st6_ms_sn;
	// Slave : X_Long
	wire [63:0] st6_sx_d;
	wire [63:0] st6_sx_s;
	wire [63:0] st6_sx_bo;
	wire [63:0] st6_sx_bi;
	assign st6_sx_bi[0] = 1'b0;
	assign st6_sx_bi[63:1] = st5_sx_bo[62:0];
	assign {wsx}_d = log_rom{i}[cntr];
	generate
		for (i=0; i<64; i=i+1) begin
			full_subtractor FS_6_sx(st5_sx_s[i], st6_sx_d[i] & st6_s, st6_sx_bi[i], st6_sx_s[i], st6_sx_bo[i]);
		end
	endgenerate
	// Slave : Y_Long
	wire [71:0] st6_sy_a;
	wire [71:0] st6_sy_a_;
	wire [71:0] st6_sy_s;
	wire [71:0] st6_sy_s_;
	wire [71:0] st6_sy_b;
	wire [71:0] st6_sy_b_;
	wire [71:0] st6_sy_t;
	wire [71:0] st6_sy_t_;
	assign st6_sy_a = st5_sy_s;
	assign st6_sy_b ={st5_sy_s_[70:0], 0};
	assign st6_sy_b_[64-8*cntr:0] = st6_sy_b[71:7+8*cntr];
	assign st6_sy_b_[71:65-8*cntr] = 0;
	assign st6_sy_a_[64-8*cntr:0] = st6_sy_a[71:7+8*cntr];
	assign st6_sy_a_[71:65-8*cntr] = 0;
	generate
		for (i=0; i<72; i=i+1) begin
			full_adder FA_6_sy(st6_sy_a[i], st6_sy_a_[i] & st6_s, st6_sy_b[i], st6_sy_t[i], st6_sy_t_[i]);
			full_adder FA_6_sy(st6_sy_t[i], st6_sy_b_[i] & st6_s, st6_sy_t_[i], st6_sy_s[i], st6_sy_s_[i]);
		end
	endgenerate
	wire st7_s;
	wire [63:0] st7_x;
	wire [63:0] st7_cd;
	assign s7_cd[0] = 1'b0;
	assign s7_cd[63:1] = st6_sx_bo[62:0];
	wire [64:0] st7_cb;
	assign st7_cb[0] = 1'b0;
	generate
		for (i=0; i<64; i=i+1) begin
			full_subtractor BPS_1(st6_sx_s[i], st7_cd[i], st7_cb[i], st7_x[i], st7_cb[i+1]);
		end
	endgenerate
	wire [63:0] st7_d;
	wire [64:0] st7_b;
	assign st7_b[0] = 1'b0;
	assign st7_d = log_rom7[cntr];
	generate
		for (i=0; i<64; i=i+1) begin
			full_subtractor BPS_2(st7_x[i], st7_d[i], st7_b[i], x_nxt[i], st7_b[i+1]);
		end
	endgenerate
	assign st7_s = ~st7_b[64];
	wire [71:0] st7_sy_a;
	wire [71:0] st7_sy_a_;
	wire [71:0] st7_sy_s;
	wire [71:0] st7_sy_s_;
	wire [71:0] st7_sy_b;
	wire [71:0] st7_sy_b_;
	wire [71:0] st7_sy_t;
	wire [71:0] st7_sy_t_;
	assign st7_sy_a = st6_sy_s;
	assign st7_sy_b ={st6_sy_s_[70:0], 0};
	assign st7_sy_b_[63-8*cntr:0] = st7_sy_b[71:7+8*cntr];
	assign st7_sy_b_[71:64-8*cntr] = 0;
	assign st7_sy_a_[63-8*cntr:0] = st7_sy_a[71:7+8*cntr];
	assign st7_sy_a_[71:64-8*cntr] = 0;
	generate
		for (i=0; i<72; i=i+1) begin
			full_adder FA_6_sy(st7_sy_a[i], st7_sy_a_[i] & st7_s, st7_sy_b[i], st7_sy_t[i], st7_sy_t_[i]);
			full_adder FA_6_sy(st7_sy_t[i], st7_sy_b_[i] & st7_s, st7_sy_t_[i], st7_sy_s[i], st7_sy_s_[i]);
		end
	endgenerate
	wire [71:0] st7_yc;
	assign st7_yc[0] = 1'b0;
	assign y_nxt[0] = st7_sy_s[0];
	generate
		for (i=1; i<72; i=i+1) begin
			full_adder CPA_2(st7_sy_s[i], st7_sy_s_[i], st7_yc[i], y_nxt[i], st7_yc[i+1]);
		end
	endgenerate
	// CORDIC Stages //
	wire [63:0] shft_abs;
	wire [63:0] shft_qty;
	wire [63:0] shft_y;
	assign shft_abs = {{48{1'b0}}, x_int};
	assign shft_qty = (shft_abs ^ {64{x_sign}}) + x_sign;
	fxp64s_var_shifter SHFT_OUT(clk, rstn, y[71:8], shft_qty, shft_y);
	reg [{BIT_LEN-1}:0] out_y;
	wire rd_en;
	reg en_shift;
	reg en_out;
	assign rd_en = en_out_data & rdy_out_data;
	assign en_out_data = out_en;
	always @(posedge clk) begin
		en_shift <= clr_cntr & rstn;
		en_out <= rstn & ~rd_en & (en_out | en_shift);
		out_y <= (en_shift ? shft_y : out_y) & {64{rstn}};
	end
	assign wip = en_cntr | en_shift | en_out;
	assign out_data = out_y;

endmodule
