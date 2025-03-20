// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/console2.sol";

/**
 * @title Floating point Library base 10 with 38 digits signed
 * @dev the library uses 2 exclusive types which means they can carry out operations only with their own type. They can
 * be easily converted, however, to ensure max flexibility. The reason for 2 different types to exist is that one is
 * optimized for operational gas efficiency (Float), and the other one is optimized for storage gas efficiency
 * (packedFloat). Their gas usage is nevertheless very similar in terms of operational consumption.
 * @author Inspired by a Python proposal by @miguel-ot and refined/implemented in Solidity by @oscarsernarosero @Palmerg4
 */

type packedFloat is uint256;

library Float128 {
    /****************************************************************************************************************************
     * The mantissa can be in 2 sizes: M: 38 digits, or L: 72 digits                                                            *
     *      Packed Float Bitmap:                                                                                                *
     *      255 ... EXPONENT ... 242, L_MATISSA_FLAG (241), MANTISSA_SIGN (240), 239 ... MANTISSA L..., 127 .. MANTISSA M ... 0 *
     *      The exponent is signed using the offset zero to 8191. max values: -8192 and +8191.                                  *
     ***************************************************************************************************************************/
    uint constant MANTISSA_MASK = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint constant MANTISSA_SIGN_MASK = 0x1000000000000000000000000000000000000000000000000000000000000;
    uint constant MANTISSA_L_FLAG_MASK = 0x2000000000000000000000000000000000000000000000000000000000000;
    uint constant EXPONENT_MASK = 0xfffc000000000000000000000000000000000000000000000000000000000000;
    uint constant TWO_COMPLEMENT_SIGN_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
    uint constant BASE = 10;
    uint constant ZERO_OFFSET = 8192;
    uint constant ZERO_OFFSET_MINUS_1 = 8191;
    uint constant EXPONENT_BIT = 242;
    uint constant MAX_DIGITS_M = 38;
    uint constant MAX_DIGITS_M_MINUS_1 = 37;
    uint constant MAX_DIGITS_M_PLUS_1 = 39;
    uint constant MAX_DIGITS_L = 72;
    uint constant MAX_DIGITS_L_MINUS_1 = 71;
    uint constant MAX_DIGITS_L_PLUS_1 = 73;
    uint constant DIGIT_DIFF_L_M = 34;
    uint constant DIGIT_DIFF_76_L = 4;
    uint constant MAX_M_DIGIT_NUMBER = 99999999999999999999999999999999999999;
    uint constant MIN_M_DIGIT_NUMBER = 10000000000000000000000000000000000000;
    uint constant MAX_L_DIGIT_NUMBER = 999999999999999999999999999999999999999999999999999999999999999999999999;
    uint constant MIN_L_DIGIT_NUMBER = 100000000000000000000000000000000000000000000000000000000000000000000000;
    uint constant BASE_TO_THE_DIGIT_DIFF = 10000000000000000000000000000000000;
    uint constant BASE_TO_THE_MAX_DIGITS_M_MINUS_1 = 10000000000000000000000000000000000000;
    uint constant BASE_TO_THE_MAX_DIGITS_M = 100000000000000000000000000000000000000;
    uint constant BASE_TO_THE_MAX_DIGITS_M_PLUS_1 = 1000000000000000000000000000000000000000;
    uint constant BASE_TO_THE_DIFF_76_L = 10000;
    uint constant MAX_75_DIGIT_NUMBER = 999999999999999999999999999999999999999999999999999999999999999999999999999;
    uint constant MAX_76_DIGIT_NUMBER = 9999999999999999999999999999999999999999999999999999999999999999999999999999;
    int constant MAXIMUM_EXPONENT = -18; // guarantees all results will have at least 18 decimals. Constrainst the exponents

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
        uint _adj;
        uint aMan;
        uint bMan;
        uint aExp;
        uint bExp;
        bool isL;
        console2.log("a", packedFloat.unwrap(a));
        console2.log("b", packedFloat.unwrap(b));
        if (packedFloat.unwrap(a) == 0) return b;
        if (packedFloat.unwrap(b) == 0) return a;
        assembly {
            let aL := gt(and(a, MANTISSA_L_FLAG_MASK), 0)
            let bL := gt(and(b, MANTISSA_L_FLAG_MASK), 0)
            if iszero(or(aL, bL)) {
                isSubtraction := xor(and(a, MANTISSA_SIGN_MASK), and(b, MANTISSA_SIGN_MASK))
                // we extract the exponent and mantissas for both
                aExp := and(a, EXPONENT_MASK)
                bExp := and(b, EXPONENT_MASK)
                aMan := and(a, MANTISSA_MASK)
                bMan := and(b, MANTISSA_MASK)
                // we adjust the significant digits and set the exponent of the result
                // subtraction case
                if isSubtraction {
                    // we add 38 digits of precision in the case of subtraction
                    if gt(aExp, bExp) {
                        r := sub(aExp, shl(EXPONENT_BIT, MAX_DIGITS_M))
                        let adj := sub(shr(EXPONENT_BIT, r), shr(EXPONENT_BIT, bExp))
                        let neg := and(TWO_COMPLEMENT_SIGN_MASK, adj)
                        if neg {
                            bMan := mul(bMan, exp(BASE, sub(0, adj)))
                            aMan := mul(aMan, BASE_TO_THE_MAX_DIGITS_M)
                        }
                        if iszero(neg) {
                            bMan := sdiv(bMan, exp(BASE, adj))
                            aMan := mul(aMan, BASE_TO_THE_MAX_DIGITS_M)
                        }
                    }
                    if gt(bExp, aExp) {
                        r := sub(bExp, shl(EXPONENT_BIT, MAX_DIGITS_M))
                        let adj := sub(shr(EXPONENT_BIT, r), shr(EXPONENT_BIT, aExp))
                        let neg := and(TWO_COMPLEMENT_SIGN_MASK, adj)
                        if neg {
                            aMan := mul(aMan, exp(BASE, sub(0, adj)))
                            bMan := mul(bMan, BASE_TO_THE_MAX_DIGITS_M)
                        }
                        if iszero(neg) {
                            aMan := sdiv(aMan, exp(BASE, adj))
                            bMan := mul(bMan, BASE_TO_THE_MAX_DIGITS_M)
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
            if or(aL, bL) {
                isL := 1
                isSubtraction := xor(and(a, MANTISSA_SIGN_MASK), and(b, MANTISSA_SIGN_MASK))
                // we extract the exponent and mantissas for both
                aExp := and(a, EXPONENT_MASK)
                bExp := and(b, EXPONENT_MASK)
                aMan := and(a, MANTISSA_MASK)
                bMan := and(b, MANTISSA_MASK)
                // we adjust the significant digits and set the exponent of the result
                // we make sure both of them are size L before continuing
                if iszero(aL) {
                    aMan := mul(aMan, BASE_TO_THE_DIGIT_DIFF)
                    aExp := sub(aExp, shl(EXPONENT_BIT, DIGIT_DIFF_L_M))
                }
                if iszero(bL) {
                    bMan := mul(bMan, BASE_TO_THE_DIGIT_DIFF)
                    bExp := sub(bExp, shl(EXPONENT_BIT, DIGIT_DIFF_L_M))
                }
                //subtraction case
                if isSubtraction {
                    // we add 4 digits of precision in the case of subtraction
                    if gt(aExp, bExp) {
                        r := sub(aExp, shl(EXPONENT_BIT, DIGIT_DIFF_76_L))
                        let adj := sub(shr(EXPONENT_BIT, r), shr(EXPONENT_BIT, bExp))
                        let neg := and(TWO_COMPLEMENT_SIGN_MASK, adj)
                        if neg {
                            bMan := mul(bMan, exp(BASE, sub(0, adj)))
                            aMan := mul(aMan, BASE_TO_THE_DIFF_76_L)
                        }
                        if iszero(neg) {
                            bMan := sdiv(bMan, exp(BASE, adj))
                            aMan := mul(aMan, BASE_TO_THE_DIFF_76_L)
                        }
                        _adj := adj
                    }
                    if gt(bExp, aExp) {
                        r := sub(bExp, shl(EXPONENT_BIT, DIGIT_DIFF_76_L))
                        let adj := sub(shr(EXPONENT_BIT, r), shr(EXPONENT_BIT, aExp))
                        let neg := and(TWO_COMPLEMENT_SIGN_MASK, adj)
                        if neg {
                            aMan := mul(aMan, exp(BASE, sub(0, adj)))
                            bMan := mul(bMan, BASE_TO_THE_DIFF_76_L)
                        }
                        if iszero(neg) {
                            aMan := sdiv(aMan, exp(BASE, adj))
                            bMan := mul(bMan, BASE_TO_THE_DIFF_76_L)
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
                // // if exponents are the same, we don't need to adjust the mantissas. We just set the result's exponent
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
        }
        console2.log("isL", isL);
        console2.log("_adj", _adj);
        console2.log("a", aMan, aExp >> EXPONENT_BIT);
        console2.log("b", bMan, bExp >> EXPONENT_BIT);
        console2.log("isSubtraction", isSubtraction);
        console2.log("addition", addition);
        console2.log("sameExponent", sameExponent);
        // normalization
        if (packedFloat.unwrap(r) > 0) {
            uint rExp;
            console2.log("r", packedFloat.unwrap(r) >> EXPONENT_BIT);
            assembly {
                rExp := shr(EXPONENT_BIT, r)
            }
            if (isSubtraction) {
                // subtraction case can have a number of digits anywhere from 1 to 76
                // we might get a normalized result, so we only normalize if necessary
                if (
                    !((addition <= MAX_M_DIGIT_NUMBER && addition >= MIN_M_DIGIT_NUMBER) ||
                        (addition <= MAX_L_DIGIT_NUMBER && addition >= MIN_L_DIGIT_NUMBER))
                ) {
                    uint digitsMantissa = findNumberOfDigits(addition);
                    console2.log("digitsMantissa", digitsMantissa);
                    console2.log("rExp", rExp);
                    assembly {
                        let mantissaReducer := sub(digitsMantissa, MAX_DIGITS_M)
                        let isResultL := slt(MAXIMUM_EXPONENT, add(sub(rExp, ZERO_OFFSET), mantissaReducer))
                        if isResultL {
                            mantissaReducer := sub(mantissaReducer, DIGIT_DIFF_L_M)
                            r := or(r, MANTISSA_L_FLAG_MASK)
                        }
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
                } else if (addition >= MIN_L_DIGIT_NUMBER && rExp < (ZERO_OFFSET - uint(MAXIMUM_EXPONENT * -1) - DIGIT_DIFF_L_M)) {
                    assembly {
                        addition := sdiv(addition, BASE_TO_THE_DIGIT_DIFF)
                        r := add(r, shl(EXPONENT_BIT, DIGIT_DIFF_L_M))
                    }
                }
            } else {
                // addition case is simpler since it can only have 2 possibilities: same digits as its addends,
                // or + 1 digits due to an "overflow"
                assembly {
                    // 38 digit case
                    if and(lt(addition, MIN_L_DIGIT_NUMBER), gt(addition, MAX_M_DIGIT_NUMBER)) {
                        addition := div(addition, BASE)
                        r := add(r, shl(EXPONENT_BIT, 1))
                    }
                    // 72 digit case
                    if gt(addition, MAX_L_DIGIT_NUMBER) {
                        addition := div(addition, BASE)
                        r := add(add(r, shl(EXPONENT_BIT, 1)), MANTISSA_L_FLAG_MASK)
                    }
                }
            }
            assembly {
                r := or(r, addition)
            }
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
                    r := sub(aExp, shl(EXPONENT_BIT, MAX_DIGITS_M))
                    let adj := sub(shr(EXPONENT_BIT, r), shr(EXPONENT_BIT, bExp))
                    let neg := and(TWO_COMPLEMENT_SIGN_MASK, adj)
                    if neg {
                        bMan := mul(bMan, exp(BASE, sub(0, adj)))
                        aMan := mul(aMan, BASE_TO_THE_MAX_DIGITS_M)
                    }
                    if iszero(neg) {
                        bMan := sdiv(bMan, exp(BASE, adj))
                        aMan := mul(aMan, BASE_TO_THE_MAX_DIGITS_M)
                    }
                }
                if gt(bExp, aExp) {
                    r := sub(bExp, shl(EXPONENT_BIT, MAX_DIGITS_M))
                    let adj := sub(shr(EXPONENT_BIT, r), shr(EXPONENT_BIT, aExp))
                    let neg := and(TWO_COMPLEMENT_SIGN_MASK, adj)
                    if neg {
                        aMan := mul(aMan, exp(BASE, sub(0, adj)))
                        bMan := mul(bMan, BASE_TO_THE_MAX_DIGITS_M)
                    }
                    if iszero(neg) {
                        aMan := sdiv(aMan, exp(BASE, adj))
                        bMan := mul(bMan, BASE_TO_THE_MAX_DIGITS_M)
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
        if (packedFloat.unwrap(r) > 0) {
            if (isSubtraction) {
                // subtraction case can have a number of digits anywhere from 1 to 76
                // we might get a normalized result, so we only normalize if necessary
                if (addition > MAX_M_DIGIT_NUMBER || addition < MIN_M_DIGIT_NUMBER) {
                    uint digitsMantissa = findNumberOfDigits(addition);
                    assembly {
                        let mantissaReducer := sub(digitsMantissa, MAX_DIGITS_M)
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
                    if gt(addition, MAX_M_DIGIT_NUMBER) {
                        addition := div(addition, BASE)
                        r := add(r, shl(EXPONENT_BIT, 1))
                    }
                }
            }
            assembly {
                r := or(r, addition)
            }
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
                    rMan := div(rMan, BASE_TO_THE_MAX_DIGITS_M)
                    rExp := add(rExp, MAX_DIGITS_M)
                }
                // if not, we then know that it is a 2k-1-digit number
                if iszero(is76digit) {
                    rMan := div(rMan, BASE_TO_THE_MAX_DIGITS_M_MINUS_1)
                    rExp := add(rExp, MAX_DIGITS_M_MINUS_1)
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
            if gt(and(a, MANTISSA_MASK), 0) {
                let aMan := and(a, MANTISSA_MASK)
                let aExp := shr(EXPONENT_BIT, and(a, EXPONENT_MASK))
                let bMan := and(b, MANTISSA_MASK)
                let bExp := shr(EXPONENT_BIT, and(b, EXPONENT_MASK))
                // we add 38 more digits of precision
                aMan := mul(aMan, BASE_TO_THE_MAX_DIGITS_M)
                aExp := sub(aExp, MAX_DIGITS_M)
                let rMan := div(aMan, bMan)

                let rExp := sub(add(aExp, ZERO_OFFSET), bExp)
                // a division between a k-digit number and a j-digit number will result in a number between (k - j)
                // and (k - j + 1) digits. Since we are dividing a 76-digit number by a 38-digit number, we know
                // that the result could have either 39 or 38 digitis.
                let is39digit := gt(rMan, MAX_M_DIGIT_NUMBER)
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
     * @notice only positive numbers can have their square root calculated through this function
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
                x := mul(and(a, MANTISSA_MASK), BASE_TO_THE_MAX_DIGITS_M)
                aExp := sub(aExp, MAX_DIGITS_M)
            }
            if mod(aExp, 2) {
                x := mul(and(a, MANTISSA_MASK), BASE_TO_THE_MAX_DIGITS_M_PLUS_1)
                aExp := sub(aExp, MAX_DIGITS_M_PLUS_1)
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

            // exponent should now be half of what it was
            aExp := add(div(sub(aExp, ZERO_OFFSET), 2), ZERO_OFFSET)
            // if we have extra digits, we know it comes from the extra digit to make the exponent even
            if gt(s, MAX_M_DIGIT_NUMBER) {
                aExp := add(aExp, 1)
                s := div(s, BASE)
            }
            // final encoding
            r := or(shl(EXPONENT_BIT, aExp), s)
        }
    }

    /**
     * @dev performs a less than comparison
     * @param a the first term
     * @param b the second term
     * @return retVal the result of a < b
     * @notice this version of the function uses only the packedFloat type
     */
    function lt(packedFloat a, packedFloat b) internal pure returns (bool retVal) {
        assembly {
            let aExp := and(a, EXPONENT_MASK)
            let bExp := and(b, EXPONENT_MASK)
            let aMan := and(a, MANTISSA_MASK)
            let bMan := and(b, MANTISSA_MASK)
            let zeroFound := false

            if and(eq(aMan, 0), eq(bMan, 0)) {
                zeroFound := true
            }
            if and(eq(aMan, 0), iszero(zeroFound)) {
                zeroFound := true
                if iszero(and(b, MANTISSA_SIGN_MASK)) {
                    retVal := true
                }
            }
            if and(eq(bMan, 0), iszero(zeroFound)) {
                zeroFound := true
                if and(a, MANTISSA_SIGN_MASK) {
                    retVal := true
                }
            }
            if iszero(zeroFound) {
                if lt(aExp, bExp) {
                    retVal := true
                }
                if eq(aExp, bExp) {
                    let aNeg := false
                    let bNeg := false
                    if and(a, MANTISSA_SIGN_MASK) {
                        aNeg := true
                    }
                    if and(b, MANTISSA_SIGN_MASK) {
                        bNeg := true
                    }
                    if and(aNeg, bNeg) {
                        retVal := gt(aMan, bMan)
                    }
                    if iszero(or(aNeg, bNeg)) {
                        retVal := lt(aMan, bMan)
                    }
                    if xor(aNeg, bNeg) {
                        retVal := aNeg
                    }
                }
            }
        }
    }

    /**
     * @dev performs a less than or equals to comparison
     * @param a the first term
     * @param b the second term
     * @return retVal the result of a <= b
     * @notice this version of the function uses only the packedFloat type
     */
    function le(packedFloat a, packedFloat b) internal pure returns (bool retVal) {
        assembly {
            let equals := eq(a, b)
            if equals {
                retVal := true
            }
            if iszero(equals) {
                let aNeg := gt(and(a, MANTISSA_SIGN_MASK), 0)
                let bNeg := gt(and(b, MANTISSA_SIGN_MASK), 0)
                let isAZero := iszero(a)
                let isBZero := iszero(b)
                let zeroFound := or(isAZero, isBZero)
                if zeroFound {
                    if or(and(isAZero, iszero(bNeg)), and(isBZero, aNeg)) {
                        retVal := true
                    }
                }
                if iszero(zeroFound) {
                    let aExp := and(a, EXPONENT_MASK)
                    let bExp := and(b, EXPONENT_MASK)
                    let aMan := and(a, MANTISSA_MASK)
                    let bMan := and(b, MANTISSA_MASK)
                    if xor(aNeg, bNeg) {
                        retVal := aNeg
                    }
                    if and(iszero(aNeg), iszero(bNeg)) {
                        if eq(aExp, bExp) {
                            retVal := lt(aMan, bMan)
                        }
                        if lt(aExp, bExp) {
                            retVal := true
                        }
                    }
                    if and(aNeg, bNeg) {
                        if eq(aExp, bExp) {
                            retVal := gt(aMan, bMan)
                        }
                        if gt(aExp, bExp) {
                            retVal := true
                        }
                    }
                }
            }
        }
    }

    /**
     * @dev performs a greater than comparison
     * @param a the first term
     * @param b the second term
     * @return retVal the result of a > b
     * @notice this version of the function uses only the packedFloat type
     */
    function gt(packedFloat a, packedFloat b) internal pure returns (bool retVal) {
        assembly {
            let aExp := and(a, EXPONENT_MASK)
            let bExp := and(b, EXPONENT_MASK)
            let aMan := and(a, MANTISSA_MASK)
            let bMan := and(b, MANTISSA_MASK)
            let zeroFound := false

            if and(eq(aMan, 0), eq(bMan, 0)) {
                zeroFound := true
            }
            if and(eq(aMan, 0), iszero(zeroFound)) {
                zeroFound := true
                if and(b, MANTISSA_SIGN_MASK) {
                    retVal := true
                }
            }
            if and(eq(bMan, 0), iszero(zeroFound)) {
                zeroFound := true
                if iszero(and(a, MANTISSA_SIGN_MASK)) {
                    retVal := true
                }
            }
            if iszero(zeroFound) {
                if lt(bExp, aExp) {
                    retVal := true
                }
                if lt(aExp, bExp) {
                    retVal := false
                }
                if eq(aExp, bExp) {
                    let aNeg := false
                    let bNeg := false
                    if and(a, MANTISSA_SIGN_MASK) {
                        aNeg := true
                    }
                    if and(b, MANTISSA_SIGN_MASK) {
                        bNeg := true
                    }
                    if and(aNeg, bNeg) {
                        retVal := gt(bMan, aMan)
                    }
                    if iszero(or(aNeg, bNeg)) {
                        retVal := lt(bMan, aMan)
                    }
                    if xor(aNeg, bNeg) {
                        retVal := bNeg
                    }
                }
            }
        }
    }

    /**
     * @dev performs a greater than or equal to comparison
     * @param a the first term
     * @param b the second term
     * @return retVal the result of a >= b
     * @notice this version of the function uses only the packedFloat type
     */
    function ge(packedFloat a, packedFloat b) internal pure returns (bool retVal) {
        assembly {
            let aExp := and(a, EXPONENT_MASK)
            let bExp := and(b, EXPONENT_MASK)
            let aMan := and(a, MANTISSA_MASK)
            let bMan := and(b, MANTISSA_MASK)
            let zeroFound := false

            if and(eq(aMan, 0), eq(bMan, 0)) {
                zeroFound := true
                retVal := true
            }
            if and(eq(aMan, 0), iszero(zeroFound)) {
                zeroFound := true
                if and(b, MANTISSA_SIGN_MASK) {
                    retVal := true
                }
            }
            if and(eq(bMan, 0), iszero(zeroFound)) {
                zeroFound := true
                if iszero(and(a, MANTISSA_SIGN_MASK)) {
                    retVal := true
                }
            }
            if iszero(zeroFound) {
                if lt(bExp, aExp) {
                    retVal := true
                }
                if lt(aExp, bExp) {
                    retVal := false
                }
                if eq(aExp, bExp) {
                    let aNeg := false
                    let bNeg := false
                    if and(a, MANTISSA_SIGN_MASK) {
                        aNeg := true
                    }
                    if and(b, MANTISSA_SIGN_MASK) {
                        bNeg := true
                    }
                    if and(aNeg, bNeg) {
                        retVal := or(gt(bMan, aMan), eq(aMan, bMan))
                    }
                    if iszero(or(aNeg, bNeg)) {
                        retVal := or(lt(bMan, aMan), eq(aMan, bMan))
                    }
                    if xor(aNeg, bNeg) {
                        retVal := bNeg
                    }
                }
            }
        }
    }

    /**
     * @dev performs an equality comparison
     * @param a the first term
     * @param b the second term
     * @return retVal the result of a == b
     * @notice this version of the function uses only the packedFloat type
     */
    function eq(packedFloat a, packedFloat b) internal pure returns (bool retVal) {
        retVal = packedFloat.unwrap(a) == packedFloat.unwrap(b);
    }

    /**
     * @dev encodes a pair of signed integer values describing a floating point number into a packedFloat
     * Examples: 1234.567 can be expressed as: 123456 x 10**(-3), or 1234560 x 10**(-4), or 12345600 x 10**(-5), etc.
     * @notice the mantissa can hold a maximum of 38 digits. Any number with more digits will lose precision.
     * @param mantissa the integer that holds the mantissa digits (38 digits max)
     * @param exponent the exponent of the floating point number (between -8192 and +8191)
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
            if (
                !((mantissa <= int(MAX_M_DIGIT_NUMBER) && mantissa >= int(MIN_M_DIGIT_NUMBER)) ||
                    (mantissa <= int(MAX_L_DIGIT_NUMBER) && mantissa >= int(MIN_L_DIGIT_NUMBER)))
            ) {
                digitsMantissa = findNumberOfDigits(uint(mantissa));
                assembly {
                    mantissaMultiplier := sub(digitsMantissa, MAX_DIGITS_M)
                    let isResultL := slt(MAXIMUM_EXPONENT, add(exponent, mantissaMultiplier))
                    if isResultL {
                        mantissaMultiplier := sub(mantissaMultiplier, DIGIT_DIFF_L_M)
                        float := or(float, MANTISSA_L_FLAG_MASK)
                    }
                    exponent := add(exponent, mantissaMultiplier)
                    let negativeMultiplier := and(TWO_COMPLEMENT_SIGN_MASK, mantissaMultiplier)
                    if negativeMultiplier {
                        mantissa := mul(mantissa, exp(BASE, sub(0, mantissaMultiplier)))
                    }
                    if iszero(negativeMultiplier) {
                        mantissa := div(mantissa, exp(BASE, mantissaMultiplier))
                    }
                }
            } else if ((mantissa <= int(MAX_M_DIGIT_NUMBER) && mantissa >= int(MIN_M_DIGIT_NUMBER)) && exponent > MAXIMUM_EXPONENT) {
                assembly {
                    mantissa := mul(mantissa, BASE_TO_THE_DIGIT_DIFF)
                    exponent := sub(exponent, DIGIT_DIFF_L_M)
                    float := add(float, MANTISSA_L_FLAG_MASK)
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
            /// we use 2's complement for mantissa sign
            if and(float, MANTISSA_SIGN_MASK) {
                mantissa := sub(0, mantissa)
            }
        }
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
