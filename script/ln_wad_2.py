import argparse
from decimal import *
from math import log
from eth_abi import encode


def calculate_ln(args):
    getcontext().prec = 83
    x = Decimal(args.x) / Decimal(1e18) / Decimal(1e18)
    

    result = x.ln()
    result = int(result * Decimal(1e18) * Decimal(1e18)) # WAD ** 2

    enc = encode(["int256"], [result])
    print("0x" + enc.hex(), end="")

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("x", type=int)

    return parser.parse_args()

   

def main():
    args = parse_args()
    calculate_ln(args)


if __name__ == "__main__":
    main()