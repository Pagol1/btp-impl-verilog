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
    global BIT_LEN
    op = ""
    op += pp("wire [{}:0] {}_a;".format(BIT_LEN-1, name))
    op += pp("wire {}_c;".format(name))
    op += pp("wire {}_c0;".format(name))
    op += pp("assign {}_a = {} ^ ".format(name, w_in) + 
            "{" + str(BIT_LEN) + "{" + w_in + f"[{BIT_LEN-1}]" + "}};")
    op += pp("assign {}_c = {}[{}];".format(name, w_in, BIT_LEN-1))
    op += pp("assign {" + f"{name}_c0, {w_out}[{BIT_LEN-2}:0]" + "} = " + 
            f"{name}_a[{BIT_LEN-2}:0] + {name}_c;")
    op += pp(f"assign {w_out}[{BIT_LEN-1}] = {w_in}[{BIT_LEN-1}];")
    return op

def gen_sm_to_2c(name, w_in, w_out):
    global BIT_LEN
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
    op += pp("input en_in,")
    op += pp("input in_buf,\t\t// Send input to buffer")
    op += pp("input [" + ADDR + "] in_data,\t\t// 2's complement")
    op += pp("input in_done,")
    op += pp("input acc_end,")                     # From global scheduler ==> Indicates that ACC is done
    op += pp("output en_out,")
    op += pp("input rdy_out,")
    op += pp("output [" + ADDR + "] out_data\t\t// 2's complement")
    INDENT -= 1
    op += pp (");"); INDENT += 1
    op += pp("")
    #### Module Core ####
    op += pp("genvar i;")
    op += pp("reg [{}:0] buffer;".format(BIT_LEN-1))
    op += pp("wire [{}:0] in_mul_a;".format(BIT_LEN-1))
    op += pp("wire [{}:0] in_mul_b;".format(BIT_LEN-1))
    op += pp("wire [{}:0] out_mul_s;".format(BIT_LEN-1))
    op += pp("wire out_mul_ovf;")
    op += pp("reg acc_done;")
    op += pp("wire mul_on;")
    op += pp("reg [{}:0] acc;".format(BIT_LEN-1))
    op += pp("wire [{}:0] acc_in;".format(BIT_LEN-1))
    op += pp("wire buf_in;")
    op += pp("assign buf_in = en_in & in_buf;")
    op += pp("assign mul_on = en_in & ~in_buf;")
    ## Buffer Stage
    op += pp("always @(posedge clk) begin")
    op += pp(f"buffer <= (buf_in ? in_data : buffer) & "+" {"+f"{BIT_LEN}"+"{rstn}};") ## (mul_on ? {BIT_LEN}'b{BIT_LEN*'0'} : buf) ) &"+" {"+f"{BIT_LEN}"+"{rstn}};")
    # op += pp(f"in_mul_b <= ((en_in & ~in_row) ? in_data : {BIT_LEN}'b{BIT_LEN*'0'}) &"+" {"+f"{BIT_LEN}"+"{rstn}};")
    op += pp("end")
    op += pp("assign in_mul_a = buffer & " + "{" + f"{BIT_LEN}" + "{mul_on}};")
    op += pp("assign in_mul_b = in_data & " + "{" + f"{BIT_LEN}" + "{mul_on}};")
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
    op += pp("acc_done <= (acc_done | (mul_on & in_done & acc_end)) & rstn & ~(en_out & rdy_out);")
    op += pp("end")
    ## Drive output
    op += pp("assign en_out = acc_done;")
    op += pp("assign out_data =  acc & {" + str(BIT_LEN) + "{en_out & rdy_out}};")
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
