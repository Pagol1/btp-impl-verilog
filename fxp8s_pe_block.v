// IO Params
`define FXP8S_BUS_WIDTH 15:0
`define FXP8S_ADDR 7:0
`define FXP8S_WIDTH 8
`define FXP8S_SIGN 7
`define FXP8S_MAG 6:0
`define FXP8S_LSB_POW -3

module fxp8s_pe_block(
	input clk,
	input rstn,
	// Input Stream
	input en_in_data,
	output rdy_in_data,
	input in_mat,
	input in_mat_done,
	input [`FXP8S_BUS_WIDTH] in_data,
	// Output Stream
	output en_out_data,
	input rdy_out_data,
	output out_mat_done,
	output [`FXP8S_BUS_WIDTH] out_data
);
	// States //
	wire out_done;
	//// Input Data Loader ////
	// Data Buffer //
	reg [7:0] buf_data [1:0][3:0];
	reg buf_valid [1:0][3:0];
	reg [1:0] base_reg_A;
	reg [1:0] base_reg_B;
	always @(posedge clk) begin // Fixed base registers
		base_reg_A <= 2'b00;
		base_reg_B <= 2'b10;
	end
	// buffer ld decl
	reg [0:0] in_row [1:0];
	reg in_row_c [1:0];
	wire in_row_end;
	wire out_mat_ready;
	wire wr_en;
	wire zero_pad;
	reg zero_pad_d;
	wire in_mat_empty;
	// buffer wr decl
	wire [1:0] wr_addr [1:0];
	wire [0:0] wr_bank_addr [1:0];
	wire wr_addr_c [1:0];
	wire [7:0] wr_data [1:0];
	// buffer ld def
	assign in_row_end = (in_row[in_mat] == 1'b1);
	assign in_mat_empty = ~( buf_valid[wr_bank_addr[0]][wr_addr[0]] | buf_valid[wr_bank_addr[1]][wr_addr[1]] );
	assign zero_pad = ( (in_mat_done & ~in_row_end) ) & in_mat_empty;
	assign rdy_in_data = en_in_data & ~zero_pad & in_mat_empty;
	assign wr_en = en_in_data & (rdy_in_data | zero_pad);
	always @(posedge clk) begin
		{in_row_c[0], in_row[0]} <= ((wr_en & ~in_mat) ? ((in_row_end) ? 2'b00 : in_row[0] + 1'b1) : {1'b0, in_row[0]}) & {2{rstn}};
		{in_row_c[1], in_row[1]} <= ((wr_en & in_mat) ? ((in_row_end) ? 2'b00 : in_row[1] + 1'b1) : {1'b0, in_row[1]}) & {2{rstn}};
		zero_pad_d <= zero_pad & rstn;
	end
	// buffer wr def
	genvar i, j;
	generate
		for (i=0; i<2; i=i+1) begin : WR_ADDR_MAP
			assign {wr_addr_c[i], wr_addr[i]} = in_mat ? (base_reg_B + in_row[1]) : (base_reg_A + i);
			assign wr_bank_addr[i] = in_mat ? i : in_row[0];
			assign wr_data[i] = in_data[8*i+7:8*i] & {8{~zero_pad_d}};
			always @(posedge clk) begin
				buf_data[wr_bank_addr[i]][wr_addr[i]] <= wr_en ? wr_data[i] : buf_data[wr_bank_addr[i]][wr_addr[i]];
			end
		end
	endgenerate
	generate
		for (i=0; i<2; i=i+1) begin : VALID_COL
			for (j=0; j<2; j=j+1) begin : VALID_ROW_A
				always @(posedge clk) begin
					buf_valid[i][j+0] <= rstn & ((sched_en & ~sched_tgt & (sched_row == j)) ? 1'b0 : ( (wr_en & ~in_mat & (in_row[0] == i)) ? 1'b1 : buf_valid[i][j+0] ) );
				end
			end
			for (j=0; j<2; j=j+1) begin : VALID_ROW_B
				always @(posedge clk) begin
					buf_valid[i][j+2] <= rstn & ((sched_en & sched_tgt & (sched_row == j)) ? 1'b0 : ( (wr_en & in_mat & (in_row[1] == j)) ? 1'b1 : buf_valid[i][j+2] ) );
				end
			end
		end
	endgenerate
	//// Scheduler ////
	wire sched_valid [3:0];
	generate
		for (j=0; j<4; j=j+1) begin : SCHED_VALID_MAP_ROWS
			assign sched_valid[j] = ( buf_valid[0][j] & buf_valid[1][j] );
		end
	endgenerate
	reg sched_start;
	wire sched_en;
	reg sched_tgt;
	reg sched_tgt_base;
	reg sched_done;
	reg [1:0] sched_row;
	reg sched_row_c;
	wire last_row;
	assign last_row = (sched_row == 1'b1) & (sched_tgt ^ sched_tgt_base);
	assign sched_en = ~sched_done & sched_valid[(sched_tgt ? base_reg_B : base_reg_A) + sched_row] & ~out_mat_ready;
	always @(posedge clk) begin
		sched_start <= rstn & ~sched_done & (sched_en | sched_start);
		sched_tgt_base <= rstn & (sched_en | sched_start ? sched_tgt_base : ~sched_valid[base_reg_A] & sched_valid[base_reg_B]);
		sched_tgt <= rstn & (sched_en ? ~sched_tgt : (sched_start ? sched_tgt : ~sched_valid[base_reg_A] & sched_valid[base_reg_B]) );
		sched_done <= rstn & (sched_done ? ~out_row_end : last_row);
		{sched_row_c, sched_row} <= (sched_done ? 2'b00 : (sched_en ? sched_row + (sched_tgt ^ sched_tgt_base) : sched_row)) & {2{rstn}};
	end
	wire [7:0] noc_row_data [1:0];
	wire [3:0] noc_row_addr [1:0];
	wire [1:0] noc_row_c;
	wire [7:0] noc_col_data [1:0];
	wire [3:0] noc_col_addr [1:0];
	wire [1:0] noc_col_c;
	wire [7:0] noc_in_data [1:0][1:0];
	wire [7:0] noc_out_data [1:0][1:0];
	wire noc_out_en [1:0][1:0];
	wire noc_out_rdy [1:0][1:0];
	generate
		for (i=0; i<2; i=i+1) begin : PE_ARRAY_ROW
			assign {noc_row_c[i], noc_row_addr[i]} = base_reg_A + sched_row;
			assign noc_row_data[i] = buf_data[i][noc_row_addr[i]];
			assign {noc_col_c[i], noc_col_addr[i]} = base_reg_B + sched_row;
			assign noc_col_data[i] = buf_data[i][noc_col_addr[i]];
			for (j=0; j<2; j=j+1) begin : PE_ARRAY_COL
				assign noc_in_data[i][j] = sched_tgt ? noc_col_data[j] : noc_row_data[i];
				fxp8s_pe PE(clk, rstn, sched_en, ~(sched_tgt ^ sched_tgt_base), noc_in_data[i][j], last_row, noc_out_en[i][j], noc_out_rdy[i][j], noc_out_data[i][j]);
			end
		end
	endgenerate
	//// Output Module ////
	reg [0:0] out_row;
	reg out_row_c;
	wire out_en;
	wire out_row_end;
	assign out_row_end = (out_row == 1'b1);
	assign out_mat_ready = ( noc_out_en[0][0] | noc_out_en[0][1] | noc_out_en[1][0] | noc_out_en[1][1] );
	assign en_out_data = out_mat_ready;
	assign out_mat_done = out_row_end;
	assign out_en = en_out_data & rdy_out_data;
	always @(posedge clk) begin
		{out_row_c, out_row} <= (out_row_end & out_en ? 2'b00 : (out_mat_ready & out_en ? out_row + 1'b1 : {1'b0, out_row})) & {2{rstn}};
	end
	generate
		for (i=0; i<2; i=i+1) begin : WR_DATA_MAP
			assign out_data[8*i+7:8*i] = ( noc_out_data[0][i] | noc_out_data[1][i] );
			for (j=0; j<2; j=j+1) begin : WR_EN_MAP
				assign noc_out_rdy[i][j] = (out_row == i) && out_en;
			end
		end
	endgenerate

endmodule
