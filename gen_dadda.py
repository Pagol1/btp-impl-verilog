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

def wire_n(stage, idx):
    return "dm_int_st{}_{}".format(stage, idx)

def gen_dadda():
    global BIT_LEN
    global INDENT
    global MODULE_FILE_NAME
    global IO_PRE
    global INT_PRE
    
    dadda_stw = [2]
    while True:
        v = (dadda_stw[-1]*3) >> 1
        if v >= BIT_LEN:
            break
        dadda_stw.append(v)
    ## Have 2 at last
    dadda_stw.reverse()
    num_st = len(dadda_stw)

    op = ""
    op += pp("// IO Params")
    ADDR = IO_PRE + "ADDR"
    WIDTH = IO_PRE + "WIDTH"
    SIGN = IO_PRE + "SIGN"
    MAG = IO_PRE + "MAG"
    op += pp("`define " + ADDR[1:] + " {}:0".format(BIT_LEN-1))
    op += pp("`define " + WIDTH[1:] + " {}".format(BIT_LEN))
    op += pp("`define " + SIGN[1:] + " {}".format(BIT_LEN-1))
    op += pp("`define " + MAG[1:] + " {}:0".format(BIT_LEN-2))

    op += "\n"
    op += pp("module " + MODULE_FILE_NAME.split(".")[0] + "(")
    INDENT += 1
    op += pp("input clk,")
    op += pp("input [" + ADDR + "] in_a,\t\t// Sign-Mag")
    op += pp("input [" + ADDR + "] in_b,\t\t// Sign-Mag")
    op += pp("input in_carry")
    op += pp("output [" + ADDR + "] out_s")
    INDENT -= 1
    op += pp(");"); INDENT += 1
   
    ADDR_O = INT_PRE[1:] + "O_ADDR"
    WIDTH_O = INT_PRE[1:] + "O_WIDTH"
    MAG_O = INT_PRE[1:] + "O_MAG"
    op += pp("localparam " + ADDR_O + " {}:0;".format(2*BIT_LEN-1))
    op += pp("localparam " + WIDTH_O + " {};".format(2*BIT_LEN))
    op += pp("localparam " + MAG_O + " {}:{};".format(2*BIT_LEN-1, BIT_LEN))

    op += "\n"
    op += pp("wire neg_out;")
    op += pp("assign neg_out = in_a[{}] ^ in_b[{}];".format(SIGN, SIGN))
    
    ## DADDA STARTS HERE
    op += pp("wire [{}] a, b;".format(ADDR))
    op += pp("wire [{}] sum;".format(ADDR_O))

    op += pp("assign a[{}] = 1'b0;".format(SIGN)); op += pp("assign a[{}] = in_a[{}];".format(MAG, MAG))
    op += pp("assign b[{}] = 1'b0;".format(SIGN)); op += pp("assign b[{}] = in_b[{}];".format(MAG, MAG))
    ## compute bit distribution for each stage
    nop = ""
    bit_distr = [[0]*(2*BIT_LEN)]
    # Partial Products
    op += "\n"
    #for i in range(2*BIT_LEN-1):
    #    bit_distr[0][i] = min([i+1, (2*BIT_LEN-1-i)])
    #    op += pp("wire [{}:0] {};".format(bit_distr[0][i]-1, wire_n(0, i)))
    
    for i in range(BIT_LEN):
        for j in range(BIT_LEN):
            nop += pp("assign {}[{}] = a[{}] & b[{}];".format(wire_n(0, i+j), bit_distr[0][i+j], i, j))
            bit_distr[0][i+j] += 1

    for i in range(2*BIT_LEN-1):
        op += pp("wire [{}:0] {};".format(bit_distr[0][i]-1, wire_n(0, i)))
    op += "\n"; op += nop; nop = ""
    
    ## Reduction Stages
    num_fa = 0
    num_ha = 0
    # Change Logic here if CLA is to be used
    for stage in range(num_st):
        op += "\n"; op += pp("//// Stage {} ////".format(stage+1)); nop = ""
        bit_distr.append(bit_distr[-1].copy())
        target = dadda_stw[stage]
        carry_last = 0
        carry_gen = 0
        ls_idx = 0
        cs_idx = 0
        ### print("TARGET: ", target)
        for i in range(len(bit_distr[stage])-1):
            ### print(bit_distr[stage]) 
            cs_idx = carry_last
            carry_gen = 0
            ls_idx = 0
            nop += pp("// Bit " + str(i))
            while (bit_distr[stage+1][i] >= target + 2):
                bit_distr[stage+1][i] -= 2
                bit_distr[stage+1][i+1] += 1
                FA_A = "{}[{}]".format(wire_n(stage, i), ls_idx)
                FA_B = "{}[{}]".format(wire_n(stage, i), ls_idx+1)
                FA_C = "{}[{}]".format(wire_n(stage, i), ls_idx+2)
                ls_idx += 3
                FA_D = "{}[{}]".format(wire_n(stage+1, i), cs_idx)
                FA_E = "{}[{}]".format(wire_n(stage+1, i+1), carry_gen)
                cs_idx += 1
                carry_gen += 1
                nop += pp("full_adder FA{}(.a({}), .b({}), .cin({}), .s({}), .cout({}));".format(num_fa, FA_A, FA_B, FA_C, FA_D, FA_E))
                num_fa += 1
            if (bit_distr[stage+1][i] == target+1):
                bit_distr[stage+1][i] -= 1
                bit_distr[stage+1][i+1] += 1
                HA_A = "{}[{}]".format(wire_n(stage, i), ls_idx)
                HA_B = "{}[{}]".format(wire_n(stage, i), ls_idx+1)
                ls_idx += 2
                HA_D = "{}[{}]".format(wire_n(stage+1, i), cs_idx)
                HA_E = "{}[{}]".format(wire_n(stage+1, i+1), carry_gen)
                cs_idx += 1
                carry_gen += 1
                nop += pp("half_adder HA{}(.a({}), .b({}), .s({}), .cout({}));".format(num_ha, HA_A, HA_B, HA_D, HA_E))
                num_ha += 1
            # Safety Check
            ### print(bit_distr[stage+1])
            ### print("Debug: {}, {}, {}, {} || {} | {}".format(i, stage, ls_idx, cs_idx, bit_distr[stage][i], bit_distr[stage+1][i]) )
            assert(bit_distr[stage][i] - ls_idx == bit_distr[stage+1][i] - cs_idx)
            while (cs_idx != bit_distr[stage+1][i]):
                nop += pp("assign {}[{}] = {}[{}];".format(wire_n(stage+1, i), cs_idx, wire_n(stage, i), ls_idx))
                cs_idx += 1
                ls_idx += 1
            carry_last = carry_gen
        # end for
        for i in range(len(bit_distr[stage+1])-1):
            op += pp("wire [{}:0] {};".format(bit_distr[stage+1][i]-1, wire_n(stage+1, i)))
        op += "\n"
        op += nop
    # end for

    ## Now, we have the two reduced patterns
    op += "\n"; op += pp("// Adder Stage")
    op += pp("wire [{}] cla_in_a, cla_in_b, sum;".format(ADDR_O))
    op += pp("wire ovf;")
    for i in range(len(bit_distr[num_st])-1):
        op += pp("assign cla_in_a[{}] = {}[0];".format(i, wire_n(num_st, i)))
        if bit_distr[num_st][i] == 2:
            op += pp("assign cla_in_b[{}] = {}[1];".format(i, wire_n(num_st, i)))
        elif bit_distr[num_st][i] == 1:
            op += pp("assign cla_in_b[{}] = 1'b0;".format(i))
        else:
            assert(False)
    for i in range(len(bit_distr[num_st])-1, 2*BIT_LEN):
        op += pp("assign cla_in_a[{}] = 1'b0;".format(i))
        op += pp("assign cla_in_b[{}] = 1'b0;".format(i))

    op += pp("cla_{}bit CLA(clk, cla_in_a, cla_in_b, 1'b0, sum, ovf);".format(2*BIT_LEN))
    
    op += "\n"
    # out_s[MSB-1:] = sum[MSB-1:]
    op += pp("assign out_s[{}] = sum[{}];".format(MAG, MAG_O))
    op += pp("assign out_s[{}] = neg_out;".format(SIGN))
    op += "\n"
    INDENT -= 1
    op += pp("endmodule")
    return op

if __name__ == "__main__":
    INDENT = 0
    BIT_LEN = 32
    MODULE_FILE_NAME = "fxp32s_dadda_full.v"
    IO_PRE = "`FXP32_"
    INT_PRE = "`FXP32_DM_"
    op = gen_dadda()
    with open(MODULE_FILE_NAME, 'w') as f:
        f.write(op)
