module comp_sub_b(
    input in_n,
    input in_d,
    input in_b,
    output out_b
);
    wire imm;
    assign imm = in_n ~^ in_d;
    assign out_b =  (in_b & imm) | (~in_n & in_d);
endmodule