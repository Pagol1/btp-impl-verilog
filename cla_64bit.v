// IO Params
`define FXP64_ADDR 63:0
`define FXP64_WIDTH 64

module cla_64bit(
	input clk,
	input [`FXP64_ADDR] in_a,
	input [`FXP64_ADDR] in_b,
	input in_carry
	output [`FXP64_ADDR] out_s,
	output out_overflow
);
	// Adder Params
	localparam FXP64_CLA_L0_ADDR 63:0;
	localparam FXP64_CLA_L1_ADDR 31:0;
	localparam FXP64_CLA_L2_ADDR 15:0;
	localparam FXP64_CLA_L3_ADDR 7:0;
	localparam FXP64_CLA_L4_ADDR 3:0;
	localparam FXP64_CLA_L5_ADDR 1:0;
	localparam FXP64_CLA_L0_WIDTH 64;
	localparam FXP64_CLA_L1_WIDTH 32;
	localparam FXP64_CLA_L2_WIDTH 16;
	localparam FXP64_CLA_L3_WIDTH 8;
	localparam FXP64_CLA_L4_WIDTH 4;
	localparam FXP64_CLA_L5_WIDTH 2;

	wire [FXP64_CLA_L0_ADDR] gen0, prop0;
	wire [FXP64_CLA_L1_ADDR] gen1, prop1;
	wire [FXP64_CLA_L2_ADDR] gen2, prop2;
	wire [FXP64_CLA_L3_ADDR] gen3, prop3;
	wire [FXP64_CLA_L4_ADDR] gen4, prop4;
	wire [FXP64_CLA_L5_ADDR] gen5, prop5;
	wire gen6, prop6;
	assign gen0 = in_a & in_b;
	assign prop0 = in_a ^ in_b;

	// GP stage
	genvar j;
	generate
		for (j=0; j<FXP64_CLA_L1_WIDTH; j=j+1) begin : CLA_GEN_PROP_L1
			cla_gen_prop L1(gen0[2*j+1], gen0[2*j], prop0[2*j+1], prop0[2*j], gen1[j], prop1[j]);
		end
	endgenerate
	generate
		for (j=0; j<FXP64_CLA_L2_WIDTH; j=j+1) begin : CLA_GEN_PROP_L2
			cla_gen_prop L2(gen1[2*j+1], gen1[2*j], prop1[2*j+1], prop1[2*j], gen2[j], prop2[j]);
		end
	endgenerate
	generate
		for (j=0; j<FXP64_CLA_L3_WIDTH; j=j+1) begin : CLA_GEN_PROP_L3
			cla_gen_prop L3(gen2[2*j+1], gen2[2*j], prop2[2*j+1], prop2[2*j], gen3[j], prop3[j]);
		end
	endgenerate
	generate
		for (j=0; j<FXP64_CLA_L4_WIDTH; j=j+1) begin : CLA_GEN_PROP_L4
			cla_gen_prop L4(gen3[2*j+1], gen3[2*j], prop3[2*j+1], prop3[2*j], gen4[j], prop4[j]);
		end
	endgenerate
	generate
		for (j=0; j<FXP64_CLA_L5_WIDTH; j=j+1) begin : CLA_GEN_PROP_L5
			cla_gen_prop L5(gen4[2*j+1], gen4[2*j], prop4[2*j+1], prop4[2*j], gen5[j], prop5[j]);
		end
	endgenerate
	cla_gen_prop L6(gen5[1], gen5[0], prop5[1], prop5[0], gen6, prop6);

	// Carry Stage
	wire [`FXP64_WIDTH/2-1:0] cry;
	// Lvl0 //
	assign cry[0] = in_carry;
	assign cry[1] = gen1[0] | (prop1[0] & in_carry);
	assign cry[2] = gen2[0] | (prop2[0] & in_carry);
	assign cry[4] = gen3[0] | (prop3[0] & in_carry);
	assign cry[8] = gen4[0] | (prop4[0] & in_carry);
	assign cry[16] = gen5[0] | (prop5[0] & in_carry);
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
	assign cry[17] = gen1[16] | (prop1[16] & cry[16]);
	assign cry[18] = gen2[8] | (prop2[8] & cry[16]);
	assign cry[20] = gen3[4] | (prop3[4] & cry[16]);
	assign cry[24] = gen4[2] | (prop4[2] & cry[16]);
	assign cry[19] = gen1[18] | (prop1[18] & cry[18]);
	assign cry[21] = gen1[20] | (prop1[20] & cry[20]);
	assign cry[22] = gen2[10] | (prop2[10] & cry[20]);
	assign cry[23] = gen1[22] | (prop1[22] & cry[22]);
	assign cry[25] = gen1[24] | (prop1[24] & cry[24]);
	assign cry[26] = gen2[12] | (prop2[12] & cry[24]);
	assign cry[28] = gen3[6] | (prop3[6] & cry[24]);
	assign cry[27] = gen1[26] | (prop1[26] & cry[26]);
	assign cry[29] = gen1[28] | (prop1[28] & cry[28]);
	assign cry[30] = gen2[14] | (prop2[14] & cry[28]);
	assign cry[31] = gen1[30] | (prop1[30] & cry[30]);

	// 2-bit RCA chain
	generate
		for (j=0; j<`FXP64_WIDTH/2; j=j+1) begin : RCA_CHAIN
			rca RCA(in_A[2*j+1:2*j], in_B[2*j+1:2*j], cry[j], out_s[2*j+1:2*j]);
		end
	endgenerate
	assign out_overflow = (gen6 | (prop6 & in_carry)) ^ (gen0[62] | (prop0[62] & cry[31])));
endmodule