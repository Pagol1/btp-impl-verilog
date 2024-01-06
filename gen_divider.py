#####
# Verilog Code Generator
# Divider should go in the range [2^M, 2^L]/[2^M, 2^L] ==> [2^M/2^L, 2^L/2^(M+1)]
# Multiplier is stuck in N bit range though so not worth it
#####
import math

def pp(msg):
    global INDENT
    msg_len = len(msg)
    words = msg.split()

    if ("end" in words):
        INDENT -= 1
    elif ("end:" in words):
        INDENT -= 1
    if ("endgenerate" in words):
        INDENT -= 1

    op = "\t"*INDENT + msg + "\n"

    if ("begin" in words):
        INDENT += 1
    elif ("begin:" in words):
        INDENT += 1
    if ("generate" in words):
        INDENT += 1
        
    assert(INDENT >= 0)
    return op

def wire_st(stage_num):
    return "div_st{}".format(stage_num)

## n_i | d_i | b_i | q_i | s_o | b_o | q_o
def rs_args(st_n, idx):
    global BIT_LEN
    ret = "("
    # n_i
    if (st_n == 0):
        ret += "in_n[{}], ".format(idx)
    elif (idx == str(0)):
        ret += "1'b0, "
    elif (idx == str(BIT_LEN-1)):
        ret += wire_st(st_n-1)+"_s[{}], ".format(BIT_LEN-2)
    else:
        ret += wire_st(st_n-1)+"_s[{}], ".format(idx+"-1")
    # d_i
    if (idx == str(BIT_LEN-1)):
        ret += "1'b0, "
    else:
        ret += "in_d[{}], ".format(idx)
    # b_i
    if (idx == "0"):
        ret += "1'b0, "
    elif (idx == str(BIT_LEN-1-(st_n==0))):
        ret += wire_st(st_n) + "_b[{}], ".format(BIT_LEN-1-(st_n==0) - 1)
    else:
        ret += wire_st(st_n) + "_b[{}], ".format(idx+"-1")
    # q_i
    if (idx == str(BIT_LEN-1-(st_n==0))):
        ret += "out_q[{}], ".format(BIT_LEN-2-st_n)
    elif (idx == str(0)):
        ret += wire_st(st_n) + "_q[{}], ".format(1)
    else:
        ret += wire_st(st_n) + "_q[{}], ".format(idx+"+1")
    # s_o
    ret += wire_st(st_n) + "_s[{}], ".format(idx)
    # b_o
    ret += wire_st(st_n) + "_b[{}], ".format(idx)
    # q_o
    ret += wire_st(st_n) + "_q[{}]".format(idx)
    ret += ")"
    return ret


def gen_divider():
    global BIT_LEN
    global INDENT
    global MODULE_FILE_NAME
    global IO_PRE
    global INT_PRE
    global OUT_PRE
    global LSB_POW
    global MSB_POW
    assert(BIT_LEN == MSB_POW-LSB_POW+1)

    op = ""
    op += pp("// IO Params")
    ADDR = IO_PRE + "ADDR"
    WIDTH = IO_PRE + "WIDTH"
    SIGN = IO_PRE + "SIGN"
    MAG = IO_PRE + "MAG"
    POW_DECL = IO_PRE + "LSB_POW"
    op += pp("`define " + ADDR[1:] + " {}:0".format(BIT_LEN-1))
    op += pp("`define " + WIDTH[1:] + " {}".format(BIT_LEN))
    op += pp("`define " + SIGN[1:] + " {}".format(BIT_LEN-1))
    op += pp("`define " + MAG[1:] + " {}:0".format(BIT_LEN-2))
    op += pp("`define " + POW_DECL[1:] + " {}".format(LSB_POW))

    # No Params for last stage
    op += "\n"
    op += pp("module " + MODULE_FILE_NAME.split(".")[0] + "(")
    INDENT += 1
    op += pp("input clk,")
    op += pp("input rstn,")
    op += pp("input [" + ADDR + "] in_n,\t\t// Sign-Mag")
    op += pp("input [" + ADDR + "] in_d,\t\t// Sign-Mag")
    op += pp("output [" + ADDR + "] out_q,")
    op += pp("output div_by_zero")
    # op += pp("output out_overflow")
    # Local Params
    INDENT -= 1
    op += pp (");"); INDENT += 1
    op += pp("")

    # Plans:
    op += pp("genvar i;")
    for it in range(BIT_LEN-1):
        op += pp("// Stage {}".format(it))
        op += pp("wire [{}:0] {}_s;".format(BIT_LEN-2 if (it == 0) else BIT_LEN-1, wire_st(it)))
        op += pp("wire [{}:0] {}_b;".format(BIT_LEN-2 if (it == 0) else BIT_LEN-1, wire_st(it)))
        op += pp("wire [{}:0] {}_q;".format(BIT_LEN-2 if (it == 0) else BIT_LEN-1, wire_st(it)))
        # First and last RS have different IO
        op += pp( "restoring_subtractor RS_st_{}".format(it) + rs_args(it, "0") + ";" )
        op += pp("generate")
        op += pp( "for (i=1; i<{}; i=i+1) begin : DIV_STAGE_{}".format(BIT_LEN-2 if (it == 0) else BIT_LEN-1, it) )
        op += pp( "restoring_subtractor RS" + rs_args(it, 'i') + ";" )
        op += pp("end")
        op += pp("endgenerate")
        op += pp( "restoring_subtractor RS_end_{}".format(it) + rs_args( it, str(BIT_LEN-1-(it==0)) ) + ";" )
        op += pp( "assign out_q[{}] = ~{}_b[{}];".format(BIT_LEN-2-it, wire_st(it), BIT_LEN-2 if (it == 0) else BIT_LEN-1) )
    ## Zero division warning
    op += pp("assign div_by_zero = ~|in_d;")
    op += pp("assign out_q[{}] = in_n[{}] ^ in_d[{}];".format(BIT_LEN-1, BIT_LEN-1, BIT_LEN-1))
    op += "\n"
    INDENT -= 1
    op += pp("endmodule")
    return op

## n_i | d_i | b_i | q_i | s_o | b_o | q_o
def rs_args_i(st_n, idx):
    global BIT_LEN
    ret = "("
    # n_i
    if (st_n == 0):
        ret += "in_n[{}], ".format(idx)
    elif (idx == 0):
        ret += "1'b0, "
    else:
        ret += wire_st(st_n-1)+"_s[{}], ".format(idx-1)
    # d_i
    if (idx == BIT_LEN-1):
        ret += "1'b0, "
    else:
        ret += "in_d[{}], ".format(idx)
    # b_i
    if (idx == 0):
        ret += "1'b0, "
    else:
        ret += wire_st(st_n) + "_b[{}], ".format(idx-1)
    # q_i
    if (idx == BIT_LEN-1-(st_n==0)):
        ret += "out_q[{}], ".format(BIT_LEN-2-st_n)
    elif (idx == 0):
        ret += wire_st(st_n) + "_q[{}], ".format(1)
    else:
        ret += wire_st(st_n) + "_q[{}], ".format(idx+1)
    # s_o
    ret += wire_st(st_n) + "_s[{}], ".format(idx)
    # b_o
    ret += wire_st(st_n) + "_b[{}], ".format(idx)
    # q_o
    ret += wire_st(st_n) + "_q[{}]".format(idx)
    ret += ")"
    return ret

def gen_div():
    global BIT_LEN
    global INDENT
    global MODULE_FILE_NAME
    global IO_PRE
    global INT_PRE
    global OUT_PRE
    global LSB_POW
    global MSB_POW
    assert(BIT_LEN == MSB_POW-LSB_POW+1)

    op = ""
    op += pp("// IO Params")
    ADDR = IO_PRE + "ADDR"
    WIDTH = IO_PRE + "WIDTH"
    SIGN = IO_PRE + "SIGN"
    MAG = IO_PRE + "MAG"
    POW_DECL = IO_PRE + "LSB_POW"
    op += pp("`define " + ADDR[1:] + " {}:0".format(BIT_LEN-1))
    op += pp("`define " + WIDTH[1:] + " {}".format(BIT_LEN))
    op += pp("`define " + SIGN[1:] + " {}".format(BIT_LEN-1))
    op += pp("`define " + MAG[1:] + " {}:0".format(BIT_LEN-2))
    op += pp("`define " + POW_DECL[1:] + " {}".format(LSB_POW))

    # No Params for last stage
    op += "\n"
    op += pp("module " + MODULE_FILE_NAME.split(".")[0] + "(")
    INDENT += 1
    op += pp("input clk,")
    op += pp("input rstn,")
    op += pp("input [" + ADDR + "] in_n,\t\t// Sign-Mag")
    op += pp("input [" + ADDR + "] in_d,\t\t// Sign-Mag")
    op += pp("output [" + ADDR + "] out_q,")
    op += pp("output div_by_zero")
    # op += pp("output out_overflow")
    # Local Params
    INDENT -= 1
    op += pp (");"); INDENT += 1
    op += pp("")

    # Plans:
    op += pp("genvar i;")
    for it in range(BIT_LEN-1):
        op += pp("// Stage {}".format(it))
        op += pp("wire [{}:0] {}_s;".format(BIT_LEN-2 if (it == 0) else BIT_LEN-1, wire_st(it)))
        op += pp("wire [{}:0] {}_b;".format(BIT_LEN-2 if (it == 0) else BIT_LEN-1, wire_st(it)))
        op += pp("wire [{}:0] {}_q;".format(BIT_LEN-2 if (it == 0) else BIT_LEN-1, wire_st(it)))
        # First and last RS have different IO
        op += pp( "restoring_subtractor RS_st{}_{}".format(it, 0) + rs_args_i(it, 0) + ";" )
        for i in range(1, BIT_LEN-1 - (it == 0)):
            op += pp( "restoring_subtractor RS_st{}_{}".format(it, i) + rs_args_i(it, i) + ";" )
        # op += pp("generate")
        # op += pp( "for (i=1; i<{}; i=i+1) begin : DIV_STAGE_{}".format(BIT_LEN-2 if (it == 0) else BIT_LEN-1, it) )
        # op += pp( "restoring_subtractor RS" + rs_args(it, 'i') + ";" )
        # op += pp("end")
        # op += pp("endgenerate")
        op += pp( "restoring_subtractor RS_st{}_{}".format(it, (BIT_LEN-1-(it==0))) + rs_args_i( it, (BIT_LEN-1-(it==0)) ) + ";" )
        op += pp( "assign out_q[{}] = ~{}_b[{}];".format(BIT_LEN-2-it, wire_st(it), BIT_LEN-2 if (it == 0) else BIT_LEN-1) )
    ## Zero division warning
    op += pp("assign div_by_zero = ~|in_d;")
    op += pp("assign out_q[{}] = in_n[{}] ^ in_d[{}];".format(BIT_LEN-1, BIT_LEN-1, BIT_LEN-1))
    op += "\n"
    INDENT -= 1
    op += pp("endmodule")
    return op

if __name__ == "__main__":
    INDENT = 0
    ###
    BIT_LEN = 4
    MODULE_FILE_NAME = "fxp{}s_div.v".format(BIT_LEN)
    IO_PRE = "`FXP{}S_".format(BIT_LEN)
    INT_PRE = "`FXP{}S_DIV_".format(BIT_LEN)
    LSB_POW = -30
    ###
    # BIT_LEN = 4
    # MODULE_FILE_NAME = "bit4_dadda.v"
    # IO_PRE = "`BIT4_"
    # INT_PRE = "`BIT4_DM_"
    # LSB_POW = -2
    ###
    # BIT_LEN = 8
    # MODULE_FILE_NAME = "bit8_dadda.v"
    # IO_PRE = "`BIT8_"
    # INT_PRE = "`BIT8_DM_"
    # LSB_POW = -7
    ###
    MSB_POW = LSB_POW + (BIT_LEN-1)

    # op = gen_divider()
    op = gen_divider()
    with open(MODULE_FILE_NAME, 'w') as f:
        f.write(op)
