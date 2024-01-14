// IO Params
`define FXP8S_ADDR 7:0
`define FXP8S_WIDTH 8
`define FXP8S_SIGN 7
`define FXP8S_MAG 6:0
`define FXP8S_LSB_POW -3

module fxp8s_pe(
	input clk,
	input rstn,
	input in_row,		// Input is the row ==> Store in Buffer, else send to MUL_B
	input en_in,
	input [`FXP8S_ADDR] in_data,		// 2's complement
	input en_out,
	output [`FXP8S_ADDR] out_data		// 2's complement
);
	
	genvar i;
	reg [7:0] in_buf[2:0];
	wire [7:0] in_mul_a;
	reg [7:0] in_mul_b;
	wire [7:0] out_mul_s;
	wire out_mul_ovf;
	reg mul_on;
	reg [7:0] acc;
	wire [7:0] acc_in;
	always @(posedge clk) begin
		in_buf[0] <= (en_in & in_row) ? in_data : in_buf[0] & {8{rstn}};
		in_mul_b <= (en_in & ~in_row) ? in_data : in_mul_b & {8{rstn}};
		mul_on <= ~in_row & en_in & rstn;
	end
	generate
		for (i=1; i<3; i=i+1) begin : IN_BUF
			always @(posedge clk) begin
				in_buf[i] <= (en_in & in_row) ? in_buf[i-1] : in_buf[i] & {8{rstn}};
			end
		end
	endgenerate
	assign in_mul_a = in_buf[2] &{8{mul_on}};
	// Convert 2C -> SM
	wire [7:0] mul_a;
	wire [7:0] mul_b;
	wire [7:0] mul_s;
	wire [7:0] pre_mul_a_a;
	wire pre_mul_a_c;
	wire pre_mul_a_c0;
	assign pre_mul_a_a = in_mul_a ^ {8{in_mul_a[7]}};
	assign pre_mul_a_c = in_mul_a[7];
	assign {pre_mul_a_c0, mul_a[6:0]} = pre_mul_a_a[6:0] + pre_mul_a_c;
	assign mul_a[7] = in_mul_a[7];
	wire [7:0] pre_mul_b_a;
	wire pre_mul_b_c;
	wire pre_mul_b_c0;
	assign pre_mul_b_a = in_mul_b ^ {8{in_mul_b[7]}};
	assign pre_mul_b_c = in_mul_b[7];
	assign {pre_mul_b_c0, mul_b[6:0]} = pre_mul_b_a[6:0] + pre_mul_b_c;
	assign mul_b[7] = in_mul_b[7];
	fxp8s_dadda MUL(clk, rstn, mul_a, mul_b, mul_s, out_mul_ovf);
	// Convert SM -> 2C
	assign out_mul_s[6:0] = mul_s[6:0] ^ {7{mul_s[7]}};
	assign out_mul_s[7] = mul_s[7];
	// Accumulator
	wire acc_cout;
	assign {acc_cout, acc_in} = acc + out_mul_s;
	always @(posedge clk) begin
		acc <= acc_in & {8{rstn}};
	end
	assign out_data =  acc & {8{en_out}};

endmodule
