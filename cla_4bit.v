// IO Params
`define BIT4_ADDR 3:0
`define BIT4_WIDTH 4

module cla_4bit(
	input clk,
	input [`BIT4_ADDR] in_a,
	input [`BIT4_ADDR] in_b,
	input in_carry
	output [`BIT4_ADDR] out_s,
	output out_overflow
);
	// Adder Params
	localparam CLA_4BIT_L0_ADDR 3:0;
	localparam CLA_4BIT_L1_ADDR 1:0;
	localparam CLA_4BIT_L0_WIDTH 4;
	localparam CLA_4BIT_L1_WIDTH 2;
	wire [CLA_4BIT_L0_ADDR] gen0, prop0;
	wire [CLA_4BIT_L1_ADDR] gen1, prop1;
	wire gen2, prop2;
	assign gen0 = in_a & in_b;
	assign prop0 = in_a ^ in_b;

	// GP stage
	genvar j;
	generate
		for (j=0; j<CLA_4BIT_L1_WIDTH; j=j+1) begin : CLA_GEN_PROP_L1
			cla_gen_prop L1(gen0[2*j+1], gen0[2*j], prop0[2*j+1], prop0[2*j], gen1[j], prop1[j]);
		end
	endgenerate
	cla_gen_prop L2(gen1[1], gen1[0], prop1[1], prop1[0], gen2, prop2);

	// Carry Stage
	wire [`BIT4_WIDTH/2-1:0] cry;
	// Lvl0 //
	assign cry[0] = in_carry;
	assign cry[1] = gen1[0] | (prop1[0] & in_carry);

	// 2-bit RCA chain
	generate
		for (j=0; j<`BIT4_WIDTH/2; j=j+1) begin : RCA_CHAIN
			rca RCA(in_A[2*j+1:2*j], in_B[2*j+1:2*j], cry[j], out_s[2*j+1:2*j]);
		end
	endgenerate
	assign out_overflow = (gen2 | (prop2 & in_carry)) ^ (gen0[2] | (prop0[2] & cry[1])));
endmodule
