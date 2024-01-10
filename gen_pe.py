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

def gen_2c_to_sm(name, w_in, w_out):
    op = ""
    op += pp("wire [{}:0] {}_a;".format(BIT_LEN-1, name))
    op += pp("wire {}_c;".format(name))
    op += pp("wire {}_c0;".format(name))
    op += pp("assign {}_a = {} ^ ".format(name, w_in) + 
            "{" + str(BIT_LEN) + "{" + w_in + f"[{BIT_LEN-1}]" + "}};")
    op += pp("assign {}_c = {}[{}];".format(name, w_in, BIT_LEN-1))
    op += pp("assign {" + f"{name}_c0, {w_out}[{BIT_LEN-2}:0]" + "} = " + 
            f"{w_in}[{BIT_LEN-2}:0] + {name}_c;")
    op += pp(f"assign {w_out}[{BIT_LEN-1}] = {w_in}[{BIT_LEN-1}];")
    return op

def gen_sm_to_2c(name, w_in, w_out):
    op = ""
    op += pp("assign {}[{}:0] = {}[{}:0] ^ ".format(w_out, BIT_LEN-2, w_in, BIT_LEN-2) + 
            "{" + str(BIT_LEN-1) + "{" + w_in + f"[{BIT_LEN-1}]" + "}};")
    op += pp(f"assign {w_out}[{BIT_LEN-1}] = {w_in}[{BIT_LEN-1}];")
    return op

def gen_pe():
    global BIT_LEN
    global INDENT
    global MODULE_FILE_NAME
    global IO_PRE
    global LSB_POW
    global MSB_POW
    ## PE
    global PE_ARRAY_DIM
    N = PE_ARRAY_DIM

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
    op += pp("input in_row,\t\t// Input is the row ==> Store in Buffer, else send to MUL_B")
    op += pp("input en_in,")
    op += pp("input [" + ADDR + "] in_data,\t\t// 2's complement")
    op += pp("input en_out,")
    op += pp("output [" + ADDR + "] out_data\t\t// 2's complement")
    INDENT -= 1
    op += pp (");"); INDENT += 1
    op += pp("")
    #### Module Core ####
    op += pp("genvar i;")
    op += pp("reg [{}:0] in_buf[{}:0];".format(BIT_LEN-1, N-1))
    op += pp("wire [{}:0] in_mul_a;".format(BIT_LEN-1))
    op += pp("reg [{}:0] in_mul_b;".format(BIT_LEN-1))
    op += pp("wire [{}:0] out_mul_s;".format(BIT_LEN-1))
    op += pp("wire out_mul_ovf;")
    op += pp("reg mul_on;")
    op += pp("reg [{}:0] acc;".format(BIT_LEN-1))
    op += pp("wire [{}:0] acc_in;".format(BIT_LEN-1))
    ## Buffer Stage
    op += pp("always @(posedge clk) begin")
    op += pp("in_buf[0] <= (en_in & in_row) ? in_data : in_buf[0] & {"+f"{BIT_LEN}"+"{rstn}};")
    op += pp("in_mul_b <= (en_in & ~in_row) ? in_data : in_mul_b & {"+f"{BIT_LEN}"+"{rstn}};")
    op += pp("mul_on <= ~in_row & en_in & rstn;")
    op += pp("end")
    ## Buffer Internals
    op += pp("generate")
    op += pp( "for (i=1; i<{}; i=i+1) begin : IN_BUF".format(N) )
    op += pp("always @(posedge clk) begin")
    op += pp("in_buf[i] <= (en_in & in_row) ? in_buf[i-1] : in_buf[i] & {"+f"{BIT_LEN}"+"{rstn}};")
    op += pp("end")
    op += pp( "end" )
    op += pp("endgenerate")
    op += pp("assign in_mul_a = in_buf[{}] &".format(N-1) + "{" + f"{BIT_LEN}" + "{mul_on}};")
    ## 2's C to SM
    op += pp("// Convert 2C -> SM")
    op += pp("wire [{}:0] mul_a;".format(BIT_LEN-1))
    op += pp("wire [{}:0] mul_b;".format(BIT_LEN-1))
    op += pp("wire [{}:0] mul_s;".format(BIT_LEN-1))
    op += gen_2c_to_sm("pre_mul_a", "in_mul_a", "mul_a")
    op += gen_2c_to_sm("pre_mul_b", "in_mul_b", "mul_b")
    ## MUL
    op += pp("fxp8s_dadda MUL(clk, rstn, mul_a, mul_b, mul_s, out_mul_ovf);")
    op += pp("// Convert SM -> 2C")
    op += gen_sm_to_2c("post_mul_s", "mul_s", "out_mul_s")
    ## ACC
    op += pp("// Accumulator")
    op += pp("wire acc_cout;")
    op += pp("assign {acc_cout, acc_in} = acc + out_mul_s;")
    op += pp("always @(posedge clk) begin")
    op += pp("acc <= acc_in & {" + str(BIT_LEN) + "{rstn}};")
    op += pp("end")
    ## Drive output
    op += pp("assign out_data = (en_out) ? acc : {" + str(BIT_LEN) + "{1'bZ}};")
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
    MODULE_FILE_NAME = "fxp{}s_pe.v".format(BIT_LEN)
    op = gen_pe()
    with open(MODULE_FILE_NAME, 'w') as f:
        f.write(op)
