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

def gen_fast_adder():
    global BIT_LEN
    global INDENT
    global MODULE_FILE_NAME
    global IO_PRE
    global INT_PRE
    assert((BIT_LEN & (BIT_LEN-1)) == 0)
    
    op = ""
    op += pp("// IO Params")
    ADDR = IO_PRE + "ADDR"
    WIDTH = IO_PRE + "WIDTH"
    op += pp("`define " + ADDR[1:] + " {}:0".format(BIT_LEN-1))
    op += pp("`define " + WIDTH[1:] + " {}".format(BIT_LEN))
    
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
    # Local Params
    INDENT -= 1
    op += pp (");"); INDENT += 1
    # For Lower Half
    st_addr = "{}:0".format((BIT_LEN >> 2)-1)
    st_wid = BIT_LEN>>2
    l_addr = "{}:0".format((BIT_LEN >> 1)-1)
    l_len = BIT_LEN >> 1
    r_addr = "{}:{}".format(BIT_LEN-2, BIT_LEN>>1)

    op += pp("// Fast Carry Generator")
    op += pp("wire [{}] gen, prop, carry;".format(st_addr))
    op += pp("cla_fast_lut LUT(clk, in_a[1:0], in_b[1:0], in_carry, gen[0], prop[0], carry[0]);")
    op += pp("genvar j;")
    op += pp("generate")
    op += pp("for (j=1; j<{}; j=j+1) begin : FAST_CARRY_GEN".format(st_wid))
    op += pp("cla_fast_lut LUT(clk, in_a[2*j+1:2*j], in_b[2*j+1, 2*j], carry[j-1], gen[j], prop[j], carry[j]);")
    op += pp("end")
    op += pp("endgenerate")

    op += "\n"
    op += pp("wire cry0, cry1;")
    op += pp("assign out_s[{0}] = in_a[{0}] \+ in_b[{0}] \+ in_carry;".format(l_addr))
    op += pp("assign {" + "cry0, out_s[{0}]".format(r_addr) + "}" + " = in_a[{0}] \+ in_b[{0}] \+ carry[{1}];".format(r_addr, st_wid-1))
    op += pp("assign {" + "cry1, out_s[{0}]".format(BIT_LEN-1) + "}" + " = in_a[{0}] \+ in_b[{0}] \+ cry0;".format(BIT_LEN-1))
    op += pp("assign out_overflow = cry1 ^ cry0;")
    #op += pp("rca RCA_LOW(in_a[{0}], in_b[{0}], in_carry, out_s[{0}], ovf);".format(l_addr))
    #op += pp("rca RCA_HIGH(in_a[{0}], in_b[{0}], carry[{1}], out_s[{0}], out_overflow);".format(r_addr, st_wid-1))
    INDENT -= 1; op += pp("endmodule")
    return op

if __name__ == "__main__":
    ### Configuration
    # # FXP32
    # IO_PRE = "`FXP32_"
    # INT_PRE = "`FXP32_FA_"
    # MODULE_FILE_NAME = "fxp32_fast_adder.v"
    # ## FXP32_pipe
    # # MODULE_FILE_NAME = "fxp32_cla_pipe.v"
    # BIT_LEN = 32
    ## FXP64
    IO_PRE = "`BIT64_"
    INT_PRE = "`BIT64_CLA_"
    # MODULE_FILE_NAME = "cla_64bit.v"
    ## FXP64_pipe
    MODULE_FILE_NAME = "fast_adder_64bit.v"
    BIT_LEN = 64
    INDENT = 0
    op = gen_fast_adder()
    # op = gen_cla()
    with open(MODULE_FILE_NAME, 'w') as f:
        f.write(op)
