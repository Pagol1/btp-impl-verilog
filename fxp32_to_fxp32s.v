// IO Params
`define FXP32_ADDR 31:0
`define FXP32_WIDTH 32
// Adder Params
`define FXP32_CLA_L0_ADDR 31:0
`define FXP32_CLA_L1_ADDR 15:0
`define FXP32_CLA_L2_ADDR 7:0
`define FXP32_CLA_L3_ADDR 3:0
`define FXP32_CLA_L4_ADDR 1:0
`define FXP32_CLA_L0_WIDTH 32
`define FXP32_CLA_L1_WIDTH 16
`define FXP32_CLA_L2_WIDTH 8
`define FXP32_CLA_L3_WIDTH 4
`define FXP32_CLA_L4_WIDTH 2

module fxp32_to_fxp32s(
	input clk,
	input [`FXP32_ADDR] in_a,
	input in_carry
	output [`FXP32_ADDR] out_s,
);
	wire [`FXP32_CLA_L0_ADDR]  prop0;
	wire [`FXP32_CLA_L1_ADDR]  prop1;
	wire [`FXP32_CLA_L2_ADDR]  prop2;
	wire [`FXP32_CLA_L3_ADDR]  prop3;
	wire [`FXP32_CLA_L4_ADDR]  prop4;
	wire prop5;
	assign prop0 = in_a ^ {`FXP32_WIDTH{in_carry}};

        // GP stage	
        genvar j;
	generate
		for (j=0; j<`FXP32_CLA_L1_WIDTH; j=j+1) begin : CLA_GEN_PROP_L1
                        prop1[j] = prop0[2*j+1] & prop0[2*j];
		end
	endgenerate
	generate
		for (j=0; j<`FXP32_CLA_L2_WIDTH; j=j+1) begin : CLA_GEN_PROP_L2
                        prop2[j] = prop1[2*j+1] & prop1[2*j];
		end
	endgenerate
	generate
		for (j=0; j<`FXP32_CLA_L3_WIDTH; j=j+1) begin : CLA_GEN_PROP_L3
                        prop3[j] = prop2[2*j+1] & prop2[2*j];
		end
	endgenerate
	generate
		for (j=0; j<`FXP32_CLA_L4_WIDTH; j=j+1) begin : CLA_GEN_PROP_L4
                        prop4[j] = prop3[2*j+1] & prop3[2*j];
		end
	endgenerate
        prop5 = prop4[1] & prop4[0];

	// Carry Stage
	wire [`FXP32_WIDTH/2-1:0] cry;
	// Lvl0 //
	assign cry[0] = in_carry;
	assign cry[1] = (prop1[0] & in_carry);
	assign cry[2] = (prop2[0] & in_carry);
	assign cry[4] = (prop3[0] & in_carry);
	assign cry[8] = (prop4[0] & in_carry);
	// Lvl1 //
	assign cry[3] = (prop1[2] & cry[2]);
	assign cry[5] = (prop1[4] & cry[4]);
	assign cry[6] = (prop2[2] & cry[4]);
	assign cry[7] = (prop1[6] & cry[6]);
	assign cry[9] = (prop1[8] & cry[8]);
	assign cry[10] = (prop2[4] & cry[8]);
	assign cry[12] = (prop3[2] & cry[8]);
	assign cry[11] = (prop1[10] & cry[10]);
	assign cry[13] = (prop1[12] & cry[12]);
	assign cry[14] = (prop2[6] & cry[12]);
	assign cry[15] = (prop1[14] & cry[14]);

	// 2-bit RCA chain
	generate
		for (j=0; j<`FXP32_WIDTH/2; j=j+1) begin : RCA_CHAIN
			rca RCA(in_A[2*j+1:2*j], in_B[2*j+1:2*j], cry[j], out_s[2*j+1:2*j]);
		end
	endgenerate
endmodule

