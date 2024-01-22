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

# TODO: Optimize for no offset case
def get_offset(N, row, col, o_w, i_w):
    ### {_, 0, 0} + {_, 0} + _ + _'
    ret = ""
    mask = bin(N)[2:]; L = len(mask)
    for i, b in enumerate(mask):
        if (b == '1'):
            if (L-i == 1):
                ret += "{" + "1'b0, "*(o_w-i_w) + row + "} + "
            else:
                ret += "{" + "1'b0, "*(o_w-i_w-(L-i-1)) + row + ", 1'b0"*(L-i-1) + "} + "
    ret += "{" + "1'b0, "*(o_w-i_w) + col + "}"
    return ret

def get_zero(N):
    return f"{N}'b" + N*"0"

def gen_pe_array():
    '''
    ## PE Array Design:
    ### Idea: Perform C = A * B
    => Load A, B ==> Zero Pad and store in buffer
    => Distribute job across PEs
    ==> Wait till Job is complete
    => Load C
    ==> Mark C output valid
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
    op += pp("input en_in_data,")               # Hold data till ready
    op += pp("output rdy_in_data,")              # Data accepted
    op += pp("input in_mat,")                   # A == 0 | B == 1
    op += pp("input in_mat_done,")
    op += pp("input [" + BUS_W + "] in_data,")
    op += pp("// Output Stream")
    op += pp("output en_out_data,")
    op += pp("input rdy_out_data,")
    op += pp("output out_mat_done,")
    op += pp("output [" + BUS_W + "] out_data")
    INDENT -= 1
    op += pp(");"); INDENT += 1
    ## Module Start ##
    ### Load Data from Input Lines
    op += pp("// States //")
    op += pp("wire out_done;")
    op += pp("//// Input Data Loader ////")
    N_W = math.ceil(math.log2(N))
    BUF_DEP = 2*N
    BUF_DEP_W = math.ceil(math.log2(2*N))
    BASE_A = 0
    BASE_B = N
    #### Buffer ####
    op += pp("// Data Buffer //")
    op += pp(f"reg [{BIT_LEN-1}:0] buf_data [{N-1}:0][{BUF_DEP-1}:0];")
    op += pp(f"reg buf_valid [{N-1}:0][{BUF_DEP-1}:0];")
    op += pp("reg [{}:0] base_reg_A;".format( BUF_DEP_W-1 ))
    op += pp("reg [{}:0] base_reg_B;".format( BUF_DEP_W-1 ))
    op += pp("always @(posedge clk) begin // Fixed base registers")
    op += pp( "base_reg_A <= {}'b".format(BUF_DEP_W) + bin(BASE_A)[2:].zfill(BUF_DEP_W) + ";" )
    op += pp( "base_reg_B <= {}'b".format(BUF_DEP_W) + bin(BASE_B)[2:].zfill(BUF_DEP_W) + ";" )
    op += pp("end")
    ## Input Registers
    op += pp("// buffer ld decl")
    op += pp("reg [{}:0] in_row [1:0];".format( N_W-1 ))
    op += pp("reg in_row_c [1:0];".format( N_W-1 ))
    op += pp("wire in_row_end;")
    op += pp("wire out_mat_ready;")     # handshake with PE on a read to set all of these to zero ==> ANDed resp_ready
    op += pp("wire wr_en;")
    op += pp("wire zero_pad;")
    op += pp("reg zero_pad_d;")     # Use this to read zeros into memory
    op += pp("wire in_mat_empty;")
    op += pp("// buffer wr decl")
    op += pp("wire [{}:0] wr_addr [{}:0];".format( BUF_DEP_W-1, N-1 ))
    op += pp("wire [{}:0] wr_bank_addr [{}:0];".format( N_W-1, N-1 ))
    op += pp("wire wr_addr_c [{}:0];".format(N-1))
    op += pp("wire [{}:0] wr_data [{}:0];".format(BIT_LEN-1, N-1))
    op += pp("// buffer ld def")
    ## Load Control Logic
    ### Hold in_mat_done till NxN matrix is filled
    op += pp("assign in_row_end = (in_row[in_mat] == {}'b".format(N_W) + bin(N-1)[2:].zfill(N_W) + ");")
    ## NOTE:
    # Zero Pad should read the last element first and then be used
    # in_col and in_row are same cycle as well then
    vld_buf_list = [f" buf_valid[wr_bank_addr[{x}]][wr_addr[{x}]] " for x in range(N)]
    in_mat_empty = "~("
    for (idx, e) in enumerate(vld_buf_list):
        in_mat_empty += e 
        in_mat_empty += "|" if idx != len(vld_buf_list)-1 else ")"
    op += pp(f"assign in_mat_empty = {in_mat_empty};")
    op += pp("assign zero_pad = ( (in_mat_done & ~in_row_end) ) & in_mat_empty;")
    op += pp("assign rdy_in_data = en_in_data & ~zero_pad & in_mat_empty;")
    op += pp("assign wr_en = en_in_data & (rdy_in_data | zero_pad);")
    op += pp("always @(posedge clk) begin")
    op += pp( "{in_row_c[0], in_row[0]} <= ((wr_en & ~in_mat) ? ((in_row_end) ? " + get_zero(N_W+1) + " : in_row[0] + 1'b1) : {1'b0, in_row[0]}) & {"+f"{N_W+1}"+"{rstn}};" )
    op += pp( "{in_row_c[1], in_row[1]} <= ((wr_en & in_mat) ? ((in_row_end) ? " + get_zero(N_W+1) + " : in_row[1] + 1'b1) : {1'b0, in_row[1]}) & {"+f"{N_W+1}"+"{rstn}};" )
    op += pp( "zero_pad_d <= zero_pad & rstn;" )
    op += pp("end")
    ## Buffer Definitions WR i/p
    op += pp("// buffer wr def")
    op += pp("genvar i, j;")
    op += pp("generate")
    op += pp(f"for (i=0; i<{N}; i=i+1) begin : WR_ADDR_MAP")
    op += pp( "assign {wr_addr_c[i], wr_addr[i]} = in_mat ? (base_reg_B + in_row[1]) : (base_reg_A + i);" ) # Old: (base_reg_B + i) : (base_reg_A + in_row[0]);" )
    op += pp( "assign wr_bank_addr[i] = in_mat ? i : in_row[0];" )
    op += pp( "assign wr_data[i] = in_data[{0}*i+{1}:{0}*i]".format(BIT_LEN, BIT_LEN-1)+" & {"+f"{BIT_LEN}"+"{~zero_pad_d}};" )
    op += pp( "always @(posedge clk) begin" )
    op += pp(  "buf_data[wr_bank_addr[i]][wr_addr[i]] <= wr_en ? wr_data[i] : buf_data[wr_bank_addr[i]][wr_addr[i]];"  )
    ### NOTE: Simultaneous reading and scheduling is done ==> Need to make scheduler send out only 2N rows though
    op += pp( "end" )
    op += pp("end")
    op += pp("endgenerate")
    ### TODO: Add valid signal wala logic
    op += pp("generate")
    op += pp(f"for (i=0; i<{N}; i=i+1) begin : VALID_COL")
    # Matrix A
    op += pp(f"for (j=0; j<{N}; j=j+1) begin : VALID_ROW_A")
    op += pp( "always @(posedge clk) begin" )
    op += pp(f"buf_valid[i][j+{BASE_A}] <= rstn & ((sched_en & ~sched_tgt & (sched_row == j)) ? 1'b0 : ( (wr_en & ~in_mat & (in_row[0] == i)) ? 1'b1 : buf_valid[i][j+{BASE_A}] ) );")
    op += pp( "end" )
    op += pp("end")
    # Matrix B
    op += pp(f"for (j=0; j<{N}; j=j+1) begin : VALID_ROW_B")
    op += pp( "always @(posedge clk) begin" )
    op += pp(f"buf_valid[i][j+{BASE_B}] <= rstn & ((sched_en & sched_tgt & (sched_row == j)) ? 1'b0 : ( (wr_en & in_mat & (in_row[1] == j)) ? 1'b1 : buf_valid[i][j+{BASE_B}] ) );")
    op += pp( "end" )
    op += pp("end")
    op += pp("end")
    op += pp("endgenerate")
    #### Scheduler ####
    op += pp("//// Scheduler ////")
    op += pp(f"wire sched_valid [{BUF_DEP-1}:0];")
    op += pp("generate")
    op += pp(f"for (j=0; j<{BUF_DEP}; j=j+1) begin : SCHED_VALID_MAP_ROWS")
    sched_vld = "("
    for i in range(N):
        sched_vld += f" buf_valid[{i}][j] "
        sched_vld += "&" if (i != N-1) else ")"
    op += pp(f"assign sched_valid[j] = {sched_vld};")
    op += pp("end")
    op += pp("endgenerate") 
    op += pp("reg sched_start;")
    op += pp("wire sched_en;")
    op += pp("reg sched_tgt;")
    op += pp("reg sched_tgt_base;")
    op += pp("reg sched_done;")
    op += pp("reg [{}:0] sched_row;".format(N_W))
    op += pp("reg sched_row_c;")
    op += pp("wire last_row;")
    op += pp("assign last_row = (sched_row == {}'b".format(N_W) + bin(N-1)[2:].zfill(N_W) + ") & (sched_tgt ^ sched_tgt_base);")
    op += pp("assign sched_en = ~sched_done & sched_valid[(sched_tgt ? base_reg_B : base_reg_A) + sched_row] & ~out_mat_ready;")
    op += pp("always @(posedge clk) begin")
    op += pp("sched_start <= rstn & ~sched_done & (sched_en | sched_start);")
    # op += pp("sched_en <= rstn & ~sched_done & sched_valid[(sched_tgt ? base_reg_B : base_reg_A) + sched_row] & ~out_mat_ready;")
    op += pp("sched_tgt_base <= rstn & (sched_en | sched_start ? sched_tgt_base : ~sched_valid[base_reg_A] & sched_valid[base_reg_B]);")
    op += pp("sched_tgt <= rstn & (sched_en ? ~sched_tgt : (sched_start ? sched_tgt : ~sched_valid[base_reg_A] & sched_valid[base_reg_B]) );")
    op += pp("sched_done <= rstn & (sched_done ? ~out_row_end : last_row);")
    op += pp("{sched_row_c, sched_row} <= (sched_done ? " + get_zero(N_W+1) + " : (sched_en ? sched_row + (sched_tgt ^ sched_tgt_base) : sched_row)) & {"+f"{N_W+1}"+"{rstn}};") 
    op += pp("end")
    # A is row major | B is column major #
    ### PE NoC
    op += pp("wire [{}:0] noc_row_data [{}:0];".format(BIT_LEN-1, N-1))
    op += pp("wire [{}:0] noc_row_addr [{}:0];".format(BUF_DEP-1, N-1))
    op += pp("wire [{}:0] noc_row_c;".format(N-1))
    op += pp("wire [{}:0] noc_col_data [{}:0];".format(BIT_LEN-1, N-1))
    op += pp("wire [{}:0] noc_col_addr [{}:0];".format(BUF_DEP-1, N-1))
    op += pp("wire [{}:0] noc_col_c;".format(N-1))
    op += pp("wire [{}:0] noc_in_data [{}:0][{}:0];".format(BIT_LEN-1, N-1, N-1))
    op += pp("wire [{}:0] noc_out_data [{}:0][{}:0];".format(BIT_LEN-1, N-1, N-1))
    op += pp("wire noc_out_en [{}:0][{}:0];".format(N-1, N-1))
    op += pp("wire noc_out_rdy [{}:0][{}:0];".format(N-1, N-1))
    op += pp("generate")
    op += pp(f"for (i=0; i<{N}; i=i+1) begin : PE_ARRAY_ROW")
    op += pp("assign {noc_row_c[i], noc_row_addr[i]} = base_reg_A + sched_row;")
    op += pp("assign noc_row_data[i] = buf_data[i][noc_row_addr[i]];")
    op += pp("assign {noc_col_c[i], noc_col_addr[i]} = base_reg_B + sched_row;")
    op += pp("assign noc_col_data[i] = buf_data[i][noc_col_addr[i]];")
    op += pp( f"for (j=0; j<{N}; j=j+1) begin : PE_ARRAY_COL" )
    pe_mod_name = MODULE_FILE_NAME.split("pe")[0] + "pe"
    op += pp("assign noc_in_data[i][j] = sched_tgt ? noc_col_data[j] : noc_row_data[i];")
    op += pp(pe_mod_name + " PE(clk, rstn, sched_en, ~(sched_tgt ^ sched_tgt_base), noc_in_data[i][j], last_row, noc_out_en[i][j], noc_out_rdy[i][j], noc_out_data[i][j]);")
    op += pp( "end" )
    op += pp("end")
    op += pp("endgenerate")
    ## Read Module
    op += pp("//// Output Module ////")
    op += pp("reg [{}:0] out_row;".format( N_W-1 ))
    op += pp("reg out_row_c;")
    op += pp("wire out_en;")
    op += pp("wire out_row_end;")
    # op += pp("wire out_mat_ready;")
    op += pp("assign out_row_end = (out_row == {}'b".format(N_W) + bin(N-1)[2:].zfill(N_W) + ");");
    out_mat_rdy = "("
    for i in range(N):
        for j in range(N):
            out_mat_rdy += f" noc_out_en[{i}][{j}] "
            out_mat_rdy += ")" if ((i==N-1) and (j==N-1)) else "|"
    op += pp(f"assign out_mat_ready = {out_mat_rdy};")
    op += pp("assign en_out_data = out_mat_ready;")
    op += pp("assign out_mat_done = out_row_end;")
    op += pp("assign out_en = en_out_data & rdy_out_data;")
    op += pp("always @(posedge clk) begin")
    op += pp("{out_row_c, out_row} <= (out_row_end & out_en ? " + get_zero(N_W+1) + " : (out_mat_ready & out_en ? out_row + 1'b1 : {1'b0, out_row})) & {"+f"{N_W+1}"+"{rstn}};")
    op += pp("end")
    out_col_data = "("
    for j in range(N):
        out_col_data += f" noc_out_data[{j}][i] "
        out_col_data += ")" if (j==N-1) else "|"
    op += pp("generate")
    op += pp(f"for (i=0; i<{N}; i=i+1) begin : WR_DATA_MAP")
    op += pp( "assign out_data[{0}*i+{1}:{0}*i] = {2};".format(BIT_LEN, BIT_LEN-1, out_col_data) )
    op += pp(f"for (j=0; j<{N}; j=j+1) begin : WR_EN_MAP")
    op += pp("assign noc_out_rdy[i][j] = (out_row == i) && out_en;")
    op += pp("end")
    op += pp("end")
    op += pp("endgenerate")
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
    MODULE_FILE_NAME = "fxp{}s_pe_block.v".format(BIT_LEN)
    op = gen_pe_array()
    with open(MODULE_FILE_NAME, 'w') as f:
        f.write(op)

        ## RAM ==> Depth kinda high, might not be needed
    # op += pp(f"wire [{BIT_LEN-1}:0] ram_out;")
    # op += pp(f"reg [{RAM_WIDTH-1}:0] ram_wr_addr;")
    # op += pp(f"reg [{RAM_WIDTH-1}:0] ram_rd_addr;")
    # op += pp("wire ram_wr_en;")
    # op += pp("wire ram_rd_en;")
    # op += pp("")
    # op += pp("BRAM_SDP_MACRO #(")
    # INDENT += 1
    # op += pp(".BRAM_SIZE(\"{}\"),".format("18Kb" if (BIT_LEN < 36) else "36Kb")
    # op += pp(".DEVICE(\"VIRTEX6\"),")
    # op += pp(".WRITE_WIDTH({}),".format(BIT_LEN))
    # op += pp(".READ_WIDTH({}),".format(BIT_LEN))
    # op += pp(".DO_REG(0),")
    # op += pp(".INIT_FILE(\"NONE\"),")
    # op += pp(".SIM_COLLISION_CHECK(\"ALL\"),")
    # op += pp(f".SRVAL({BIT_LEN}'b" + BIT_LEN*"0" + "),")
    # op += pp(f".INIT({BIT_LEN}'b" + BIT_LEN*"0" + "),")
    # op += pp(".WRITE_MODE(\"READ_FIRST\"),")
    # INDENT -= 1
    # op += pp(") BRAM_SDP_MACRO_inst (")
    # op += pp(".DO(ram_out),")
    # op += pp(".DI(in_data),")
    # op += pp(".RDADDR(),")

