#####
# Verilog Code Generator
#####

## TODO
## Define global input_done, comp_done, tf_done states
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

def get_offset(N, row, col, o_w, i_w):
    ### {_, 0, 0} + {_, 0} + _ + _'
    ret = ""
    mask = bin(N)[2:]; L = len(mask)
    for i, b in enumerate(mask):
        if (b == '1'):
            if (L-i == 1):
                ret += "{" + "0, "*(o_w-i_w) + row + "} + "
            else:
                ret += "{" + "0, "*(o_w-i_w-(L-i-1)) + row + ", 0"*(L-i-1) + "} + "
    ret += "{" + "0, "*(o_w-i_w) + col + "}"
    return ret


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
    op += pp("input en_in_data,")               # Hold data till ready
    op += pp("input rdy_in_data,")              # Data accepted
    op += pp("input in_mat,")                   # A == 0 | B == 1
    op += pp("input in_new_row,")
    op += pp("input in_mat_done,")
    op += pp("input [" + ADDR + "] in_data,")
    op += pp("// Output Stream")
    op += pp("output en_out_data,")
    op += pp("input rdy_out_data,")
    op += pp("output out_mat,")
    op += pp("output out_new_row,")
    op += pp("output [" + ADDR + "] out_data,")
    INDENT -= 1
    op += pp(");"); INDENT += 1
    ## Module Start ##
    ### Load Data from Input Lines
    op += pp("// States //")
    op += pp("wire input_done;")
    op += pp("//// Input Data Loader ////")
    N_W = math.ceil(math.log2(N))
    BUF_DEP = math.ceil(math.log2(2*N*N))
    BASE_A = 0
    BASE_B = N*N
    op += pp("reg [{}:0] in_col;".format( N_W-1 ))
    op += pp("wire in_col_c;".format( N_W-1 ))
    op += pp("reg [{}:0] in_row;".format( N_W-1 ))
    op += pp("wire in_row_c;".format( N_W-1 ))
    op += pp("wire in_row_end;")
    op += pp("wire in_col_end;")
    op += pp("reg [1:0] in_mat_loaded;")
    op += pp("wire wr_en;")
    op += pp("wire zero_pad;")
    op += pp("reg zero_pad_d;")     # Use this to read zeros into memory
    op += pp("wire in_mat_empty;")
    ## Load Control Logic
    ### Hold in_mat_done till NxN matrix is filled
    op += pp("assign in_row_end = (in_row == {}'b".format(N_W) + bin(N-1)[2:].zfill(N_W) + "));");
    op += pp("assign in_col_end = (in_col == {}'b".format(N_W) + bin(N-1)[2:].zfill(N_W) + "));");
    op += pp("assign in_mat_empty = (in_mat) ? ~in_mat_loaded[1] : ~in_mat_loaded[0];")
    ## NOTE:
    # Zero Pad should read the last element first and then be used
    # in_col and in_row are same cycle as well then
    op += pp("assign zero_pad = (in_col != {}'b".format(N_W) + bin(N-1)[2:].zfill(N_W) + ") & (in_new_row | ((in_row != {}'b".format(N_W) + bin(N-1)[2:].zfill(N_W) + ") & in_mat_done));")
    op += pp("assign rdy_in_data = en_in_data & ~zero_pad & in_mat_empty;")
    op += pp("assign wr_en = en_in_data & (rdy_in_data | zero_pad);")
    op += pp("always @(posedge clk) begin")
    op += pp( "{in_col_c, in_col} <= (en_in_data ? ((in_col_end) ? 0 : in_col + 1'b1) : {0, in_col}) & {"+f"{BUF_DEP+1}"+"{rstn}};" )
    op += pp( "{in_row_c, in_row} <= (en_in_data ? ((in_row_end) ? 0 : in_row + 1'b1) : {0, in_row}) & {"+f"{BUF_DEP+1}"+"{rstn}};" )
    op += pp( "zero_pad_d <= zero_pad & rstn;" )
    # TODO: Add refresh on output
    op += pp( "in_mat_loaded[1] <= rstn & (in_mat_loaded[1] | (in_col_end & in_row_end & in_mat));")
    op += pp( "in_mat_loaded[0] <= rstn & (in_mat_loaded[0] | (in_col_end & in_row_end & ~in_mat));")
    op += pp("end")
    #### Buffer ####
    op += pp("// Data Buffer //")
    op += pp(f"reg [{BIT_LEN-1}:0] data [{BUF_DEP-1}:0];")
    op += pp("reg [{}:0] base_reg_A;".format( BUF_DEP-1 ))
    op += pp("reg [{}:0] base_reg_B;".format( BUF_DEP-1 ))
    op += pp("always @(posedge clk) begin // Fixed base registers")
    op += pp( "base_reg_A <= {}'b".format(BUF_DEP) + bin(BASE_A)[2:].zfill(BUF_DEP) + ";" )
    op += pp( "base_reg_B <= {}'b".format(BUF_DEP) + bin(BASE_B)[2:].zfill(BUF_DEP) + ";" )
    op += pp("end")
    op += pp("wire [{}:0] wr_base_addr;".format( BUF_DEP-1 ))
    op += pp("wire [{}:0] wr_offset;".format( BUF_DEP-1 ))
    op += pp("wire [{}:0] wr_tgt_addr;".format( BUF_DEP-1 ))
    op += pp("wire wr_addr_c;")
    op += pp("wire [{}:0] wr_data;".format(BIT_LEN-1))
    ## Buffer Definitions WR
    op += pp("assign wr_data = zero_pad_d ? 0 : in_data;")
    op += pp("assign wr_base_addr = in_mat ? base_reg_A : base_reg_B;")
    off_str = "in_mat ? (" + get_offset(N, "in_row", "in_col", BUF_DEP, N_W) + ") : (" + get_offset(N, "in_col", "in_row", BUF_DEP, N_W) + ")" 
    op += pp("assign wr_offset = " + off_str + ";" )
    op += pp("assign {wr_addr_c, wr_tgt_addr} = wr_base_addr + wr_offset;")
    op += pp("always @(posedge clk) begin")
    op += pp("data[wr_tgt_addr] <= (wr_en ? wr_data : data[wr_tgt_addr]) & {"+f"{BIT_LEN}"+"{rstn}};")
    op += pp("end")
    #### Scheduler ####
    op += pp("//// Scheduler ////")
    op += pp("assign input_done = in_mat_loaded[1] & in_mat_loaded[0];")
    op += pp("wire rd_mat_done;")
    op += pp("reg sched_col;")
    op += pp("reg sched_done;")
    op += pp("reg [{}:0] rd_offset;".format(BUF_DEP-1))
    op += pp("wire [{}:0] rd_tgt_addr;".format(BUF_DEP-1))
    op += pp("wire rd_off_c;")
    # ROW_DONE ==> Switch next cycle
    op += pp("assign rd_mat_done = (rd_offset == {}'b".format(BUF_DEP) + bin(N*N-N)[2:].zfill(BUF_DEP) + ");")
    op += pp("assign rd_tgt_addr = sched_col ? base_reg_A : base_reg_B;")
    op += pp("always @(posedge clk) begin")
    op += pp( "sched_col <= rstn & (rd_mat_done & input_done | sched_col);" )
    op += pp( "{rd_off_c, rd_offset} <= (sched_done ? {0, rd_offset} : rd_offset" + " + {}'b".format(BUF_DEP) + bin(N)[2:].zfill(BUF_DEP) + ") & {"+f"{BUF_DEP+1}"+"{rstn}};" )
    op += pp( "sched_done <= rd_mat_done & sched_col & rstn;" )
    op += pp("end")
    # A is row major | B is column major #
    ### PE NoC
    op += pp("wire [{}:0] noc_row_data [{}:0];".format(BIT_LEN-1, N_W-1))
    op += pp("wire [{}:0] noc_row_addr [{}:0];".format(BUF_DEP-1, N_W-1))
    op += pp("wire [{}:0] noc_row_c;".format(N_W-1))
    op += pp("wire [{}:0] noc_col_data [{}:0];".format(BIT_LEN-1, N_W-1))
    op += pp("wire [{}:0] noc_col_addr [{}:0];".format(BUF_DEP-1, N_W-1))
    op += pp("wire [{}:0] noc_col_c;".format(N_W-1))
    op += pp("wire [{}:0] noc_in_data [{}:0][{}:0];".format(BIT_LEN-1, N_W-1, N_W-1))
    op += pp("wire [{}:0] noc_out_data [{}:0][{}:0];".format(BIT_LEN-1, N_W-1, N_W-1))
    op += pp("wire noc_out_en [{}:0][{}:0];".format(N_W-1, N_W-1))
    op += pp("genvar i, j;")
    op += pp("generate")
    op += pp(f"for (i=0; i<{N}; i=i+1) begin : PE_ARRAY_ROW")
    op += pp("assign {noc_row_c[i], noc_row_addr[i]} = rd_offset + i;")
    op += pp("assign noc_row_data[i] = data[noc_row_addr[i]];")
    op += pp("assign {noc_col_c[i], noc_col_addr[i]} = rd_offset + i;")
    op += pp("assign noc_col_data[i] = data[noc_col_addr[i]];")
    op += pp( f"for (j=0; j<{N}; j=j+1) begin : PE_ARRAY_COL" )
    pe_mod_name = MODULE_FILE_NAME.split("pe")[0] + "pe"
    op += pp("assign noc_in_data[i][j] = sched_col ? noc_col_data[j] : noc_row_data[i];")
    op += pp(pe_mod_name + " PE(clk, rstn, sched_col, ~sched_done & input_done, noc_in_data[i][j], noc_out_en[i][j], noc_out_data[i][j]);")
    op += pp( "end" )
    op += pp("end")
    op += pp("endgenerate")
    ## Read Module
    op += pp("//// Output Module ////")
    op += pp("reg [{}:0] out_col;".format( N_W-1 ))
    op += pp("wire out_col_c;".format( N_W-1 ))
    op += pp("reg [{}:0] out_row;".format( N_W-1 ))
    op += pp("wire out_row_c;".format( N_W-1 ))
    op += pp("wire out_row_end;")
    op += pp("wire out_col_end;")
    op += pp("reg out_ready;")
    op += pp("reg out_done;")
    op += pp("wire out_rd_data;")
    op += pp("assign en_out_data = out_ready;")
    op += pp("assign out_row_end = (out_row == {}'b".format(N_W) + bin(N-1)[2:].zfill(N_W) + "));");
    op += pp("assign out_col_end = (out_col == {}'b".format(N_W) + bin(N-1)[2:].zfill(N_W) + "));");
    op += pp("assign out_rd_data = en_out_data & rdy_out_data & ~out_done;")
    op += pp("always @(posedge clk) begin")
    op += pp("out_ready <= sched_done & rstn;")
    op += pp("out_done <= ((out_row_end & out_col_end) | out_done) & rstn;")
    op += pp("{out_col_c, out_col} <= (out_rd_data ? (out_col_end ? 0 : out_col + 1'b1) : out_col) & {"+f"{BUF_DEP+1}"+"{rstn}};")
    op += pp("{out_row_c, out_row} <= ((out_rd_data & out_col_end) ? (out_row_end ? 0 : out_row + 1'b1) : out_row) & {"+f"{BUF_DEP+1}"+"{rstn}};")
    op += pp("end")
    op += pp("assign out_data = noc_out_data[out_row][out_col] & {"+f"{BIT_LEN}"+"{rstn & out_rd_data}};")
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
    MODULE_FILE_NAME = "fxp{}s_pe_array.v".format(BIT_LEN)
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

