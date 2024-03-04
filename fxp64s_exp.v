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
	assign x_frac = in_x[47:0];
	assign clr_cntr = (cntr == 3'b111);
	reg [71:0] x;
	reg [79:0] y;
	wire [71:0] x_nxt;
	wire [79:0] y_nxt;
	always @(posedge clk) begin
		x <= (wr_en ? {x_frac, 16'b0000000000000000, 8'b00000000} : (en_cntr ? x_nxt : x)) & {72{rstn}};
		y <= (wr_en ? {16'b0000000000000000, 1'b1, 63'b000000000000000000000000000000000000000000000000000000000000000} : (en_cntr ? y_nxt : y)) & {80{rstn}};
	end
	// >>>> CORDIC Stages >>>>
	//// ROM blocks ////
	reg [71:0] log_rom0[6:0];
	always @(posedge clk) begin
		log_rom0[0] <= 72'b100101011100000000011010001110011111101111010110100010000000000000000000;
		log_rom0[1] <= 72'b000000001011100001111100000111111111100001010011101010110010100000000000;
		log_rom0[2] <= 72'b000000000000000010111000101010100000110011111110110111001011000100100000;
		log_rom0[3] <= 72'b000000000000000000000000101110001010101000111010111110110011000110001001;
		log_rom0[4] <= 72'b000000000000000000000000000000001011100010101010001110110010100100101101;
		log_rom0[5] <= 72'b000000000000000000000000000000000000000010111000101010100011101100101001;
		log_rom0[6] <= 72'b000000000000000000000000000000000000000000000000101110001010101000111011;
	end
	reg [71:0] log_rom1[6:0];
	always @(posedge clk) begin
		log_rom1[0] <= 72'b010100100110100111100001001011110011010001101110001011000000000000000000;
		log_rom1[1] <= 72'b000000000101110001001001100101001101110100001111110100010101010000000000;
		log_rom1[2] <= 72'b000000000000000001011100010101010001001000001010000011000100010111010100;
		log_rom1[3] <= 72'b000000000000000000000000010111000101010100011101100010010010001101101000;
		log_rom1[4] <= 72'b000000000000000000000000000000000101110001010101000111011001010010100010;
		log_rom1[5] <= 72'b000000000000000000000000000000000000000001011100010101010001110110010100;
		log_rom1[6] <= 72'b000000000000000000000000000000000000000000000000010111000101010100011101;
	end
	reg [71:0] log_rom2[6:0];
	always @(posedge clk) begin
		log_rom2[0] <= 72'b001010111000000000110100011100111111011110101101000100000000000000000000;
		log_rom2[1] <= 72'b000000000010111000100111101011000101111011110010101011111000011000000000;
		log_rom2[2] <= 72'b000000000000000000101110001010101000101111100111101011100101011011100110;
		log_rom2[3] <= 72'b000000000000000000000000001011100010101010001110110001110111010001011101;
		log_rom2[4] <= 72'b000000000000000000000000000000000010111000101010100011101100101001010100;
		log_rom2[5] <= 72'b000000000000000000000000000000000000000000101110001010101000111011001010;
		log_rom2[6] <= 72'b000000000000000000000000000000000000000000000000001011100010101010001110;
	end
	reg [71:0] log_rom3[6:0];
	always @(posedge clk) begin
		log_rom3[0] <= 72'b000101100110001111110110111110101100100100010011000101100000000000000000;
		log_rom3[1] <= 72'b000000000001011100010100100011101100001010100001101111111100100100000000;
		log_rom3[2] <= 72'b000000000000000000010111000101010100011010101100100000010100111110000111;
		log_rom3[3] <= 72'b000000000000000000000000000101110001010101000111011001000111001011011000;
		log_rom3[4] <= 72'b000000000000000000000000000000000001011100010101010001110110010100101010;
		log_rom3[5] <= 72'b000000000000000000000000000000000000000000010111000101010100011101100101;
		log_rom3[6] <= 72'b000000000000000000000000000000000000000000000000000101110001010101000111;
	end
	reg [71:0] log_rom4[6:0];
	always @(posedge clk) begin
		log_rom4[0] <= 72'b000010110101110101101001101110101100011101111110110000111000000000000000;
		log_rom4[1] <= 72'b000000000000101110001010011101011000100011111101001010011011001000000000;
		log_rom4[2] <= 72'b000000000000000000001011100010101010001110000100011010110011001110101011;
		log_rom4[3] <= 72'b000000000000000000000000000010111000101010100011101100100110011110010110;
		log_rom4[4] <= 72'b000000000000000000000000000000000000101110001010101000111011001010010101;
		log_rom4[5] <= 72'b000000000000000000000000000000000000000000001011100010101010001110110010;
		log_rom4[6] <= 72'b000000000000000000000000000000000000000000000101110001010101000111011001;
	end
	reg [71:0] log_rom5[6:0];
	always @(posedge clk) begin
		log_rom5[0] <= 72'b000001011011100111100101101000010111000010110100100010101000000000000000;
		log_rom5[1] <= 72'b000000000000010111000101010001100100111011000101111101001101011110000000;
		log_rom5[2] <= 72'b000000000000000000000101110001010101000111001101110000000011110100101011;
		log_rom5[3] <= 72'b000000000000000000000000000001011100010101010001110110010011111101010110;
		log_rom5[4] <= 72'b000000000000000000000000000000000000010111000101010100011101100101001010;
		log_rom5[5] <= 72'b000000000000000000000000000000000000000000000101110001010101000111011001;
		log_rom5[6] <= 72'b000000000000000000000000000000000000000000000010111000101010100011101100;
	end
	reg [71:0] log_rom6[6:0];
	always @(posedge clk) begin
		log_rom6[0] <= 72'b000000101101111111001010000101101101110111100001000010100100000000000000;
		log_rom6[1] <= 72'b000000000000001011100010101001100000101000000000010111001001010111100000;
		log_rom6[2] <= 72'b000000000000000000000010111000101010100011101001110000101100011101110111;
		log_rom6[3] <= 72'b000000000000000000000000000000101110001010101000111011001010001010001101;
		log_rom6[4] <= 72'b000000000000000000000000000000000000001011100010101010001110110010100101;
		log_rom6[5] <= 72'b000000000000000000000000000000000000000000000010111000101010100011101100;
		log_rom6[6] <= 72'b000000000000000000000000000000000000000000000001011100010101010001110110;
	end
	reg [71:0] log_rom7[6:0];
	always @(posedge clk) begin
		log_rom7[0] <= 72'b000000010111000010011100010001101101011110101010110001110111000000000000;
		log_rom7[1] <= 72'b000000000000000101110001010100111011110110101000111110000010001001010000;
		log_rom7[2] <= 72'b000000000000000000000001011100010101010001110101100110100000110111110101;
		log_rom7[3] <= 72'b000000000000000000000000000000010111000101010100011101100101000111111111;
		log_rom7[4] <= 72'b000000000000000000000000000000000000000101110001010101000111011001010010;
		log_rom7[5] <= 72'b000000000000000000000000000000000000000000000001011100010101010001110110;
		log_rom7[6] <= 72'b000000000000000000000000000000000000000000000000101110001010101000111011;
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
	assign st0_ms_n[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[7] : x[15] ) : ( cntr[0] ? x[23] : x[31] ) ) : ( cntr[1] ? ( cntr[0] ? x[39] : x[47] ) : ( cntr[0] ? x[55] : x[63] ) ) );
	assign st0_ms_n[1] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[8] : x[16] ) : ( cntr[0] ? x[24] : x[32] ) ) : ( cntr[1] ? ( cntr[0] ? x[40] : x[48] ) : ( cntr[0] ? x[56] : x[64] ) ) );
	assign st0_ms_n[2] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[9] : x[17] ) : ( cntr[0] ? x[25] : x[33] ) ) : ( cntr[1] ? ( cntr[0] ? x[41] : x[49] ) : ( cntr[0] ? x[57] : x[65] ) ) );
	assign st0_ms_n[3] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[10] : x[18] ) : ( cntr[0] ? x[26] : x[34] ) ) : ( cntr[1] ? ( cntr[0] ? x[42] : x[50] ) : ( cntr[0] ? x[58] : x[66] ) ) );
	assign st0_ms_n[4] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[11] : x[19] ) : ( cntr[0] ? x[27] : x[35] ) ) : ( cntr[1] ? ( cntr[0] ? x[43] : x[51] ) : ( cntr[0] ? x[59] : x[67] ) ) );
	assign st0_ms_n[5] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[12] : x[20] ) : ( cntr[0] ? x[28] : x[36] ) ) : ( cntr[1] ? ( cntr[0] ? x[44] : x[52] ) : ( cntr[0] ? x[60] : x[68] ) ) );
	assign st0_ms_n[6] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[13] : x[21] ) : ( cntr[0] ? x[29] : x[37] ) ) : ( cntr[1] ? ( cntr[0] ? x[45] : x[53] ) : ( cntr[0] ? x[61] : x[69] ) ) );
	assign st0_ms_n[7] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[14] : x[22] ) : ( cntr[0] ? x[30] : x[38] ) ) : ( cntr[1] ? ( cntr[0] ? x[46] : x[54] ) : ( cntr[0] ? x[62] : x[70] ) ) );
	assign st0_ms_n[8] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[15] : x[23] ) : ( cntr[0] ? x[31] : x[39] ) ) : ( cntr[1] ? ( cntr[0] ? x[47] : x[55] ) : ( cntr[0] ? x[63] : x[71] ) ) );
	assign st0_ms_d[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][7] : log_rom0[cntr][15] ) : ( cntr[0] ? log_rom0[cntr][23] : log_rom0[cntr][31] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][39] : log_rom0[cntr][47] ) : ( cntr[0] ? log_rom0[cntr][55] : log_rom0[cntr][63] ) ) );
	assign st0_ms_d[1] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][8] : log_rom0[cntr][16] ) : ( cntr[0] ? log_rom0[cntr][24] : log_rom0[cntr][32] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][40] : log_rom0[cntr][48] ) : ( cntr[0] ? log_rom0[cntr][56] : log_rom0[cntr][64] ) ) );
	assign st0_ms_d[2] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][9] : log_rom0[cntr][17] ) : ( cntr[0] ? log_rom0[cntr][25] : log_rom0[cntr][33] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][41] : log_rom0[cntr][49] ) : ( cntr[0] ? log_rom0[cntr][57] : log_rom0[cntr][65] ) ) );
	assign st0_ms_d[3] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][10] : log_rom0[cntr][18] ) : ( cntr[0] ? log_rom0[cntr][26] : log_rom0[cntr][34] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][42] : log_rom0[cntr][50] ) : ( cntr[0] ? log_rom0[cntr][58] : log_rom0[cntr][66] ) ) );
	assign st0_ms_d[4] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][11] : log_rom0[cntr][19] ) : ( cntr[0] ? log_rom0[cntr][27] : log_rom0[cntr][35] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][43] : log_rom0[cntr][51] ) : ( cntr[0] ? log_rom0[cntr][59] : log_rom0[cntr][67] ) ) );
	assign st0_ms_d[5] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][12] : log_rom0[cntr][20] ) : ( cntr[0] ? log_rom0[cntr][28] : log_rom0[cntr][36] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][44] : log_rom0[cntr][52] ) : ( cntr[0] ? log_rom0[cntr][60] : log_rom0[cntr][68] ) ) );
	assign st0_ms_d[6] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][13] : log_rom0[cntr][21] ) : ( cntr[0] ? log_rom0[cntr][29] : log_rom0[cntr][37] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][45] : log_rom0[cntr][53] ) : ( cntr[0] ? log_rom0[cntr][61] : log_rom0[cntr][69] ) ) );
	assign st0_ms_d[7] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][14] : log_rom0[cntr][22] ) : ( cntr[0] ? log_rom0[cntr][30] : log_rom0[cntr][38] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][46] : log_rom0[cntr][54] ) : ( cntr[0] ? log_rom0[cntr][62] : log_rom0[cntr][70] ) ) );
	assign st0_ms_d[8] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][15] : log_rom0[cntr][23] ) : ( cntr[0] ? log_rom0[cntr][31] : log_rom0[cntr][39] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][47] : log_rom0[cntr][55] ) : ( cntr[0] ? log_rom0[cntr][63] : log_rom0[cntr][71] ) ) );
	restoring_subtractor RS_0_0(st0_ms_n[0], st0_ms_d[0], 1'b0, st0_ms_q[1], st0_ms_s[0], st0_ms_b[0], st0_ms_q[0]);
	generate
		for (i=1; i<8; i=i+1) begin : LOW_PREC_ST_0
			restoring_subtractor RS_0_i(st0_ms_n[i], st0_ms_d[i], st0_ms_b[i-1], st0_ms_q[i+1], st0_ms_s[i], st0_ms_b[i], st0_ms_q[i]);
		end
	endgenerate
	restoring_subtractor RS_0_8(st0_ms_n[8], st0_ms_d[8], st0_ms_b[7], st0_s, st0_ms_s[8], st0_ms_sn, st0_ms_q[8]);
	assign st0_s = ~st0_ms_sn;
	// Slave : X_Long
	wire [71:0] st0_sx_d;
	wire [71:0] st0_sx_s;
	wire [71:0] st0_sx_bo;
	assign st0_sx_d = log_rom0[cntr];
	generate
		for (i=0; i<72; i=i+1) begin : HIGH_PREC_ST_0
			full_subtractor FS_0_sx(x[i], st0_sx_d[i] & st0_s, 1'b0, st0_sx_s[i], st0_sx_bo[i]);
		end
	endgenerate
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
	// Master : X_Short
	wire st1_s;
	wire st1_ms_sn;
	wire [9:0] st1_ms_n;
	wire [9:0] st1_ms_d;
	wire [9:0] st1_ms_b;
	wire [9:0] st1_ms_q;
	wire [9:0] st1_ms_s;
	assign st1_ms_n[9:1] = st0_ms_s[8:0];
	assign st1_ms_n[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[6] : x[14] ) : ( cntr[0] ? x[22] : x[30] ) ) : ( cntr[1] ? ( cntr[0] ? x[38] : x[46] ) : ( cntr[0] ? x[54] : x[62] ) ) );
	assign st1_ms_d[9] = 1'b0;
	assign st1_ms_d[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][6] : log_rom1[cntr][14] ) : ( cntr[0] ? log_rom1[cntr][22] : log_rom1[cntr][30] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][38] : log_rom1[cntr][46] ) : ( cntr[0] ? log_rom1[cntr][54] : log_rom1[cntr][62] ) ) );
	assign st1_ms_d[1] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][7] : log_rom1[cntr][15] ) : ( cntr[0] ? log_rom1[cntr][23] : log_rom1[cntr][31] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][39] : log_rom1[cntr][47] ) : ( cntr[0] ? log_rom1[cntr][55] : log_rom1[cntr][63] ) ) );
	assign st1_ms_d[2] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][8] : log_rom1[cntr][16] ) : ( cntr[0] ? log_rom1[cntr][24] : log_rom1[cntr][32] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][40] : log_rom1[cntr][48] ) : ( cntr[0] ? log_rom1[cntr][56] : log_rom1[cntr][64] ) ) );
	assign st1_ms_d[3] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][9] : log_rom1[cntr][17] ) : ( cntr[0] ? log_rom1[cntr][25] : log_rom1[cntr][33] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][41] : log_rom1[cntr][49] ) : ( cntr[0] ? log_rom1[cntr][57] : log_rom1[cntr][65] ) ) );
	assign st1_ms_d[4] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][10] : log_rom1[cntr][18] ) : ( cntr[0] ? log_rom1[cntr][26] : log_rom1[cntr][34] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][42] : log_rom1[cntr][50] ) : ( cntr[0] ? log_rom1[cntr][58] : log_rom1[cntr][66] ) ) );
	assign st1_ms_d[5] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][11] : log_rom1[cntr][19] ) : ( cntr[0] ? log_rom1[cntr][27] : log_rom1[cntr][35] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][43] : log_rom1[cntr][51] ) : ( cntr[0] ? log_rom1[cntr][59] : log_rom1[cntr][67] ) ) );
	assign st1_ms_d[6] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][12] : log_rom1[cntr][20] ) : ( cntr[0] ? log_rom1[cntr][28] : log_rom1[cntr][36] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][44] : log_rom1[cntr][52] ) : ( cntr[0] ? log_rom1[cntr][60] : log_rom1[cntr][68] ) ) );
	assign st1_ms_d[7] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][13] : log_rom1[cntr][21] ) : ( cntr[0] ? log_rom1[cntr][29] : log_rom1[cntr][37] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][45] : log_rom1[cntr][53] ) : ( cntr[0] ? log_rom1[cntr][61] : log_rom1[cntr][69] ) ) );
	assign st1_ms_d[8] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][14] : log_rom1[cntr][22] ) : ( cntr[0] ? log_rom1[cntr][30] : log_rom1[cntr][38] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][46] : log_rom1[cntr][54] ) : ( cntr[0] ? log_rom1[cntr][62] : log_rom1[cntr][70] ) ) );
	restoring_subtractor RS_1_0(st1_ms_n[0], st1_ms_d[0], 1'b0, st1_ms_q[1], st1_ms_s[0], st1_ms_b[0], st1_ms_q[0]);
	generate
		for (i=1; i<9; i=i+1) begin : LOW_PREC_ST_1
			restoring_subtractor RS_1_i(st1_ms_n[i], st1_ms_d[i], st1_ms_b[i-1], st1_ms_q[i+1], st1_ms_s[i], st1_ms_b[i], st1_ms_q[i]);
		end
	endgenerate
	restoring_subtractor RS_1_9(st1_ms_n[9], st1_ms_d[9], st1_ms_b[8], st1_s, st1_ms_s[9], st1_ms_sn, st1_ms_q[9]);
	assign st1_s = ~st1_ms_sn;
	// Slave : X_Long
	wire [71:0] st1_sx_d;
	wire [71:0] st1_sx_s;
	wire [71:0] st1_sx_bo;
	wire [71:0] st1_sx_bi;
	assign st1_sx_bi[0] = 1'b0;
	assign st1_sx_bi[71:1] = st0_sx_bo[70:0];
	assign st1_sx_d = log_rom1[cntr];
	generate
		for (i=0; i<72; i=i+1) begin : HIGH_PREC_ST_1
			full_subtractor FS_1_sx(st0_sx_s[i], st1_sx_d[i] & st1_s, st1_sx_bi[i], st1_sx_s[i], st1_sx_bo[i]);
		end
	endgenerate
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
	// Master : X_Short
	wire st2_s;
	wire st2_ms_sn;
	wire [9:0] st2_ms_n;
	wire [9:0] st2_ms_d;
	wire [9:0] st2_ms_b;
	wire [9:0] st2_ms_q;
	wire [9:0] st2_ms_s;
	assign st2_ms_n[9:1] = st1_ms_s[8:0];
	assign st2_ms_n[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[5] : x[13] ) : ( cntr[0] ? x[21] : x[29] ) ) : ( cntr[1] ? ( cntr[0] ? x[37] : x[45] ) : ( cntr[0] ? x[53] : x[61] ) ) );
	assign st2_ms_d[9] = 1'b0;
	assign st2_ms_d[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][5] : log_rom2[cntr][13] ) : ( cntr[0] ? log_rom2[cntr][21] : log_rom2[cntr][29] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][37] : log_rom2[cntr][45] ) : ( cntr[0] ? log_rom2[cntr][53] : log_rom2[cntr][61] ) ) );
	assign st2_ms_d[1] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][6] : log_rom2[cntr][14] ) : ( cntr[0] ? log_rom2[cntr][22] : log_rom2[cntr][30] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][38] : log_rom2[cntr][46] ) : ( cntr[0] ? log_rom2[cntr][54] : log_rom2[cntr][62] ) ) );
	assign st2_ms_d[2] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][7] : log_rom2[cntr][15] ) : ( cntr[0] ? log_rom2[cntr][23] : log_rom2[cntr][31] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][39] : log_rom2[cntr][47] ) : ( cntr[0] ? log_rom2[cntr][55] : log_rom2[cntr][63] ) ) );
	assign st2_ms_d[3] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][8] : log_rom2[cntr][16] ) : ( cntr[0] ? log_rom2[cntr][24] : log_rom2[cntr][32] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][40] : log_rom2[cntr][48] ) : ( cntr[0] ? log_rom2[cntr][56] : log_rom2[cntr][64] ) ) );
	assign st2_ms_d[4] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][9] : log_rom2[cntr][17] ) : ( cntr[0] ? log_rom2[cntr][25] : log_rom2[cntr][33] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][41] : log_rom2[cntr][49] ) : ( cntr[0] ? log_rom2[cntr][57] : log_rom2[cntr][65] ) ) );
	assign st2_ms_d[5] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][10] : log_rom2[cntr][18] ) : ( cntr[0] ? log_rom2[cntr][26] : log_rom2[cntr][34] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][42] : log_rom2[cntr][50] ) : ( cntr[0] ? log_rom2[cntr][58] : log_rom2[cntr][66] ) ) );
	assign st2_ms_d[6] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][11] : log_rom2[cntr][19] ) : ( cntr[0] ? log_rom2[cntr][27] : log_rom2[cntr][35] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][43] : log_rom2[cntr][51] ) : ( cntr[0] ? log_rom2[cntr][59] : log_rom2[cntr][67] ) ) );
	assign st2_ms_d[7] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][12] : log_rom2[cntr][20] ) : ( cntr[0] ? log_rom2[cntr][28] : log_rom2[cntr][36] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][44] : log_rom2[cntr][52] ) : ( cntr[0] ? log_rom2[cntr][60] : log_rom2[cntr][68] ) ) );
	assign st2_ms_d[8] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][13] : log_rom2[cntr][21] ) : ( cntr[0] ? log_rom2[cntr][29] : log_rom2[cntr][37] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][45] : log_rom2[cntr][53] ) : ( cntr[0] ? log_rom2[cntr][61] : log_rom2[cntr][69] ) ) );
	restoring_subtractor RS_2_0(st2_ms_n[0], st2_ms_d[0], 1'b0, st2_ms_q[1], st2_ms_s[0], st2_ms_b[0], st2_ms_q[0]);
	generate
		for (i=1; i<9; i=i+1) begin : LOW_PREC_ST_2
			restoring_subtractor RS_2_i(st2_ms_n[i], st2_ms_d[i], st2_ms_b[i-1], st2_ms_q[i+1], st2_ms_s[i], st2_ms_b[i], st2_ms_q[i]);
		end
	endgenerate
	restoring_subtractor RS_2_9(st2_ms_n[9], st2_ms_d[9], st2_ms_b[8], st2_s, st2_ms_s[9], st2_ms_sn, st2_ms_q[9]);
	assign st2_s = ~st2_ms_sn;
	// Slave : X_Long
	wire [71:0] st2_sx_d;
	wire [71:0] st2_sx_s;
	wire [71:0] st2_sx_bo;
	wire [71:0] st2_sx_bi;
	assign st2_sx_bi[0] = 1'b0;
	assign st2_sx_bi[71:1] = st1_sx_bo[70:0];
	assign st2_sx_d = log_rom2[cntr];
	generate
		for (i=0; i<72; i=i+1) begin : HIGH_PREC_ST_2
			full_subtractor FS_2_sx(st1_sx_s[i], st2_sx_d[i] & st2_s, st2_sx_bi[i], st2_sx_s[i], st2_sx_bo[i]);
		end
	endgenerate
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
	// Master : X_Short
	wire st3_s;
	wire st3_ms_sn;
	wire [9:0] st3_ms_n;
	wire [9:0] st3_ms_d;
	wire [9:0] st3_ms_b;
	wire [9:0] st3_ms_q;
	wire [9:0] st3_ms_s;
	assign st3_ms_n[9:1] = st2_ms_s[8:0];
	assign st3_ms_n[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[4] : x[12] ) : ( cntr[0] ? x[20] : x[28] ) ) : ( cntr[1] ? ( cntr[0] ? x[36] : x[44] ) : ( cntr[0] ? x[52] : x[60] ) ) );
	assign st3_ms_d[9] = 1'b0;
	assign st3_ms_d[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom3[cntr][4] : log_rom3[cntr][12] ) : ( cntr[0] ? log_rom3[cntr][20] : log_rom3[cntr][28] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom3[cntr][36] : log_rom3[cntr][44] ) : ( cntr[0] ? log_rom3[cntr][52] : log_rom3[cntr][60] ) ) );
	assign st3_ms_d[1] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom3[cntr][5] : log_rom3[cntr][13] ) : ( cntr[0] ? log_rom3[cntr][21] : log_rom3[cntr][29] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom3[cntr][37] : log_rom3[cntr][45] ) : ( cntr[0] ? log_rom3[cntr][53] : log_rom3[cntr][61] ) ) );
	assign st3_ms_d[2] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom3[cntr][6] : log_rom3[cntr][14] ) : ( cntr[0] ? log_rom3[cntr][22] : log_rom3[cntr][30] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom3[cntr][38] : log_rom3[cntr][46] ) : ( cntr[0] ? log_rom3[cntr][54] : log_rom3[cntr][62] ) ) );
	assign st3_ms_d[3] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom3[cntr][7] : log_rom3[cntr][15] ) : ( cntr[0] ? log_rom3[cntr][23] : log_rom3[cntr][31] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom3[cntr][39] : log_rom3[cntr][47] ) : ( cntr[0] ? log_rom3[cntr][55] : log_rom3[cntr][63] ) ) );
	assign st3_ms_d[4] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom3[cntr][8] : log_rom3[cntr][16] ) : ( cntr[0] ? log_rom3[cntr][24] : log_rom3[cntr][32] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom3[cntr][40] : log_rom3[cntr][48] ) : ( cntr[0] ? log_rom3[cntr][56] : log_rom3[cntr][64] ) ) );
	assign st3_ms_d[5] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom3[cntr][9] : log_rom3[cntr][17] ) : ( cntr[0] ? log_rom3[cntr][25] : log_rom3[cntr][33] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom3[cntr][41] : log_rom3[cntr][49] ) : ( cntr[0] ? log_rom3[cntr][57] : log_rom3[cntr][65] ) ) );
	assign st3_ms_d[6] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom3[cntr][10] : log_rom3[cntr][18] ) : ( cntr[0] ? log_rom3[cntr][26] : log_rom3[cntr][34] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom3[cntr][42] : log_rom3[cntr][50] ) : ( cntr[0] ? log_rom3[cntr][58] : log_rom3[cntr][66] ) ) );
	assign st3_ms_d[7] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom3[cntr][11] : log_rom3[cntr][19] ) : ( cntr[0] ? log_rom3[cntr][27] : log_rom3[cntr][35] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom3[cntr][43] : log_rom3[cntr][51] ) : ( cntr[0] ? log_rom3[cntr][59] : log_rom3[cntr][67] ) ) );
	assign st3_ms_d[8] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom3[cntr][12] : log_rom3[cntr][20] ) : ( cntr[0] ? log_rom3[cntr][28] : log_rom3[cntr][36] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom3[cntr][44] : log_rom3[cntr][52] ) : ( cntr[0] ? log_rom3[cntr][60] : log_rom3[cntr][68] ) ) );
	restoring_subtractor RS_3_0(st3_ms_n[0], st3_ms_d[0], 1'b0, st3_ms_q[1], st3_ms_s[0], st3_ms_b[0], st3_ms_q[0]);
	generate
		for (i=1; i<9; i=i+1) begin : LOW_PREC_ST_3
			restoring_subtractor RS_3_i(st3_ms_n[i], st3_ms_d[i], st3_ms_b[i-1], st3_ms_q[i+1], st3_ms_s[i], st3_ms_b[i], st3_ms_q[i]);
		end
	endgenerate
	restoring_subtractor RS_3_9(st3_ms_n[9], st3_ms_d[9], st3_ms_b[8], st3_s, st3_ms_s[9], st3_ms_sn, st3_ms_q[9]);
	assign st3_s = ~st3_ms_sn;
	// Slave : X_Long
	wire [71:0] st3_sx_d;
	wire [71:0] st3_sx_s;
	wire [71:0] st3_sx_bo;
	wire [71:0] st3_sx_bi;
	assign st3_sx_bi[0] = 1'b0;
	assign st3_sx_bi[71:1] = st2_sx_bo[70:0];
	assign st3_sx_d = log_rom3[cntr];
	generate
		for (i=0; i<72; i=i+1) begin : HIGH_PREC_ST_3
			full_subtractor FS_3_sx(st2_sx_s[i], st3_sx_d[i] & st3_s, st3_sx_bi[i], st3_sx_s[i], st3_sx_bo[i]);
		end
	endgenerate
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
	// Master : X_Short
	wire st4_s;
	wire st4_ms_sn;
	wire [9:0] st4_ms_n;
	wire [9:0] st4_ms_d;
	wire [9:0] st4_ms_b;
	wire [9:0] st4_ms_q;
	wire [9:0] st4_ms_s;
	assign st4_ms_n[9:1] = st3_ms_s[8:0];
	assign st4_ms_n[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[3] : x[11] ) : ( cntr[0] ? x[19] : x[27] ) ) : ( cntr[1] ? ( cntr[0] ? x[35] : x[43] ) : ( cntr[0] ? x[51] : x[59] ) ) );
	assign st4_ms_d[9] = 1'b0;
	assign st4_ms_d[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom4[cntr][3] : log_rom4[cntr][11] ) : ( cntr[0] ? log_rom4[cntr][19] : log_rom4[cntr][27] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom4[cntr][35] : log_rom4[cntr][43] ) : ( cntr[0] ? log_rom4[cntr][51] : log_rom4[cntr][59] ) ) );
	assign st4_ms_d[1] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom4[cntr][4] : log_rom4[cntr][12] ) : ( cntr[0] ? log_rom4[cntr][20] : log_rom4[cntr][28] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom4[cntr][36] : log_rom4[cntr][44] ) : ( cntr[0] ? log_rom4[cntr][52] : log_rom4[cntr][60] ) ) );
	assign st4_ms_d[2] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom4[cntr][5] : log_rom4[cntr][13] ) : ( cntr[0] ? log_rom4[cntr][21] : log_rom4[cntr][29] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom4[cntr][37] : log_rom4[cntr][45] ) : ( cntr[0] ? log_rom4[cntr][53] : log_rom4[cntr][61] ) ) );
	assign st4_ms_d[3] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom4[cntr][6] : log_rom4[cntr][14] ) : ( cntr[0] ? log_rom4[cntr][22] : log_rom4[cntr][30] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom4[cntr][38] : log_rom4[cntr][46] ) : ( cntr[0] ? log_rom4[cntr][54] : log_rom4[cntr][62] ) ) );
	assign st4_ms_d[4] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom4[cntr][7] : log_rom4[cntr][15] ) : ( cntr[0] ? log_rom4[cntr][23] : log_rom4[cntr][31] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom4[cntr][39] : log_rom4[cntr][47] ) : ( cntr[0] ? log_rom4[cntr][55] : log_rom4[cntr][63] ) ) );
	assign st4_ms_d[5] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom4[cntr][8] : log_rom4[cntr][16] ) : ( cntr[0] ? log_rom4[cntr][24] : log_rom4[cntr][32] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom4[cntr][40] : log_rom4[cntr][48] ) : ( cntr[0] ? log_rom4[cntr][56] : log_rom4[cntr][64] ) ) );
	assign st4_ms_d[6] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom4[cntr][9] : log_rom4[cntr][17] ) : ( cntr[0] ? log_rom4[cntr][25] : log_rom4[cntr][33] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom4[cntr][41] : log_rom4[cntr][49] ) : ( cntr[0] ? log_rom4[cntr][57] : log_rom4[cntr][65] ) ) );
	assign st4_ms_d[7] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom4[cntr][10] : log_rom4[cntr][18] ) : ( cntr[0] ? log_rom4[cntr][26] : log_rom4[cntr][34] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom4[cntr][42] : log_rom4[cntr][50] ) : ( cntr[0] ? log_rom4[cntr][58] : log_rom4[cntr][66] ) ) );
	assign st4_ms_d[8] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom4[cntr][11] : log_rom4[cntr][19] ) : ( cntr[0] ? log_rom4[cntr][27] : log_rom4[cntr][35] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom4[cntr][43] : log_rom4[cntr][51] ) : ( cntr[0] ? log_rom4[cntr][59] : log_rom4[cntr][67] ) ) );
	restoring_subtractor RS_4_0(st4_ms_n[0], st4_ms_d[0], 1'b0, st4_ms_q[1], st4_ms_s[0], st4_ms_b[0], st4_ms_q[0]);
	generate
		for (i=1; i<9; i=i+1) begin : LOW_PREC_ST_4
			restoring_subtractor RS_4_i(st4_ms_n[i], st4_ms_d[i], st4_ms_b[i-1], st4_ms_q[i+1], st4_ms_s[i], st4_ms_b[i], st4_ms_q[i]);
		end
	endgenerate
	restoring_subtractor RS_4_9(st4_ms_n[9], st4_ms_d[9], st4_ms_b[8], st4_s, st4_ms_s[9], st4_ms_sn, st4_ms_q[9]);
	assign st4_s = ~st4_ms_sn;
	// Slave : X_Long
	wire [71:0] st4_sx_d;
	wire [71:0] st4_sx_s;
	wire [71:0] st4_sx_bo;
	wire [71:0] st4_sx_bi;
	assign st4_sx_bi[0] = 1'b0;
	assign st4_sx_bi[71:1] = st3_sx_bo[70:0];
	assign st4_sx_d = log_rom4[cntr];
	generate
		for (i=0; i<72; i=i+1) begin : HIGH_PREC_ST_4
			full_subtractor FS_4_sx(st3_sx_s[i], st4_sx_d[i] & st4_s, st4_sx_bi[i], st4_sx_s[i], st4_sx_bo[i]);
		end
	endgenerate
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
	// Master : X_Short
	wire st5_s;
	wire st5_ms_sn;
	wire [9:0] st5_ms_n;
	wire [9:0] st5_ms_d;
	wire [9:0] st5_ms_b;
	wire [9:0] st5_ms_q;
	wire [9:0] st5_ms_s;
	assign st5_ms_n[9:1] = st4_ms_s[8:0];
	assign st5_ms_n[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[2] : x[10] ) : ( cntr[0] ? x[18] : x[26] ) ) : ( cntr[1] ? ( cntr[0] ? x[34] : x[42] ) : ( cntr[0] ? x[50] : x[58] ) ) );
	assign st5_ms_d[9] = 1'b0;
	assign st5_ms_d[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom5[cntr][2] : log_rom5[cntr][10] ) : ( cntr[0] ? log_rom5[cntr][18] : log_rom5[cntr][26] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom5[cntr][34] : log_rom5[cntr][42] ) : ( cntr[0] ? log_rom5[cntr][50] : log_rom5[cntr][58] ) ) );
	assign st5_ms_d[1] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom5[cntr][3] : log_rom5[cntr][11] ) : ( cntr[0] ? log_rom5[cntr][19] : log_rom5[cntr][27] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom5[cntr][35] : log_rom5[cntr][43] ) : ( cntr[0] ? log_rom5[cntr][51] : log_rom5[cntr][59] ) ) );
	assign st5_ms_d[2] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom5[cntr][4] : log_rom5[cntr][12] ) : ( cntr[0] ? log_rom5[cntr][20] : log_rom5[cntr][28] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom5[cntr][36] : log_rom5[cntr][44] ) : ( cntr[0] ? log_rom5[cntr][52] : log_rom5[cntr][60] ) ) );
	assign st5_ms_d[3] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom5[cntr][5] : log_rom5[cntr][13] ) : ( cntr[0] ? log_rom5[cntr][21] : log_rom5[cntr][29] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom5[cntr][37] : log_rom5[cntr][45] ) : ( cntr[0] ? log_rom5[cntr][53] : log_rom5[cntr][61] ) ) );
	assign st5_ms_d[4] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom5[cntr][6] : log_rom5[cntr][14] ) : ( cntr[0] ? log_rom5[cntr][22] : log_rom5[cntr][30] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom5[cntr][38] : log_rom5[cntr][46] ) : ( cntr[0] ? log_rom5[cntr][54] : log_rom5[cntr][62] ) ) );
	assign st5_ms_d[5] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom5[cntr][7] : log_rom5[cntr][15] ) : ( cntr[0] ? log_rom5[cntr][23] : log_rom5[cntr][31] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom5[cntr][39] : log_rom5[cntr][47] ) : ( cntr[0] ? log_rom5[cntr][55] : log_rom5[cntr][63] ) ) );
	assign st5_ms_d[6] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom5[cntr][8] : log_rom5[cntr][16] ) : ( cntr[0] ? log_rom5[cntr][24] : log_rom5[cntr][32] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom5[cntr][40] : log_rom5[cntr][48] ) : ( cntr[0] ? log_rom5[cntr][56] : log_rom5[cntr][64] ) ) );
	assign st5_ms_d[7] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom5[cntr][9] : log_rom5[cntr][17] ) : ( cntr[0] ? log_rom5[cntr][25] : log_rom5[cntr][33] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom5[cntr][41] : log_rom5[cntr][49] ) : ( cntr[0] ? log_rom5[cntr][57] : log_rom5[cntr][65] ) ) );
	assign st5_ms_d[8] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom5[cntr][10] : log_rom5[cntr][18] ) : ( cntr[0] ? log_rom5[cntr][26] : log_rom5[cntr][34] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom5[cntr][42] : log_rom5[cntr][50] ) : ( cntr[0] ? log_rom5[cntr][58] : log_rom5[cntr][66] ) ) );
	restoring_subtractor RS_5_0(st5_ms_n[0], st5_ms_d[0], 1'b0, st5_ms_q[1], st5_ms_s[0], st5_ms_b[0], st5_ms_q[0]);
	generate
		for (i=1; i<9; i=i+1) begin : LOW_PREC_ST_5
			restoring_subtractor RS_5_i(st5_ms_n[i], st5_ms_d[i], st5_ms_b[i-1], st5_ms_q[i+1], st5_ms_s[i], st5_ms_b[i], st5_ms_q[i]);
		end
	endgenerate
	restoring_subtractor RS_5_9(st5_ms_n[9], st5_ms_d[9], st5_ms_b[8], st5_s, st5_ms_s[9], st5_ms_sn, st5_ms_q[9]);
	assign st5_s = ~st5_ms_sn;
	// Slave : X_Long
	wire [71:0] st5_sx_d;
	wire [71:0] st5_sx_s;
	wire [71:0] st5_sx_bo;
	wire [71:0] st5_sx_bi;
	assign st5_sx_bi[0] = 1'b0;
	assign st5_sx_bi[71:1] = st4_sx_bo[70:0];
	assign st5_sx_d = log_rom5[cntr];
	generate
		for (i=0; i<72; i=i+1) begin : HIGH_PREC_ST_5
			full_subtractor FS_5_sx(st4_sx_s[i], st5_sx_d[i] & st5_s, st5_sx_bi[i], st5_sx_s[i], st5_sx_bo[i]);
		end
	endgenerate
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
	// Master : X_Short
	wire st6_s;
	wire st6_ms_sn;
	wire [9:0] st6_ms_n;
	wire [9:0] st6_ms_d;
	wire [9:0] st6_ms_b;
	wire [9:0] st6_ms_q;
	wire [9:0] st6_ms_s;
	assign st6_ms_n[9:1] = st5_ms_s[8:0];
	assign st6_ms_n[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[1] : x[9] ) : ( cntr[0] ? x[17] : x[25] ) ) : ( cntr[1] ? ( cntr[0] ? x[33] : x[41] ) : ( cntr[0] ? x[49] : x[57] ) ) );
	assign st6_ms_d[9] = 1'b0;
	assign st6_ms_d[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom6[cntr][1] : log_rom6[cntr][9] ) : ( cntr[0] ? log_rom6[cntr][17] : log_rom6[cntr][25] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom6[cntr][33] : log_rom6[cntr][41] ) : ( cntr[0] ? log_rom6[cntr][49] : log_rom6[cntr][57] ) ) );
	assign st6_ms_d[1] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom6[cntr][2] : log_rom6[cntr][10] ) : ( cntr[0] ? log_rom6[cntr][18] : log_rom6[cntr][26] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom6[cntr][34] : log_rom6[cntr][42] ) : ( cntr[0] ? log_rom6[cntr][50] : log_rom6[cntr][58] ) ) );
	assign st6_ms_d[2] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom6[cntr][3] : log_rom6[cntr][11] ) : ( cntr[0] ? log_rom6[cntr][19] : log_rom6[cntr][27] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom6[cntr][35] : log_rom6[cntr][43] ) : ( cntr[0] ? log_rom6[cntr][51] : log_rom6[cntr][59] ) ) );
	assign st6_ms_d[3] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom6[cntr][4] : log_rom6[cntr][12] ) : ( cntr[0] ? log_rom6[cntr][20] : log_rom6[cntr][28] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom6[cntr][36] : log_rom6[cntr][44] ) : ( cntr[0] ? log_rom6[cntr][52] : log_rom6[cntr][60] ) ) );
	assign st6_ms_d[4] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom6[cntr][5] : log_rom6[cntr][13] ) : ( cntr[0] ? log_rom6[cntr][21] : log_rom6[cntr][29] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom6[cntr][37] : log_rom6[cntr][45] ) : ( cntr[0] ? log_rom6[cntr][53] : log_rom6[cntr][61] ) ) );
	assign st6_ms_d[5] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom6[cntr][6] : log_rom6[cntr][14] ) : ( cntr[0] ? log_rom6[cntr][22] : log_rom6[cntr][30] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom6[cntr][38] : log_rom6[cntr][46] ) : ( cntr[0] ? log_rom6[cntr][54] : log_rom6[cntr][62] ) ) );
	assign st6_ms_d[6] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom6[cntr][7] : log_rom6[cntr][15] ) : ( cntr[0] ? log_rom6[cntr][23] : log_rom6[cntr][31] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom6[cntr][39] : log_rom6[cntr][47] ) : ( cntr[0] ? log_rom6[cntr][55] : log_rom6[cntr][63] ) ) );
	assign st6_ms_d[7] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom6[cntr][8] : log_rom6[cntr][16] ) : ( cntr[0] ? log_rom6[cntr][24] : log_rom6[cntr][32] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom6[cntr][40] : log_rom6[cntr][48] ) : ( cntr[0] ? log_rom6[cntr][56] : log_rom6[cntr][64] ) ) );
	assign st6_ms_d[8] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom6[cntr][9] : log_rom6[cntr][17] ) : ( cntr[0] ? log_rom6[cntr][25] : log_rom6[cntr][33] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom6[cntr][41] : log_rom6[cntr][49] ) : ( cntr[0] ? log_rom6[cntr][57] : log_rom6[cntr][65] ) ) );
	restoring_subtractor RS_6_0(st6_ms_n[0], st6_ms_d[0], 1'b0, st6_ms_q[1], st6_ms_s[0], st6_ms_b[0], st6_ms_q[0]);
	generate
		for (i=1; i<9; i=i+1) begin : LOW_PREC_ST_6
			restoring_subtractor RS_6_i(st6_ms_n[i], st6_ms_d[i], st6_ms_b[i-1], st6_ms_q[i+1], st6_ms_s[i], st6_ms_b[i], st6_ms_q[i]);
		end
	endgenerate
	restoring_subtractor RS_6_9(st6_ms_n[9], st6_ms_d[9], st6_ms_b[8], st6_s, st6_ms_s[9], st6_ms_sn, st6_ms_q[9]);
	assign st6_s = ~st6_ms_sn;
	// Slave : X_Long
	wire [71:0] st6_sx_d;
	wire [71:0] st6_sx_s;
	wire [71:0] st6_sx_bo;
	wire [71:0] st6_sx_bi;
	assign st6_sx_bi[0] = 1'b0;
	assign st6_sx_bi[71:1] = st5_sx_bo[70:0];
	assign st6_sx_d = log_rom6[cntr];
	generate
		for (i=0; i<72; i=i+1) begin : HIGH_PREC_ST_6
			full_subtractor FS_6_sx(st5_sx_s[i], st6_sx_d[i] & st6_s, st6_sx_bi[i], st6_sx_s[i], st6_sx_bo[i]);
		end
	endgenerate
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
	wire st7_s;
	wire [71:0] st7_x;
	wire [71:0] st7_cd;
	assign st7_cd[0] = 1'b0;
	assign st7_cd[71:1] = st6_sx_bo[70:0];
	wire [72:0] st7_cb;
	assign st7_cb[0] = 1'b0;
	generate
		for (i=0; i<72; i=i+1) begin : BPS_1
			full_subtractor BPS_1(st6_sx_s[i], st7_cd[i], st7_cb[i], st7_x[i], st7_cb[i+1]);
		end
	endgenerate
	wire [71:0] st7_d;
	wire [72:0] st7_b;
	assign st7_b[0] = 1'b0;
	assign st7_d = log_rom7[cntr];
	generate
		for (i=0; i<72; i=i+1) begin : BPS_2
			full_subtractor BPS_2(st7_x[i], st7_d[i], st7_b[i], x_nxt[i], st7_b[i+1]);
		end
	endgenerate
	assign st7_s = ~st7_b[72];
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
	wire [63:0] shft_qty;
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
