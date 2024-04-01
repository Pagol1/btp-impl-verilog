#####
# Verilog Code Generator
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

def get_mc(N, sig):
    return "{" + str(N) + "{" + sig + "}}"

def gen_var_shifter():
    global BIT_LEN
    global INDENT
    global MODULE_FILE_NAME
    global IO_PRE
    global LSB_POW
    global MSB_POW
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
    ## Module Start ##
    op += "\n"
    op += pp("module " + MODULE_FILE_NAME.split(".")[0] + "(")
    INDENT += 1
    op += pp("input clk,")
    op += pp("input rstn,")
    op += pp("// Input Stream")
    op += pp("input [" + ADDR + "] in_data,")
    op += pp("input [" + ADDR + "] in_shift,")
    op += pp("input shift_sign, // 0: LS | 1: RS")
    op += pp("// Output Stream")
    op += pp("output [" + ADDR + "] out_data")
    INDENT -= 1
    op += pp(");"); INDENT += 1
    SHFT_W = math.ceil(math.log2(BIT_LEN))
    ## Module Start ##
    op += pp(f"wire [{BIT_LEN-1}:0] sat_val;")
    op += pp(f"wire saturate;")
    # op += pp("wire shift_sign;")                    # Left shift if 0 else right
    op += pp(f"wire [{SHFT_W-1}:0] shift_val;")
    # op += pp(f"assign shift_sign = in_shift[{BIT_LEN-1}];")
    # op += pp("assign sat_val = (in_shift ^ "+get_mc(BIT_LEN, "shift_sign")+") + shift_sign;")
    # Saturate ==> Make output bits 0
    op += pp(f"assign saturate = ~|in_shift[{BIT_LEN-1}:{SHFT_W}];")
    op += pp(f"assign shift_val = in_shift[{SHFT_W-1}:0];")
    op += pp("// Stages")
    op += pp(f"wire [{BIT_LEN-1}:0] stage_val [{SHFT_W}:0];")
    op += pp("assign stage_val[0] = in_data;")
    for i in range(1, SHFT_W+1):
        shft_val = int(math.pow(2, i-1))
        op += pp(f"assign stage_val[{i}] = shift_val[{i-1}] ? (shift_sign ? " + 
                "{{" + str(shft_val) +"{in_data["+str(BIT_LEN-1)+"]}}, " +          
                f"stage_val[{i-1}][{BIT_LEN-1}:{shft_val}]" + "} : { " +
                f"stage_val[{i-1}][{BIT_LEN-1-shft_val}:0], " 
                "{" + str(shft_val) +"{1'b0}} }) : " + f"stage_val[{i-1}];")
    op += pp(f"assign out_data[{BIT_LEN-1}] = in_data[{BIT_LEN-1}] & saturate;")
    op += pp(f"assign out_data[{BIT_LEN-2}:0] = stage_val[{SHFT_W}][{BIT_LEN-2}:0] & " + 
            "{" + f"{BIT_LEN-1}" + "{saturate}}"+";")
    ## Module End ##
    op += "\n"
    INDENT -= 1
    op += pp("endmodule")
    return op

if __name__ == "__main__":
    global BIT_LEN
    global IO_PRE
    global LSB_POW
    INDENT = 0
    MSB_POW = LSB_POW + (BIT_LEN-1) 
    MODULE_FILE_NAME = "fxp{}s_var_shifter.v".format(BIT_LEN)
    op = gen_var_shifter()
    with open(MODULE_FILE_NAME, 'w') as f:
        f.write(op)
    # Part - II
    BIT_LEN = BIT_LEN + ((NUM_PASS+1)*NUM_STAGE + LSB_POW) + GUARD_BIT
    INDENT = 0
    MSB_POW = LSB_POW + (BIT_LEN-1) 
    MODULE_FILE_NAME = "fxp{}s_var_shifter.v".format(BIT_LEN)
    op = gen_var_shifter()
    with open(MODULE_FILE_NAME, 'w') as f:
        f.write(op)