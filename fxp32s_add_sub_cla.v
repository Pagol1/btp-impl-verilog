module fxp32s_add_sub_cla(
    input clk,
    input [`FXP32S_ADDR]    in_a,
    input [`FXP32S_ADDR]    in_b,
    input                   sub,    // sub if HIGH
    output [`FXP32S_ADDR]   out_s,  // out_s = in_a +/- in_b
    output [`FXP32S_ADDR]   out_overflow
);
    wire [`FXP32S_ADDR] adj_a, adj_b, adj_s, conv_in, conv_out;
    wire sign_a, sign_b, inv_a, inv_b, inv_out_sign, pass_carry;

    assign sign_a = in_a[`FXP32S_SIGN];
    assign sign_b = in_b[`FXP32S_SIGN] ^ sub;
    assign inv_out_sign = sign_a & sign_b;
    assign inv_a = sign_a & ~sign_b;
    assign inv_b = ~sign_a & sign_b;
    assign pass_carry = inv_a | inv_b;
    
    assign adj_a[`FXP32S_MAG] = in_a[`FXP32S_MAG] ^ {`FXP32S_WIDTH-1{inv_a}};
    assign adj_a[`FXP32S_SIGN] = 1'b0;
    assign adj_b[`FXP32S_MAG] = in_b[`FXP32S_MAG] ^ {`FXP32S_WIDTH-1{inv_b}};
    assign adj_b[`FXP32S_SIGN] = 1'b0;

    fxp32_cla ADDER(clk, adj_a, adj_b, pass_carry, adj_s, out_overflow);

    assign out_s[`FXP32S_SIGN] = adj_s[`FXP32S_SIGN] | inv_out_sign;
    assign conv_in = adj_s ^ {`FXP32S_WIDTH{adj_s[`FXP32S_SIGN]}};
    fxp32_to_fxp32s CONV(clk, conv_in, adj_s[`FXP32S_SIGN], conv_out);

    assign out_s[`FXP32S_MAG] = conv_out[`FXP32S_MAG];

endmodule
