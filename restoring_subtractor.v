module restoring_subtractor(
    input in_n,
    input in_d,
    input in_b,
    input in_q,
    output out_s,
    output out_b,
    output out_q
);
    wire imm_s;
    full_subtractor FS(in_n, in_d, in_b, imm_s, out_b);
    assign out_q = in_q;
    assign out_s = in_q ? imm_s : in_n;
endmodule