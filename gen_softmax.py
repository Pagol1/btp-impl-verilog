#####
# Verilog Code Generator
#####

## TODO : Test restart mechnism ==> Schedule 2 runs
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

def gen_softmax():
    '''
    Idea:
    - Pre-compute max by modifying the PE block
    - 
    '''
    global BIT_LEN
    global INDENT
    global MODULE_FILE_NAME
    global IO_PRE
    global LSB_POW
    global MSB_POW
    ## PE
    global PE_ARRAY_DIM
    N = PE_ARRAY_DIM
    RAM_WIDTH = 11

    op = ""
    op += pp("// IO Params")
    BUS_W = IO_PRE + "BUS_WIDTH"
    ADDR = IO_PRE + "ADDR"
    WIDTH = IO_PRE + "WIDTH"
    SIGN = IO_PRE + "SIGN"
    MAG = IO_PRE + "MAG"
    POW_DECL = IO_PRE + "LSB_POW"
    op += pp("`define " + BUS_W[1:] + " {}:0".format(N*BIT_LEN-1))
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
    op += pp("input en_in_data,")
    op += pp("output in_vec_done,")
    op += pp("input [" + ADDR_W + "] in_data,")
    op += pp("// Output Stream")
    op += pp("output en_out_data,")
    op += pp("input rdy_out_data,")
    op += pp("output out_vec_done,")
    op += pp("output [" + ADDR_W + "] out_data")
    INDENT -= 1
    op += pp(");"); INDENT += 1
    ## Module Start ##
    ## Idea:
    # Read in the vector and perform the operations on it
    # ==> High Storage Requirements right now (larger than the external PE RAM)
    # ==> Could make a dedicated softmax unit tbh
    op += pp("")
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
    MODULE_FILE_NAME = "fxp{}s_softmax.v".format(BIT_LEN)
    op = gen_pe_array()
    with open(MODULE_FILE_NAME, 'w') as f:
        f.write(op)

