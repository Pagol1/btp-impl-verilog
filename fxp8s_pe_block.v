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
	reg buf_valid [3:0];
	reg [1:0] base_reg_A;
	reg [1:0] base_reg_B;
	always @(posedge clk) begin // Fixed base registers
		base_reg_A <= 2'b00;
		base_reg_B <= 2'b10;
	end
	reg [0:0] in_row [1:0];
	reg in_row_c [1:0];
	wire in_row_end;
	wire [1:0] in_mat_loaded;
	wire out_mat_ready;
	wire out_mat_loaded;
	wire wr_en;
	wire zero_pad;
	reg zero_pad_d;
	wire in_mat_empty;
	assign in_mat_loaded[0] = &buf_valid[1:0];
	assign in_mat_loaded[1] = &buf_valid[3:2];
	assign in_row_end = (in_row[in_mat] == 1'b1);
	assign in_mat_empty = ~in_mat_loaded[in_mat];
	assign zero_pad = ( (in_mat_done & ~in_row_end) ) & in_mat_empty;
	assign rdy_in_data = en_in_data & ~zero_pad & ~( buf_valid[wr_bank_addr[0]][wr_addr[0]] | buf_valid[wr_bank_addr[1]][wr_addr[1]] );
	assign wr_en = en_in_data & (rdy_in_data | zero_pad);
	always @(posedge clk) begin
		{in_row_c[0], in_row[0]} <= ((wr_en & ~in_mat) ? ((in_row_end) ? 2'b00 : in_row[0] + 1'b1) : {1'b0, in_row[0]}) & {2{rstn}};
		{in_row_c[1], in_row[1]} <= ((wr_en & in_mat) ? ((in_row_end) ? 2'b00 : in_row[1] + 1'b1) : {1'b0, in_row[1]}) & {2{rstn}};
		zero_pad_d <= zero_pad & rstn;
	end
	wire [1:0] wr_addr [1:0];
	wire [0:0] wr_bank_addr [1:0];
	wire wr_addr_c [1:0];
	wire [7:0] wr_data [1:0];
	genvar i, j;
	generate
		for (i=0; i<2; i=i+1) begin : WR_ADDR_MAP
			{wr_addr_c[i], wr_addr[i]} = in_mat ? (base_reg_B + i) : (base_reg_A + in_row[0]);
			wr_bank_addr[i] = in_mat ? in_row[1] : i;
			wr_data[i] = in_data[15-8*i:8*(2-1-i)] & {8{~zero_pad_d}}
			always @(posedge clk) begin
				buf_data[wr_bank_addr[i]][wr_addr[i]] <= wr_en ? wr_data[i] : buf_data[wr_bank_addr[i]][wr_addr[i]];
			end
		end
	endgenerate
	//// Scheduler ////
	reg sched_start;
	reg sched_tgt;
	reg sched_tgt_base;
	reg sched_done;
	reg [1:0] sched_row;
	always @(posedge clk) begin
		sched_start <= rstn & ~sched_done & (sched_start | buf_valid[BUF_A] | buf_valid[BUF_B]);
		sched_tgt_base <= rstn & ~buf_valid[BUF_A] & buf_valid[BUF_B];
		sched_tgt <= rstn & (sched_start ? ~sched_tgt : ~buf_valid[BUF_A] & buf_valid[BUF_B]);
		sched_done <= rstn & ((~sched_done & (sched_row == 1'b1)) | (sched_done
		sched_row <= 
	end
	assign input_done = in_mat_loaded[1] & in_mat_loaded[0];
	wire rd_mat_done;
	reg sched_col;
	reg [1:0] rd_offset;
	wire [1:0] rd_tgt_addr;
	reg rd_off_c;
	assign rd_mat_done = (rd_offset == 2'b10);
	assign rd_tgt_addr = sched_col ? base_reg_B : base_reg_A;
	always @(posedge clk) begin
		sched_col <= rstn & clr_data_n & (rd_mat_done & input_done | sched_col);
		{rd_off_c, rd_offset} <= (sched_done ? {1'b0, rd_offset} : ( rd_mat_done ? 3'b000 : rd_offset + 3'b010) ) & {3{rstn & input_done & clr_data_n}};
		sched_done <= (sched_done | (rd_mat_done & sched_col)) & rstn & clr_data_n;
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
	generate
		for (i=0; i<2; i=i+1) begin : PE_ARRAY_ROW
			assign {noc_row_c[i], noc_row_addr[i]} = rd_tgt_addr + (rd_offset + i);
			assign noc_row_data[i] = data[noc_row_addr[i]];
			assign {noc_col_c[i], noc_col_addr[i]} = rd_tgt_addr + (rd_offset + i);
			assign noc_col_data[i] = data[noc_col_addr[i]];
			for (j=0; j<2; j=j+1) begin : PE_ARRAY_COL
				assign noc_in_data[i][j] = sched_col ? noc_col_data[j] : noc_row_data[i];
				fxp8s_pe PE(clk, rstn & clr_data_n, ~sched_col, ~sched_done & input_done, noc_in_data[i][j], noc_out_en[i][j], noc_out_data[i][j]);
			end
		end
	endgenerate
	//// Output Module ////
	reg [0:0] out_col;
	reg out_col_c;
	reg [0:0] out_row;
	reg out_row_c;
	wire out_row_end;
	wire out_col_end;
	reg out_ready;
	wire out_rd_data;
	assign en_out_data = out_ready;
	assign out_row_end = (out_row == 1'b1);
	assign out_col_end = (out_col == 1'b1);
	assign out_rd_data = en_out_data & rdy_out_data & ~out_done;
	assign out_done = (out_row_end & out_col_end);
	assign clr_data_n = ~out_done;
	always @(posedge clk) begin
		out_ready <= sched_done & ~out_done & rstn;
		{out_col_c, out_col} <= (out_rd_data ? (out_col_end ? 2'b00 : out_col + 1'b1) : out_col) & {2{rstn & clr_data_n}};
		{out_row_c, out_row} <= ((out_rd_data & out_col_end) ? (out_row_end ? 2'b00 : out_row + 1'b1) : out_row) & {2{rstn & clr_data_n}};
	end
	generate
		for (i=0; i<2; i=i+1) begin : NOC_OUT_ROW
			for (j=0; j<2; j=j+1) begin : NOC_OUT_COL
				assign noc_out_en[i][j] = out_rd_data & (out_row == i) & (out_col == j);
			end
		end
	endgenerate
	assign out_data = noc_out_data[out_row][out_col] & {8{rstn & out_rd_data}};

endmodule
