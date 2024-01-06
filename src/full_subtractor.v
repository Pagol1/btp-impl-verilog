module full_subtractor(
    input n,
    input d,
    input bi,
    output s,
    output bo
);
    wire imm;
    assign imm = n ^ d;
    assign s = imm ^ bi;
    assign bo =  (bi & ~imm) | (~n & d);
endmodule