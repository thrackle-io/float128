// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title Floating point Library base 10 with 38 digits signed
 * @dev the library uses 2 exclusive types which means they can carry out operations only with their own type. They can
 * be easily converted, however, to ensure max flexibility. The reason for 2 different types to exist is that one is
 * optimized for operational gas efficiency (Float), and the other one is optimized for storage gas efficiency
 * (packedFloat). Their gas usage is nevertheless very similar in terms of operational consumption.
 * @author Inspired by a Python proposal by @miguel-ot and refined/implemented in Solidity by @oscarsernarosero @Palmerg4
 */

type packedFloat is uint256;

struct Float {
    int mantissa;
    int exponent;
}

library Float128 {
    /*****************************************************************************************************************
     *      Packed Float Bitmap:                                                                                   *
     *      255 ... UNUSED ... 144, 143 ... EXPONENT ... 129, MANTISSA_SIGN (128), 127 .. MANTISSA ... 0             *
     *      The exponent is signed using the offset zero to 16383. max values: -16384 and +16383.                    *
     ****************************************************************************************************************/
    uint constant MANTISSA_MASK = 0xffffffffffffffffffffffffffffffff;
    uint constant MANTISSA_SIGN_MASK = 0x100000000000000000000000000000000;
    uint constant EXPONENT_MASK = 0xfffffffffffffffffffffffffffffffe00000000000000000000000000000000;
    uint constant TWO_COMPLEMENT_SIGN_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
    uint constant BASE = 10;
    uint constant ZERO_OFFSET = 16384;
    uint constant ZERO_OFFSET_MINUS_1 = 16383;
    uint constant EXPONENT_BIT = 129;
    uint constant MAX_DIGITS = 38;
    uint constant MAX_DIGITS_MINUS_1 = 37;
    uint constant MAX_DIGITS_PLUS_1 = 39;
    uint constant MAX_38_DIGIT_NUMBER = 99999999999999999999999999999999999999;
    uint constant MIN_38_DIGIT_NUMBER = 10000000000000000000000000000000000000;
    uint constant BASE_TO_THE_MAX_DIGITS_MINUS_1 = 10000000000000000000000000000000000000;
    uint constant BASE_TO_THE_MAX_DIGITS = 100000000000000000000000000000000000000;
    uint constant BASE_TO_THE_MAX_DIGITS_PLUS_1 = 1000000000000000000000000000000000000000;
    uint constant MAX_75_DIGIT_NUMBER = 999999999999999999999999999999999999999999999999999999999999999999999999999;
    uint constant MAX_76_DIGIT_NUMBER = 9999999999999999999999999999999999999999999999999999999999999999999999999999;

    /**
     * @dev adds 2 signed floating point numbers
     * @param a the first addend
     * @param b the second addend
     * @return r the result of a + b
     * @notice this version of the function uses only the packedFloat type
     */
    function add(packedFloat a, packedFloat b) internal pure returns (packedFloat r) {
        uint addition;
        bool isSubtraction;
        bool sameExponent;
        assembly {
            isSubtraction := xor(and(a, MANTISSA_SIGN_MASK), and(b, MANTISSA_SIGN_MASK))
            // we extract the exponent and mantissas for both
            let aExp := and(a, EXPONENT_MASK)
            let bExp := and(b, EXPONENT_MASK)
            let aMan := and(a, MANTISSA_MASK)
            let bMan := and(b, MANTISSA_MASK)
            // we adjust the significant digits and set the exponent of the result
            // subtraction case
            if isSubtraction {
                // we add 38 digits of precision in the case of subtraction
                if gt(aExp, bExp) {
                    r := sub(aExp, shl(EXPONENT_BIT, MAX_DIGITS))
                    let adj := sub(shr(EXPONENT_BIT, r), shr(EXPONENT_BIT, bExp))
                    let neg := and(TWO_COMPLEMENT_SIGN_MASK, adj)
                    if neg {
                        bMan := mul(bMan, exp(BASE, sub(0, adj)))
                        aMan := mul(aMan, BASE_TO_THE_MAX_DIGITS)
                    }
                    if iszero(neg) {
                        bMan := sdiv(bMan, exp(BASE, adj))
                        aMan := mul(aMan, BASE_TO_THE_MAX_DIGITS)
                    }
                }
                if gt(bExp, aExp) {
                    r := sub(bExp, shl(EXPONENT_BIT, MAX_DIGITS))
                    let adj := sub(shr(EXPONENT_BIT, r), shr(EXPONENT_BIT, aExp))
                    let neg := and(TWO_COMPLEMENT_SIGN_MASK, adj)
                    if neg {
                        aMan := mul(aMan, exp(BASE, sub(0, adj)))
                        bMan := mul(bMan, BASE_TO_THE_MAX_DIGITS)
                    }
                    if iszero(neg) {
                        aMan := sdiv(aMan, exp(BASE, adj))
                        bMan := mul(bMan, BASE_TO_THE_MAX_DIGITS)
                    }
                }
            }
            // addition case
            if iszero(isSubtraction) {
                if gt(aExp, bExp) {
                    r := aExp
                    let adj := sub(shr(EXPONENT_BIT, r), shr(EXPONENT_BIT, bExp))
                    bMan := sdiv(bMan, exp(BASE, adj))
                }
                if gt(bExp, aExp) {
                    r := bExp
                    let adj := sub(shr(EXPONENT_BIT, r), shr(EXPONENT_BIT, aExp))
                    aMan := sdiv(aMan, exp(BASE, adj))
                }
            }
            // if exponents are the same, we don't need to adjust the mantissas. We just set the result's exponent
            if eq(aExp, bExp) {
                r := aExp
                sameExponent := 1
            }
            // now we convert to 2's complement to carry out the operation
            if and(b, MANTISSA_SIGN_MASK) {
                bMan := sub(0, bMan)
            }
            if and(a, MANTISSA_SIGN_MASK) {
                aMan := sub(0, aMan)
            }
            // now we can add/subtract
            addition := add(aMan, bMan)
            // encoding the unnormalized result
            if and(TWO_COMPLEMENT_SIGN_MASK, addition) {
                r := or(r, MANTISSA_SIGN_MASK) // assign the negative sign
                addition := sub(0, addition) // convert back from 2's complement
            }
            if iszero(addition) {
                r := 0
            }
        }
        // normalization
        if (isSubtraction) {
            // subtraction case can have a number of digits anywhere from 1 to 76
            // we might get a normalized result, so we only normalize if necessary
            if (addition > MAX_38_DIGIT_NUMBER || addition < MIN_38_DIGIT_NUMBER) {
                uint digitsMantissa = findNumberOfDigits(addition);
                assembly {
                    let mantissaReducer := sub(digitsMantissa, MAX_DIGITS)
                    let negativeReducer := and(TWO_COMPLEMENT_SIGN_MASK, mantissaReducer)
                    if negativeReducer {
                        addition := mul(addition, exp(BASE, sub(0, mantissaReducer)))
                        r := sub(r, shl(EXPONENT_BIT, sub(0, mantissaReducer)))
                    }
                    if iszero(negativeReducer) {
                        addition := div(addition, exp(BASE, mantissaReducer))
                        r := add(r, shl(EXPONENT_BIT, mantissaReducer))
                    }
                }
            }
        } else {
            // addition case is simpler since it can only have 2 possibilities: same digits as its addends,
            // or + 1 digits due to an "overflow"
            assembly {
                if gt(addition, MAX_38_DIGIT_NUMBER) {
                    addition := div(addition, BASE)
                    r := add(r, shl(EXPONENT_BIT, 1))
                }
            }
        }
        assembly {
            r := or(r, addition)
        }
    }

    /**
     * @dev gets the difference between 2 signed floating point numbers
     * @param a the minuend
     * @param b the subtrahend
     * @return r the result of a - b
     * @notice this version of the function uses only the packedFloat type
     */
    function sub(packedFloat a, packedFloat b) internal pure returns (packedFloat r) {
        uint addition;
        bool isSubtraction;
        bool sameExponent;
        assembly {
            isSubtraction := eq(and(a, MANTISSA_SIGN_MASK), and(b, MANTISSA_SIGN_MASK))
            // we extract the exponent and mantissas for both
            let aExp := and(a, EXPONENT_MASK)
            let bExp := and(b, EXPONENT_MASK)
            let aMan := and(a, MANTISSA_MASK)
            let bMan := and(b, MANTISSA_MASK)
            // we adjust the significant digits and set the exponent of the result
            // subtraction case
            if isSubtraction {
                // we add 38 digits of precision in the case of subtraction
                if gt(aExp, bExp) {
                    r := sub(aExp, shl(EXPONENT_BIT, MAX_DIGITS))
                    let adj := sub(shr(EXPONENT_BIT, r), shr(EXPONENT_BIT, bExp))
                    let neg := and(TWO_COMPLEMENT_SIGN_MASK, adj)
                    if neg {
                        bMan := mul(bMan, exp(BASE, sub(0, adj)))
                        aMan := mul(aMan, BASE_TO_THE_MAX_DIGITS)
                    }
                    if iszero(neg) {
                        bMan := sdiv(bMan, exp(BASE, adj))
                        aMan := mul(aMan, BASE_TO_THE_MAX_DIGITS)
                    }
                }
                if gt(bExp, aExp) {
                    r := sub(bExp, shl(EXPONENT_BIT, MAX_DIGITS))
                    let adj := sub(shr(EXPONENT_BIT, r), shr(EXPONENT_BIT, aExp))
                    let neg := and(TWO_COMPLEMENT_SIGN_MASK, adj)
                    if neg {
                        aMan := mul(aMan, exp(BASE, sub(0, adj)))
                        bMan := mul(bMan, BASE_TO_THE_MAX_DIGITS)
                    }
                    if iszero(neg) {
                        aMan := sdiv(aMan, exp(BASE, adj))
                        bMan := mul(bMan, BASE_TO_THE_MAX_DIGITS)
                    }
                }
            }
            // addition case
            if iszero(isSubtraction) {
                if gt(aExp, bExp) {
                    r := aExp
                    let adj := sub(shr(EXPONENT_BIT, r), shr(EXPONENT_BIT, bExp))
                    bMan := sdiv(bMan, exp(BASE, adj))
                }
                if gt(bExp, aExp) {
                    r := bExp
                    let adj := sub(shr(EXPONENT_BIT, r), shr(EXPONENT_BIT, aExp))
                    aMan := sdiv(aMan, exp(BASE, adj))
                }
            }
            // if exponents are the same, we don't need to adjust the mantissas. We just set the result's exponent
            if eq(aExp, bExp) {
                r := aExp
                sameExponent := 1
            }
            // now we convert to 2's complement to carry out the operation
            if and(a, MANTISSA_SIGN_MASK) {
                aMan := sub(0, aMan)
            }
            // we negate the sign of b to make this a subtraction
            if iszero(and(b, MANTISSA_SIGN_MASK)) {
                bMan := sub(0, bMan)
            }
            // now we can add/subtract
            addition := add(aMan, bMan)
            // encoding the unnormalized result
            if and(TWO_COMPLEMENT_SIGN_MASK, addition) {
                r := or(r, MANTISSA_SIGN_MASK) // assign the negative sign
                addition := sub(0, addition) // convert back from 2's complement
            }
            if iszero(addition) {
                r := 0
            }
        }
        // normalization
        if (isSubtraction) {
            // subtraction case can have a number of digits anywhere from 1 to 76
            // we might get a normalized result, so we only normalize if necessary
            if (addition > MAX_38_DIGIT_NUMBER || addition < MIN_38_DIGIT_NUMBER) {
                uint digitsMantissa = findNumberOfDigits(addition);
                assembly {
                    let mantissaReducer := sub(digitsMantissa, MAX_DIGITS)
                    let negativeReducer := and(TWO_COMPLEMENT_SIGN_MASK, mantissaReducer)
                    if negativeReducer {
                        addition := mul(addition, exp(BASE, sub(0, mantissaReducer)))
                        r := sub(r, shl(EXPONENT_BIT, sub(0, mantissaReducer)))
                    }
                    if iszero(negativeReducer) {
                        addition := div(addition, exp(BASE, mantissaReducer))
                        r := add(r, shl(EXPONENT_BIT, mantissaReducer))
                    }
                }
            }
        } else {
            // addition case is simpler since it can only have 2 possibilities: same digits as its addends,
            // or + 1 digits due to an "overflow"
            assembly {
                if gt(addition, MAX_38_DIGIT_NUMBER) {
                    addition := div(addition, BASE)
                    r := add(r, shl(EXPONENT_BIT, 1))
                }
            }
        }
        assembly {
            r := or(r, addition)
        }
    }

    /**
     * @dev gets the multiplication of 2 signed floating point numbers
     * @param a the first factor
     * @param b the second factor
     * @return r the result of a * b
     * @notice this version of the function uses only the packedFloat type
     */
    function mul(packedFloat a, packedFloat b) internal pure returns (packedFloat r) {
        uint rMan;
        uint rExp;
        assembly {
            // if any of the elements is zero then the result will be zero
            if iszero(or(iszero(a), iszero(b))) {
                // we extract the exponent and mantissas for both
                let aExp := and(a, EXPONENT_MASK)
                let bExp := and(b, EXPONENT_MASK)
                let aMan := and(a, MANTISSA_MASK)
                let bMan := and(b, MANTISSA_MASK)

                rMan := mul(aMan, bMan)
                rExp := sub(add(shr(EXPONENT_BIT, aExp), shr(EXPONENT_BIT, bExp)), ZERO_OFFSET)
                // multiplication between 2 numbers with k digits can result in a number between 2*k - 1 and 2*k digits
                // we check first if rMan is a 2k-digit number
                let is76digit := gt(rMan, MAX_75_DIGIT_NUMBER)
                if is76digit {
                    rMan := div(rMan, BASE_TO_THE_MAX_DIGITS)
                    rExp := add(rExp, MAX_DIGITS)
                }
                // if not, we then know that it is a 2k-1-digit number
                if iszero(is76digit) {
                    rMan := div(rMan, BASE_TO_THE_MAX_DIGITS_MINUS_1)
                    rExp := add(rExp, MAX_DIGITS_MINUS_1)
                }
                r := or(xor(and(a, MANTISSA_SIGN_MASK), and(b, MANTISSA_SIGN_MASK)), or(rMan, shl(EXPONENT_BIT, rExp)))
            }
        }
    }

    /**
     * @dev gets the division of 2 signed floating point numbers
     * @param a the numerator
     * @param b the denominator
     * @return r the result of a / b
     * @notice this version of the function uses only the packedFloat type
     */
    function div(packedFloat a, packedFloat b) internal pure returns (packedFloat r) {
        assembly {
            if eq(and(b, MANTISSA_MASK), 0) {
                let ptr := mload(0x40) // Get free memory pointer
                mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000) // Selector for method Error(string)
                mstore(add(ptr, 0x04), 0x20) // String offset
                mstore(add(ptr, 0x24), 26) // Revert reason length
                mstore(add(ptr, 0x44), "float128: division by zero")
                revert(ptr, 0x64) // Revert data length is 4 bytes for selector and 3 slots of 0x20 bytes
            }
            // if a is zero then the result will be zero
            if gt(a, 0) {
                let aMan := and(a, MANTISSA_MASK)
                let aExp := shr(EXPONENT_BIT, and(a, EXPONENT_MASK))
                let bMan := and(b, MANTISSA_MASK)
                let bExp := shr(EXPONENT_BIT, and(b, EXPONENT_MASK))
                // we add 38 more digits of precision
                aMan := mul(aMan, BASE_TO_THE_MAX_DIGITS)
                aExp := sub(aExp, MAX_DIGITS)
                let rMan := div(aMan, bMan)

                let rExp := sub(add(aExp, ZERO_OFFSET), bExp)
                // a division between a k-digit number and a j-digit number will result in a number between (k - j)
                // and (k - j + 1) digits. Since we are dividing a 76-digit number by a 38-digit number, we know
                // that the result could have either 39 or 38 digitis.
                let is39digit := gt(rMan, MAX_38_DIGIT_NUMBER)
                if is39digit {
                    // we need to truncate the last digit
                    rExp := add(rExp, 1)
                    rMan := div(rMan, BASE)
                }
                r := or(xor(and(a, MANTISSA_SIGN_MASK), and(b, MANTISSA_SIGN_MASK)), or(rMan, shl(EXPONENT_BIT, rExp)))
            }
        }
    }

    /**
     * @dev gets the square root of a signed floating point
     * @notice only positive numbers can get its square root calculated through this function
     * @param a the numerator to get the square root of
     * @return r the result of √a
     * @notice this version of the function uses only the packedFloat type
     */
    function sqrt(packedFloat a) internal pure returns (packedFloat r) {
        uint s;
        uint aExp;
        uint x;
        uint256 roundedDownResult;
        assembly {
            if and(a, MANTISSA_SIGN_MASK) {
                let ptr := mload(0x40) // Get free memory pointer
                mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000) // Selector for method Error(string)
                mstore(add(ptr, 0x04), 0x20) // String offset
                mstore(add(ptr, 0x24), 32) // Revert reason length
                mstore(add(ptr, 0x44), "float128: squareroot of negative")
                revert(ptr, 0x64) // Revert data length is 4 bytes for selector and 3 slots of 0x20 bytes
            }

            aExp := shr(EXPONENT_BIT, and(a, EXPONENT_MASK))
            // we need the exponent to be even so we can calculate the square root correctly
            if iszero(mod(aExp, 2)) {
                x := mul(and(a, MANTISSA_MASK), BASE_TO_THE_MAX_DIGITS)
                aExp := sub(aExp, MAX_DIGITS)
            }
            if mod(aExp, 2) {
                x := mul(and(a, MANTISSA_MASK), BASE_TO_THE_MAX_DIGITS_PLUS_1)
                aExp := sub(aExp, MAX_DIGITS_PLUS_1)
            }
            s := 1

            let xAux := x

            let cmp := or(gt(xAux, 0x100000000000000000000000000000000), eq(xAux, 0x100000000000000000000000000000000))
            xAux := sar(mul(cmp, 128), xAux)
            s := shl(mul(cmp, 64), s)

            cmp := or(gt(xAux, 0x10000000000000000), eq(xAux, 0x10000000000000000))
            xAux := sar(mul(cmp, 64), xAux)
            s := shl(mul(cmp, 32), s)

            cmp := or(gt(xAux, 0x100000000), eq(xAux, 0x100000000))
            xAux := sar(mul(cmp, 32), xAux)
            s := shl(mul(cmp, 16), s)

            cmp := or(gt(xAux, 0x10000), eq(xAux, 0x10000))
            xAux := sar(mul(cmp, 16), xAux)
            s := shl(mul(cmp, 8), s)

            cmp := or(gt(xAux, 0x100), eq(xAux, 0x100))
            xAux := sar(mul(cmp, 8), xAux)
            s := shl(mul(cmp, 4), s)

            cmp := or(gt(xAux, 0x10), eq(xAux, 0x10))
            xAux := sar(mul(cmp, 4), xAux)
            s := shl(mul(cmp, 2), s)

            s := shl(mul(or(gt(xAux, 0x8), eq(xAux, 0x8)), 2), s)

            s := shr(1, add(div(x, s), s))
            s := shr(1, add(div(x, s), s))
            s := shr(1, add(div(x, s), s))
            s := shr(1, add(div(x, s), s))
            s := shr(1, add(div(x, s), s))
            s := shr(1, add(div(x, s), s))
            s := shr(1, add(div(x, s), s))

            roundedDownResult := div(x, s)
            if or(gt(s, roundedDownResult), eq(s, roundedDownResult)) {
                s := roundedDownResult
            }

            // exponent should be now halve of what it was
            aExp := add(div(sub(aExp, ZERO_OFFSET), 2), ZERO_OFFSET)
            // if we have extra digits, we know it comes from the extra digit to make the exponent even
            if gt(s, MAX_38_DIGIT_NUMBER) {
                aExp := add(aExp, 1)
                s := div(s, BASE)
            }
            // final encoding
            r := or(shl(EXPONENT_BIT, aExp), s)
        }
    }

    /**
     * @dev adds 2 signed floating point numbers
     * @param a the first addend
     * @param b the second addend
     * @return r the result of a + b
     * @notice this version of the function uses only the Float type
     */
    function add(Float memory a, Float memory b) internal pure returns (Float memory r) {
        unchecked {
            bool isSubtraction = (uint(a.mantissa) >> 255) ^ (uint(b.mantissa) >> 255) > 0;
            bool sameExponent;
            if (isSubtraction) {
                // subtraction case
                if (a.exponent > b.exponent) {
                    r.exponent = a.exponent - int(MAX_DIGITS);
                    int adj = r.exponent - b.exponent;
                    if (adj < 0) {
                        a.mantissa *= int(BASE_TO_THE_MAX_DIGITS);
                        b.mantissa *= int(BASE ** uint(adj * -1));
                    } else {
                        a.mantissa *= int(BASE_TO_THE_MAX_DIGITS);
                        b.mantissa /= int(BASE ** (uint(adj)));
                    }
                } else if (a.exponent < b.exponent) {
                    r.exponent = b.exponent - int(MAX_DIGITS);
                    int adj = r.exponent - a.exponent;
                    if (adj < 0) {
                        a.mantissa *= int(BASE ** uint(adj * -1));
                        b.mantissa *= int(BASE_TO_THE_MAX_DIGITS);
                    } else {
                        a.mantissa /= int(BASE ** (uint(adj)));
                        b.mantissa *= int(BASE_TO_THE_MAX_DIGITS);
                    }
                }
            } else {
                // addition case
                if (a.exponent > b.exponent) {
                    r.exponent = a.exponent;
                    int adj = r.exponent - b.exponent;
                    b.mantissa /= int(BASE ** (uint(adj)));
                } else if (a.exponent < b.exponent) {
                    r.exponent = b.exponent;
                    int adj = r.exponent - a.exponent;
                    a.mantissa /= int(BASE ** (uint(adj)));
                }
            }
            // if exponents are the same, we don't need to adjust the mantissas. We just set the result's exponent
            if (a.exponent == b.exponent) {
                r.exponent = a.exponent;
                sameExponent = true;
            }
            // now we can add/subtract
            r.mantissa = a.mantissa + b.mantissa;
            if (r.mantissa == 0) r.exponent = 0 - int(ZERO_OFFSET);
            // normalization
            if (isSubtraction) {
                if (r.mantissa > int(MAX_38_DIGIT_NUMBER) || r.mantissa < int(MIN_38_DIGIT_NUMBER)) {
                    uint digitsMantissa = findNumberOfDigits(r.mantissa < 0 ? uint(r.mantissa * -1) : uint(r.mantissa));
                    int mantissaReducer = int(digitsMantissa - MAX_DIGITS);
                    if (mantissaReducer < 0) {
                        r.mantissa *= int(BASE ** uint(mantissaReducer * -1));
                        r.exponent += mantissaReducer;
                    } else {
                        r.mantissa /= int(BASE ** uint(mantissaReducer));
                        r.exponent += mantissaReducer;
                    }
                }
            } else {
                if (r.mantissa > int(MAX_38_DIGIT_NUMBER) || r.mantissa * -1 > int(MAX_38_DIGIT_NUMBER)) {
                    r.mantissa /= int(BASE);
                    ++r.exponent;
                }
            }
        }
    }

    /**
     * @dev gets the difference between 2 signed floating point numbers
     * @param a the minuend
     * @param b the subtrahend
     * @return r the result of a - b
     * @notice this version of the function uses only the Float type
     */
    function sub(Float memory a, Float memory b) internal pure returns (Float memory r) {
        unchecked {
            bool isSubtraction = (uint(a.mantissa) >> 255) == (uint(b.mantissa) >> 255);
            bool sameExponent;
            if (isSubtraction) {
                // subtraction case
                if (a.exponent > b.exponent) {
                    r.exponent = a.exponent - int(MAX_DIGITS);
                    int adj = r.exponent - b.exponent;
                    if (adj < 0) {
                        a.mantissa *= int(BASE_TO_THE_MAX_DIGITS);
                        b.mantissa *= int(BASE ** uint(adj * -1));
                    } else {
                        a.mantissa *= int(BASE_TO_THE_MAX_DIGITS);
                        b.mantissa /= int(BASE ** (uint(adj)));
                    }
                } else if (a.exponent < b.exponent) {
                    r.exponent = b.exponent - int(MAX_DIGITS);
                    int adj = r.exponent - a.exponent;
                    if (adj < 0) {
                        a.mantissa *= int(BASE ** uint(adj * -1));
                        b.mantissa *= int(BASE_TO_THE_MAX_DIGITS);
                    } else {
                        a.mantissa /= int(BASE ** (uint(adj)));
                        b.mantissa *= int(BASE_TO_THE_MAX_DIGITS);
                    }
                }
            } else {
                // addition case
                if (a.exponent > b.exponent) {
                    r.exponent = a.exponent;
                    int adj = r.exponent - b.exponent;
                    b.mantissa /= int(BASE ** (uint(adj)));
                } else if (a.exponent < b.exponent) {
                    r.exponent = b.exponent;
                    int adj = r.exponent - a.exponent;
                    a.mantissa /= int(BASE ** (uint(adj)));
                }
            }
            // if exponents are the same, we don't need to adjust the mantissas. We just set the result's exponent
            if (a.exponent == b.exponent) {
                r.exponent = a.exponent;
                sameExponent = true;
            }
            // now we can add/subtract
            r.mantissa = a.mantissa - b.mantissa;
            if (r.mantissa == 0) r.exponent = 0 - int(ZERO_OFFSET);
            // normalization
            if (isSubtraction) {
                if (r.mantissa > int(MAX_38_DIGIT_NUMBER) || r.mantissa < int(MIN_38_DIGIT_NUMBER)) {
                    uint digitsMantissa = findNumberOfDigits(r.mantissa < 0 ? uint(r.mantissa * -1) : uint(r.mantissa));
                    int mantissaReducer = int(digitsMantissa - MAX_DIGITS);
                    if (mantissaReducer < 0) {
                        r.mantissa *= int(BASE ** uint(mantissaReducer * -1));
                        r.exponent += mantissaReducer;
                    } else {
                        r.mantissa /= int(BASE ** uint(mantissaReducer));
                        r.exponent += mantissaReducer;
                    }
                }
            } else {
                if (r.mantissa > int(MAX_38_DIGIT_NUMBER) || r.mantissa * -1 > int(MAX_38_DIGIT_NUMBER)) {
                    r.mantissa /= int(BASE);
                    ++r.exponent;
                }
            }
        }
    }

    /**
     * @dev gets the multiplication of 2 signed floating point numbers
     * @param a the first factor
     * @param b the second factor
     * @return r the result of a * b
     * @notice this version of the function uses only the Float type
     */
    function mul(Float memory a, Float memory b) internal pure returns (Float memory r) {
        assembly {
            let rMan := mul(mload(a), mload(b))
            let rExp := add(mload(add(a, 0x20)), mload(add(b, 0x20)))
            // multiplication between 2 numbers with k digits can result in a number between 2*k - 1 and 2*k digits
            // we check first if rMan is a 2k-digit number
            let is76digit := or(sgt(rMan, MAX_75_DIGIT_NUMBER), slt(rMan, sub(0, MAX_75_DIGIT_NUMBER)))
            if is76digit {
                rMan := sdiv(rMan, BASE_TO_THE_MAX_DIGITS)
                rExp := add(rExp, MAX_DIGITS)
            }
            // if not, we then know that it is a 2k-1-digit number
            if iszero(is76digit) {
                rMan := sdiv(rMan, BASE_TO_THE_MAX_DIGITS_MINUS_1)
                rExp := add(rExp, MAX_DIGITS_MINUS_1)
            }
            mstore(r, rMan)
            mstore(add(0x20, r), rExp)
        }
    }

    /**
     * @dev gets the division of 2 signed floating point numbers
     * @param a the numerator
     * @param b the denominator
     * @return r the result of a / b
     * @notice this version of the function uses only the Float type
     */
    function div(Float memory a, Float memory b) internal pure returns (Float memory r) {
        int256 mantissa = b.mantissa;
        assembly {
            if eq(mantissa, 0) {
                let ptr := mload(0x40) // Get free memory pointer
                mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000) // Selector for method Error(string)
                mstore(add(ptr, 0x04), 0x20) // String offset
                mstore(add(ptr, 0x24), 26) // Revert reason length
                mstore(add(ptr, 0x44), "float128: division by zero")
                revert(ptr, 0x64) // Revert data length is 4 bytes for selector and 3 slots of 0x20 bytes
            }

            // we add 38 more digits of precision
            let aMan := mul(mload(a), BASE_TO_THE_MAX_DIGITS)
            let rMan := sdiv(aMan, mload(b))
            let rExp := sub(sub(mload(add(a, 0x20)), MAX_DIGITS), mload(add(b, 0x20)))
            // a division between a k-digit number and a j-digit number will result in a number between (k - j)
            // and (k - j + 1) digits. Since we are dividing a 76-digit number by a 38-digit number, we know
            // that the result could have either 39 or 38 digitis.
            let is39digit := or(sgt(rMan, MAX_38_DIGIT_NUMBER), slt(rMan, sub(0, MAX_38_DIGIT_NUMBER)))
            if is39digit {
                // we need to truncate the last digit
                rExp := add(rExp, 1)
                rMan := sdiv(rMan, BASE)
            }
            mstore(r, rMan)
            mstore(add(0x20, r), rExp)
        }
    }

    /**
     * @dev gets the square root of a signed floating point
     * @notice only positive numbers can get its square root calculated through this function
     * @param a the numerator to get the square root of
     * @return r the result of √a
     * @notice this version of the function uses only the Float type
     */
    function sqrt(Float memory a) internal pure returns (Float memory r) {
        if (a.mantissa != 0) {
            uint s;
            int aExp = a.exponent;
            uint x;
            int256 mantissa = a.mantissa;
            assembly {
                if and(mantissa, MANTISSA_SIGN_MASK) {
                    let ptr := mload(0x40) // Get free memory pointer
                    mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000) // Selector for method Error(string)
                    mstore(add(ptr, 0x04), 0x20) // String offset
                    mstore(add(ptr, 0x24), 32) // Revert reason length
                    mstore(add(ptr, 0x44), "float128: squareroot of negative")
                    revert(ptr, 0x64) // Revert data length is 4 bytes for selector and 3 slots of 0x20 bytes
                }

                // we need the exponent to be even so we can calculate the square root correctly
                if iszero(mod(aExp, 2)) {
                    x := mul(and(mload(a), MANTISSA_MASK), BASE_TO_THE_MAX_DIGITS)
                    aExp := sub(aExp, MAX_DIGITS)
                }
                if mod(aExp, 2) {
                    x := mul(and(mload(a), MANTISSA_MASK), BASE_TO_THE_MAX_DIGITS_PLUS_1)
                    aExp := sub(aExp, MAX_DIGITS_PLUS_1)
                }
                s := 1

                let xAux := x

                let cmp := or(gt(xAux, 0x100000000000000000000000000000000), eq(xAux, 0x100000000000000000000000000000000))
                xAux := sar(mul(cmp, 128), xAux)
                s := shl(mul(cmp, 64), s)

                cmp := or(gt(xAux, 0x10000000000000000), eq(xAux, 0x10000000000000000))
                xAux := sar(mul(cmp, 64), xAux)
                s := shl(mul(cmp, 32), s)

                cmp := or(gt(xAux, 0x100000000), eq(xAux, 0x100000000))
                xAux := sar(mul(cmp, 32), xAux)
                s := shl(mul(cmp, 16), s)

                cmp := or(gt(xAux, 0x10000), eq(xAux, 0x10000))
                xAux := sar(mul(cmp, 16), xAux)
                s := shl(mul(cmp, 8), s)

                cmp := or(gt(xAux, 0x100), eq(xAux, 0x100))
                xAux := sar(mul(cmp, 8), xAux)
                s := shl(mul(cmp, 4), s)

                cmp := or(gt(xAux, 0x10), eq(xAux, 0x10))
                xAux := sar(mul(cmp, 4), xAux)
                s := shl(mul(cmp, 2), s)

                s := shl(mul(or(gt(xAux, 0x8), eq(xAux, 0x8)), 2), s)
            }
            unchecked {
                s = (s + x / s) >> 1;
                s = (s + x / s) >> 1;
                s = (s + x / s) >> 1;
                s = (s + x / s) >> 1;
                s = (s + x / s) >> 1;
                s = (s + x / s) >> 1;
                s = (s + x / s) >> 1;
                uint256 roundedDownResult = x / s;
                s = s >= roundedDownResult ? roundedDownResult : s;
            }
            assembly {
                // exponent should be now halve of what it was
                aExp := sdiv(aExp, 2)
                // if we have extra digits, we know it comes from the extra digit to make the exponent even
                if gt(s, MAX_38_DIGIT_NUMBER) {
                    aExp := add(aExp, 1)
                    s := div(s, BASE)
                }
                mstore(r, s)
                mstore(add(0x20, r), aExp)
            }
        } else r.exponent = 0 - int(ZERO_OFFSET);
    }

    /**
     * @dev encodes a pair of signed integer values describing a floating point number into a packedFloat
     * Examples: 1234.567 can be expressed as: 123456 x 10**(-3), or 1234560 x 10**(-4), or 12345600 x 10**(-5), etc.
     * @notice the mantissa can hold a maximum of 38 digits. Any number with more digits will lose precision.
     * @param mantissa the integer that holds the mantissa digits (38 digits max)
     * @param exponent the exponent of the floating point number (between -16384 and +16383)
     * @return float the encoded number. This value will ocupy a single 256-bit word and will hold the normalized
     * version of the floating-point number (shifts the exponent enough times to have exactly 38 significant digits)
     */
    function toPackedFloat(int mantissa, int exponent) internal pure returns (packedFloat float) {
        uint digitsMantissa;
        uint mantissaMultiplier;
        // we start by extracting the sign of the mantissa
        if (mantissa != 0) {
            assembly {
                if and(mantissa, TWO_COMPLEMENT_SIGN_MASK) {
                    float := MANTISSA_SIGN_MASK
                    mantissa := sub(0, mantissa)
                }
            }
            // we normalize only if necessary
            if (uint(mantissa) > MAX_38_DIGIT_NUMBER || uint(mantissa) < MIN_38_DIGIT_NUMBER) {
                digitsMantissa = findNumberOfDigits(uint(mantissa));
                assembly {
                    mantissaMultiplier := sub(digitsMantissa, MAX_DIGITS)
                    exponent := add(exponent, mantissaMultiplier)
                    let negativeMultiplier := and(TWO_COMPLEMENT_SIGN_MASK, mantissaMultiplier)
                    if negativeMultiplier {
                        mantissa := mul(mantissa, exp(BASE, sub(0, mantissaMultiplier)))
                    }
                    if iszero(negativeMultiplier) {
                        mantissa := div(mantissa, exp(BASE, mantissaMultiplier))
                    }
                }
            }
            // final encoding
            assembly {
                float := or(float, or(mantissa, shl(EXPONENT_BIT, add(exponent, ZERO_OFFSET))))
            }
        }
    }

    /**
     * @dev decodes a packedFloat into its mantissa and its exponent
     * @param float the floating-point number expressed as a packedFloat to decode
     * @return mantissa the 38 mantissa digits of the floating-point number
     * @return exponent the exponent of the floating-point number
     */
    function decode(packedFloat float) internal pure returns (int mantissa, int exponent) {
        assembly {
            // exponent
            let _exp := shr(EXPONENT_BIT, float)
            if gt(ZERO_OFFSET, _exp) {
                exponent := sub(0, sub(ZERO_OFFSET, _exp))
            }
            if gt(_exp, ZERO_OFFSET_MINUS_1) {
                exponent := sub(_exp, ZERO_OFFSET)
            }
            // mantissa
            mantissa := and(float, MANTISSA_MASK)
            /// we use complements 2 for mantissa sign
            if and(float, MANTISSA_SIGN_MASK) {
                mantissa := sub(0, mantissa)
            }
        }
    }

    /**
     * @dev shifts the exponent enough times to have a mantissa with exactly 38 digits
     * @notice this is a VITAL STEP to ensure the highest precision of the calculations
     * @param x the Float number to normalize
     * @return float the normalized version of x
     */
    function normalize(Float memory x) internal pure returns (Float memory float) {
        uint digitsMantissa;
        uint mantissaMultiplier;
        bool isMantissaNegative;

        if (x.mantissa == 0) {
            float.exponent = -128;
            float.mantissa = 0;
        } else {
            assembly {
                isMantissaNegative := and(mload(x), TWO_COMPLEMENT_SIGN_MASK)
                if isMantissaNegative {
                    mstore(x, sub(0, mload(x)))
                }
            }
            if (uint(x.mantissa) > MAX_38_DIGIT_NUMBER || uint(x.mantissa) < MIN_38_DIGIT_NUMBER) {
                digitsMantissa = findNumberOfDigits(uint(x.mantissa));
                assembly {
                    mantissaMultiplier := sub(digitsMantissa, MAX_DIGITS)
                    mstore(add(x, 0x20), add(mload(add(x, 0x20)), mantissaMultiplier))
                    let negativeMultiplier := and(MANTISSA_SIGN_MASK, mantissaMultiplier)
                    if negativeMultiplier {
                        mstore(x, mul(mload(x), exp(BASE, sub(0, mantissaMultiplier))))
                    }
                    if iszero(negativeMultiplier) {
                        mstore(x, div(mload(x), exp(BASE, mantissaMultiplier)))
                    }
                }
            }
            assembly {
                if isMantissaNegative {
                    mstore(x, sub(0, mload(x)))
                }
            }
            float = x;
        }
    }

    /**
     * @dev packs a pair of signed integer values describing a floating-point number into a Float struct.
     * Examples: 1234.567 can be expressed as: 123456 x 10**(-3), or 1234560 x 10**(-4), or 12345600 x 10**(-5), etc.
     * @notice the mantissa can hold a maximum of 38 digits. Any number with more digits will lose precision.
     * @param _mantissa the integer that holds the mantissa digits (38 digits max)
     * @param _exponent the exponent of the floating point number (between -16384 and +16383)
     * @return float the normalized version of the floating-point number packed in a Float struct.
     */
    function toFloat(int _mantissa, int _exponent) internal pure returns (Float memory float) {
        float = normalize(Float({mantissa: _mantissa, exponent: _exponent}));
    }

    /**
     * @dev from Float to packedFloat
     * @param _float the Float number to encode into a packedFloat
     * @return float the packed version of Float
     */
    function convertToPackedFloat(Float memory _float) internal pure returns (packedFloat float) {
        float = toPackedFloat(_float.mantissa, _float.exponent);
    }

    /**
     * @dev from packedFloat to Float
     * @param _float the encoded floating-point number to unpack into a Float
     * @return float the unpacked version of packedFloat
     */
    function convertToUnpackedFloat(packedFloat _float) internal pure returns (Float memory float) {
        (float.mantissa, float.exponent) = decode(_float);
    }

    /**
     * @dev finds the amount of digits of a number
     * @param x the number
     * @return log the amount of digits of x
     */
    function findNumberOfDigits(uint x) internal pure returns (uint log) {
        assembly {
            if gt(x, 0) {
                if gt(x, 9999999999999999999999999999999999999999999999999999999999999999) {
                    log := 64
                    x := div(x, 10000000000000000000000000000000000000000000000000000000000000000)
                }
                if gt(x, 99999999999999999999999999999999) {
                    log := add(log, 32)
                    x := div(x, 100000000000000000000000000000000)
                }
                if gt(x, 9999999999999999) {
                    log := add(log, 16)
                    x := div(x, 10000000000000000)
                }
                if gt(x, 99999999) {
                    log := add(log, 8)
                    x := div(x, 100000000)
                }
                if gt(x, 9999) {
                    log := add(log, 4)
                    x := div(x, 10000)
                }
                if gt(x, 99) {
                    log := add(log, 2)
                    x := div(x, 100)
                }
                if gt(x, 9) {
                    log := add(log, 1)
                }
                log := add(log, 1)
            }
        }
    }
}
