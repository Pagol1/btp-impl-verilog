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
		x_int <= (wr_en ? in_x[63:48] + in_data[63] : x_int) & {16{rstn}};
	end
	assign x_frac = in_data[47:0];
	assign clr_cntr = (cntr == 3'b111);
	reg [71:0] x;
	reg [79:0] y;
	wire [71:0] x_nxt;
	wire [79:0] y_nxt;
	always @(posedge clk) begin
		x <= (wr_en ? {x_frac, 16'b0000000000000000, 8'b00000000} : (en_cntr ? x_nxt : x)) & {72{rstn}};
		y <= (wr_en ? {15'b000000000000000, 1'b1, 64'b0000000000000000000000000000000000000000000000000000000000000000} : (en_cntr ? y_nxt : y)) & {80{rstn}};
	end
	// >>>> CORDIC Stages >>>>
	//// ROM blocks ////
	reg [71:0] log_rom0[7:0];
	always @(posedge clk) begin
		log_rom0[0] <= 72'b100101011100000000011010001110011111101111010110100001111001111110100000;
		log_rom0[1] <= 72'b000000001011100001111100000111111111100001010011101010110010011000110001;
		log_rom0[2] <= 72'b000000000000000010111000101010100000110011111110110111001011000100011000;
		log_rom0[3] <= 72'b000000000000000000000000101110001010101000111010111110110011000110001001;
		log_rom0[4] <= 72'b000000000000000000000000000000001011100010101010001110110010100100101101;
		log_rom0[5] <= 72'b000000000000000000000000000000000000000010111000101010100011101100101001;
		log_rom0[6] <= 72'b000000000000000000000000000000000000000000000000101110001010101000111011;
		log_rom0[7] <= 72'b000000000000000000000000000000000000000000000000000000001011100010101010;
	end
	reg [71:0] log_rom1[7:0];
	always @(posedge clk) begin
		log_rom1[0] <= 72'b010100100110100111100001001011110011010001101110001010111111100100100100;
		log_rom1[1] <= 72'b000000000101110001001001100101001101110100001111110100010101000001111110;
		log_rom1[2] <= 72'b000000000000000001011100010101010001001000001010000011000100010111010010;
		log_rom1[3] <= 72'b000000000000000000000000010111000101010100011101100010010010001101101000;
		log_rom1[4] <= 72'b000000000000000000000000000000000101110001010101000111011001010010100010;
		log_rom1[5] <= 72'b000000000000000000000000000000000000000001011100010101010001110110010100;
		log_rom1[6] <= 72'b000000000000000000000000000000000000000000000000010111000101010100011101;
		log_rom1[7] <= 72'b000000000000000000000000000000000000000000000000000000000101110001010101;
	end
	reg [71:0] log_rom2[7:0];
	always @(posedge clk) begin
		log_rom2[0] <= 72'b001010111000000000110100011100111111011110101101000011110011111101000000;
		log_rom2[1] <= 72'b000000000010111000100111101011000101111011110010101011111000011000010101;
		log_rom2[2] <= 72'b000000000000000000101110001010101000101111100111101011100101011011100100;
		log_rom2[3] <= 72'b000000000000000000000000001011100010101010001110110001110111010001011101;
		log_rom2[4] <= 72'b000000000000000000000000000000000010111000101010100011101100101001010100;
		log_rom2[5] <= 72'b000000000000000000000000000000000000000000101110001010101000111011001010;
		log_rom2[6] <= 72'b000000000000000000000000000000000000000000000000001011100010101010001110;
		log_rom2[7] <= 72'b000000000000000000000000000000000000000000000000000000000010111000101010;
	end
	reg [71:0] log_rom3[7:0];
	always @(posedge clk) begin
		log_rom3[0] <= 72'b000101100110001111110110111110101100100100010011000101100111110011001100;
		log_rom3[1] <= 72'b000000000001011100010100100011101100001010100001101111111100100010001110;
		log_rom3[2] <= 72'b000000000000000000010111000101010100011010101100100000010100111110000110;
		log_rom3[3] <= 72'b000000000000000000000000000101110001010101000111011001000111001011011000;
		log_rom3[4] <= 72'b000000000000000000000000000000000001011100010101010001110110010100101010;
		log_rom3[5] <= 72'b000000000000000000000000000000000000000000010111000101010100011101100101;
		log_rom3[6] <= 72'b000000000000000000000000000000000000000000000000000101110001010101000111;
		log_rom3[7] <= 72'b000000000000000000000000000000000000000000000000000000000001011100010101;
	end
	reg [71:0] log_rom4[7:0];
	always @(posedge clk) begin
		log_rom4[0] <= 72'b000010110101110101101001101110101100011101111110110000111001100010011011;
		log_rom4[1] <= 72'b000000000000101110001010011101011000100011111101001010011011000110111010;
		log_rom4[2] <= 72'b000000000000000000001011100010101010001110000100011010110011001110101010;
		log_rom4[3] <= 72'b000000000000000000000000000010111000101010100011101100100110011110010110;
		log_rom4[4] <= 72'b000000000000000000000000000000000000101110001010101000111011001010010101;
		log_rom4[5] <= 72'b000000000000000000000000000000000000000000001011100010101010001110110010;
		log_rom4[6] <= 72'b000000000000000000000000000000000000000000000000000010111000101010100011;
		log_rom4[7] <= 72'b000000000000000000000000000000000000000000000000000000000000101110001010;
	end
	reg [71:0] log_rom5[7:0];
	always @(posedge clk) begin
		log_rom5[0] <= 72'b000001011011100111100101101000010111000010110100100010100110001010011011;
		log_rom5[1] <= 72'b000000000000010111000101010001100100111011000101111101001101011101001100;
		log_rom5[2] <= 72'b000000000000000000000101110001010101000111001101110000000011110100101011;
		log_rom5[3] <= 72'b000000000000000000000000000001011100010101010001110110010011111101010110;
		log_rom5[4] <= 72'b000000000000000000000000000000000000010111000101010100011101100101001010;
		log_rom5[5] <= 72'b000000000000000000000000000000000000000000000101110001010101000111011001;
		log_rom5[6] <= 72'b000000000000000000000000000000000000000000000000000001011100010101010001;
		log_rom5[7] <= 72'b000000000000000000000000000000000000000000000000000000000000010111000101;
	end
	reg [71:0] log_rom6[7:0];
	always @(posedge clk) begin
		log_rom6[0] <= 72'b000000101101111111001010000101101101110111100001000010100010111111110001;
		log_rom6[1] <= 72'b000000000000001011100010101001100000101000000000010111001001010111001000;
		log_rom6[2] <= 72'b000000000000000000000010111000101010100011101001110000101100011101110110;
		log_rom6[3] <= 72'b000000000000000000000000000000101110001010101000111011001010001010001101;
		log_rom6[4] <= 72'b000000000000000000000000000000000000001011100010101010001110110010100101;
		log_rom6[5] <= 72'b000000000000000000000000000000000000000000000010111000101010100011101100;
		log_rom6[6] <= 72'b000000000000000000000000000000000000000000000000000000101110001010101000;
		log_rom6[7] <= 72'b000000000000000000000000000000000000000000000000000000000000001011100010;
	end
	reg [71:0] log_rom7[7:0];
	always @(posedge clk) begin
		log_rom7[0] <= 72'b000000010111000010011100010001101101011110101010110001110111010010101101;
		log_rom7[1] <= 72'b000000000000000101110001010100111011110110101000111110000010001001010000;
		log_rom7[2] <= 72'b000000000000000000000001011100010101010001110101100110100000110111110101;
		log_rom7[3] <= 72'b000000000000000000000000000000010111000101010100011101100101000111111111;
		log_rom7[4] <= 72'b000000000000000000000000000000000000000101110001010101000111011001010010;
		log_rom7[5] <= 72'b000000000000000000000000000000000000000000000001011100010101010001110110;
		log_rom7[6] <= 72'b000000000000000000000000000000000000000000000000000000010111000101010100;
		log_rom7[7] <= 72'b000000000000000000000000000000000000000000000000000000000000000101110001;
	end
	genvar i;
	//// Stage 0 ////
	// Master : X_Long
	wire st0_s;
	wire st0_sx_sn;
	wire [71:0] st0_sx_n;
	wire [71:0] st0_sx_d;
	wire [71:0] st0_sx_b;
	wire [71:0] st0_sx_q;
	wire [71:0] st0_sx_s;
	assign st0_sx_n = x;
	assign st0_sx_d = log_rom0[cntr];
	restoring_subtractor RS_0_0(st0_sx_n[0], st0_sx_d[0], 1'b0, st0_sx_q[1], st0_sx_s[0], st0_sx_b[0], st0_sx_q[0]);
	generate
		for (i=1; i<71; i=i+1) begin : FULL_PREC_ST_0
			restoring_subtractor RS_0_i(st0_sx_n[i], st0_sx_d[i], st0_sx_b[i-1], st0_sx_q[i+1], st0_sx_s[i], st0_sx_b[i], st0_sx_q[i]);
		end
	endgenerate
	restoring_subtractor RS_0_71(st0_sx_n[71], st0_sx_d[71], st0_sx_b[70], st0_s, st0_sx_s[71], st0_sx_sn, st0_sx_q[71]);
	assign st0_s = ~st0_sx_sn;
	// Slave : Y_Long
	wire [79:0] st0_sy_a;
	wire [79:0] st0_sy_a_;
	wire [79:0] st0_sy_s;
	wire [79:0] st0_sy_s_;
	wire [79:0] st0_sy_shift_abs;
	assign st0_sy_shift_abs = 1 + {cntr, {3{1'b0}}};
	fxp80s_var_shifter SHFTA_Y_ST0(clk, rstn, st0_sy_a, st0_sy_shift_abs, 1'b1, st0_sy_a_);
	assign st0_sy_a = y;
	generate
		for (i=0; i<80; i=i+1) begin : SLAVE_ST_0
			full_adder FA_0_sy_0(st0_sy_a[i], st0_sy_a_[i] & st0_s, 1'b0, st0_sy_s[i], st0_sy_s_[i]);
		end
	endgenerate
	//// Stage 1 ////
	// Master : X_Long
	wire st1_s;
	wire st1_sx_sn;
	wire [71:0] st1_sx_n;
	wire [71:0] st1_sx_d;
	wire [71:0] st1_sx_b;
	wire [71:0] st1_sx_q;
	wire [71:0] st1_sx_s;
	assign st1_sx_n = st0_sx_s;
	assign st1_sx_d = log_rom1[cntr];
	restoring_subtractor RS_1_0(st1_sx_n[0], st1_sx_d[0], 1'b0, st1_sx_q[1], st1_sx_s[0], st1_sx_b[0], st1_sx_q[0]);
	generate
		for (i=1; i<71; i=i+1) begin : FULL_PREC_ST_1
			restoring_subtractor RS_1_i(st1_sx_n[i], st1_sx_d[i], st1_sx_b[i-1], st1_sx_q[i+1], st1_sx_s[i], st1_sx_b[i], st1_sx_q[i]);
		end
	endgenerate
	restoring_subtractor RS_1_71(st1_sx_n[71], st1_sx_d[71], st1_sx_b[70], st1_s, st1_sx_s[71], st1_sx_sn, st1_sx_q[71]);
	assign st1_s = ~st1_sx_sn;
	// Slave : Y_Long
	wire [79:0] st1_sy_a;
	wire [79:0] st1_sy_a_;
	wire [79:0] st1_sy_s;
	wire [79:0] st1_sy_s_;
	wire [79:0] st1_sy_b;
	wire [79:0] st1_sy_b_;
	wire [79:0] st1_sy_t;
	wire [79:0] st1_sy_t_;
	assign st1_sy_a = st0_sy_s;
	assign st1_sy_b ={st0_sy_s_[78:0], 1'b0};
	wire [79:0] st1_sy_shift_abs;
	assign st1_sy_shift_abs = 2 + {cntr, {3{1'b0}}};
	fxp80s_var_shifter SHFTA_Y_ST1(clk, rstn, st1_sy_a, st1_sy_shift_abs, 1'b1, st1_sy_a_);
	fxp80s_var_shifter SHFTB_Y_ST1(clk, rstn, st1_sy_b, st1_sy_shift_abs, 1'b1, st1_sy_b_);
	generate
		for (i=0; i<80; i=i+1) begin : SLAVE_ST_1
			full_adder FA_1_sy_0(st1_sy_a[i], st1_sy_a_[i] & st1_s, st1_sy_b[i], st1_sy_t[i], st1_sy_t_[i]);
			full_adder FA_1_sy_1(st1_sy_t[i], st1_sy_b_[i] & st1_s, st1_sy_t_[i], st1_sy_s[i], st1_sy_s_[i]);
		end
	endgenerate
	//// Stage 2 ////
	// Master : X_Long
	wire st2_s;
	wire st2_sx_sn;
	wire [71:0] st2_sx_n;
	wire [71:0] st2_sx_d;
	wire [71:0] st2_sx_b;
	wire [71:0] st2_sx_q;
	wire [71:0] st2_sx_s;
	assign st2_sx_n = st1_sx_s;
	assign st2_sx_d = log_rom2[cntr];
	restoring_subtractor RS_2_0(st2_sx_n[0], st2_sx_d[0], 1'b0, st2_sx_q[1], st2_sx_s[0], st2_sx_b[0], st2_sx_q[0]);
	generate
		for (i=1; i<71; i=i+1) begin : FULL_PREC_ST_2
			restoring_subtractor RS_2_i(st2_sx_n[i], st2_sx_d[i], st2_sx_b[i-1], st2_sx_q[i+1], st2_sx_s[i], st2_sx_b[i], st2_sx_q[i]);
		end
	endgenerate
	restoring_subtractor RS_2_71(st2_sx_n[71], st2_sx_d[71], st2_sx_b[70], st2_s, st2_sx_s[71], st2_sx_sn, st2_sx_q[71]);
	assign st2_s = ~st2_sx_sn;
	// Slave : Y_Long
	wire [79:0] st2_sy_a;
	wire [79:0] st2_sy_a_;
	wire [79:0] st2_sy_s;
	wire [79:0] st2_sy_s_;
	wire [79:0] st2_sy_b;
	wire [79:0] st2_sy_b_;
	wire [79:0] st2_sy_t;
	wire [79:0] st2_sy_t_;
	assign st2_sy_a = st1_sy_s;
	assign st2_sy_b ={st1_sy_s_[78:0], 1'b0};
	wire [79:0] st2_sy_shift_abs;
	assign st2_sy_shift_abs = 3 + {cntr, {3{1'b0}}};
	fxp80s_var_shifter SHFTA_Y_ST2(clk, rstn, st2_sy_a, st2_sy_shift_abs, 1'b1, st2_sy_a_);
	fxp80s_var_shifter SHFTB_Y_ST2(clk, rstn, st2_sy_b, st2_sy_shift_abs, 1'b1, st2_sy_b_);
	generate
		for (i=0; i<80; i=i+1) begin : SLAVE_ST_2
			full_adder FA_2_sy_0(st2_sy_a[i], st2_sy_a_[i] & st2_s, st2_sy_b[i], st2_sy_t[i], st2_sy_t_[i]);
			full_adder FA_2_sy_1(st2_sy_t[i], st2_sy_b_[i] & st2_s, st2_sy_t_[i], st2_sy_s[i], st2_sy_s_[i]);
		end
	endgenerate
	//// Stage 3 ////
	// Master : X_Long
	wire st3_s;
	wire st3_sx_sn;
	wire [71:0] st3_sx_n;
	wire [71:0] st3_sx_d;
	wire [71:0] st3_sx_b;
	wire [71:0] st3_sx_q;
	wire [71:0] st3_sx_s;
	assign st3_sx_n = st2_sx_s;
	assign st3_sx_d = log_rom3[cntr];
	restoring_subtractor RS_3_0(st3_sx_n[0], st3_sx_d[0], 1'b0, st3_sx_q[1], st3_sx_s[0], st3_sx_b[0], st3_sx_q[0]);
	generate
		for (i=1; i<71; i=i+1) begin : FULL_PREC_ST_3
			restoring_subtractor RS_3_i(st3_sx_n[i], st3_sx_d[i], st3_sx_b[i-1], st3_sx_q[i+1], st3_sx_s[i], st3_sx_b[i], st3_sx_q[i]);
		end
	endgenerate
	restoring_subtractor RS_3_71(st3_sx_n[71], st3_sx_d[71], st3_sx_b[70], st3_s, st3_sx_s[71], st3_sx_sn, st3_sx_q[71]);
	assign st3_s = ~st3_sx_sn;
	// Slave : Y_Long
	wire [79:0] st3_sy_a;
	wire [79:0] st3_sy_a_;
	wire [79:0] st3_sy_s;
	wire [79:0] st3_sy_s_;
	wire [79:0] st3_sy_b;
	wire [79:0] st3_sy_b_;
	wire [79:0] st3_sy_t;
	wire [79:0] st3_sy_t_;
	assign st3_sy_a = st2_sy_s;
	assign st3_sy_b ={st2_sy_s_[78:0], 1'b0};
	wire [79:0] st3_sy_shift_abs;
	assign st3_sy_shift_abs = 4 + {cntr, {3{1'b0}}};
	fxp80s_var_shifter SHFTA_Y_ST3(clk, rstn, st3_sy_a, st3_sy_shift_abs, 1'b1, st3_sy_a_);
	fxp80s_var_shifter SHFTB_Y_ST3(clk, rstn, st3_sy_b, st3_sy_shift_abs, 1'b1, st3_sy_b_);
	generate
		for (i=0; i<80; i=i+1) begin : SLAVE_ST_3
			full_adder FA_3_sy_0(st3_sy_a[i], st3_sy_a_[i] & st3_s, st3_sy_b[i], st3_sy_t[i], st3_sy_t_[i]);
			full_adder FA_3_sy_1(st3_sy_t[i], st3_sy_b_[i] & st3_s, st3_sy_t_[i], st3_sy_s[i], st3_sy_s_[i]);
		end
	endgenerate
	//// Stage 4 ////
	// Master : X_Long
	wire st4_s;
	wire st4_sx_sn;
	wire [71:0] st4_sx_n;
	wire [71:0] st4_sx_d;
	wire [71:0] st4_sx_b;
	wire [71:0] st4_sx_q;
	wire [71:0] st4_sx_s;
	assign st4_sx_n = st3_sx_s;
	assign st4_sx_d = log_rom4[cntr];
	restoring_subtractor RS_4_0(st4_sx_n[0], st4_sx_d[0], 1'b0, st4_sx_q[1], st4_sx_s[0], st4_sx_b[0], st4_sx_q[0]);
	generate
		for (i=1; i<71; i=i+1) begin : FULL_PREC_ST_4
			restoring_subtractor RS_4_i(st4_sx_n[i], st4_sx_d[i], st4_sx_b[i-1], st4_sx_q[i+1], st4_sx_s[i], st4_sx_b[i], st4_sx_q[i]);
		end
	endgenerate
	restoring_subtractor RS_4_71(st4_sx_n[71], st4_sx_d[71], st4_sx_b[70], st4_s, st4_sx_s[71], st4_sx_sn, st4_sx_q[71]);
	assign st4_s = ~st4_sx_sn;
	// Slave : Y_Long
	wire [79:0] st4_sy_a;
	wire [79:0] st4_sy_a_;
	wire [79:0] st4_sy_s;
	wire [79:0] st4_sy_s_;
	wire [79:0] st4_sy_b;
	wire [79:0] st4_sy_b_;
	wire [79:0] st4_sy_t;
	wire [79:0] st4_sy_t_;
	assign st4_sy_a = st3_sy_s;
	assign st4_sy_b ={st3_sy_s_[78:0], 1'b0};
	wire [79:0] st4_sy_shift_abs;
	assign st4_sy_shift_abs = 5 + {cntr, {3{1'b0}}};
	fxp80s_var_shifter SHFTA_Y_ST4(clk, rstn, st4_sy_a, st4_sy_shift_abs, 1'b1, st4_sy_a_);
	fxp80s_var_shifter SHFTB_Y_ST4(clk, rstn, st4_sy_b, st4_sy_shift_abs, 1'b1, st4_sy_b_);
	generate
		for (i=0; i<80; i=i+1) begin : SLAVE_ST_4
			full_adder FA_4_sy_0(st4_sy_a[i], st4_sy_a_[i] & st4_s, st4_sy_b[i], st4_sy_t[i], st4_sy_t_[i]);
			full_adder FA_4_sy_1(st4_sy_t[i], st4_sy_b_[i] & st4_s, st4_sy_t_[i], st4_sy_s[i], st4_sy_s_[i]);
		end
	endgenerate
	//// Stage 5 ////
	// Master : X_Long
	wire st5_s;
	wire st5_sx_sn;
	wire [71:0] st5_sx_n;
	wire [71:0] st5_sx_d;
	wire [71:0] st5_sx_b;
	wire [71:0] st5_sx_q;
	wire [71:0] st5_sx_s;
	assign st5_sx_n = st4_sx_s;
	assign st5_sx_d = log_rom5[cntr];
	restoring_subtractor RS_5_0(st5_sx_n[0], st5_sx_d[0], 1'b0, st5_sx_q[1], st5_sx_s[0], st5_sx_b[0], st5_sx_q[0]);
	generate
		for (i=1; i<71; i=i+1) begin : FULL_PREC_ST_5
			restoring_subtractor RS_5_i(st5_sx_n[i], st5_sx_d[i], st5_sx_b[i-1], st5_sx_q[i+1], st5_sx_s[i], st5_sx_b[i], st5_sx_q[i]);
		end
	endgenerate
	restoring_subtractor RS_5_71(st5_sx_n[71], st5_sx_d[71], st5_sx_b[70], st5_s, st5_sx_s[71], st5_sx_sn, st5_sx_q[71]);
	assign st5_s = ~st5_sx_sn;
	// Slave : Y_Long
	wire [79:0] st5_sy_a;
	wire [79:0] st5_sy_a_;
	wire [79:0] st5_sy_s;
	wire [79:0] st5_sy_s_;
	wire [79:0] st5_sy_b;
	wire [79:0] st5_sy_b_;
	wire [79:0] st5_sy_t;
	wire [79:0] st5_sy_t_;
	assign st5_sy_a = st4_sy_s;
	assign st5_sy_b ={st4_sy_s_[78:0], 1'b0};
	wire [79:0] st5_sy_shift_abs;
	assign st5_sy_shift_abs = 6 + {cntr, {3{1'b0}}};
	fxp80s_var_shifter SHFTA_Y_ST5(clk, rstn, st5_sy_a, st5_sy_shift_abs, 1'b1, st5_sy_a_);
	fxp80s_var_shifter SHFTB_Y_ST5(clk, rstn, st5_sy_b, st5_sy_shift_abs, 1'b1, st5_sy_b_);
	generate
		for (i=0; i<80; i=i+1) begin : SLAVE_ST_5
			full_adder FA_5_sy_0(st5_sy_a[i], st5_sy_a_[i] & st5_s, st5_sy_b[i], st5_sy_t[i], st5_sy_t_[i]);
			full_adder FA_5_sy_1(st5_sy_t[i], st5_sy_b_[i] & st5_s, st5_sy_t_[i], st5_sy_s[i], st5_sy_s_[i]);
		end
	endgenerate
	//// Stage 6 ////
	// Master : X_Long
	wire st6_s;
	wire st6_sx_sn;
	wire [71:0] st6_sx_n;
	wire [71:0] st6_sx_d;
	wire [71:0] st6_sx_b;
	wire [71:0] st6_sx_q;
	wire [71:0] st6_sx_s;
	assign st6_sx_n = st5_sx_s;
	assign st6_sx_d = log_rom6[cntr];
	restoring_subtractor RS_6_0(st6_sx_n[0], st6_sx_d[0], 1'b0, st6_sx_q[1], st6_sx_s[0], st6_sx_b[0], st6_sx_q[0]);
	generate
		for (i=1; i<71; i=i+1) begin : FULL_PREC_ST_6
			restoring_subtractor RS_6_i(st6_sx_n[i], st6_sx_d[i], st6_sx_b[i-1], st6_sx_q[i+1], st6_sx_s[i], st6_sx_b[i], st6_sx_q[i]);
		end
	endgenerate
	restoring_subtractor RS_6_71(st6_sx_n[71], st6_sx_d[71], st6_sx_b[70], st6_s, st6_sx_s[71], st6_sx_sn, st6_sx_q[71]);
	assign st6_s = ~st6_sx_sn;
	// Slave : Y_Long
	wire [79:0] st6_sy_a;
	wire [79:0] st6_sy_a_;
	wire [79:0] st6_sy_s;
	wire [79:0] st6_sy_s_;
	wire [79:0] st6_sy_b;
	wire [79:0] st6_sy_b_;
	wire [79:0] st6_sy_t;
	wire [79:0] st6_sy_t_;
	assign st6_sy_a = st5_sy_s;
	assign st6_sy_b ={st5_sy_s_[78:0], 1'b0};
	wire [79:0] st6_sy_shift_abs;
	assign st6_sy_shift_abs = 7 + {cntr, {3{1'b0}}};
	fxp80s_var_shifter SHFTA_Y_ST6(clk, rstn, st6_sy_a, st6_sy_shift_abs, 1'b1, st6_sy_a_);
	fxp80s_var_shifter SHFTB_Y_ST6(clk, rstn, st6_sy_b, st6_sy_shift_abs, 1'b1, st6_sy_b_);
	generate
		for (i=0; i<80; i=i+1) begin : SLAVE_ST_6
			full_adder FA_6_sy_0(st6_sy_a[i], st6_sy_a_[i] & st6_s, st6_sy_b[i], st6_sy_t[i], st6_sy_t_[i]);
			full_adder FA_6_sy_1(st6_sy_t[i], st6_sy_b_[i] & st6_s, st6_sy_t_[i], st6_sy_s[i], st6_sy_s_[i]);
		end
	endgenerate
	//// Stage 7 ////
	// Master : X_Long
	wire st7_s;
	wire st7_sx_sn;
	wire [71:0] st7_sx_n;
	wire [71:0] st7_sx_d;
	wire [71:0] st7_sx_b;
	wire [71:0] st7_sx_q;
	assign st7_sx_n = st6_sx_s;
	assign st7_sx_d = log_rom7[cntr];
	restoring_subtractor RS_7_0(st7_sx_n[0], st7_sx_d[0], 1'b0, st7_sx_q[1], x_nxt[0], st7_sx_b[0], st7_sx_q[0]);
	generate
		for (i=1; i<71; i=i+1) begin : FULL_PREC_ST_7
			restoring_subtractor RS_7_i(st7_sx_n[i], st7_sx_d[i], st7_sx_b[i-1], st7_sx_q[i+1], x_nxt[i], st7_sx_b[i], st7_sx_q[i]);
		end
	endgenerate
	restoring_subtractor RS_7_71(st7_sx_n[71], st7_sx_d[71], st7_sx_b[70], st7_s, x_nxt[71], st7_sx_sn, st7_sx_q[71]);
	assign st7_s = ~st7_sx_sn;
	wire [79:0] st7_sy_a;
	wire [79:0] st7_sy_a_;
	wire [79:0] st7_sy_s;
	wire [79:0] st7_sy_s_;
	wire [79:0] st7_sy_b;
	wire [79:0] st7_sy_b_;
	wire [79:0] st7_sy_t;
	wire [79:0] st7_sy_t_;
	wire [79:0] st7_sy_shift_abs;
	assign st7_sy_a = st6_sy_s;
	assign st7_sy_b ={st6_sy_s_[78:0], 1'b0};
	assign st7_sy_shift_abs = 8 + {cntr, {3{1'b0}}};
	fxp80s_var_shifter SHFTA_Y_ST7(clk, rstn, st7_sy_a, st7_sy_shift_abs, 1'b1, st7_sy_a_);
	fxp80s_var_shifter SHFTB_Y_ST7(clk, rstn, st7_sy_b, st7_sy_shift_abs, 1'b1, st7_sy_b_);
	generate
		for (i=0; i<80; i=i+1) begin : SLAVE_ST_7
			full_adder FA_7_sy_0(st7_sy_a[i], st7_sy_a_[i] & st7_s, st7_sy_b[i], st7_sy_t[i], st7_sy_t_[i]);
			full_adder FA_7_sy_1(st7_sy_t[i], st7_sy_b_[i] & st7_s, st7_sy_t_[i], st7_sy_s[i], st7_sy_s_[i]);
		end
	endgenerate
	wire [80:0] st7_yc;
	assign st7_yc[0] = 1'b0;
	generate
		for (i=0; i<80; i=i+1) begin : CPA
			full_adder CPA_2(st7_sy_s[i], st7_sy_s_[i], st7_yc[i], y_nxt[i], st7_yc[i+1]);
		end
	endgenerate
	// <<<< CORDIC Stages <<<<
	wire [63:0] shft_abs;
	wire [63:0] shft_y;
	assign shft_abs = {{48{1'b0}}, x_int};
	fxp64s_var_shifter SHFT_OUT(clk, rstn, y[79:16], shft_abs, x_sign, shft_y);
	reg [63:0] out_y;
	wire rd_en;
	reg en_shift;
	reg en_out;
	assign rd_en = en_out_data & rdy_out_data;
	assign en_out_data = en_out;
	always @(posedge clk) begin
		en_shift <= clr_cntr & rstn;
		en_out <= rstn & ~rd_en & (en_out | en_shift);
		out_y <= (en_shift ? shft_y : out_y) & {64{rstn}};
	end
	assign wip = en_cntr | en_shift | en_out;
	assign out_data = out_y;

endmodule
