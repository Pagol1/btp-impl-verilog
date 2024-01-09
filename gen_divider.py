#####
# Verilog Code Generator
# Divider should go in the range [2^M, 2^L]/[2^M, 2^L] ==> [2^M/2^L, 2^L/2^(M+1)]
# Multiplier is stuck in N bit range though so not worth it
#####
import math
from gen_config import *

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

## n_i | d_i | b_i | q_i | s_o | b_o | q_o
def get_rs_args(st_n, idx, use_n, n_id, d_zero, l_end, r_end):
    global BIT_LEN
    ret = "("
    # n_i
    if (use_n):
        ret += "in_n[{}], ".format(n_id)
    elif not r_end:
        if isinstance(idx, str):
            ret += wire_st(st_n-1) + "_s[{}], ".format(idx + "-1")
        else:
            ret += wire_st(st_n-1) + "_s[{}], ".format(idx-1)
    else:
        ret += "1'b0, "
    # d_i
    if not d_zero:
        ret += "in_d[{}], ".format(idx)
    else:
        ret += "1'b0, "
    # b_i
    if not r_end:
        if isinstance(idx, str):
            ret += wire_st(st_n) + "_b[{}], ".format(idx + "-1")
        else:
            ret += wire_st(st_n) + "_b[{}], ".format(idx-1)
    else:
        ret += "1'b0, "
    # q_i
    if l_end:
        ret += "out_q[{}], ".format(BIT_LEN-2-st_n)
    else:
        if isinstance(idx, str):
            ret += wire_st(st_n) + "_q[{}], ".format(idx+"+1")
        else:
            ret += wire_st(st_n) + "_q[{}], ".format(idx+1)
    # s_o
    ret += wire_st(st_n) + "_s[{}], ".format(idx)
    # b_o
    ret += wire_st(st_n) + "_b[{}], ".format(idx)
    # q_o
    ret += wire_st(st_n) + "_q[{}]".format(idx)
    ret += ");"
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
    assert(BIT_LEN-1 == MSB_POW-LSB_POW+1)
    
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

    ## MSB_POW == Max +ve power of 2 in expr
    op += pp("genvar i;")
    used_bits = 0
    used_n = 0
    mask_bits = 0
    if (MSB_POW > 1):
        op += pp("wire [{}:0] div_q_mask;".format(MSB_POW-1))
        op += pp("assign div_q_mask[0] = in_d[{}];".format(BIT_LEN-2))
        op += pp("generate")
        op += pp("for (i=1; i<{}; i=i+1) begin : DIV_MASK".format(
                min(MSB_POW, BIT_LEN-2)
            ))
        mask_bits = min(MSB_POW, BIT_LEN-2)
        op += pp("assign div_q_mask[i] = div_q_mask[i-1] | in_d[{}-i];".format(BIT_LEN-2))
        op += pp("end")
        op += pp("endgenerate")

    ## Useless, not gonna be a use-case tbh
    for idx in range(MSB_POW, MSB_POW-LSB_POW, -1):
        op += pp("// Stage {} : 2^{}".format(used_bits, idx))
        op += pp("assign out_q[{}] = 1'b0;".format(BIT_LEN-2-used_bits))
        used_bits += 1
        if (used_bits == BIT_LEN-1):
            op += "\n"; INDENT -= 1
            op += pp("endmodule")
            return op
    # Start from MAX_POW or MAX_POW-LOW_POW if LOW_POW > 0
    for power in range(MSB_POW-used_bits, 0, -1):
        n_tgt = MSB_POW-LSB_POW+1 - power # used_n = n_tgt
        op += pp("// Stage {} : 2^{}".format(used_bits, power))
        op += pp("wire [{}:0] {}_s;".format(n_tgt-1, wire_st(used_bits)))
        op += pp("wire [{}:0] {}_b;".format(n_tgt-1, wire_st(used_bits)))
        op += pp("wire [{}:0] {}_q;".format(n_tgt-1, wire_st(used_bits)))
        ## Need to take logic one step behind now
        ## rs_args -> 
            ### use_n, d_val = idx, b_in = {0, idx-1}
            ### q_in = {Q[BL-2-used_bits], idx+1}, rest = idx
        ## Count number of blocks in "group" ==> Add generate
        if (used_n >= 1):
            op += pp("restoring_subtractor RS_lEnd_{}".format(used_bits) + get_rs_args(used_bits, n_tgt-1, False, "", False, True, False))
        else:
            op += pp("restoring_subtractor RS_lEnd_{}".format(used_bits) + get_rs_args(used_bits, n_tgt-1, True, f"{MSB_POW-LSB_POW}", False, True, False))
        ## Chain Used
        if (used_n >= 2):
            op += pp("generate")
            op += pp( "for (i={}; i>={}; i=i-1) begin : RS_ROW_N_USED_{}".format(n_tgt-2, max(n_tgt-used_n, 1), used_bits) )
            op += pp( "restoring_subtractor RS_{}".format(used_bits) + get_rs_args(used_bits, "i", False, "", False, False, False) )
            op += pp( "end" )
            op += pp("endgenerate")
        ## Chain Free
        if (n_tgt > used_n):
            op += pp("generate")
            op += pp( "for (i={}; i>={}; i=i-1) begin : RS_ROW_N_NEW_{}".format(n_tgt-used_n-1-1*(used_n==0), 1, used_bits) )
            op += pp( "restoring_subtractor RS_{}".format(used_bits) + get_rs_args(used_bits, "i", True, "i+{}".format(power), False, False, False) )
            op += pp( "end" )
            op += pp("endgenerate")
            op += pp("restoring_subtractor RS_rEnd_{}".format(used_bits) + get_rs_args(used_bits, 0, True, power, False, False, True))
        else:   ## Not a valid scenario but OK
            print("[WARN]")
            op += pp("restoring_subtractor RS_rEnd_{}".format(used_bits) + get_rs_args(used_bits, 0, False, "", False, False, True))
        op += pp("assign out_q[{}] = ~(div_q_mask[{}] | {}_b[{}]);".format(BIT_LEN-2-used_bits, power-1, wire_st(used_bits), n_tgt-1))
        used_n = n_tgt
        used_bits += 1

    for power in range(0, LSB_POW-1, -1):
        n_tgt = MSB_POW-LSB_POW+1 + (power < 0)
        op += pp("// Stage {} : 2^{}".format(used_bits, power))
        op += pp("wire [{}:0] {}_s;".format(n_tgt-1, wire_st(used_bits)))
        op += pp("wire [{}:0] {}_b;".format(n_tgt-1, wire_st(used_bits)))
        op += pp("wire [{}:0] {}_q;".format(n_tgt-1, wire_st(used_bits)))
        if (power == 0):
            if (used_n >= 1):
                op += pp("restoring_subtractor RS_lEnd_{}".format(used_bits) + get_rs_args(used_bits, n_tgt-1, False, "", False, True, False))
            else:
                op += pp("restoring_subtractor RS_lEnd_{}".format(used_bits) + get_rs_args(used_bits, n_tgt-1, True, f"{MSB_POW-LSB_POW}", False, True, False))
            if (used_n >= 2):
                op += pp("generate")
                op += pp( "for (i={}; i>={}; i=i-1) begin : RS_ROW_N_USED_{}".format(n_tgt-2, max(n_tgt-used_n, 1), used_bits) )
                op += pp( "restoring_subtractor RS_{}".format(used_bits) + get_rs_args(used_bits, "i", False, "", False, False, False) )
                op += pp( "end" )
                op += pp("endgenerate")
            if (n_tgt > used_n):
                op += pp("generate")
                op += pp( "for (i={}; i>={}; i=i-1) begin : RS_ROW_N_NEW_{}".format(n_tgt-used_n-1-1*(used_n==0), 1, used_bits) )
                op += pp( "restoring_subtractor RS_{}".format(used_bits) + get_rs_args(used_bits, "i", True, "i+{}".format(power), False, False, False) )
                op += pp( "end" )
                op += pp("endgenerate")
                op += pp("restoring_subtractor RS_rEnd_{}".format(used_bits) + get_rs_args(used_bits, 0, True, power, False, False, True))
            else:
                op += pp("restoring_subtractor RS_rEnd_{}".format(used_bits) + get_rs_args(used_bits, 0, False, "", False, False, True))
            used_n = n_tgt
        else:
            op += pp("restoring_subtractor RS_lEnd_{}".format(used_bits) + get_rs_args(used_bits, n_tgt-1, False, "", True, True, False))
            op += pp("generate")
            op += pp( "for (i={}; i>{}; i=i-1) begin : RS_ROW_N_USED_{}".format(n_tgt-2, 0, used_bits) )
            op += pp( "restoring_subtractor RS_{}".format(used_bits) + get_rs_args(used_bits, "i", False, "", False, False, False) )
            op += pp( "end" )
            op += pp("endgenerate")
            op += pp("restoring_subtractor RS_rEnd_{}".format(used_bits) + get_rs_args(used_bits, 0, False, "", False, False, True))
        op += pp("assign out_q[{}] = ~{}_b[{}];".format(BIT_LEN-2-used_bits, wire_st(used_bits), n_tgt-1))
        used_bits += 1

    ## After one's place
    #op += pp("genvar i;")
    #for it in range(BIT_LEN-1):
    #    op += pp("// Stage {}".format(it))
    #    op += pp("wire [{}:0] {}_s;".format(BIT_LEN-2 if (it == 0) else BIT_LEN-1, wire_st(it)))
    #    op += pp("wire [{}:0] {}_b;".format(BIT_LEN-2 if (it == 0) else BIT_LEN-1, wire_st(it)))
    #    op += pp("wire [{}:0] {}_q;".format(BIT_LEN-2 if (it == 0) else BIT_LEN-1, wire_st(it)))
    #    # First and last RS have different IO
    #    op += pp( "restoring_subtractor RS_st_{}".format(it) + rs_args(it, "0") + ";" )
    #    op += pp("generate")
    #    op += pp( "for (i=1; i<{}; i=i+1) begin : DIV_STAGE_{}".format(BIT_LEN-2 if (it == 0) else BIT_LEN-1, it) )
    #    op += pp( "restoring_subtractor RS" + rs_args(it, 'i') + ";" )
    #    op += pp("end")
    #    op += pp("endgenerate")
    #    op += pp( "restoring_subtractor RS_end_{}".format(it) + rs_args( it, str(BIT_LEN-1-(it==0)) ) + ";" )
    #    op += pp( "assign out_q[{}] = ~{}_b[{}];".format(BIT_LEN-2-it, wire_st(it), BIT_LEN-2 if (it == 0) else BIT_LEN-1) )

    ## Zero division warning
    op += pp("assign div_by_zero = ~|in_d;")
    op += pp("assign out_q[{}] = in_n[{}] ^ in_d[{}];".format(BIT_LEN-1, BIT_LEN-1, BIT_LEN-1))
    op += "\n"
    INDENT -= 1
    op += pp("endmodule")
    return op

if __name__ == "__main__":
    global BIT_LEN
    global IO_PRE
    global LSB_POW
    INDENT = 0
    ###
    # BIT_LEN = 6
    # MODULE_FILE_NAME = "fxp{}s_div.v".format(BIT_LEN)
    # IO_PRE = "`FXP{}S_".format(BIT_LEN)
    # INT_PRE = "`FXP{}S_DIV_".format(BIT_LEN)
    # LSB_POW = -2
    MSB_POW = LSB_POW + (BIT_LEN-1) - 1
    MODULE_FILE_NAME = "fxp{}s_div.v".format(BIT_LEN)
    # op = gen_divider()
    op = gen_divider()
    with open(MODULE_FILE_NAME, 'w') as f:
        f.write(op)
