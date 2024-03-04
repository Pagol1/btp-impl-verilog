import decimal
from decimal import Decimal
import math
from gen_config import *

def gen_pow2():
    global BIT_LEN
    global BL_X
    decimal.getcontext().prec = (BL_X + int(math.log2(BL_X)))
    op = ""
    for i in range(1, BIT_LEN+1):
        p = Decimal("2") ** Decimal(f"{-i}") + Decimal("1")
        print("Raw: ", p)
        p = p.log10() / Decimal("2").log10() # log2
        print("log: ", p)
        op += f"{BL_X}'b"
        for j in range(1, BL_X+1):
            d = Decimal("2") ** Decimal(f"{-j}")
            t = p - d
            if (t < 0):
                op += "0"
            else:
                op += "1"
                p = t
        print("Residue: ", p)
        op += "\n"
    return op

if __name__ == "__main__":
    global FILE_POW2
    global BIT_LEN
    op = gen_pow2()
    with open(f"{FILE_POW2}_{BIT_LEN}.txt", 'w') as f:
        f.write(op)