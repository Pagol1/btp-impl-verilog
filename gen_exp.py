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

def get_zero(N):
    return f"{N}'b" + N*"0"

def get_bin(W, N):
    return "{}'b".format(W) + bin(N)[2:].zfill(W) 

def get_ffrac_bin(W, N):
    f = N - int(N)
    return "{}'b".format(W) + bin(int(f * (2**W)))[2:].zfill(W)

def get_mc(N, sig):
    return "{" + str(N) + "{" + sig + "}}"

def wire_st(i):
    return f"st{i}"

def gen_exp():
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
    op += pp("input en_in_data,")
    op += pp("output rdy_in_data,")
    op += pp("input [" + ADDR + "] in_data,")
    op += pp("// Output Stream")
    op += pp("output en_out_data,")
    op += pp("input rdy_out_data,")
    op += pp("output [" + ADDR + "] out_data")
    INDENT -= 1
    op += pp(");"); INDENT += 1
    ## Module Start ##
    CNTR_W = 3 # MAX Seq Width
    CNTR_MAX = 6
    BIT_S = 9 # Bit Width of the smaller compute
    POW_ZERO = -LSB_POW
    ## Guard Bits
    BIT_G = 0
    BIT_G_X = BIT_G # Guard Bits for X
    BIT_G_Y = ((CNTR_MAX+1)*8 + LSB_POW) + BIT_G # Guard Bits for Y
    ## << Params Over << ##
    op += pp("wire wr_en;")
    op += pp("assign wr_en = en_in_data & rdy_in_data;")
    # TODO: Assign wip == Work in Progress (fr)
    op += pp("wire wip;")
    op += pp("reg en_cntr;")
    op += pp("wire clr_cntr;")
    op += pp(f"reg [{CNTR_W-1}:0] cntr;")
    op += pp("reg cntr_c;")
    op += pp(f"wire [{BIT_LEN-1}:0] in_x;")
    op += pp("assign in_x = (in_data ^ " + get_mc(BIT_LEN, f"in_data[{BIT_LEN-1}]")
            + f") + in_data[{BIT_LEN-1}];")
    op += pp("reg x_sign;")
    op += pp(f"reg [{BIT_LEN-1-POW_ZERO}:0] x_int;")
    op += pp(f"wire [{POW_ZERO-1}:0] x_frac;")
    # Initial Fork and CORDIC Counter
    op += pp("assign rdy_in_data = en_in_data & ~wip;")
    op += pp("always @(posedge clk) begin")
    op += pp("en_cntr <= rstn & ~clr_cntr & (en_cntr | wr_en);")
    op += pp("{cntr_c, cntr} <= (cntr + en_cntr) & "+ get_mc(CNTR_W+1, "rstn & ~clr_cntr")+";")
    op += pp(f"x_sign <= rstn & (wr_en ? in_data[{BIT_LEN-1}] : x_sign);")
    op += pp(f"x_int <= (wr_en ? in_x[{BIT_LEN-1}:{POW_ZERO}] : x_int) & " +
            get_mc(BIT_LEN-POW_ZERO, "rstn") + ";")
    op += pp("end")
    op += pp("assign x_frac = in_x[{POW_ZERO-1}:0];")
    op += pp("assign clr_cntr = (cntr == " + get_bin(CNTR_W, CNTR_MAX) + ");")
    ## CORDIC Stages
    BL_X = BIT_LEN + BIT_G_X
    BL_Y = BIT_LEN + BIT_G_Y
    op += pp(f"reg [{BL_X-1}:0] x;")
    op += pp(f"reg [{BL_Y-1}:0] y;")
    op += pp(f"wire [{BL_X-1}:0] x_nxt;")
    op += pp(f"wire [{BL_Y-1}:0] y_nxt;")
    op += pp("always @(posedge clk) begin")
    op += pp(
            "x <= (wr_en ? {" + "x_frac, " + get_zero(BIT_LEN-POW_ZERO) +
            (get_zero(BIT_G_X) if BIT_G_X>0 else "") + 
            "} : (en_cntr ? x_nxt : x)) & " + get_mc(BL_X, "rstn") + ";"
        )
    op += pp("y <= (wr_en ? {" + get_zero(BIT_LEN-POW_ZERO) + ", 1'b1, " + 
            get_zero(BL_Y - (BIT_LEN-POW_ZERO+1)) + 
            "} : (en_cntr ? y_nxt : y)) & " + get_mc(BL_Y, "rstn") + ";")
    op += pp("end")
    op += pp("// CORDIC Stages //")
    op += pp("//// ROM blocks ////")
    x_last = ""
    for i in range(8):
        # TODO: Make this work
        op += pp(f"reg [{BL_X-1}:0][{CNTR_MAX-1}:0] log_rom{i};")
        op += pp("always @(posedge clk) begin")
        for j in range(CNTR_MAX):
            upd = False
            x = get_ffrac_bin(BL_X, math.log2( 1+math.pow(2, -(8*j+i+1))) )
            if math.log2( 1+math.pow(2, -(8*j+i+1))) == 0:
                sp = x_last[:-1].split('b')
                x = sp[0] + "b0" + sp[1]
            op += pp(f"log_rom{i}[{j}] <= " + x + ";" + (" // Div2" if upd else ""))
            if (j == CNTR_MAX-1):
                x_last = x
        op += pp("end")
    op += pp("genvar i;")
    for i in range(7):
        # Low precision compute
        op += pp(f"//// Stage {i} ////")
        op += pp("// Master : X_Short")
        id_l = BIT_S - (i==0)
        wms = wire_st(i) + "_ms"
        op += pp(f"wire {wire_st(i)}_s;")
        op += pp(f"wire {wms}_sn;")
        op += pp(f"wire [{BIT_S-(i==0)}:0] {wms}_n;")
        op += pp(f"wire [{BIT_S-(i==0)}:0] {wms}_d;")
        op += pp(f"wire [{BIT_S-(i==0)}:0] {wms}_b;")
        op += pp(f"wire [{BIT_S-(i==0)}:0] {wms}_q;")
        op += pp(f"wire [{BIT_S-(i==0)}:0] {wms}_s;")
        #op += pp(f"wire [{BIT_S-(i==0)}:0] {wms}_bo;")
        # op += pp(f"wire [{BIT_S-(i==0)}:0] {wms}_qo;")
        n_id = BL_X-BIT_S-i
        if i == 0:
            op += pp(f"assign {wms}_n = x[{BL_X-1}-8*cntr:{n_id}-8*cntr];")
        else:
            wms_ = wire_st(i-1) + "_ms"
            op += pp(f"assign {wms}_n[{BIT_S}:1] = {wms_}_s[{BIT_S-1}:0];")
            op += pp(f"assign {wms}_n[0] = x[{n_id}-8*cntr];")
        if i == 0:
            op += pp(f"assign {wms}_d = log_rom{i}[cntr][{BL_X-1}-8*cntr:{BL_X-BIT_S}-8*cntr];")
        else:
            op += pp(f"assign {wms}_d[{BIT_S}] = 1'b0;")
            op += pp(f"assign {wms}_d[{BIT_S-1}:0] = log_rom{i}[cntr][{BL_X-1-i}-8*cntr:{BL_X-BIT_S-i}-8*cntr];")
        ## Drive n and d
        op += pp(f"restoring_subtractor RS_{i}_0({wms}_n[0], {wms}_d[0], 1'b0, {wms}_q[1], {wms}_s[0], {wms}_b[0], {wms}_q[0]);")
        op += pp("generate")
        op += pp(f"for (i=1; i<{BIT_S-(i==0)}; i=i+1) begin")
        op += pp(f"restoring_subtractor RS_{i}_i({wms}_n[i], {wms}_d[i], {wms}_b[i-1], {wms}_q[i+1], {wms}_s[i], {wms}_b[i], {wms}_q[i]);")
        op += pp("end")
        op += pp("endgenerate")
        idx = BIT_S-(i==0)
        op += pp(f"restoring_subtractor RS_{i}_{idx}({wms}_n[{idx}], {wms}_d[{idx}], {wms}_sn, {wire_st(i)}_s, {wms}_s[{idx}], {wms}_b[{idx}], {wms}_q[{idx}]);")
        op += pp(f"assign {wire_st(i)}_s = ~{wms}_sn;")
        # High Precision Calc
        op += pp("// Slave : X_Long")
        wsx = wire_st(i) + "_sx"
        wsx_ = wire_st(i-1) + "_sx"
        op += pp(f"wire [{BL_X-1}:0] {wsx}_d;")
        op += pp(f"wire [{BL_X-1}:0] {wsx}_s;")
        op += pp(f"wire [{BL_X-1}:0] {wsx}_bo;")
        if i != 0:
            op += pp(f"wire [{BL_X-1}:0] {wsx}_bi;")
            op += pp(f"assign {wsx}_bi[0] = 1'b0;")
            op += pp(f"assign {wsx}_bi[{BL_X-1}:1] = {wsx_}_bo[{BL_X-2}:0];")
        op += pp("assign {wsx}_d = log_rom{i}[cntr];")
        op += pp("generate")
        op += pp(f"for (i=0; i<{BL_X}; i=i+1) begin")
        if i == 0:
            op += pp(f"full_subtractor FS_{i}_sx(x[i], {wsx}_d[i] & {wire_st(i)}_s, 1'b0, {wsx}_s[i], {wsx}_bo[i]);")
        else:
            op += pp(f"full_subtractor FS_{i}_sx({wsx_}_s[i], {wsx}_d[i] & {wire_st(i)}_s, {wsx}_bi[i], {wsx}_s[i], {wsx}_bo[i]);")
        op += pp("end")
        op += pp("endgenerate")
        # Need CCSA
        op += pp("// Slave : Y_Long")
        wsy = wire_st(i) + "_sy"
        wsy_ = wire_st(i-1) + "_sy"
        # Input
        op += pp(f"wire [{BL_Y-1}:0] {wsy}_a;")
        op += pp(f"wire [{BL_Y-1}:0] {wsy}_a_;")
        # Output
        op += pp(f"wire [{BL_Y-1}:0] {wsy}_s;")
        op += pp(f"wire [{BL_Y-1}:0] {wsy}_s_;")
        id_y = BL_Y-2-i
        if i != 0:
            # Last stage carry
            op += pp(f"wire [{BL_Y-1}:0] {wsy}_b;")
            op += pp(f"wire [{BL_Y-1}:0] {wsy}_b_;")
            # Temp storage
            op += pp(f"wire [{BL_Y-1}:0] {wsy}_t;")
            op += pp(f"wire [{BL_Y-1}:0] {wsy}_t_;")
            op += pp(f"assign {wsy}_a = {wsy_}_s;")
            op += pp(f"assign {wsy}_b =" + "{"+ f"{wsy_}_s_[{BL_Y-2}:0]" +", 0"+"};")
            op += pp(f"assign {wsy}_b_[{id_y}-8*cntr:0] = {wsy}_b[{BL_Y-1}:{i+1}+8*cntr];")
            op += pp(f"assign {wsy}_b_[{BL_Y-1}:{id_y+1}-8*cntr] = 0;")
        else:
            op += pp(f"assign {wsy}_a = y;")
        op += pp(f"assign {wsy}_a_[{id_y}-8*cntr:0] = {wsy}_a[{BL_Y-1}:{i+1}+8*cntr];")
        op += pp(f"assign {wsy}_a_[{BL_Y-1}:{id_y+1}-8*cntr] = 0;")
        op += pp("generate")
        op += pp(f"for (i=0; i<{BL_Y}; i=i+1) begin")
        if i == 0:
            op += pp(f"full_adder FA_{i}_sy({wsy}_a[i], {wsy}_a_[i] & {wire_st(i)}_s, 1'b0, {wsy}_s[i], {wsy}_s_[i]);")
        else:
            op += pp(f"full_adder FA_{i}_sy({wsy}_a[i], {wsy}_a_[i] & {wire_st(i)}_s, {wsy}_b[i], {wsy}_t[i], {wsy}_t_[i]);")
            op += pp(f"full_adder FA_{i}_sy({wsy}_t[i], {wsy}_b_[i] & {wire_st(i)}_s, {wsy}_t_[i], {wsy}_s[i], {wsy}_s_[i]);")
        op += pp("end")
        op += pp("endgenerate")
    ### High precision stage @ last
    ## Comp x_nxt
    wsxl = wire_st(6) + "_sx"
    op += pp("wire st7_s;")
    op += pp(f"wire [{BL_X-1}:0] st7_x;")
    op += pp(f"wire [{BL_X-1}:0] st7_cd;")
    op += pp("assign s7_cd[0] = 1'b0;")
    op += pp(f"assign s7_cd[{BL_X-1}:1] = {wsxl}_bo[{BL_X-2}:0];")
    op += pp(f"wire [{BL_X}:0] st7_cb;")
    op += pp("assign st7_cb[0] = 1'b0;")
    # Prop first
    op += pp("generate")
    op += pp(f"for (i=0; i<{BL_X}; i=i+1) begin")
    op += pp(f"full_subtractor BPS_1({wsxl}_s[i], st7_cd[i], st7_cb[i], st7_x[i], st7_cb[i+1]);")
    op += pp("end")
    op += pp("endgenerate")
    # Subtract final
    op += pp(f"wire [{BL_X-1}:0] st7_d;")
    op += pp(f"wire [{BL_X}:0] st7_b;")
    op += pp("assign st7_b[0] = 1'b0;")
    op += pp(f"assign st7_d = log_rom7[cntr];")
    op += pp("generate")
    op += pp(f"for (i=0; i<{BL_X}; i=i+1) begin")
    op += pp(f"full_subtractor BPS_2(st7_x[i], st7_d[i], st7_b[i], x_nxt[i], st7_b[i+1]);")
    op += pp("end")
    op += pp("endgenerate")
    op += pp(f"assign st7_s = ~st7_b[{BL_X}];")
    ## Comp y_nxt
    wsy_ = wire_st(6) + "_sy"
    wsy = wire_st(7) + "_sy"
    # Input
    op += pp(f"wire [{BL_Y-1}:0] {wsy}_a;")
    op += pp(f"wire [{BL_Y-1}:0] {wsy}_a_;")
    # Output
    op += pp(f"wire [{BL_Y-1}:0] {wsy}_s;")
    op += pp(f"wire [{BL_Y-1}:0] {wsy}_s_;")
    id_y = BL_Y-9
    # Last stage carry
    op += pp(f"wire [{BL_Y-1}:0] {wsy}_b;")
    op += pp(f"wire [{BL_Y-1}:0] {wsy}_b_;")
    # Temp storage
    op += pp(f"wire [{BL_Y-1}:0] {wsy}_t;")
    op += pp(f"wire [{BL_Y-1}:0] {wsy}_t_;")
    op += pp(f"assign {wsy}_a = {wsy_}_s;")
    op += pp(f"assign {wsy}_b =" + "{"+ f"{wsy_}_s_[{BL_Y-2}:0]" +", 0"+"};")
    op += pp(f"assign {wsy}_b_[{id_y}-8*cntr:0] = {wsy}_b[{BL_Y-1}:{i+1}+8*cntr];")
    op += pp(f"assign {wsy}_b_[{BL_Y-1}:{id_y+1}-8*cntr] = 0;")
    op += pp(f"assign {wsy}_a_[{id_y}-8*cntr:0] = {wsy}_a[{BL_Y-1}:{i+1}+8*cntr];")
    op += pp(f"assign {wsy}_a_[{BL_Y-1}:{id_y+1}-8*cntr] = 0;")
    op += pp("generate")
    op += pp(f"for (i=0; i<{BL_Y}; i=i+1) begin")
    op += pp(f"full_adder FA_{i}_sy({wsy}_a[i], {wsy}_a_[i] & st7_s, {wsy}_b[i], {wsy}_t[i], {wsy}_t_[i]);")
    op += pp(f"full_adder FA_{i}_sy({wsy}_t[i], {wsy}_b_[i] & st7_s, {wsy}_t_[i], {wsy}_s[i], {wsy}_s_[i]);")
    op += pp("end")
    op += pp("endgenerate")
    # CPA Stage
    op += pp(f"wire [{BL_Y-1}:0] st7_yc;")
    op += pp(f"assign st7_yc[0] = 1'b0;")
    op += pp(f"assign y_nxt[0] = {wsy}_s[0];")
    op += pp("generate")
    op += pp(f"for (i=1; i<{BL_Y}; i=i+1) begin")
    op += pp(f"full_adder CPA_2({wsy}_s[i], {wsy}_s_[i], st7_yc[i], y_nxt[i], st7_yc[i+1]);")
    op += pp("end")
    op += pp("endgenerate")
    op += pp("// CORDIC Stages //")
    op += pp(f"wire [{BIT_LEN-1}:0] shft_abs;")
    op += pp(f"wire [{BIT_LEN-1}:0] shft_qty;")
    op += pp(f"wire [{BIT_LEN-1}:0] shft_y;")
    op += pp("assign shft_abs = {" + get_mc(POW_ZERO, "1'b0") + ", x_int};")
    op += pp("assign shft_qty = (shft_abs ^ " + get_mc(BIT_LEN, "x_sign") + ") + x_sign;")
    op += pp(f"fxp{BIT_LEN}s_var_shifter SHFT_OUT(clk, rstn, y[{BL_Y-1}:{BL_Y-BIT_LEN}], shft_qty, shft_y);")
    op += pp("reg [{BIT_LEN-1}:0] out_y;")
    op += pp("wire rd_en;")
    op += pp("reg en_shift;")
    op += pp("reg en_out;")
    op += pp("assign rd_en = en_out_data & rdy_out_data;")
    op += pp("assign en_out_data = out_en;")
    op += pp("always @(posedge clk) begin")
    op += pp("en_shift <= clr_cntr & rstn;")
    op += pp("en_out <= rstn & ~rd_en & (en_out | en_shift);")
    op += pp("out_y <= (en_shift ? shft_y : out_y) & " + get_mc(BIT_LEN, "rstn") + ";" ) 
    op += pp("end")
    op += pp("assign wip = en_cntr | en_shift | en_out;")
    op += pp("assign out_data = out_y;")
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
    MODULE_FILE_NAME = "fxp{}s_exp.v".format(BIT_LEN)
    op = gen_exp()
    with open(MODULE_FILE_NAME, 'w') as f:
        f.write(op)
