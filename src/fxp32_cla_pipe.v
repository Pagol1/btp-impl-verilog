// IO Params
`define FXP32_ADDR 31:0
`define FXP32_WIDTH 32

module fxp32_cla_pipe(
	input clk,
	input rstn,
	input [`FXP32_ADDR] in_a,
	input [`FXP32_ADDR] in_b,
	input in_carry,
	output [`FXP32_ADDR] out_s,
	output out_overflow
);

	reg [`FXP32_ADDR] in_a_val, in_b_val;
	reg in_carry_val;
	wire [31:0] gen0, prop0;
	reg [31:0] gen0_val, prop0_val;
	wire [15:0] gen1, prop1;
	reg [15:0] gen1_val, prop1_val;
	wire [7:0] gen2, prop2;
	reg [7:0] gen2_val, prop2_val;
	wire [3:0] gen3, prop3;
	reg [3:0] gen3_val, prop3_val;
	wire [1:0] gen4, prop4;
	reg [1:0] gen4_val, prop4_val;
	wire gen5, prop5;
	reg gen5_val, prop5_val;
	assign gen0 = in_a & in_b;
	assign prop0 = in_a ^ in_b;

	// GP stage
	genvar j;
	generate
		for (j=0; j<16; j=j+1) begin : CLA_GEN_PROP_L1
			cla_gen_prop L1(gen0[2*j+1], gen0[2*j], prop0[2*j+1], prop0[2*j], gen1[j], prop1[j]);
		end
	endgenerate
	generate
		for (j=0; j<8; j=j+1) begin : CLA_GEN_PROP_L2
			cla_gen_prop L2(gen1[2*j+1], gen1[2*j], prop1[2*j+1], prop1[2*j], gen2[j], prop2[j]);
		end
	endgenerate
	generate
		for (j=0; j<4; j=j+1) begin : CLA_GEN_PROP_L3
			cla_gen_prop L3(gen2[2*j+1], gen2[2*j], prop2[2*j+1], prop2[2*j], gen3[j], prop3[j]);
		end
	endgenerate
	generate
		for (j=0; j<2; j=j+1) begin : CLA_GEN_PROP_L4
			cla_gen_prop L4(gen3[2*j+1], gen3[2*j], prop3[2*j+1], prop3[2*j], gen4[j], prop4[j]);
		end
	endgenerate
	cla_gen_prop L5(gen4[1], gen4[0], prop4[1], prop4[0], gen5, prop5);
	always @(posedge clk) begin
		in_a_val <= in_a & {`FXP32_WIDTH{rstn}};
		in_b_val <= in_b & {`FXP32_WIDTH{rstn}};
		in_carry_val <= in_carry & rstn;
		gen0_val <= gen0 & {32{rstn}};
		prop0_val <= prop0 & {32{rstn}};
		gen1_val <= gen1 & {16{rstn}};
		prop1_val <= prop1 & {16{rstn}};
		gen2_val <= gen2 & {8{rstn}};
		prop2_val <= prop2 & {8{rstn}};
		gen3_val <= gen3 & {4{rstn}};
		prop3_val <= prop3 & {4{rstn}};
		gen4_val <= gen4 & {2{rstn}};
		prop4_val <= prop4 & {2{rstn}};
		gen5_val <= gen5 & {1{rstn}};
		prop5_val <= prop5 & {1{rstn}};
	end

	// Carry Stage
	wire [`FXP32_WIDTH/2-1:0] cry;
	// Lvl0 //
	assign cry[0] = in_carry_val;
	assign cry[1] = gen1_val[0] | (prop1_val[0] & in_carry_val);
	assign cry[2] = gen2_val[0] | (prop2_val[0] & in_carry_val);
	assign cry[4] = gen3_val[0] | (prop3_val[0] & in_carry_val);
	assign cry[8] = gen4_val[0] | (prop4_val[0] & in_carry_val);
	// Lvl1 //
	assign cry[3] = gen1_val[2] | (prop1_val[2] & cry[2]);
	assign cry[5] = gen1_val[4] | (prop1_val[4] & cry[4]);
	assign cry[6] = gen2_val[2] | (prop2_val[2] & cry[4]);
	assign cry[7] = gen1_val[6] | (prop1_val[6] & cry[6]);
	assign cry[9] = gen1_val[8] | (prop1_val[8] & cry[8]);
	assign cry[10] = gen2_val[4] | (prop2_val[4] & cry[8]);
	assign cry[12] = gen3_val[2] | (prop3_val[2] & cry[8]);
	assign cry[11] = gen1_val[10] | (prop1_val[10] & cry[10]);
	assign cry[13] = gen1_val[12] | (prop1_val[12] & cry[12]);
	assign cry[14] = gen2_val[6] | (prop2_val[6] & cry[12]);
	assign cry[15] = gen1_val[14] | (prop1_val[14] & cry[14]);

	// 2-bit RCA chain
	generate
		for (j=0; j<`FXP32_WIDTH/2; j=j+1) begin : RCA_CHAIN
			rca RCA(in_a_val[2*j+1:2*j], in_b_val[2*j+1:2*j], cry[j], out_s[2*j+1:2*j]);
		end
	endgenerate
	assign out_overflow = (gen5_val | (prop5_val & in_carry_val)) ^ (gen0_val[30] | (prop0_val[30] & cry[15]));
endmodule