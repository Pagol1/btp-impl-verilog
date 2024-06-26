// IO Params
`define FXP8S_ADDR 7:0
`define FXP8S_WIDTH 8
`define FXP8S_SIGN 7
`define FXP8S_MAG 6:0
`define FXP8S_LSB_POW -3

module fxp8s_pe_array_(
	input clk,
	input rstn,
	// Input Stream
	input en_in_data,
	output rdy_in_data,
	input in_mat,
	input in_new_row,
	input in_mat_done,
	input [`FXP8S_ADDR] in_data,
	// Output Stream
	output en_out_data,
	input rdy_out_data,
	output out_mat,
	output out_new_row,
	output [`FXP8S_ADDR] out_data
);
	// States //
	wire clr_data_n;
	wire input_done;
	reg sched_done;
	wire out_done;
	//// Input Data Loader ////
	reg [0:0] in_col;
	reg in_col_c;
	reg [0:0] in_row;
	reg in_row_c;
	wire in_row_end;
	wire in_col_end;
	reg [1:0] in_mat_loaded;
	wire wr_en;
	wire zero_pad;
	reg zero_pad_d;
	wire in_mat_empty;
	assign in_row_end = (in_row == 1'b1);
	assign in_col_end = (in_col == 1'b1);
	assign in_mat_empty = (in_mat) ? ~in_mat_loaded[1] : ~in_mat_loaded[0];
	assign zero_pad = ( (in_new_row & ~in_col_end) | (in_mat_done & ~(in_row_end & in_col_end)) ) & in_mat_empty;
	assign rdy_in_data = en_in_data & ~zero_pad & in_mat_empty;
	assign wr_en = en_in_data & (rdy_in_data | zero_pad) & ~input_done;
	always @(posedge clk) begin
		{in_col_c, in_col} <= (wr_en ? ((in_col_end) ? 2'b00 : in_col + 1'b1) : {1'b0, in_col}) & {2{rstn & clr_data_n}};
		{in_row_c, in_row} <= ((wr_en & in_col_end) ? ((in_row_end) ? 2'b00 : in_row + 1'b1) : {1'b0, in_row}) & {2{rstn & clr_data_n}};
		zero_pad_d <= zero_pad & rstn & clr_data_n;
		in_mat_loaded[1] <= rstn & clr_data_n & (in_mat_loaded[1] | (in_col_end & in_row_end & in_mat));
		in_mat_loaded[0] <= rstn & clr_data_n & (in_mat_loaded[0] | (in_col_end & in_row_end & ~in_mat));
	end
	// Data Buffer //
	reg [7:0] data [7:0];
	reg [2:0] base_reg_A;
	reg [2:0] base_reg_B;
	always @(posedge clk) begin // Fixed base registers
		base_reg_A <= 3'b000;
		base_reg_B <= 3'b100;
	end
	wire [2:0] wr_base_addr;
	wire [2:0] wr_offset;
	wire [2:0] wr_tgt_addr;
	wire wr_addr_c;
	wire [7:0] wr_data;
	assign wr_data = zero_pad_d ? 8'b00000000 : in_data;
	assign wr_base_addr = in_mat ? base_reg_B : base_reg_A;
	assign wr_offset = in_mat ? ({1'b0, in_col, 1'b0} + {1'b0, 1'b0, in_row}) : ({1'b0, in_row, 1'b0} + {1'b0, 1'b0, in_col});
	assign {wr_addr_c, wr_tgt_addr} = wr_base_addr + wr_offset;
	always @(posedge clk) begin
		data[wr_tgt_addr] <= (wr_en ? wr_data : data[wr_tgt_addr]) & {8{rstn & clr_data_n}};
	end
	//// Scheduler ////
	assign input_done = in_mat_loaded[1] & in_mat_loaded[0];
	wire rd_mat_done;
	reg sched_col;
	reg [2:0] rd_offset;
	wire [2:0] rd_tgt_addr;
	reg rd_off_c;
	assign rd_mat_done = (rd_offset == 3'b010);
	assign rd_tgt_addr = sched_col ? base_reg_B : base_reg_A;
	always @(posedge clk) begin
		sched_col <= rstn & clr_data_n & (rd_mat_done & input_done | sched_col);
		{rd_off_c, rd_offset} <= (sched_done ? {1'b0, rd_offset} : ( rd_mat_done ? 4'b0000 : rd_offset + 4'b0010) ) & {4{rstn & input_done & clr_data_n}};
		sched_done <= (sched_done | (rd_mat_done & sched_col)) & rstn & clr_data_n;
	end
	wire [7:0] noc_row_data [1:0];
	wire [7:0] noc_row_addr [1:0];
	wire [1:0] noc_row_c;
	wire [7:0] noc_col_data [1:0];
	wire [7:0] noc_col_addr [1:0];
	wire [1:0] noc_col_c;
	wire [7:0] noc_in_data [1:0][1:0];
	wire [7:0] noc_out_data [1:0][1:0];
	wire noc_out_en [1:0][1:0];
	genvar i, j;
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
