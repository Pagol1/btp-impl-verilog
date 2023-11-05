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

def wire_n_pipe(stage, idx, driver, stage_num, pipe_num=4):
    if stage != 0 and ((stage % 4) == 0 or stage == stage_num) and driver:
        return "dm_int_st{}_{}_tmp".format(stage, idx)  # suffixed wire
    else:
        return "dm_int_st{}_{}".format(stage, idx)      # normal wire

def gen_dadda():
    global BIT_LEN
    global INDENT
    global MODULE_FILE_NAME
    global IO_PRE
    global INT_PRE
    global LSB_POW
    global MSB_POW
    
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
    POW_DECL = IO_PRE + "LSB_POW"
    op += pp("`define " + ADDR[1:] + " {}:0".format(BIT_LEN-1))
    op += pp("`define " + WIDTH[1:] + " {}".format(BIT_LEN))
    op += pp("`define " + SIGN[1:] + " {}".format(BIT_LEN-1))
    op += pp("`define " + MAG[1:] + " {}:0".format(BIT_LEN-2))
    op += pp("`define " + POW_DECL[1:] + " {}".format(LSB_POW))

    op += "\n"
    op += pp("module " + MODULE_FILE_NAME.split(".")[0] + "(")
    INDENT += 1
    op += pp("input clk,")
    op += pp("input rstn,")
    op += pp("input [" + ADDR + "] in_a,\t\t// Sign-Mag")
    op += pp("input [" + ADDR + "] in_b,\t\t// Sign-Mag")
    op += pp("output [" + ADDR + "] out_s,")
    op += pp("output out_overflow")
    INDENT -= 1
    op += pp(");"); INDENT += 1
   
    ADDR_O = "{}:0".format(2*BIT_LEN-1)
    WIDTH_O = "{}".format(2*BIT_LEN)
    MAG_O = "{}:{}".format(2*BIT_LEN-1, BIT_LEN)
    # ADDR_O = INT_PRE[1:] + "O_ADDR"
    # WIDTH_O = INT_PRE[1:] + "O_WIDTH"
    # MAG_O = INT_PRE[1:] + "O_MAG"
    # op += pp("localparam " + ADDR_O + " {}:0;".format(2*BIT_LEN-1))
    # op += pp("localparam " + WIDTH_O + " {};".format(2*BIT_LEN))
    # op += pp("localparam " + MAG_O + " {}:{};".format(2*BIT_LEN-1, BIT_LEN))

    op += "\n"
    op += pp("wire neg_out;")
    op += pp("assign neg_out = in_a[{}] ^ in_b[{}];".format(SIGN, SIGN))
    
    ## DADDA STARTS HERE
    op += pp("wire [{}] a, b;".format(ADDR))

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

    op += pp("cla_{}bit CLA(clk, rstn, cla_in_a, cla_in_b, 1'b0, sum, ovf);".format(2*BIT_LEN))
    
    op += "\n"
    # out_s[MSB-1:] = sum[MSB-1:]
    ################### 
    ## [MSB_POW:LSB_POW] <= [MSB_POW64:LSB_POW64]
    ## 
    LSB_POW_L = 2*LSB_POW;
    BIT_LEN_L = 2*(BIT_LEN-1) + 1
    MSB_POW_L = LSB_POW_L + BIT_LEN_L;  # 1 bit is sign in the i/p => 2 bits 0 in MUL
    
    if (LSB_POW > MSB_POW_L):
        print("Guaranteed Underflow! Please change paramters")
        op += pp("assign out_s[{}] = ".format(MAG) + "{" + str(BIT_LEN-1) + "{1'b0}};")
        op += pp("assign out_overflow = 1'b0;")
    elif (MSB_POW > MSB_POW_L):
        #print("case b", MSB_POW, MSB_POW_L, MSB_POW-LSB_POW)
        dist = MSB_POW_L-LSB_POW
        op += pp("assign out_s[{}:0] = ".format(dist) + "sum[{}:{}];".format(BIT_LEN_L, BIT_LEN_L-dist))
        op += pp("assign out_s[{}:{}] = ".format(BIT_LEN-2, dist+1) + "{" + str(BIT_LEN-2-dist) + "{1'b0}};")
        op += pp("assign out_overflow = 1'b0;")
    elif (MSB_POW < LSB_POW_L):
        print("Guaranteed Overflow! Please change paramters")
        op += pp("assign out_s[{}] = ".format(MAG) + "{" + str(BIT_LEN-1) + "{1'b0}};")
        op += pp("assign out_overflow = 1'b1;")
    elif (LSB_POW < LSB_POW_L):
        #print("case d")
        dist = MSB_POW - LSB_POW_L
        op += pp("assign out_s[{}:{}] = ".format(BIT_LEN-2, BIT_LEN-2-dist) + "sum[{}:{}];".format(dist, 0))
        op += pp("assign out_s[{}:{}] = ".format(BIT_LEN-3-dist, 0) + "{" + str(BIT_LEN-dist-2) + "{1'b0}};")
        op += pp("assign out_overflow = sum[{}];".format(dist+1))
    else:
        #print("case e")
        dist = LSB_POW-LSB_POW_L
        if (dist+BIT_LEN-1 == BIT_LEN_L):
            op += pp("assign out_overflow = 1'b0;")
        else:
            op += pp("assign out_overflow = sum[{}];".format(dist+BIT_LEN-1))
        op += pp("assign out_s[{}] = sum[{}:{}] | ".format(MAG, dist+BIT_LEN-2, dist) + "{" + WIDTH + "-1{out_overflow}};")
    
    op += pp("assign out_s[{}] = neg_out;".format(SIGN))
    ## op += pp("assign out_s[{}] = sum[{}];".format(MAG, MAG_O))
    ## op += pp("assign out_s[{}] = neg_out;".format(SIGN))
    op += "\n"
    INDENT -= 1
    op += pp("endmodule")
    return op

def gen_dadda_pipe():
    global BIT_LEN
    global INDENT
    global MODULE_FILE_NAME
    global IO_PRE
    global INT_PRE
    global LSB_POW
    global MSB_POW
    
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
    POW_DECL = IO_PRE + "LSB_POW"
    op += pp("`define " + ADDR[1:] + " {}:0".format(BIT_LEN-1))
    op += pp("`define " + WIDTH[1:] + " {}".format(BIT_LEN))
    op += pp("`define " + SIGN[1:] + " {}".format(BIT_LEN-1))
    op += pp("`define " + MAG[1:] + " {}:0".format(BIT_LEN-2))
    op += pp("`define " + POW_DECL[1:] + " {}".format(LSB_POW))

    op += "\n"
    op += pp("module " + MODULE_FILE_NAME.split(".")[0] + "(")
    INDENT += 1
    op += pp("input clk,")
    op += pp("input rstn,")
    op += pp("input [" + ADDR + "] in_a,\t\t// Sign-Mag")
    op += pp("input [" + ADDR + "] in_b,\t\t// Sign-Mag")
    op += pp("output [" + ADDR + "] out_s,")
    op += pp("output out_overflow")
    INDENT -= 1
    op += pp(");"); INDENT += 1
   
    ADDR_O = "{}:0".format(2*BIT_LEN-1)
    WIDTH_O = "{}".format(2*BIT_LEN)
    MAG_O = "{}:{}".format(2*BIT_LEN-1, BIT_LEN)
    # ADDR_O = INT_PRE[1:] + "O_ADDR"
    # WIDTH_O = INT_PRE[1:] + "O_WIDTH"
    # MAG_O = INT_PRE[1:] + "O_MAG"
    # op += pp("localparam " + ADDR_O + " {}:0;".format(2*BIT_LEN-1))
    # op += pp("localparam " + WIDTH_O + " {};".format(2*BIT_LEN))
    # op += pp("localparam " + MAG_O + " {}:{};".format(2*BIT_LEN-1, BIT_LEN))

    op += "\n"
    op += pp("wire neg_out_st_0;")
    op += pp("assign neg_out_st_0 = in_a[{}] ^ in_b[{}];".format(SIGN, SIGN))
    
    ## DADDA STARTS HERE
    op += pp("wire [{}] a, b;".format(ADDR))

    op += pp("assign a[{}] = 1'b0;".format(SIGN)); op += pp("assign a[{}] = in_a[{}];".format(MAG, MAG))
    op += pp("assign b[{}] = 1'b0;".format(SIGN)); op += pp("assign b[{}] = in_b[{}];".format(MAG, MAG))
    ## compute bit distribution for each stage
    nop = ""
    bit_distr = [[0]*(2*BIT_LEN)]
    # Partial Products
    op += "\n"
    #for i in range(2*BIT_LEN-1):
    #    bit_distr[0][i] = min([i+1, (2*BIT_LEN-1-i)])
    #    op += pp("wire [{}:0] {};".format(bit_distr[0][i]-1, wire_n_pipe(0, i)))
    
    for i in range(BIT_LEN):
        for j in range(BIT_LEN):
            nop += pp("assign {}[{}] = a[{}] & b[{}];".format(wire_n_pipe(0, i+j, True, num_st), bit_distr[0][i+j], i, j))
            bit_distr[0][i+j] += 1

    for i in range(2*BIT_LEN-1):
        op += pp("wire [{}:0] {};".format(bit_distr[0][i]-1, wire_n_pipe(0, i, True, num_st)))
    op += "\n"; op += nop; nop = ""
    
    ## Reduction Stages
    num_fa = 0
    num_ha = 0
    # Change Logic here if CLA is to be used
    ## Pipelining every 4 stages and before the adder
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
                FA_A = "{}[{}]".format(wire_n_pipe(stage, i, False, num_st), ls_idx)
                FA_B = "{}[{}]".format(wire_n_pipe(stage, i, False, num_st), ls_idx+1)
                FA_C = "{}[{}]".format(wire_n_pipe(stage, i, False, num_st), ls_idx+2)
                ls_idx += 3
                FA_D = "{}[{}]".format(wire_n_pipe(stage+1, i, True, num_st), cs_idx)
                FA_E = "{}[{}]".format(wire_n_pipe(stage+1, i+1, True, num_st), carry_gen)
                cs_idx += 1
                carry_gen += 1
                nop += pp("full_adder FA{}(.a({}), .b({}), .cin({}), .s({}), .cout({}));".format(num_fa, FA_A, FA_B, FA_C, FA_D, FA_E))
                num_fa += 1
            if (bit_distr[stage+1][i] == target+1):
                bit_distr[stage+1][i] -= 1
                bit_distr[stage+1][i+1] += 1
                HA_A = "{}[{}]".format(wire_n_pipe(stage, i, False, num_st), ls_idx)
                HA_B = "{}[{}]".format(wire_n_pipe(stage, i, False, num_st), ls_idx+1)
                ls_idx += 2
                HA_D = "{}[{}]".format(wire_n_pipe(stage+1, i, True, num_st), cs_idx)
                HA_E = "{}[{}]".format(wire_n_pipe(stage+1, i+1, True, num_st), carry_gen)
                cs_idx += 1
                carry_gen += 1
                nop += pp("half_adder HA{}(.a({}), .b({}), .s({}), .cout({}));".format(num_ha, HA_A, HA_B, HA_D, HA_E))
                num_ha += 1
            # Safety Check
            ### print(bit_distr[stage+1])
            ### print("Debug: {}, {}, {}, {} || {} | {}".format(i, stage, ls_idx, cs_idx, bit_distr[stage][i], bit_distr[stage+1][i]) )
            assert(bit_distr[stage][i] - ls_idx == bit_distr[stage+1][i] - cs_idx)
            while (cs_idx != bit_distr[stage+1][i]):
                nop += pp("assign {}[{}] = {}[{}];".format(wire_n_pipe(stage+1, i, True, num_st), cs_idx, wire_n_pipe(stage, i, False, num_st), ls_idx))
                cs_idx += 1
                ls_idx += 1
            carry_last = carry_gen
        # end for
        for i in range(len(bit_distr[stage+1])-1):
            op += pp("wire [{}:0] {};".format(bit_distr[stage+1][i]-1, wire_n_pipe(stage+1, i, True, num_st)))
            if (stage+1) % 4 == 0 or (stage+1) == num_st:
                op += pp("reg [{}:0] {};".format(bit_distr[stage+1][i]-1, wire_n_pipe(stage+1, i, False, num_st)))
        if (stage+1) % 4 == 0 or (stage+1) == num_st:
            op += pp("reg neg_out_st_{};".format(stage+1))
        op += "\n"
        # Add pipeline if needed
        if (stage+1) % 4 == 0 or (stage+1) == num_st:
            op += pp("always @(posedge clk) begin")
            op += pp("neg_out_st_{} <= neg_out_st_{} & rstn;".format(stage+1, stage-3))
            for i in range(len(bit_distr[stage+1])-1):
                op += pp(
                            "{} <= {} & ".format(wire_n_pipe(stage+1, i, False, num_st), wire_n_pipe(stage+1, i, True, num_st)) 
                            + "{" + str(bit_distr[stage+1][i]) + "{rstn}};"
                        )
            op += pp("end")
        op += nop
    # end for

    ## Now, we have the two reduced patterns
    op += "\n"; op += pp("// Adder Stage")
    op += pp("wire [{}] cla_in_a, cla_in_b, sum;".format(ADDR_O))
    op += pp("wire ovf;")
    for i in range(len(bit_distr[num_st])-1):
        op += pp("assign cla_in_a[{}] = {}[0];".format(i, wire_n_pipe(num_st, i, False, num_st)))
        if bit_distr[num_st][i] == 2:
            op += pp("assign cla_in_b[{}] = {}[1];".format(i, wire_n_pipe(num_st, i, False, num_st)))
        elif bit_distr[num_st][i] == 1:
            op += pp("assign cla_in_b[{}] = 1'b0;".format(i))
        else:
            assert(False)
    for i in range(len(bit_distr[num_st])-1, 2*BIT_LEN):
        op += pp("assign cla_in_a[{}] = 1'b0;".format(i))
        op += pp("assign cla_in_b[{}] = 1'b0;".format(i))

    op += pp("cla_{}bit_pipe CLA(clk, rstn, cla_in_a, cla_in_b, 1'b0, sum, ovf);".format(2*BIT_LEN))

    ## Delay sign by 1 cycle
    op += "\n"
    op += pp("reg neg_out;")
    op += pp("always @(posedge clk) begin")
    op += pp("neg_out <= neg_out_st_{} & rstn;".format(num_st))
    op += pp("end")
    op += "\n"
    # out_s[MSB-1:] = sum[MSB-1:]
    ################### 
    ## [MSB_POW:LSB_POW] <= [MSB_POW64:LSB_POW64]
    ## 
    LSB_POW_L = 2*LSB_POW;
    BIT_LEN_L = 2*(BIT_LEN-1) + 1
    MSB_POW_L = LSB_POW_L + BIT_LEN_L;  # 1 bit is sign in the i/p => 2 bits 0 in MUL
    
    if (LSB_POW > MSB_POW_L):
        print("Guaranteed Underflow! Please change paramters")
        op += pp("assign out_s[{}] = ".format(MAG) + "{" + str(BIT_LEN-1) + "{1'b0}};")
        op += pp("assign out_overflow = 1'b0;")
    elif (MSB_POW > MSB_POW_L):
        #print("case b", MSB_POW, MSB_POW_L, MSB_POW-LSB_POW)
        dist = MSB_POW_L-LSB_POW
        op += pp("assign out_s[{}:0] = ".format(dist) + "sum[{}:{}];".format(BIT_LEN_L, BIT_LEN_L-dist))
        op += pp("assign out_s[{}:{}] = ".format(BIT_LEN-2, dist+1) + "{" + str(BIT_LEN-2-dist) + "{1'b0}};")
        op += pp("assign out_overflow = 1'b0;")
    elif (MSB_POW < LSB_POW_L):
        print("Guaranteed Overflow! Please change paramters")
        op += pp("assign out_s[{}] = ".format(MAG) + "{" + str(BIT_LEN-1) + "{1'b0}};")
        op += pp("assign out_overflow = 1'b1;")
    elif (LSB_POW < LSB_POW_L):
        #print("case d")
        dist = MSB_POW - LSB_POW_L
        op += pp("assign out_s[{}:{}] = ".format(BIT_LEN-2, BIT_LEN-2-dist) + "sum[{}:{}];".format(dist, 0))
        op += pp("assign out_s[{}:{}] = ".format(BIT_LEN-3-dist, 0) + "{" + str(BIT_LEN-dist-2) + "{1'b0}};")
        op += pp("assign out_overflow = sum[{}];".format(dist+1))
    else:
        #print("case e")
        dist = LSB_POW-LSB_POW_L
        if (dist+BIT_LEN-1 == BIT_LEN_L):
            op += pp("assign out_overflow = 1'b0;")
        else:
            op += pp("assign out_overflow = sum[{}];".format(dist+BIT_LEN-1))
        op += pp("assign out_s[{}] = sum[{}:{}] | ".format(MAG, dist+BIT_LEN-2, dist) + "{" + WIDTH + "-1{out_overflow}};")
    
    op += pp("assign out_s[{}] = neg_out;".format(SIGN))
    ## op += pp("assign out_s[{}] = sum[{}];".format(MAG, MAG_O))
    ## op += pp("assign out_s[{}] = neg_out;".format(SIGN))
    op += "\n"
    INDENT -= 1
    op += pp("endmodule")
    return op


if __name__ == "__main__":
    INDENT = 0
    ###
    BIT_LEN = 32
    MODULE_FILE_NAME = "fxp32s_dadda.v"
    ## Pipeline
    MODULE_FILE_NAME = "fxp32s_dadda_pipe.v"
    IO_PRE = "`FXP32S_"
    INT_PRE = "`FXP32S_DM_"
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

    # op = gen_dadda()
    op = gen_dadda_pipe()
    with open(MODULE_FILE_NAME, 'w') as f:
        f.write(op)
