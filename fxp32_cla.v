// IO Params
`define FXP32_ADDR 31:0
`define FXP32_WIDTH 32

module fxp32_cla(
	input clk,
	input [`FXP32_ADDR] in_a,
	input [`FXP32_ADDR] in_b,
	input in_carry,
	output [`FXP32_ADDR] out_s,
	output out_overflow
);

	wire [31:0] gen0, prop0;
	wire [15:0] gen1, prop1;
	wire [7:0] gen2, prop2;
	wire [3:0] gen3, prop3;
	wire [1:0] gen4, prop4;
	wire gen5, prop5;
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

	// Carry Stage
	wire [`FXP32_WIDTH/2-1:0] cry;
	// Lvl0 //
	assign cry[0] = in_carry;
	assign cry[1] = gen1[0] | (prop1[0] & in_carry);
	assign cry[2] = gen2[0] | (prop2[0] & in_carry);
	assign cry[4] = gen3[0] | (prop3[0] & in_carry);
	assign cry[8] = gen4[0] | (prop4[0] & in_carry);
	// Lvl1 //
	assign cry[3] = gen1[2] | (prop1[2] & cry[2]);
	assign cry[5] = gen1[4] | (prop1[4] & cry[4]);
	assign cry[6] = gen2[2] | (prop2[2] & cry[4]);
	assign cry[7] = gen1[6] | (prop1[6] & cry[6]);
	assign cry[9] = gen1[8] | (prop1[8] & cry[8]);
	assign cry[10] = gen2[4] | (prop2[4] & cry[8]);
	assign cry[12] = gen3[2] | (prop3[2] & cry[8]);
	assign cry[11] = gen1[10] | (prop1[10] & cry[10]);
	assign cry[13] = gen1[12] | (prop1[12] & cry[12]);
	assign cry[14] = gen2[6] | (prop2[6] & cry[12]);
	assign cry[15] = gen1[14] | (prop1[14] & cry[14]);

	// 2-bit RCA chain
	generate
		for (j=0; j<`FXP32_WIDTH/2; j=j+1) begin : RCA_CHAIN
			rca RCA(in_a[2*j+1:2*j], in_b[2*j+1:2*j], cry[j], out_s[2*j+1:2*j]);
		end
	endgenerate
	assign out_overflow = (gen5 | (prop5 & in_carry)) ^ (gen0[30] | (prop0[30] & cry[15]));
endmodule