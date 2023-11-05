`include "my_defines.vh"
//`include "cla_gen_prop.v"
//`include "rca.v"
//`include "rcha.v"

// Unfortunately, ACC must be single cycle op (20ns clock rate target)
module fxp32_mac(
	input clk,
	input rstn,
	input acc,
	input prstn,
	input [`FXP32_ADDR] in_a,
	input [`FXP32_ADDR] in_b,
	output [`FXP32_ADDR] out_c
);
	wire [`FXP32_ADDR] conv_a, conv_b, mul_a_pre, mul_b_pre;
	reg [`FXP32_ADDR] mul_a, mul_b;
	assign conv_a = in_a ^ {`FXP32_WIDTH{in_a[`FXP32_SIGN]}};
	assign conv_b = in_b ^ {`FXP32_WIDTH{in_b[`FXP32_SIGN]}};
	fxp32_to_fxp32s CONV_IN_A(clk, conv_a, in_a[`FXP32_SIGN], mul_a_pre);
	fxp32_to_fxp32s CONV_IN_B(clk, conv_b, in_b[`FXP32_SIGN], mul_b_pre);
	always @(posedge clk) begin	// op: Cycle 1
		mul_a <= mul_a_pre & {`FXP32_WIDTH{rstn}};
		mul_b <= mul_b_pre & {`FXP32_WIDTH{rstn}};
	end
	
	wire mul_ovf; /* Do we do something with this?*/
	wire [`FXP32_ADDR] mul_out_pre;
	reg [`FXP32_ADDR] mul_out;
	fxp32s_dadda_pipe MUL(clk, rstn & prstn & acc, mul_a, mul_b, mul_out_pre, mul_ovf);
	always @(posedge clk) begin	// op: Cycle 5
		mul_out <= mul_out_pre & {`FXP32_WIDTH{rstn & prstn & acc}};
	end
	
	wire [`FXP32_ADDR] conv_mul_out_pre, mul_out_post;
	reg [`FXP32_ADDR] conv_mul_out;
	assign mul_out_post[`FXP32_MAG] = mul_out[`FXP32_ADDR] ^ {`FXP32_WIDTH-1{mul_out[`FXP32_SIGN]}};
	assign mul_out_post[`FXP32_SIGN] = mul_out[`FXP32_SIGN];
	fxp32s_to_fxp32 CONV_MUL(clk, mul_out_post, mul_out[`FXP32_SIGN], conv_mul_out_pre);
	always @(posedge clk) begin	// op: Cycle 6
		conv_mul_out <= conv_mul_out_pre & {`FXP32_WIDTH{rstn & prstn & acc}};
	end
	
	wire add_ovf;
	wire [`FXP32_ADDR] add_in_a, add_in_b, add_out;
	reg [`FXP32_ADDR] add_reg;
	assign add_in_a = (acc) ? conv_mul_out : in_a;
	assign add_in_b = (acc) ? add_reg : in_b;
	fxp32_cla ADD(clk, add_in_a, add_in_b, 1'b0, add_out, add_ovf);
	always @(posedge clk) begin	// op: Cycle 7 (MAC) || Cycle 1 (nACC)
		add_reg <= ((prstn) ? add_out : in_a) & {`FXP32_WIDTH{rstn & acc}};
	end
	
	assign out_c = add_out; // Latchable after 7 cycles for MAC
	
endmodule
