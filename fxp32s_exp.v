// IO Params
`define FXP32S_ADDR 31:0
`define FXP32S_WIDTH 32
`define FXP32S_SIGN 31
`define FXP32S_MAG 30:0
`define FXP32S_LSB_POW -24

module fxp32s_exp(
	input clk,
	input rstn,
	// Input Stream
	input en_in_data,
	output rdy_in_data,
	input [`FXP32S_ADDR] in_data,
	// Output Stream
	output en_out_data,
	input rdy_out_data,
	output [`FXP32S_ADDR] out_data
);
	wire wr_en;
	assign wr_en = en_in_data & rdy_in_data;
	wire wip;
	reg en_cntr;
	wire clr_cntr;
	reg [2:0] cntr;
	reg cntr_c;
	wire [31:0] in_x;
	assign in_x = (in_data ^ {32{in_data[31]}}) + in_data[31];
	reg x_sign;
	reg [7:0] x_int;
	wire [23:0] x_frac;
	assign rdy_in_data = en_in_data & ~wip;
	always @(posedge clk) begin
		en_cntr <= rstn & ~clr_cntr & (en_cntr | wr_en);
		{cntr_c, cntr} <= (cntr + en_cntr) & {4{rstn & ~clr_cntr}};
		x_sign <= rstn & (wr_en ? in_data[31] : x_sign);
		x_int <= (wr_en ? in_x[31:24] + in_data[31] : x_int) & {8{rstn}};
	end
	assign x_frac = in_data[23:0];
	assign clr_cntr = (cntr == 3'b111);
	reg [39:0] x;
	reg [39:0] y;
	wire [39:0] x_nxt;
	wire [39:0] y_nxt;
	always @(posedge clk) begin
		x <= (wr_en ? {x_frac, 8'b00000000, 8'b00000000} : (en_cntr ? x_nxt : x)) & {40{rstn}};
		y <= (wr_en ? {7'b0000000, 1'b1, 32'b00000000000000000000000000000000} : (en_cntr ? y_nxt : y)) & {40{rstn}};
	end
	// >>>> CORDIC Stages >>>>
	//// ROM blocks ////
	reg [39:0] log_rom0[7:0];
	always @(posedge clk) begin
		log_rom0[0] <= 40'b1001010111000000000110100011100111111011;
		log_rom0[1] <= 40'b0000101101011101011010011011101011000111;
		log_rom0[2] <= 40'b0000000010111000011111000001111111111000;
		log_rom0[3] <= 40'b0000000000001011100010100111010110001000;
		log_rom0[4] <= 40'b0000000000000000101110001010101000001100;
		log_rom0[5] <= 40'b0000000000000000000010111000101010100011;
		log_rom0[6] <= 40'b0000000000000000000000001011100010101010;
		log_rom0[7] <= 40'b0000000000000000000000000000101110001010;
	end
	reg [39:0] log_rom1[7:0];
	always @(posedge clk) begin
		log_rom1[0] <= 40'b0101001001101001111000010010111100110100;
		log_rom1[1] <= 40'b0000010110111001111001011010000101110000;
		log_rom1[2] <= 40'b0000000001011100010010011001010011011101;
		log_rom1[3] <= 40'b0000000000000101110001010100011001001110;
		log_rom1[4] <= 40'b0000000000000000010111000101010100010010;
		log_rom1[5] <= 40'b0000000000000000000001011100010101010001;
		log_rom1[6] <= 40'b0000000000000000000000000101110001010101;
		log_rom1[7] <= 40'b0000000000000000000000000000010111000101;
	end
	reg [39:0] log_rom2[7:0];
	always @(posedge clk) begin
		log_rom2[0] <= 40'b0010101110000000001101000111001111110111;
		log_rom2[1] <= 40'b0000001011011111110010100001011011011101;
		log_rom2[2] <= 40'b0000000000101110001001111010110001011110;
		log_rom2[3] <= 40'b0000000000000010111000101010011000001010;
		log_rom2[4] <= 40'b0000000000000000001011100010101010001011;
		log_rom2[5] <= 40'b0000000000000000000000101110001010101000;
		log_rom2[6] <= 40'b0000000000000000000000000010111000101010;
		log_rom2[7] <= 40'b0000000000000000000000000000001011100010;
	end
	reg [39:0] log_rom3[7:0];
	always @(posedge clk) begin
		log_rom3[0] <= 40'b0001011001100011111101101111101011001001;
		log_rom3[1] <= 40'b0000000101110000100111000100011011010111;
		log_rom3[2] <= 40'b0000000000010111000101001000111011000010;
		log_rom3[3] <= 40'b0000000000000001011100010101001110111101;
		log_rom3[4] <= 40'b0000000000000000000101110001010101000110;
		log_rom3[5] <= 40'b0000000000000000000000010111000101010100;
		log_rom3[6] <= 40'b0000000000000000000000000001011100010101;
		log_rom3[7] <= 40'b0000000000000000000000000000000101110001;
	end
	genvar i;
	//// Stage 0 ////
	// Master : X_Short
	wire st0_s;
	wire st0_ms_sn;
	wire [8:0] st0_ms_n;
	wire [8:0] st0_ms_d;
	wire [8:0] st0_ms_b;
	assign st0_ms_n[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[3] : x[7] ) : ( cntr[0] ? x[11] : x[15] ) ) : ( cntr[1] ? ( cntr[0] ? x[19] : x[23] ) : ( cntr[0] ? x[27] : x[31] ) ) );
	assign st0_ms_n[1] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[4] : x[8] ) : ( cntr[0] ? x[12] : x[16] ) ) : ( cntr[1] ? ( cntr[0] ? x[20] : x[24] ) : ( cntr[0] ? x[28] : x[32] ) ) );
	assign st0_ms_n[2] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[5] : x[9] ) : ( cntr[0] ? x[13] : x[17] ) ) : ( cntr[1] ? ( cntr[0] ? x[21] : x[25] ) : ( cntr[0] ? x[29] : x[33] ) ) );
	assign st0_ms_n[3] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[6] : x[10] ) : ( cntr[0] ? x[14] : x[18] ) ) : ( cntr[1] ? ( cntr[0] ? x[22] : x[26] ) : ( cntr[0] ? x[30] : x[34] ) ) );
	assign st0_ms_n[4] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[7] : x[11] ) : ( cntr[0] ? x[15] : x[19] ) ) : ( cntr[1] ? ( cntr[0] ? x[23] : x[27] ) : ( cntr[0] ? x[31] : x[35] ) ) );
	assign st0_ms_n[5] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[8] : x[12] ) : ( cntr[0] ? x[16] : x[20] ) ) : ( cntr[1] ? ( cntr[0] ? x[24] : x[28] ) : ( cntr[0] ? x[32] : x[36] ) ) );
	assign st0_ms_n[6] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[9] : x[13] ) : ( cntr[0] ? x[17] : x[21] ) ) : ( cntr[1] ? ( cntr[0] ? x[25] : x[29] ) : ( cntr[0] ? x[33] : x[37] ) ) );
	assign st0_ms_n[7] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[10] : x[14] ) : ( cntr[0] ? x[18] : x[22] ) ) : ( cntr[1] ? ( cntr[0] ? x[26] : x[30] ) : ( cntr[0] ? x[34] : x[38] ) ) );
	assign st0_ms_n[8] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? x[11] : x[15] ) : ( cntr[0] ? x[19] : x[23] ) ) : ( cntr[1] ? ( cntr[0] ? x[27] : x[31] ) : ( cntr[0] ? x[35] : x[39] ) ) );
	assign st0_ms_d[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][3] : log_rom0[cntr][7] ) : ( cntr[0] ? log_rom0[cntr][11] : log_rom0[cntr][15] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][19] : log_rom0[cntr][23] ) : ( cntr[0] ? log_rom0[cntr][27] : log_rom0[cntr][31] ) ) );
	assign st0_ms_d[1] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][4] : log_rom0[cntr][8] ) : ( cntr[0] ? log_rom0[cntr][12] : log_rom0[cntr][16] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][20] : log_rom0[cntr][24] ) : ( cntr[0] ? log_rom0[cntr][28] : log_rom0[cntr][32] ) ) );
	assign st0_ms_d[2] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][5] : log_rom0[cntr][9] ) : ( cntr[0] ? log_rom0[cntr][13] : log_rom0[cntr][17] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][21] : log_rom0[cntr][25] ) : ( cntr[0] ? log_rom0[cntr][29] : log_rom0[cntr][33] ) ) );
	assign st0_ms_d[3] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][6] : log_rom0[cntr][10] ) : ( cntr[0] ? log_rom0[cntr][14] : log_rom0[cntr][18] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][22] : log_rom0[cntr][26] ) : ( cntr[0] ? log_rom0[cntr][30] : log_rom0[cntr][34] ) ) );
	assign st0_ms_d[4] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][7] : log_rom0[cntr][11] ) : ( cntr[0] ? log_rom0[cntr][15] : log_rom0[cntr][19] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][23] : log_rom0[cntr][27] ) : ( cntr[0] ? log_rom0[cntr][31] : log_rom0[cntr][35] ) ) );
	assign st0_ms_d[5] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][8] : log_rom0[cntr][12] ) : ( cntr[0] ? log_rom0[cntr][16] : log_rom0[cntr][20] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][24] : log_rom0[cntr][28] ) : ( cntr[0] ? log_rom0[cntr][32] : log_rom0[cntr][36] ) ) );
	assign st0_ms_d[6] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][9] : log_rom0[cntr][13] ) : ( cntr[0] ? log_rom0[cntr][17] : log_rom0[cntr][21] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][25] : log_rom0[cntr][29] ) : ( cntr[0] ? log_rom0[cntr][33] : log_rom0[cntr][37] ) ) );
	assign st0_ms_d[7] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][10] : log_rom0[cntr][14] ) : ( cntr[0] ? log_rom0[cntr][18] : log_rom0[cntr][22] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][26] : log_rom0[cntr][30] ) : ( cntr[0] ? log_rom0[cntr][34] : log_rom0[cntr][38] ) ) );
	assign st0_ms_d[8] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][11] : log_rom0[cntr][15] ) : ( cntr[0] ? log_rom0[cntr][19] : log_rom0[cntr][23] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom0[cntr][27] : log_rom0[cntr][31] ) : ( cntr[0] ? log_rom0[cntr][35] : log_rom0[cntr][39] ) ) );
	comp_sub_b RS_0_0(st0_ms_n[0], st0_ms_d[0], 1'b0, st0_ms_b[0]);
	generate
		for (i=1; i<8; i=i+1) begin : LOW_PREC_ST_0
			comp_sub_b RS_0_i(st0_ms_n[i], st0_ms_d[i], st0_ms_b[i-1], st0_ms_b[i]);
		end
	endgenerate
	comp_sub_b RS_0_8(st0_ms_n[8], st0_ms_d[8], st0_ms_b[7], st0_ms_sn);
	assign st0_s = ~st0_ms_sn;
	// Slave : X_Long
	wire [39:0] st0_sx_d;
	wire [39:0] st0_sx_s;
	wire [39:0] st0_sx_bo;
	assign st0_sx_d = log_rom0[cntr];
	wire [39:0] st0_sx_test;
	generate
		for (i=0; i<40; i=i+1) begin : HIGH_PREC_ST_0
			assign st0_sx_test[i] = x[i];
			full_subtractor FS_0_sx(st0_sx_test[i], st0_sx_d[i] & st0_s, 1'b0, st0_sx_s[i], st0_sx_bo[i]);
		end
	endgenerate
	// Slave : Y_Long
	wire [39:0] st0_sy_a;
	wire [39:0] st0_sy_a_;
	wire [39:0] st0_sy_s;
	wire [39:0] st0_sy_s_;
	wire [39:0] st0_sy_shift_abs;
	assign st0_sy_shift_abs = 1 + {cntr, {3{1'b0}}};
	fxp40s_var_shifter SHFTA_Y_ST0(clk, rstn, st0_sy_a, st0_sy_shift_abs, 1'b1, st0_sy_a_);
	assign st0_sy_a = y;
	generate
		for (i=0; i<40; i=i+1) begin : SLAVE_ST_0
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
	assign st1_ms_n[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st0_sx_s[2] : st0_sx_s[6] ) : ( cntr[0] ? st0_sx_s[10] : st0_sx_s[14] ) ) : ( cntr[1] ? ( cntr[0] ? st0_sx_s[18] : st0_sx_s[22] ) : ( cntr[0] ? st0_sx_s[26] : st0_sx_s[30] ) ) );
	assign st1_ms_n[1] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st0_sx_s[3] : st0_sx_s[7] ) : ( cntr[0] ? st0_sx_s[11] : st0_sx_s[15] ) ) : ( cntr[1] ? ( cntr[0] ? st0_sx_s[19] : st0_sx_s[23] ) : ( cntr[0] ? st0_sx_s[27] : st0_sx_s[31] ) ) );
	assign st1_ms_n[2] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st0_sx_s[4] : st0_sx_s[8] ) : ( cntr[0] ? st0_sx_s[12] : st0_sx_s[16] ) ) : ( cntr[1] ? ( cntr[0] ? st0_sx_s[20] : st0_sx_s[24] ) : ( cntr[0] ? st0_sx_s[28] : st0_sx_s[32] ) ) );
	assign st1_ms_n[3] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st0_sx_s[5] : st0_sx_s[9] ) : ( cntr[0] ? st0_sx_s[13] : st0_sx_s[17] ) ) : ( cntr[1] ? ( cntr[0] ? st0_sx_s[21] : st0_sx_s[25] ) : ( cntr[0] ? st0_sx_s[29] : st0_sx_s[33] ) ) );
	assign st1_ms_n[4] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st0_sx_s[6] : st0_sx_s[10] ) : ( cntr[0] ? st0_sx_s[14] : st0_sx_s[18] ) ) : ( cntr[1] ? ( cntr[0] ? st0_sx_s[22] : st0_sx_s[26] ) : ( cntr[0] ? st0_sx_s[30] : st0_sx_s[34] ) ) );
	assign st1_ms_n[5] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st0_sx_s[7] : st0_sx_s[11] ) : ( cntr[0] ? st0_sx_s[15] : st0_sx_s[19] ) ) : ( cntr[1] ? ( cntr[0] ? st0_sx_s[23] : st0_sx_s[27] ) : ( cntr[0] ? st0_sx_s[31] : st0_sx_s[35] ) ) );
	assign st1_ms_n[6] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st0_sx_s[8] : st0_sx_s[12] ) : ( cntr[0] ? st0_sx_s[16] : st0_sx_s[20] ) ) : ( cntr[1] ? ( cntr[0] ? st0_sx_s[24] : st0_sx_s[28] ) : ( cntr[0] ? st0_sx_s[32] : st0_sx_s[36] ) ) );
	assign st1_ms_n[7] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st0_sx_s[9] : st0_sx_s[13] ) : ( cntr[0] ? st0_sx_s[17] : st0_sx_s[21] ) ) : ( cntr[1] ? ( cntr[0] ? st0_sx_s[25] : st0_sx_s[29] ) : ( cntr[0] ? st0_sx_s[33] : st0_sx_s[37] ) ) );
	assign st1_ms_n[8] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st0_sx_s[10] : st0_sx_s[14] ) : ( cntr[0] ? st0_sx_s[18] : st0_sx_s[22] ) ) : ( cntr[1] ? ( cntr[0] ? st0_sx_s[26] : st0_sx_s[30] ) : ( cntr[0] ? st0_sx_s[34] : st0_sx_s[38] ) ) );
	assign st1_ms_n[9] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st0_sx_s[11] : st0_sx_s[15] ) : ( cntr[0] ? st0_sx_s[19] : st0_sx_s[23] ) ) : ( cntr[1] ? ( cntr[0] ? st0_sx_s[27] : st0_sx_s[31] ) : ( cntr[0] ? st0_sx_s[35] : st0_sx_s[39] ) ) );
	assign st1_ms_d[9] = 1'b0;
	assign st1_ms_d[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][2] : log_rom1[cntr][6] ) : ( cntr[0] ? log_rom1[cntr][10] : log_rom1[cntr][14] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][18] : log_rom1[cntr][22] ) : ( cntr[0] ? log_rom1[cntr][26] : log_rom1[cntr][30] ) ) );
	assign st1_ms_d[1] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][3] : log_rom1[cntr][7] ) : ( cntr[0] ? log_rom1[cntr][11] : log_rom1[cntr][15] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][19] : log_rom1[cntr][23] ) : ( cntr[0] ? log_rom1[cntr][27] : log_rom1[cntr][31] ) ) );
	assign st1_ms_d[2] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][4] : log_rom1[cntr][8] ) : ( cntr[0] ? log_rom1[cntr][12] : log_rom1[cntr][16] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][20] : log_rom1[cntr][24] ) : ( cntr[0] ? log_rom1[cntr][28] : log_rom1[cntr][32] ) ) );
	assign st1_ms_d[3] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][5] : log_rom1[cntr][9] ) : ( cntr[0] ? log_rom1[cntr][13] : log_rom1[cntr][17] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][21] : log_rom1[cntr][25] ) : ( cntr[0] ? log_rom1[cntr][29] : log_rom1[cntr][33] ) ) );
	assign st1_ms_d[4] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][6] : log_rom1[cntr][10] ) : ( cntr[0] ? log_rom1[cntr][14] : log_rom1[cntr][18] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][22] : log_rom1[cntr][26] ) : ( cntr[0] ? log_rom1[cntr][30] : log_rom1[cntr][34] ) ) );
	assign st1_ms_d[5] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][7] : log_rom1[cntr][11] ) : ( cntr[0] ? log_rom1[cntr][15] : log_rom1[cntr][19] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][23] : log_rom1[cntr][27] ) : ( cntr[0] ? log_rom1[cntr][31] : log_rom1[cntr][35] ) ) );
	assign st1_ms_d[6] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][8] : log_rom1[cntr][12] ) : ( cntr[0] ? log_rom1[cntr][16] : log_rom1[cntr][20] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][24] : log_rom1[cntr][28] ) : ( cntr[0] ? log_rom1[cntr][32] : log_rom1[cntr][36] ) ) );
	assign st1_ms_d[7] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][9] : log_rom1[cntr][13] ) : ( cntr[0] ? log_rom1[cntr][17] : log_rom1[cntr][21] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][25] : log_rom1[cntr][29] ) : ( cntr[0] ? log_rom1[cntr][33] : log_rom1[cntr][37] ) ) );
	assign st1_ms_d[8] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][10] : log_rom1[cntr][14] ) : ( cntr[0] ? log_rom1[cntr][18] : log_rom1[cntr][22] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom1[cntr][26] : log_rom1[cntr][30] ) : ( cntr[0] ? log_rom1[cntr][34] : log_rom1[cntr][38] ) ) );
	comp_sub_b RS_1_0(st1_ms_n[0], st1_ms_d[0], 1'b0, st1_ms_b[0]);
	generate
		for (i=1; i<9; i=i+1) begin : LOW_PREC_ST_1
			comp_sub_b RS_1_i(st1_ms_n[i], st1_ms_d[i], st1_ms_b[i-1], st1_ms_b[i]);
		end
	endgenerate
	comp_sub_b RS_1_9(st1_ms_n[9], st1_ms_d[9], st1_ms_b[8], st1_ms_sn);
	assign st1_s = ~st1_ms_sn;
	// Slave : X_Long
	wire [39:0] st1_sx_d;
	wire [39:0] st1_sx_s;
	wire [39:0] st1_sx_bo;
	wire [39:0] st1_sx_bi;
	assign st1_sx_bi[0] = 1'b0;
	assign st1_sx_bi[39:1] = st0_sx_bo[38:0];
	assign st1_sx_d = log_rom1[cntr];
	wire [39:0] st1_sx_test;
	generate
		for (i=0; i<40; i=i+1) begin : HIGH_PREC_ST_1
			assign st1_sx_test[i] = st0_sx_s[i];
			full_subtractor FS_1_sx(st1_sx_test[i], st1_sx_d[i] & st1_s, st1_sx_bi[i], st1_sx_s[i], st1_sx_bo[i]);
		end
	endgenerate
	// Slave : Y_Long
	wire [39:0] st1_sy_a;
	wire [39:0] st1_sy_a_;
	wire [39:0] st1_sy_s;
	wire [39:0] st1_sy_s_;
	wire [39:0] st1_sy_b;
	wire [39:0] st1_sy_b_;
	wire [39:0] st1_sy_t;
	wire [39:0] st1_sy_t_;
	assign st1_sy_a = st0_sy_s;
	assign st1_sy_b ={st0_sy_s_[38:0], 1'b0};
	wire [39:0] st1_sy_shift_abs;
	assign st1_sy_shift_abs = 2 + {cntr, {3{1'b0}}};
	fxp40s_var_shifter SHFTA_Y_ST1(clk, rstn, st1_sy_a, st1_sy_shift_abs, 1'b1, st1_sy_a_);
	fxp40s_var_shifter SHFTB_Y_ST1(clk, rstn, st1_sy_b, st1_sy_shift_abs, 1'b1, st1_sy_b_);
	generate
		for (i=0; i<40; i=i+1) begin : SLAVE_ST_1
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
	assign st2_ms_n[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st1_sx_s[1] : st1_sx_s[5] ) : ( cntr[0] ? st1_sx_s[9] : st1_sx_s[13] ) ) : ( cntr[1] ? ( cntr[0] ? st1_sx_s[17] : st1_sx_s[21] ) : ( cntr[0] ? st1_sx_s[25] : st1_sx_s[29] ) ) );
	assign st2_ms_n[1] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st1_sx_s[2] : st1_sx_s[6] ) : ( cntr[0] ? st1_sx_s[10] : st1_sx_s[14] ) ) : ( cntr[1] ? ( cntr[0] ? st1_sx_s[18] : st1_sx_s[22] ) : ( cntr[0] ? st1_sx_s[26] : st1_sx_s[30] ) ) );
	assign st2_ms_n[2] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st1_sx_s[3] : st1_sx_s[7] ) : ( cntr[0] ? st1_sx_s[11] : st1_sx_s[15] ) ) : ( cntr[1] ? ( cntr[0] ? st1_sx_s[19] : st1_sx_s[23] ) : ( cntr[0] ? st1_sx_s[27] : st1_sx_s[31] ) ) );
	assign st2_ms_n[3] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st1_sx_s[4] : st1_sx_s[8] ) : ( cntr[0] ? st1_sx_s[12] : st1_sx_s[16] ) ) : ( cntr[1] ? ( cntr[0] ? st1_sx_s[20] : st1_sx_s[24] ) : ( cntr[0] ? st1_sx_s[28] : st1_sx_s[32] ) ) );
	assign st2_ms_n[4] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st1_sx_s[5] : st1_sx_s[9] ) : ( cntr[0] ? st1_sx_s[13] : st1_sx_s[17] ) ) : ( cntr[1] ? ( cntr[0] ? st1_sx_s[21] : st1_sx_s[25] ) : ( cntr[0] ? st1_sx_s[29] : st1_sx_s[33] ) ) );
	assign st2_ms_n[5] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st1_sx_s[6] : st1_sx_s[10] ) : ( cntr[0] ? st1_sx_s[14] : st1_sx_s[18] ) ) : ( cntr[1] ? ( cntr[0] ? st1_sx_s[22] : st1_sx_s[26] ) : ( cntr[0] ? st1_sx_s[30] : st1_sx_s[34] ) ) );
	assign st2_ms_n[6] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st1_sx_s[7] : st1_sx_s[11] ) : ( cntr[0] ? st1_sx_s[15] : st1_sx_s[19] ) ) : ( cntr[1] ? ( cntr[0] ? st1_sx_s[23] : st1_sx_s[27] ) : ( cntr[0] ? st1_sx_s[31] : st1_sx_s[35] ) ) );
	assign st2_ms_n[7] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st1_sx_s[8] : st1_sx_s[12] ) : ( cntr[0] ? st1_sx_s[16] : st1_sx_s[20] ) ) : ( cntr[1] ? ( cntr[0] ? st1_sx_s[24] : st1_sx_s[28] ) : ( cntr[0] ? st1_sx_s[32] : st1_sx_s[36] ) ) );
	assign st2_ms_n[8] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st1_sx_s[9] : st1_sx_s[13] ) : ( cntr[0] ? st1_sx_s[17] : st1_sx_s[21] ) ) : ( cntr[1] ? ( cntr[0] ? st1_sx_s[25] : st1_sx_s[29] ) : ( cntr[0] ? st1_sx_s[33] : st1_sx_s[37] ) ) );
	assign st2_ms_n[9] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? st1_sx_s[10] : st1_sx_s[14] ) : ( cntr[0] ? st1_sx_s[18] : st1_sx_s[22] ) ) : ( cntr[1] ? ( cntr[0] ? st1_sx_s[26] : st1_sx_s[30] ) : ( cntr[0] ? st1_sx_s[34] : st1_sx_s[38] ) ) );
	assign st2_ms_d[9] = 1'b0;
	assign st2_ms_d[0] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][1] : log_rom2[cntr][5] ) : ( cntr[0] ? log_rom2[cntr][9] : log_rom2[cntr][13] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][17] : log_rom2[cntr][21] ) : ( cntr[0] ? log_rom2[cntr][25] : log_rom2[cntr][29] ) ) );
	assign st2_ms_d[1] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][2] : log_rom2[cntr][6] ) : ( cntr[0] ? log_rom2[cntr][10] : log_rom2[cntr][14] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][18] : log_rom2[cntr][22] ) : ( cntr[0] ? log_rom2[cntr][26] : log_rom2[cntr][30] ) ) );
	assign st2_ms_d[2] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][3] : log_rom2[cntr][7] ) : ( cntr[0] ? log_rom2[cntr][11] : log_rom2[cntr][15] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][19] : log_rom2[cntr][23] ) : ( cntr[0] ? log_rom2[cntr][27] : log_rom2[cntr][31] ) ) );
	assign st2_ms_d[3] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][4] : log_rom2[cntr][8] ) : ( cntr[0] ? log_rom2[cntr][12] : log_rom2[cntr][16] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][20] : log_rom2[cntr][24] ) : ( cntr[0] ? log_rom2[cntr][28] : log_rom2[cntr][32] ) ) );
	assign st2_ms_d[4] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][5] : log_rom2[cntr][9] ) : ( cntr[0] ? log_rom2[cntr][13] : log_rom2[cntr][17] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][21] : log_rom2[cntr][25] ) : ( cntr[0] ? log_rom2[cntr][29] : log_rom2[cntr][33] ) ) );
	assign st2_ms_d[5] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][6] : log_rom2[cntr][10] ) : ( cntr[0] ? log_rom2[cntr][14] : log_rom2[cntr][18] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][22] : log_rom2[cntr][26] ) : ( cntr[0] ? log_rom2[cntr][30] : log_rom2[cntr][34] ) ) );
	assign st2_ms_d[6] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][7] : log_rom2[cntr][11] ) : ( cntr[0] ? log_rom2[cntr][15] : log_rom2[cntr][19] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][23] : log_rom2[cntr][27] ) : ( cntr[0] ? log_rom2[cntr][31] : log_rom2[cntr][35] ) ) );
	assign st2_ms_d[7] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][8] : log_rom2[cntr][12] ) : ( cntr[0] ? log_rom2[cntr][16] : log_rom2[cntr][20] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][24] : log_rom2[cntr][28] ) : ( cntr[0] ? log_rom2[cntr][32] : log_rom2[cntr][36] ) ) );
	assign st2_ms_d[8] = ( cntr[2] ? ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][9] : log_rom2[cntr][13] ) : ( cntr[0] ? log_rom2[cntr][17] : log_rom2[cntr][21] ) ) : ( cntr[1] ? ( cntr[0] ? log_rom2[cntr][25] : log_rom2[cntr][29] ) : ( cntr[0] ? log_rom2[cntr][33] : log_rom2[cntr][37] ) ) );
	comp_sub_b RS_2_0(st2_ms_n[0], st2_ms_d[0], 1'b0, st2_ms_b[0]);
	generate
		for (i=1; i<9; i=i+1) begin : LOW_PREC_ST_2
			comp_sub_b RS_2_i(st2_ms_n[i], st2_ms_d[i], st2_ms_b[i-1], st2_ms_b[i]);
		end
	endgenerate
	comp_sub_b RS_2_9(st2_ms_n[9], st2_ms_d[9], st2_ms_b[8], st2_ms_sn);
	assign st2_s = ~st2_ms_sn;
	// Slave : X_Long
	wire [39:0] st2_sx_d;
	wire [39:0] st2_sx_s;
	wire [39:0] st2_sx_bo;
	wire [39:0] st2_sx_bi;
	assign st2_sx_bi[0] = 1'b0;
	assign st2_sx_bi[39:1] = st1_sx_bo[38:0];
	assign st2_sx_d = log_rom2[cntr];
	wire [39:0] st2_sx_test;
	generate
		for (i=0; i<40; i=i+1) begin : HIGH_PREC_ST_2
			assign st2_sx_test[i] = st1_sx_s[i];
			full_subtractor FS_2_sx(st2_sx_test[i], st2_sx_d[i] & st2_s, st2_sx_bi[i], st2_sx_s[i], st2_sx_bo[i]);
		end
	endgenerate
	// Slave : Y_Long
	wire [39:0] st2_sy_a;
	wire [39:0] st2_sy_a_;
	wire [39:0] st2_sy_s;
	wire [39:0] st2_sy_s_;
	wire [39:0] st2_sy_b;
	wire [39:0] st2_sy_b_;
	wire [39:0] st2_sy_t;
	wire [39:0] st2_sy_t_;
	assign st2_sy_a = st1_sy_s;
	assign st2_sy_b ={st1_sy_s_[38:0], 1'b0};
	wire [39:0] st2_sy_shift_abs;
	assign st2_sy_shift_abs = 3 + {cntr, {3{1'b0}}};
	fxp40s_var_shifter SHFTA_Y_ST2(clk, rstn, st2_sy_a, st2_sy_shift_abs, 1'b1, st2_sy_a_);
	fxp40s_var_shifter SHFTB_Y_ST2(clk, rstn, st2_sy_b, st2_sy_shift_abs, 1'b1, st2_sy_b_);
	generate
		for (i=0; i<40; i=i+1) begin : SLAVE_ST_2
			full_adder FA_2_sy_0(st2_sy_a[i], st2_sy_a_[i] & st2_s, st2_sy_b[i], st2_sy_t[i], st2_sy_t_[i]);
			full_adder FA_2_sy_1(st2_sy_t[i], st2_sy_b_[i] & st2_s, st2_sy_t_[i], st2_sy_s[i], st2_sy_s_[i]);
		end
	endgenerate
	//// Stage 3 ////
	wire [39:0] st3_d;
	wire [40:0] st3_b;
	wire [39:0] st3_q;
	assign st3_b[0] = 1'b0;
	assign st3_d = log_rom3[cntr];
	generate
		for (i=0; i<39; i=i+1) begin : BPS
			restoring_subtractor BPS(st2_sx_s[i], st3_d[i], st3_b[i], st3_q[i+1], x_nxt[i], st3_b[i+1], st3_q[i]);
		end
	endgenerate
	restoring_subtractor BPS_L(st2_sx_s[39], st3_d[39], st3_b[39], st3_s, x_nxt[39], st3_b[40], st3_q[39]);
	assign st3_s = ~st3_b[40];
	wire [39:0] st3_sy_a;
	wire [39:0] st3_sy_a_;
	wire [39:0] st3_sy_s;
	wire [39:0] st3_sy_s_;
	wire [39:0] st3_sy_b;
	wire [39:0] st3_sy_b_;
	wire [39:0] st3_sy_t;
	wire [39:0] st3_sy_t_;
	wire [39:0] st3_sy_shift_abs;
	assign st3_sy_a = st2_sy_s;
	assign st3_sy_b ={st2_sy_s_[38:0], 1'b0};
	assign st3_sy_shift_abs = 4 + {cntr, {3{1'b0}}};
	fxp40s_var_shifter SHFTA_Y_ST3(clk, rstn, st3_sy_a, st3_sy_shift_abs, 1'b1, st3_sy_a_);
	fxp40s_var_shifter SHFTB_Y_ST3(clk, rstn, st3_sy_b, st3_sy_shift_abs, 1'b1, st3_sy_b_);
	generate
		for (i=0; i<40; i=i+1) begin : SLAVE_ST_3
			full_adder FA_3_sy_0(st3_sy_a[i], st3_sy_a_[i] & st3_s, st3_sy_b[i], st3_sy_t[i], st3_sy_t_[i]);
			full_adder FA_3_sy_1(st3_sy_t[i], st3_sy_b_[i] & st3_s, st3_sy_t_[i], st3_sy_s[i], st3_sy_s_[i]);
		end
	endgenerate
	wire [40:0] st3_yc;
	assign st3_yc[0] = 1'b0;
	generate
		for (i=0; i<40; i=i+1) begin : CPA
			full_adder CPA_2(st3_sy_s[i], st3_sy_s_[i], st3_yc[i], y_nxt[i], st3_yc[i+1]);
		end
	endgenerate
	// <<<< CORDIC Stages <<<<
	wire [31:0] shft_abs;
	wire [31:0] shft_y;
	assign shft_abs = {{24{1'b0}}, x_int};
	fxp32s_var_shifter SHFT_OUT(clk, rstn, y[39:8], shft_abs, x_sign, shft_y);
	reg [31:0] out_y;
	wire rd_en;
	reg en_shift;
	reg en_out;
	assign rd_en = en_out_data & rdy_out_data;
	assign en_out_data = en_out;
	always @(posedge clk) begin
		en_shift <= clr_cntr & rstn;
		en_out <= rstn & ~rd_en & (en_out | en_shift);
		out_y <= (en_shift ? shft_y : out_y) & {32{rstn}};
	end
	assign wip = en_cntr | en_shift | en_out;
	assign out_data = out_y;

endmodule
