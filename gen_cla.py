#####
# Verilog Code Generator
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

def all_marked(arr):
    return True if 0 not in arr else False

def gen_cla():
    global BIT_LEN
    global INDENT
    global MODULE_FILE_NAME
    global IO_PRE
    global INT_PRE
    assert((BIT_LEN & (BIT_LEN-1)) == 0)
    num_stage = int(math.log2(BIT_LEN))
    num_pad = int(math.log10(num_stage)) + 1

    op = ""
    op += pp("// IO Params")
    ADDR = IO_PRE + "ADDR"
    WIDTH = IO_PRE + "WIDTH"
    op += pp("`define " + ADDR[1:] + " {}:0".format(BIT_LEN-1))
    op += pp("`define " + WIDTH[1:] + " {}".format(BIT_LEN))
    
    ST_ADDR = []
    ST_WIDTH = []
    for i in range(num_stage):
        ST_ADDR.append(INT_PRE[1:] + "L" + f"{i:0{num_pad}d}" + "_ADDR")
        ST_WIDTH.append(INT_PRE[1:] + "L" + f"{i:0{num_pad}d}" + "_WIDTH")
    # No Params for last stage
    op += "\n"
    op += pp("module " + MODULE_FILE_NAME.split(".")[0] + "(")
    INDENT += 1
    op += pp("input clk,")
    op += pp("input [" + ADDR + "] in_a,")
    op += pp("input [" + ADDR + "] in_b,")
    op += pp("input in_carry,")
    op += pp("output [" + ADDR + "] out_s,")
    op += pp("output out_overflow")
    INDENT -= 1
    # Local Params
    op += pp (");"); INDENT += 1
    op += pp("// Adder Params")
    for i in range(len(ST_ADDR)):
        op += pp("localparam " + ST_ADDR[i] + " {}:0;".format((BIT_LEN >> i) - 1))
    for i in range(len(ST_WIDTH)):
        op += pp("localparam " + ST_WIDTH[i] + " {};".format(BIT_LEN >> i))
    #op += pp(
    op += "\n"
    gen_l = []
    prop_l = []
    for i in range(len(ST_ADDR)):
        gen_l.append("gen" + f"{i:0{num_pad}d}")
        prop_l.append("prop" + f"{i:0{num_pad}d}")
        op += pp("wire [" + ST_ADDR[i] + "] " + gen_l[-1] + ", " + prop_l[-1] + ";")
    i_ = num_stage
    gen_l.append("gen" + f"{i_:0{num_pad}d}")
    prop_l.append("prop" + f"{i_:0{num_pad}d}")
    op += pp("wire " + gen_l[-1] + ", " + prop_l[-1] + ";")

    op += pp("assign " + gen_l[0] + " = in_a & in_b;");
    op += pp("assign " + prop_l[0] + " = in_a ^ in_b;");
    
    op += "\n"
    op += pp("// GP stage")
    op += pp("genvar j;")
    for i in range(1, num_stage):
        op += pp("generate")
        op += pp("for (j=0; j<" + ST_WIDTH[i] + "; j=j+1) begin : CLA_GEN_PROP_L" + f"{i:0{num_pad}d}")
        op += pp("cla_gen_prop L" + f"{i:0{num_pad}d}" + "(" + gen_l[i-1] + "[2*j+1], " + gen_l[i-1] + "[2*j], " + prop_l[i-1] + "[2*j+1], " + prop_l[i-1] + "[2*j], " + gen_l[i] + "[j], " + prop_l[i] + "[j]);")
        op += pp("end")
        op += pp("endgenerate")
    i_ = num_stage
    op += pp("cla_gen_prop L" + f"{i_:0{num_pad}d}" + "(" + gen_l[i_-1] + "[1], " + gen_l[i_-1] + "[0], " + prop_l[i_-1] + "[1], " + prop_l[i_-1] + "[0], " + gen_l[i_] + ", " + prop_l[i_] + ");")
    
    op += "\n"
    op += pp("// Carry Stage")
    op += pp("wire [" + WIDTH + "/2-1:0] cry;")
    carry_mask = [0] * (BIT_LEN >> 1)
    # Lvl 0
    lvl = 0
    op += pp("// Lvl{} //".format(lvl))
    op += pp("assign cry[0] = in_carry;")
    carry_mask[0] = 1
    for exp in range(num_stage-1):
        idx = 1 << exp
        op += pp("assign cry[{}] = {}[0] | ({}[0] & in_carry);".format(idx, gen_l[exp+1], prop_l[exp+1]))
        carry_mask[idx] = 1
    
    while not all_marked(carry_mask):
        lvl += 1
        op += pp("// Lvl{} //".format(lvl))
        for i in range(len(carry_mask)-1):
            for exp in range(num_stage-2):
                j = 1 << exp
                r = (i % j == 0)
                if not r:
                    break
                if (i + j) < len(carry_mask):
                    if carry_mask[i] == 1 and carry_mask[i+j] == 0:
                        op += pp("assign cry[{}] = {}[{}] | ({}[{}] & cry[{}]);".format(i+j, gen_l[exp+1], i>>exp, prop_l[exp+1], i>>exp, i))
                        carry_mask[i+j] = 1

    op += "\n"
    op += pp("// 2-bit RCA chain")
    op += pp("generate")
    op += pp("for (j=0; j<{}/2; j=j+1) begin : RCA_CHAIN".format(WIDTH))
    op += pp("rca RCA(in_A[2*j+1:2*j], in_B[2*j+1:2*j], cry[j], out_s[2*j+1:2*j]);")
    op += pp("end")
    op += pp("endgenerate")

    op += pp("assign out_overflow = ({} | ({} & in_carry)) ^ ({}[{}] | ({}[{}] & cry[{}])));".format(
            gen_l[-1], prop_l[-1], gen_l[0], BIT_LEN-2, prop_l[0], BIT_LEN-2, len(carry_mask)-1
        ))

    INDENT -= 1
    op += ("endmodule")
    return op

if __name__ == "__main__":
    ### Configuration
    ## FXP32
#    IO_PRE = "`FXP32_"
#    INT_PRE = "`FXP32_CLA_"
#    MODULE_FILE_NAME = "fxp32_cla.v"
#    BIT_LEN = 32
    ## FXP64
    IO_PRE = "`BIT64_"
    INT_PRE = "`BIT64_CLA_"
    MODULE_FILE_NAME = "cla_64bit.v"
    BIT_LEN = 64
    ## CLA_4
#    IO_PRE = "`BIT4_"
#    INT_PRE = "`CLA_4BIT_"
#    MODULE_FILE_NAME = "cla_4bit.v"
#    BIT_LEN = 4
    ##
    INDENT = 0
    op = gen_cla()
    with open(MODULE_FILE_NAME, 'w') as f:
        f.write(op)
