// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/console2.sol";
import {Uint512} from "./lib/Uint512.sol";

/**
 * @title Floating point Library base 10 with 38 digits signed
 * @dev the library uses the type packedFloat whih is a uint under the hood
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
    uint constant MAX_DIGITS_M_X_2 = 76;
    uint constant MAX_DIGITS_M_MINUS_1 = 37;
    uint constant MAX_DIGITS_M_PLUS_1 = 39;
    uint constant MAX_DIGITS_L = 72;
    uint constant MAX_DIGITS_L_MINUS_1 = 71;
    uint constant MAX_DIGITS_L_PLUS_1 = 73;
    uint constant DIGIT_DIFF_L_M = 34;
    uint constant DIGIT_DIFF_L_M_PLUS_1 = 35;
    uint constant DIGIT_DIFF_76_L_MINUS_1 = 3;
    uint constant DIGIT_DIFF_76_L = 4;
    uint constant DIGIT_DIFF_76_L_PLUS_1 = 5;
    uint constant MAX_M_DIGIT_NUMBER = 99999999999999999999999999999999999999;
    uint constant MIN_M_DIGIT_NUMBER = 10000000000000000000000000000000000000;
    uint constant MAX_L_DIGIT_NUMBER = 999999999999999999999999999999999999999999999999999999999999999999999999;
    uint constant MIN_L_DIGIT_NUMBER = 100000000000000000000000000000000000000000000000000000000000000000000000;
    uint constant BASE_TO_THE_MAX_DIGITS_L = 1000000000000000000000000000000000000000000000000000000000000000000000000;
    uint constant BASE_TO_THE_DIGIT_DIFF = 10000000000000000000000000000000000;
    uint constant BASE_TO_THE_DIGIT_DIFF_PLUS_1 = 100000000000000000000000000000000000;
    uint constant BASE_TO_THE_MAX_DIGITS_M_MINUS_1 = 10000000000000000000000000000000000000;
    uint constant BASE_TO_THE_MAX_DIGITS_M = 100000000000000000000000000000000000000;
    uint constant BASE_TO_THE_MAX_DIGITS_M_PLUS_1 = 1000000000000000000000000000000000000000;
    uint constant BASE_TO_THE_MAX_DIGITS_M_X_2 = 10000000000000000000000000000000000000000000000000000000000000000000000000000;
    uint constant BASE_TO_THE_DIFF_76_L_MINUS_1 = 1_000;
    uint constant BASE_TO_THE_DIFF_76_L = 10_000;
    uint constant BASE_TO_THE_DIFF_76_L_PLUS_1 = 100_000;
    uint constant MAX_75_DIGIT_NUMBER = 999999999999999999999999999999999999999999999999999999999999999999999999999;
    uint constant MAX_76_DIGIT_NUMBER = 9999999999999999999999999999999999999999999999999999999999999999999999999999;
    int constant MAXIMUM_EXPONENT = -18; // guarantees all results will have at least 18 decimals. Constrainst the exponents

    // ln specific variables
    int constant M = 38; // number of digits of precision that we work with.

    // ln(2) from Wolfram
    // 0.6931471805599453094172321214581765680755001343602552541206800094933936219696947

    // ln(1.1) from Wolfram
    // 0.095310179804324860043952123280765092220605365308644199185239808163001014

    int constant  ln10_70 =  23025850929940456840179914546843642076011014886287729760333279009675726;
    int constant ln2_70 =    6931471805599453094172321214581765680755001343602552541206800094933936;
    int constant ln1dot1_70 = 953101798043248600439521232807650922206053653086441991852398081630010;
    int constant ln1dot01_70 = 99503308531680828482153575442607416886796099400587978646095597668666;
    int constant ln1dot001_70 = 9995003330835331668093989205350114607550623931665519970196668289003;

    // ln10, ln2 and ln1.1 represented as integers with M significant digits
    int constant ln10_M = ln10_70 / int(10**(uint(70-M+1)));
    int constant ln2_M = ln2_70 / int(10**(uint(70-M)));
    int constant ln1dot1_M = ln1dot1_70 / int(10**(uint(70-M-1)));
    int constant ln1dot01_M = ln1dot01_70 / int(10**(uint(70-M-2)));
    int constant ln1dot001_M = ln1dot001_70 / int(10**(uint(70-M-3)));

    // ln10, ln2 and ln1.1 represented as float128
    packedFloat constant ln10 = packedFloat.wrap(57634551253070896831007164474234001986315550567012630870766974200712100735196);
    packedFloat constant ln2 = packedFloat.wrap(57627483864811783293688831284231030312298529498551182469036031073505904270823);
    packedFloat constant ln1dot1 = packedFloat.wrap(57620416476552669756370498094228058638261215024712010322305773559835681227132);
    packedFloat constant ln1dot01 = packedFloat.wrap(57613349088293556219052164904225086964202098217851863814911488587192353072694);
    packedFloat constant ln1dot001 = packedFloat.wrap(57606281700034442681733831714222115290139235007041033827277788478998076322779);

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
        if (packedFloat.unwrap(a) == 0) return b;
        if (packedFloat.unwrap(b) == 0) return a;
        assembly {
            let aL := gt(and(a, MANTISSA_L_FLAG_MASK), 0)
            let bL := gt(and(b, MANTISSA_L_FLAG_MASK), 0)
            isSubtraction := xor(and(a, MANTISSA_SIGN_MASK), and(b, MANTISSA_SIGN_MASK))
            // we extract the exponent and mantissas for both
            let aExp := and(a, EXPONENT_MASK)
            let bExp := and(b, EXPONENT_MASK)
            let aMan := and(a, MANTISSA_MASK)
            let bMan := and(b, MANTISSA_MASK)
            if iszero(or(aL, bL)) {
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
                // if exponents are the same, we don't need to adjust the mantissas. We just set the result's exponent
                if eq(aExp, bExp) {
                    aMan := mul(aMan, BASE_TO_THE_MAX_DIGITS_M)
                    bMan := mul(bMan, BASE_TO_THE_MAX_DIGITS_M)
                    r := sub(aExp, shl(EXPONENT_BIT, MAX_DIGITS_M))
                    sameExponent := 1
                }
            }
            if or(aL, bL) {
                // we make sure both of them are size L before continuing
                if iszero(aL) {
                    aMan := mul(aMan, BASE_TO_THE_DIGIT_DIFF)
                    aExp := sub(aExp, shl(EXPONENT_BIT, DIGIT_DIFF_L_M))
                }
                if iszero(bL) {
                    bMan := mul(bMan, BASE_TO_THE_DIGIT_DIFF)
                    bExp := sub(bExp, shl(EXPONENT_BIT, DIGIT_DIFF_L_M))
                }
                // we adjust the significant digits and set the exponent of the result
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
                // // if exponents are the same, we don't need to adjust the mantissas. We just set the result's exponent
                if eq(aExp, bExp) {
                    aMan := mul(aMan, BASE_TO_THE_DIFF_76_L)
                    bMan := mul(bMan, BASE_TO_THE_DIFF_76_L)
                    r := sub(aExp, shl(EXPONENT_BIT, DIGIT_DIFF_76_L))
                    sameExponent := 1
                }
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
        if (packedFloat.unwrap(r) > 0) {
            uint rExp;
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
                    // console2.log("digitsMantissa", digitsMantissa);
                    // console2.log("rExp", rExp);
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
                    let isGreaterThan76Digits := gt(addition, MAX_76_DIGIT_NUMBER)
                    let maxExp := sub(sub(sub(add(ZERO_OFFSET, MAXIMUM_EXPONENT), DIGIT_DIFF_L_M), DIGIT_DIFF_76_L), isGreaterThan76Digits)
                    let _isM := or(eq(rExp, maxExp), lt(rExp, maxExp))
                    if _isM {
                        addition := div(addition, BASE_TO_THE_MAX_DIGITS_M)
                        r := add(r, shl(EXPONENT_BIT, MAX_DIGITS_M))
                    }
                    if iszero(_isM) {
                        addition := div(addition, BASE_TO_THE_DIFF_76_L)
                        r := add(r, shl(EXPONENT_BIT, DIGIT_DIFF_76_L))
                        r := add(r, MANTISSA_L_FLAG_MASK)
                    }
                    if or(gt(addition, MAX_L_DIGIT_NUMBER), and(lt(addition, MIN_L_DIGIT_NUMBER), gt(addition, MAX_M_DIGIT_NUMBER))) {
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
        if (packedFloat.unwrap(a) == 0) {
            assembly {
                if gt(b, 0) {
                    b := xor(MANTISSA_SIGN_MASK, b)
                }
            }
            return b;
        }
        if (packedFloat.unwrap(b) == 0) return a;
        assembly {
            let aL := gt(and(a, MANTISSA_L_FLAG_MASK), 0)
            let bL := gt(and(b, MANTISSA_L_FLAG_MASK), 0)
            isSubtraction := eq(and(a, MANTISSA_SIGN_MASK), and(b, MANTISSA_SIGN_MASK))
            // we extract the exponent and mantissas for both
            let aExp := and(a, EXPONENT_MASK)
            let bExp := and(b, EXPONENT_MASK)
            let aMan := and(a, MANTISSA_MASK)
            let bMan := and(b, MANTISSA_MASK)
            if iszero(or(aL, bL)) {
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
                // if exponents are the same, we don't need to adjust the mantissas. We just set the result's exponent
                if eq(aExp, bExp) {
                    aMan := mul(aMan, BASE_TO_THE_MAX_DIGITS_M)
                    bMan := mul(bMan, BASE_TO_THE_MAX_DIGITS_M)
                    r := sub(aExp, shl(EXPONENT_BIT, MAX_DIGITS_M))
                    sameExponent := 1
                }
            }
            if or(aL, bL) {
                // we make sure both of them are size L before continuing
                if iszero(aL) {
                    aMan := mul(aMan, BASE_TO_THE_DIGIT_DIFF)
                    aExp := sub(aExp, shl(EXPONENT_BIT, DIGIT_DIFF_L_M))
                }
                if iszero(bL) {
                    bMan := mul(bMan, BASE_TO_THE_DIGIT_DIFF)
                    bExp := sub(bExp, shl(EXPONENT_BIT, DIGIT_DIFF_L_M))
                }
                // we adjust the significant digits and set the exponent of the result
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
                // // if exponents are the same, we don't need to adjust the mantissas. We just set the result's exponent
                if eq(aExp, bExp) {
                    aMan := mul(aMan, BASE_TO_THE_DIFF_76_L)
                    bMan := mul(bMan, BASE_TO_THE_DIFF_76_L)
                    r := sub(aExp, shl(EXPONENT_BIT, DIGIT_DIFF_76_L))
                    sameExponent := 1
                }
            }
            // now we convert to 2's complement to carry out the operation
            if iszero(and(b, MANTISSA_SIGN_MASK)) {
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
        if (packedFloat.unwrap(r) > 0) {
            uint rExp;
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
                    // console2.log("digitsMantissa", digitsMantissa);
                    // console2.log("rExp", rExp);
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
                    let isGreaterThan76Digits := gt(addition, MAX_76_DIGIT_NUMBER)
                    let maxExp := sub(sub(sub(add(ZERO_OFFSET, MAXIMUM_EXPONENT), DIGIT_DIFF_L_M), DIGIT_DIFF_76_L), isGreaterThan76Digits)
                    let _isM := or(eq(rExp, maxExp), lt(rExp, maxExp))
                    if _isM {
                        addition := div(addition, BASE_TO_THE_MAX_DIGITS_M)
                        r := add(r, shl(EXPONENT_BIT, MAX_DIGITS_M))
                    }
                    if iszero(_isM) {
                        addition := div(addition, BASE_TO_THE_DIFF_76_L)
                        r := add(r, shl(EXPONENT_BIT, DIGIT_DIFF_76_L))
                        r := add(r, MANTISSA_L_FLAG_MASK)
                    }
                    if or(gt(addition, MAX_L_DIGIT_NUMBER), and(lt(addition, MIN_L_DIGIT_NUMBER), gt(addition, MAX_M_DIGIT_NUMBER))) {
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
        uint r0;
        uint r1;
        bool Loperation;
        if (packedFloat.unwrap(a) == 0 || packedFloat.unwrap(b) == 0) return packedFloat.wrap(0);
        assembly {
            let aL := gt(and(a, MANTISSA_L_FLAG_MASK), 0)
            let bL := gt(and(b, MANTISSA_L_FLAG_MASK), 0)
            Loperation := or(aL, bL)
            // we extract the exponent and mantissas for both
            let aExp := and(a, EXPONENT_MASK)
            let bExp := and(b, EXPONENT_MASK)
            let aMan := and(a, MANTISSA_MASK)
            let bMan := and(b, MANTISSA_MASK)

            if Loperation {
                // we make sure both of them are size L before continuing
                if iszero(aL) {
                    aMan := mul(aMan, BASE_TO_THE_DIGIT_DIFF)
                    aExp := sub(aExp, shl(EXPONENT_BIT, DIGIT_DIFF_L_M))
                }
                if iszero(bL) {
                    bMan := mul(bMan, BASE_TO_THE_DIGIT_DIFF)
                    bExp := sub(bExp, shl(EXPONENT_BIT, DIGIT_DIFF_L_M))
                }
                rExp := sub(add(shr(EXPONENT_BIT, aExp), shr(EXPONENT_BIT, bExp)), ZERO_OFFSET)
                let mm := mulmod(aMan, bMan, not(0))
                r0 := mul(aMan, bMan)
                r1 := sub(sub(mm, r0), lt(mm, r0))
            }
            if iszero(Loperation) {
                rMan := mul(aMan, bMan)
                rExp := sub(add(shr(EXPONENT_BIT, aExp), shr(EXPONENT_BIT, bExp)), ZERO_OFFSET)
            }
        }
        if (Loperation) {
            // MIN_L_DIGIT_NUMBER is equal to BASE ** (MAX_L_DIGITS - 1).
            // We avoid losing the lsd this way, but we could get 1 extra digit
            rMan = Uint512.div512x256(r0, r1, MIN_L_DIGIT_NUMBER);
            // console2.log("rMan after 512 division", rMan);
            assembly {
                rExp := add(rExp, MAX_DIGITS_L_MINUS_1)
                let hasExtraDigit := gt(rMan, MAX_L_DIGIT_NUMBER)
                let maxExp := sub(sub(add(ZERO_OFFSET, MAXIMUM_EXPONENT), DIGIT_DIFF_L_M), hasExtraDigit)
                Loperation := gt(rExp, maxExp)
                // if not, we then know that it is a 2k-1-digit number
                if and(Loperation, hasExtraDigit) {
                    rMan := div(rMan, BASE)
                    rExp := add(rExp, 1)
                }
                if iszero(Loperation) {
                    if hasExtraDigit {
                        rMan := div(rMan, BASE_TO_THE_DIGIT_DIFF_PLUS_1)
                        rExp := add(rExp, DIGIT_DIFF_L_M_PLUS_1)
                    }
                    if iszero(hasExtraDigit) {
                        rMan := div(rMan, BASE_TO_THE_DIGIT_DIFF)
                        rExp := add(rExp, DIGIT_DIFF_L_M)
                    }
                }
            }
        } else {
            assembly {
                // multiplication between 2 numbers with k digits can result in a number between 2*k - 1 and 2*k digits
                // we check first if rMan is a 2k-digit number
                let is76digit := gt(rMan, MAX_75_DIGIT_NUMBER)
                let maxExp := add(sub(sub(add(ZERO_OFFSET, MAXIMUM_EXPONENT), DIGIT_DIFF_L_M), DIGIT_DIFF_76_L), iszero(is76digit))
                Loperation := gt(rExp, maxExp)
                if is76digit {
                    if Loperation {
                        rMan := div(rMan, BASE_TO_THE_DIFF_76_L)
                        rExp := add(rExp, DIGIT_DIFF_76_L)
                    }
                    if iszero(Loperation) {
                        rMan := div(rMan, BASE_TO_THE_MAX_DIGITS_M)
                        rExp := add(rExp, MAX_DIGITS_M)
                    }
                }
                // if not, we then know that it is a 2k-1-digit number
                if iszero(is76digit) {
                    if Loperation {
                        rMan := div(rMan, BASE_TO_THE_DIFF_76_L_MINUS_1)
                        rExp := add(rExp, DIGIT_DIFF_76_L_MINUS_1)
                    }
                    if iszero(Loperation) {
                        rMan := div(rMan, BASE_TO_THE_MAX_DIGITS_M_MINUS_1)
                        rExp := add(rExp, MAX_DIGITS_M_MINUS_1)
                    }
                }
            }
        }
        assembly {
            r := or(xor(and(a, MANTISSA_SIGN_MASK), and(b, MANTISSA_SIGN_MASK)), or(rMan, shl(EXPONENT_BIT, rExp)))
            if Loperation {
                r := or(r, MANTISSA_L_FLAG_MASK)
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
        r = div(a, b, false);
    }

    /**
     * @dev gets the division of 2 signed floating point numbers which results in a large mantissa
     * @param a the numerator
     * @param b the denominator
     * @return r the result of a / b
     * @notice this version of the function uses only the packedFloat type
     */
    function divL(packedFloat a, packedFloat b) internal pure returns (packedFloat r) {
        r = div(a, b, true);
    }

    /**
     * @dev gets the division of 2 signed floating point numbers
     * @param a the numerator
     * @param b the denominator
     * @return r the result of a / b
     * @notice this version of the function uses only the packedFloat type
     */
    function div(packedFloat a, packedFloat b, bool rL) internal pure returns (packedFloat r) {
        // console2.log(packedFloat.unwrap(b));
        assembly {
            if eq(and(b, MANTISSA_MASK), 0) {
                let ptr := mload(0x40) // Get free memory pointer
                mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000) // Selector for method Error(string)
                mstore(add(ptr, 0x04), 0x20) // String offset
                mstore(add(ptr, 0x24), 26) // Revert reason length
                mstore(add(ptr, 0x44), "float128: division by zero")
                revert(ptr, 0x64) // Revert data length is 4 bytes for selector and 3 slots of 0x20 bytes
            }
        }
        if (packedFloat.unwrap(a) == 0) return a;
        uint rMan;
        uint rExp;
        uint a0;
        uint a1;
        uint aMan;
        uint aExp;
        uint bMan;
        uint bExp;
        bool Loperation;
        assembly {
            let aL := gt(and(a, MANTISSA_L_FLAG_MASK), 0)
            let bL := gt(and(b, MANTISSA_L_FLAG_MASK), 0)
            // if a is zero then the result will be zero
            aMan := and(a, MANTISSA_MASK)
            aExp := shr(EXPONENT_BIT, and(a, EXPONENT_MASK))
            bMan := and(b, MANTISSA_MASK)
            bExp := shr(EXPONENT_BIT, and(b, EXPONENT_MASK))
            Loperation := or(
                or(rL, or(aL, bL)),
                // we add 1 to the calculation because division could result in an extra digit which will increase
                // the value of the exponent hence potentially violating maximum exponent
                sgt(add(sub(sub(sub(aExp, ZERO_OFFSET), MAX_DIGITS_M), sub(bExp, ZERO_OFFSET)), 1), MAXIMUM_EXPONENT)
            )

            if Loperation {
                if iszero(aL) {
                    aMan := mul(aMan, BASE_TO_THE_DIGIT_DIFF)
                    aExp := sub(aExp, DIGIT_DIFF_L_M)
                }
                if iszero(bL) {
                    bMan := mul(bMan, BASE_TO_THE_DIGIT_DIFF)
                    bExp := sub(bExp, DIGIT_DIFF_L_M)
                }
                let mm := mulmod(aMan, BASE_TO_THE_MAX_DIGITS_L, not(0))
                a0 := mul(aMan, BASE_TO_THE_MAX_DIGITS_L)
                a1 := sub(sub(mm, a0), lt(mm, a0))
                aExp := sub(aExp, MAX_DIGITS_L)
            }
            if iszero(Loperation) {
                // we add 38 more digits of precision
                aMan := mul(aMan, BASE_TO_THE_MAX_DIGITS_M)
                aExp := sub(aExp, MAX_DIGITS_M)
            }
        }
        if (Loperation) {
            rMan = Uint512.div512x256(a0, a1, bMan);
            unchecked {
                rExp = (aExp + ZERO_OFFSET) - bExp;
            }
        } else {
            assembly {
                rMan := div(aMan, bMan)
                rExp := sub(add(aExp, ZERO_OFFSET), bExp)
            }
        }
        assembly {
            if iszero(Loperation) {
                let hasExtraDigit := gt(rMan, MAX_M_DIGIT_NUMBER)
                if hasExtraDigit {
                    // we need to truncate the last digit
                    rExp := add(rExp, 1)
                    rMan := div(rMan, BASE)
                }
            }
            if Loperation {
                let hasExtraDigit := gt(rMan, MAX_L_DIGIT_NUMBER)
                let maxExp := sub(sub(add(ZERO_OFFSET, MAXIMUM_EXPONENT), DIGIT_DIFF_L_M), hasExtraDigit)
                Loperation := or(gt(rExp, maxExp), rL)
                if and(Loperation, hasExtraDigit) {
                    // we need to truncate the last digit
                    rExp := add(rExp, 1)
                    rMan := div(rMan, BASE)
                }
                if iszero(Loperation) {
                    if hasExtraDigit {
                        rExp := add(rExp, DIGIT_DIFF_L_M_PLUS_1)
                        rMan := div(rMan, BASE_TO_THE_DIGIT_DIFF_PLUS_1)
                    }
                    if iszero(hasExtraDigit) {
                        rExp := add(rExp, DIGIT_DIFF_L_M)
                        rMan := div(rMan, BASE_TO_THE_DIGIT_DIFF)
                    }
                }
            }
            r := or(xor(and(a, MANTISSA_SIGN_MASK), and(b, MANTISSA_SIGN_MASK)), or(rMan, shl(EXPONENT_BIT, rExp)))
            if Loperation {
                r := or(r, MANTISSA_L_FLAG_MASK)
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
        uint aMan;
        uint256 roundedDownResult;
        if (packedFloat.unwrap(a) == 0) return a;
        assembly {
            let aL := gt(and(a, MANTISSA_L_FLAG_MASK), 0)
            aMan := and(a, MANTISSA_MASK)
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
                if aL {
                    x := mul(aMan, BASE_TO_THE_DIFF_76_L)
                    aExp := sub(aExp, DIGIT_DIFF_76_L)
                }
                if iszero(aL) {
                    x := mul(aMan, BASE_TO_THE_MAX_DIGITS_M)
                    aExp := sub(aExp, MAX_DIGITS_M)
                }
            }
            if mod(aExp, 2) {
                if aL {
                    x := mul(aMan, BASE_TO_THE_DIFF_76_L_PLUS_1)
                    aExp := sub(aExp, DIGIT_DIFF_76_L_PLUS_1)
                }
                if iszero(aL) {
                    x := mul(aMan, BASE_TO_THE_MAX_DIGITS_M_PLUS_1)
                    aExp := sub(aExp, MAX_DIGITS_M_PLUS_1)
                }
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
        // console2.log("a", aMan);
    }

    /**
     * @dev performs a less than comparison
     * @param a the first term
     * @param b the second term
     * @return retVal the result of a < b
     * @notice this version of the function uses only the packedFloat type
     */
    function lt(packedFloat a, packedFloat b) internal pure returns (bool retVal) {
        if (packedFloat.unwrap(a) == packedFloat.unwrap(b)) return false;
        assembly {
            let aL := gt(and(a, MANTISSA_L_FLAG_MASK), 0)
            let bL := gt(and(b, MANTISSA_L_FLAG_MASK), 0)
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
                if iszero(aL) {
                    aMan := mul(aMan, BASE_TO_THE_DIGIT_DIFF)
                    aExp := sub(aExp, shl(EXPONENT_BIT, DIGIT_DIFF_L_M))
                }
                if iszero(bL) {
                    bMan := mul(bMan, BASE_TO_THE_DIGIT_DIFF)
                    bExp := sub(bExp, shl(EXPONENT_BIT, DIGIT_DIFF_L_M))
                }
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

    /**
     * @dev performs a less than or equals to comparison
     * @param a the first term
     * @param b the second term
     * @return retVal the result of a <= b
     * @notice this version of the function uses only the packedFloat type
     */
    function le(packedFloat a, packedFloat b) internal pure returns (bool retVal) {
        if (packedFloat.unwrap(a) == packedFloat.unwrap(b)) return true;
        assembly {
            let aL := gt(and(a, MANTISSA_L_FLAG_MASK), 0)
            let bL := gt(and(b, MANTISSA_L_FLAG_MASK), 0)
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
                if iszero(aL) {
                    aMan := mul(aMan, BASE_TO_THE_DIGIT_DIFF)
                    aExp := sub(aExp, shl(EXPONENT_BIT, DIGIT_DIFF_L_M))
                }
                if iszero(bL) {
                    bMan := mul(bMan, BASE_TO_THE_DIGIT_DIFF)
                    bExp := sub(bExp, shl(EXPONENT_BIT, DIGIT_DIFF_L_M))
                }
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

    /**
     * @dev performs a greater than comparison
     * @param a the first term
     * @param b the second term
     * @return retVal the result of a > b
     * @notice this version of the function uses only the packedFloat type
     */
    function gt(packedFloat a, packedFloat b) internal pure returns (bool retVal) {
        if (packedFloat.unwrap(a) == packedFloat.unwrap(b)) return false;
        assembly {
            let aL := gt(and(a, MANTISSA_L_FLAG_MASK), 0)
            let bL := gt(and(b, MANTISSA_L_FLAG_MASK), 0)
            let aNeg := gt(and(a, MANTISSA_SIGN_MASK), 0)
            let bNeg := gt(and(b, MANTISSA_SIGN_MASK), 0)
            let isAZero := iszero(a)
            let isBZero := iszero(b)
            let zeroFound := or(isAZero, isBZero)
            if zeroFound {
                if or(and(isBZero, iszero(aNeg)), and(isAZero, bNeg)) {
                    retVal := true
                }
            }
            if iszero(zeroFound) {
                let aExp := and(a, EXPONENT_MASK)
                let bExp := and(b, EXPONENT_MASK)
                let aMan := and(a, MANTISSA_MASK)
                let bMan := and(b, MANTISSA_MASK)
                if iszero(aL) {
                    aMan := mul(aMan, BASE_TO_THE_DIGIT_DIFF)
                    aExp := sub(aExp, shl(EXPONENT_BIT, DIGIT_DIFF_L_M))
                }
                if iszero(bL) {
                    bMan := mul(bMan, BASE_TO_THE_DIGIT_DIFF)
                    bExp := sub(bExp, shl(EXPONENT_BIT, DIGIT_DIFF_L_M))
                }
                if xor(aNeg, bNeg) {
                    retVal := bNeg
                }
                if and(iszero(aNeg), iszero(bNeg)) {
                    if eq(aExp, bExp) {
                        retVal := lt(bMan, aMan)
                    }
                    if lt(bExp, aExp) {
                        retVal := true
                    }
                }
                if and(aNeg, bNeg) {
                    if eq(aExp, bExp) {
                        retVal := lt(aMan, bMan)
                    }
                    if lt(aExp, bExp) {
                        retVal := true
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
        if (packedFloat.unwrap(a) == packedFloat.unwrap(b)) return true;
        assembly {
            let aL := gt(and(a, MANTISSA_L_FLAG_MASK), 0)
            let bL := gt(and(b, MANTISSA_L_FLAG_MASK), 0)
            let aNeg := gt(and(a, MANTISSA_SIGN_MASK), 0)
            let bNeg := gt(and(b, MANTISSA_SIGN_MASK), 0)
            let isAZero := iszero(a)
            let isBZero := iszero(b)
            let zeroFound := or(isAZero, isBZero)
            if zeroFound {
                if or(and(isBZero, iszero(aNeg)), and(isAZero, bNeg)) {
                    retVal := true
                }
            }
            if iszero(zeroFound) {
                let aExp := and(a, EXPONENT_MASK)
                let bExp := and(b, EXPONENT_MASK)
                let aMan := and(a, MANTISSA_MASK)
                let bMan := and(b, MANTISSA_MASK)
                if iszero(aL) {
                    aMan := mul(aMan, BASE_TO_THE_DIGIT_DIFF)
                    aExp := sub(aExp, shl(EXPONENT_BIT, DIGIT_DIFF_L_M))
                }
                if iszero(bL) {
                    bMan := mul(bMan, BASE_TO_THE_DIGIT_DIFF)
                    bExp := sub(bExp, shl(EXPONENT_BIT, DIGIT_DIFF_L_M))
                }
                if xor(aNeg, bNeg) {
                    retVal := bNeg
                }
                if and(iszero(aNeg), iszero(bNeg)) {
                    if eq(aExp, bExp) {
                        retVal := lt(bMan, aMan)
                    }
                    if lt(bExp, aExp) {
                        retVal := true
                    }
                }
                if and(aNeg, bNeg) {
                    if eq(aExp, bExp) {
                        retVal := lt(aMan, bMan)
                    }
                    if lt(aExp, bExp) {
                        retVal := true
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

     function ln_prec(int mantissa, int exp) public pure returns (packedFloat result) {

        int len_mantissa = int(findNumberOfDigits(uint(mantissa)));
        
        int positiveExp = exp * -1;
        int comparison = int(uint(10) ** uint(positiveExp));
        
        if(exp <= 0 && mantissa == comparison) {
            // This is the case in which the argument of the logarithm is 1.
            return packedFloat.wrap(0);
        } else if(len_mantissa > positiveExp) {
            if(len_mantissa > 38) {
                uint extra_digits = uint(len_mantissa - 38);
                mantissa = mantissa / int(10**extra_digits);
                exp = exp + int(extra_digits);
            } else if(len_mantissa < 38) {
                uint extra_digits = uint(38 - len_mantissa);
                mantissa = mantissa * int(10 ** extra_digits);
                exp = exp - int(extra_digits);
            }

            int q1 = (10**76) / mantissa;
            int r1 = (10**76) % mantissa;
            int q2 = ((10**38) * r1) / mantissa;
            uint one_over_argument_in_long_int = uint(q1) * (10**38) + uint(q2);
            int m10 = int(findNumberOfDigits(uint(one_over_argument_in_long_int)));

            uint one_over_arguments_76 = one_over_argument_in_long_int;
            int m76 = m10;
            if(m76 > 76) {
                uint extra_digits = uint(m76) - 76;
                m76 = m76 - int(extra_digits);
                one_over_arguments_76 = one_over_argument_in_long_int / 10**extra_digits;
            }
            int exp_one_over_argument = 0 - 38 - 76 - exp;

            packedFloat a = sub(packedFloat.wrap(0), ln_prec(int(one_over_arguments_76), -m76));
            packedFloat b = sub(a, toPackedFloat((exp_one_over_argument + m10), 0));
            result = mul(b, ln10);
        }
        
        if(len_mantissa <= positiveExp) {
            int256 m10 = len_mantissa + exp;
            exp = exp - m10;

            int256 m2 = 76 - len_mantissa;
            mantissa = mantissa * int(10**uint(m2));
            exp = exp - m2;

            int256 k;
            int256 multiplier_k;

            if(mantissa > (25 * (10**74))) {
                if(mantissa > (50 * (10**74))) {
                    k = 0;
                    multiplier_k = 1;
                } else {
                    k = 1;
                    multiplier_k = 2;
                }
            } else {
                if(mantissa > (125 * 10**73)) {
                    k = 2;
                    multiplier_k = 4;
                } else {
                    k = 3;
                    multiplier_k = 8;
                }
            }
            mantissa = mantissa * multiplier_k;
            uint256 uMantissa = uint256(mantissa);

            int256 q1;
            (q1, uMantissa) = calculateQ1(uMantissa);


            // We find the suitable value of q2 and the multiplier (1.014)**q2
            // so that 0.986 <= (1.014)**q2 * updated_x <= 1 
            // We use the following intervals:
            // (index -> lower bound of the interval)
            // 0 ->  9 * 10**75
            // 1 ->  9072 * 10**72
            // 2 ->  9199 * 10**72
            // 3 ->  9328 * 10**72
            // 4 ->  9459 * 10**72
            // 5 ->  9591 * 10**72
            // 6 ->  9725 * 10**72 
            // 7 ->  9860 * 10**72
            // partition_1014 = [0.9, 0.9072, 0.9199, 0.9328, 0.9459, 0.9591, 0.9725, 0.986, 1]

            int256 q2;
            (q2, uMantissa) = calculateQ2(uMantissa);
            
            // Now digits has already been updated
            // assert digits >= 9860 * 10**72
            // assert digits <= 10**76

            // We find the suitable value of q3 and the multiplier (1.0013)**q3
            // so that 0.9949 <= (1.0013)**q3 * updated_x <= 1 
            // We use the following intervals:
            // (index -> lower bound of the interval)
            // 0 ->  986 * 10**73
            // 1 ->  987274190490 * 10**64
            // 2 ->  988557646937 * 10**64
            // 3 ->  989842771878 * 10**64
            // 4 ->  991129567482 * 10**64
            // 5 ->  992418035920 * 10**64
            // 6 ->  993708179366 * 10**64 
            // 7 ->  995 * 10**73
            // partition_10013 = [0.986, 0.987274190490, 0.988557646937, 0.989842771878, 0.991129567482, 0.992418035920, 0.993708179366, 0.995, 1]
            
            int256 q3;
            (q3, uMantissa) = calculateQ3(uMantissa);
            
            // Now digits has already been updated
            // assert digits > 9949 * 10**72
            // assert digits <= 10**76

            int z_int = 10**76 - int(uMantissa);
            int len_z_int = int(findNumberOfDigits(uint(z_int)));

            int diff = len_z_int - 38;
            z_int = z_int / int(10**uint(diff));

            packedFloat z = toPackedFloat(z_int, (len_z_int - 76 - 38));
            
            // Number of terms of the Taylor series:
            int terms = 15;
            result = z;
            packedFloat z_to_j = z;
            for(uint j = 2; j < uint(terms + 1); j++) {
                z_to_j = mul(z_to_j, z);
                result = add(result, div(z_to_j, toPackedFloat(int(j), int(0))));
            } 

            packedFloat lnB = toPackedFloat(13902905168991420865477877458246859530, -39);
            packedFloat lnC = toPackedFloat(12991557316200501157605555658804528711, -40);

            packedFloat firstTerm = add(result, mul(toPackedFloat(k, 0), ln2));

            packedFloat secondTerm = add(firstTerm, mul(toPackedFloat(q1, 0), ln1dot1));

            packedFloat thirdTerm = add(secondTerm, mul(toPackedFloat(q2, 0), lnB));

            packedFloat fourthTerm = add(thirdTerm, mul(toPackedFloat(q3, 0), lnC));

            packedFloat fifthTerm = sub(fourthTerm, mul(toPackedFloat(m10, 0), ln10));

            result = mul(fifthTerm, toPackedFloat(-1, 0));
        }
    }

    function calculateQ1(uint256 uMantissa) public pure returns(int256 q1, uint256 updatedMantissa) {
        if(uMantissa > (68300000 * 10**68)) {
            if(uMantissa > (82000000 * 10**68)) {
                if(uMantissa > (90000000 * 10**68)) {
                    q1 = 0;
                    // multiplier_q1
                    updatedMantissa = uMantissa;
                } else {
                    q1 = 1;
                    updatedMantissa = uMantissa / 10;
                }
            } else {
                if(uMantissa > (75000000 * 10**68)) {
                    q1 = 2;
                    updatedMantissa = uMantissa + 2 * uMantissa / 10 + uMantissa / 100;
                } else {
                    q1 = 3;
                    updatedMantissa = uMantissa + 3 * uMantissa / 10 + 3 * uMantissa / 100 + uMantissa / 1000;
                }
            }
        } else {
            if(uMantissa > (56400000 * 10**68)) {
                if(uMantissa > (62000000 * 10**68)) {
                    q1 = 4;
                    updatedMantissa = uMantissa + 4 * uMantissa / 10 + 6 * uMantissa / 100 + 4 * uMantissa / 1000 + uMantissa / 10000;
                } else {
                    q1 = 5;
                    updatedMantissa = uMantissa + 6 * uMantissa / 10 + 1 * uMantissa / 100 + 0 * uMantissa / 1000 + 5 * uMantissa / 10000 + 1 * uMantissa / 100000;
                }
            } else {
                if(uMantissa > (51200000 * 10**68)) {
                    q1 = 6;
                    updatedMantissa = uMantissa + 7 * uMantissa / 10 + 7 * uMantissa / 100 + 1 * uMantissa / 1000 + 5 * uMantissa / 10000 + 6 * uMantissa / 100000 + 1 * uMantissa / 1000000;
                } else {
                    q1 = 7;
                    // multiplier_q1 = 1.1 ** 7 # = 1.9487171
                    updatedMantissa = uMantissa + 9 * uMantissa / 10 + 4 * uMantissa / 100 + 8 * uMantissa / 1000 + 7 * uMantissa / 10000 + 1 * uMantissa / 100000 + 7 * uMantissa / 1000000 + 1 * uMantissa / 10000000;
                }
            }
        }
    } 

    function calculateQ2(uint256 uMantissa) public pure returns(int256 q2, uint256 updatedMantissa) {
        if(uMantissa > (9459 * 10**72)) {
            if(uMantissa > (9725 * 10**72)) {
                if(uMantissa > 9860 * 10**72) {
                    q2 = 0;
                    // multiplier_q2 = 1
                    updatedMantissa = uMantissa;
                } else {
                    q2 = 1;
                    updatedMantissa = uMantissa + 0 * uMantissa / 10 + 1 * uMantissa / 100 + 4 * uMantissa / 1000;
                }
            } else {
                if(uMantissa > (9591 * 10**72)) {
                    q2 = 2;
                    // multiplier_q2 = 1.028196
                    updatedMantissa = uMantissa + 0 * uMantissa / 10 + 2 * uMantissa / 100 + 8 * uMantissa /1000 
                                + 1 * uMantissa / 10000 + 9 * uMantissa / 100000 + 6 * uMantissa / 1000000;
                } else {
                    q2 = 3;
                    // multiplier_q2 = 1.042590744
                    updatedMantissa = uMantissa + 0 * uMantissa / 10 + 4 * uMantissa / 100 + 2 * uMantissa / 1000 
                                + 5 * uMantissa / 10000 + 9 * uMantissa / 100000 + 0 * uMantissa / 1000000 
                                + 7 * uMantissa / 10000000 + 4 * uMantissa / 100000000 + 4 * uMantissa / 1000000000;
                }
            }
        } else {
            if(uMantissa > (9199 * 10**72)) {
                if(uMantissa > (9328 * 10**72)) {
                    q2 = 4;
                    // multiplier_q2 = 1.057187014416
                    updatedMantissa = uMantissa + 0 * uMantissa / 10 + 5 * uMantissa / 100 + 7 * uMantissa / 1000 
                                + 1 * uMantissa / 10000 + 8 * uMantissa / 100000 + 7 * uMantissa / 1000000 
                                + 0 * uMantissa / 10000000 + 1 * uMantissa / 100000000 + 4 * uMantissa / 1000000000 
                                + 4 * uMantissa / 10000000000 + 1 * uMantissa / 100000000000 + 6 * uMantissa / 1000000000000;
                } else {
                    q2 = 5;
                    // multiplier_q2 = 1.071987632617824
                    updatedMantissa = uMantissa + 0 * uMantissa / 10 + 7 * uMantissa / 100 + 1 * uMantissa / 1000 
                                    + 9 * uMantissa / 10000 + 8 * uMantissa / 100000 + 7 * uMantissa / 1000000 
                                    + 6 * uMantissa / 10000000 + 3 * uMantissa / 100000000 + 2 * uMantissa / 1000000000 
                                    + 6 * uMantissa / 10000000000 + 1 * uMantissa / 100000000000 + 7 * uMantissa / 1000000000000 
                                    + 8 * uMantissa / 10000000000000 + 2 * uMantissa / 100000000000000 + 4 * uMantissa / 1000000000000000;    
                }
            } else {
                if (uMantissa > (9072 * 10**72)) {
                    q2 = 6;
                    // multiplier_q2 = 1.086995459474473536
                    updatedMantissa = uMantissa + 0 * uMantissa / 10 + 8 * uMantissa / 100 + 6 * uMantissa / 1000 
                                + 9 * uMantissa / 10000 + 9 * uMantissa / 100000 + 5 * uMantissa / 1000000 
                                + 4 * uMantissa / 10000000 + 5 * uMantissa / 100000000 + 9 * uMantissa / 1000000000 
                                + 4 * uMantissa / 10000000000 + 7 * uMantissa / 100000000000 + 4 * uMantissa / 1000000000000 
                                + 4 * uMantissa / 10000000000000 + 7 * uMantissa / 100000000000000 + 3 * uMantissa / 1000000000000000 
                                + 5 * uMantissa / 10000000000000000 + 3 * uMantissa / 100000000000000000 + 6 * uMantissa / 1000000000000000000; 
                } else {
                    q2 = 7;
                    // multiplier_q2 = 1.102213395907116165504
                    updatedMantissa = uMantissa + 1 * uMantissa / 10 + 0 * uMantissa / 100 + 2 * uMantissa / 1000 
                            + 2 * uMantissa / 10000 + 1 * uMantissa / 100000 + 3 * uMantissa / 1000000 
                            + 3 * uMantissa / 10000000 + 9 * uMantissa / 100000000 + 5 * uMantissa / 1000000000 
                            + 9 * uMantissa / 10000000000 + 0 * uMantissa / 100000000000 + 7 * uMantissa / 1000000000000 
                            + 1 * uMantissa / 10000000000000 + 1 * uMantissa / 100000000000000 + 6 * uMantissa / 1000000000000000 
                            + 1 * uMantissa / 10000000000000000 + 6 * uMantissa / 100000000000000000 + 5 * uMantissa / 1000000000000000000 
                            + 5 * uMantissa / 10000000000000000000 + 0 * uMantissa / 100000000000000000000 + 4 * uMantissa / 1000000000000000000000;    
                }
            }
        }
    }

    function calculateQ3(uint256 uMantissa) public pure returns(int256 q3, uint256 updatedMantissa) {
        if(uMantissa > (991129567482 * 10**64)) {
            if(uMantissa > (993708179366 * 10**64)) {
                if(uMantissa > (995 * 10**73)) {
                    q3 = 0;
                    // multiplier_q3 = 1
                    updatedMantissa = uMantissa;
                } else {
                    q3 = 1;
                    // multiplier_q3 = 1.0013
                    updatedMantissa = uMantissa + 0 * uMantissa / 10 + 0 * uMantissa / 100 + 1 * uMantissa / 1000 + 3 * uMantissa / 10000;
                }
            } else {
                if(uMantissa > (992418035920 * 10**64)) {
                    q3 = 2;
                    // multiplier_q3 = 1.00260169
                    updatedMantissa = uMantissa + 0 * uMantissa / 10 + 0 * uMantissa / 100 + 2 * uMantissa / 1000 + 6 * uMantissa / 10000 
                                + 0 * uMantissa / 100000 + 1 * uMantissa / 1000000 + 6 * uMantissa / 10000000 + 9 * uMantissa / 100000000;
                } else {
                    q3 = 3;
                    // multiplier_q3 = 1.003905072197
                    updatedMantissa = uMantissa + 0 * uMantissa / 10 + 0 * uMantissa / 100 + 3 * uMantissa / 1000 + 9 * uMantissa / 10000 
                                + 0 * uMantissa / 100000 + 5 * uMantissa / 1000000 + 0 * uMantissa / 10000000 + 7 * uMantissa / 100000000 
                                + 2 * uMantissa / 1000000000 + 1 * uMantissa / 10000000000 + 9 * uMantissa / 100000000000 + 7 * uMantissa / 1000000000000; 
                }
            }
        } else {
            if(uMantissa > (988557646937 * 10**64)) {
                if(uMantissa > (989842771878 * 10**64)) {
                    q3 = 4;
                    // multiplier_q3 = 1.0052101487908561
                    updatedMantissa = uMantissa + 0 * uMantissa / 10 + 0 * uMantissa / 100 + 5 * uMantissa / 1000 + 2 * uMantissa / 10000 
                                + 1 * uMantissa / 100000 + 0 * uMantissa / 1000000 + 1 * uMantissa / 10000000 + 4 * uMantissa / 100000000 
                                + 8 * uMantissa / 1000000000 + 7 * uMantissa / 10000000000 + 9 * uMantissa / 100000000000 + 0 * uMantissa / 1000000000000 
                                + 8 * uMantissa / 10000000000000 + 5 * uMantissa / 100000000000000 + 6 * uMantissa / 1000000000000000 + 1 * uMantissa / 10000000000000000;
                } else {
                    q3 = 5;
                    // multiplier_q3 = 1.00651692198428421293
                    updatedMantissa = uMantissa + 0 * uMantissa / 10 + 0 * uMantissa / 100 + 6 * uMantissa / 1000 + 5 * uMantissa / 10000 
                                + 1 * uMantissa / 100000 + 6 * uMantissa / 1000000 + 9 * uMantissa / 10000000 + 2 * uMantissa / 100000000 
                                + 1 * uMantissa / 1000000000 + 9 * uMantissa / 10000000000 + 8 * uMantissa / 100000000000 + 4 * uMantissa / 1000000000000 
                                + 2 * uMantissa / 10000000000000 + 8 * uMantissa / 100000000000000 + 4 * uMantissa / 1000000000000000 + 2 * uMantissa / 10000000000000000 
                                + 1 * uMantissa / 100000000000000000 + 2 * uMantissa / 1000000000000000000 + 9 * uMantissa / 10000000000000000000 + 3 * uMantissa / 100000000000000000000; 
                }
            } else {
                if(uMantissa > (987274190490 * 10**64)) {
                    q3 = 6;
                    // multiplier_q3 = 1.007825393982863782406809
                    updatedMantissa = uMantissa + 0 * uMantissa / 10 + 0 * uMantissa / 100 + 7 * uMantissa / 1000 + 8 * uMantissa / 10000 
                                + 2 * uMantissa / 100000 + 5 * uMantissa / 1000000 + 3 * uMantissa / 10000000 + 9 * uMantissa / 100000000 
                                + 3 * uMantissa / 1000000000 + 9 * uMantissa / 10000000000 + 8 * uMantissa / 100000000000 + 2 * uMantissa / 1000000000000 
                                + 8 * uMantissa / 10000000000000 + 6 * uMantissa / 100000000000000 + 3 * uMantissa / 1000000000000000 + 7 * uMantissa / 10000000000000000 
                                + 8 * uMantissa / 100000000000000000 + 2 * uMantissa / 1000000000000000000 + 4 * uMantissa / 10000000000000000000 + 0 * uMantissa / 100000000000000000000 
                                + 6 * uMantissa / 1000000000000000000000 + 8 * uMantissa / 10000000000000000000000 + 0 * uMantissa / 100000000000000000000000 + 9 * uMantissa / 1000000000000000000000000;  
                } else {
                    q3 = 7;
                    // multiplier_q3 = 1.0091355669950415053239378517
                    updatedMantissa = uMantissa + 0 * uMantissa / 10 + 0 * uMantissa / 100 + 9 * uMantissa / 1000 + 1 * uMantissa / 10000 
                                + 3 * uMantissa / 100000 + 5 * uMantissa / 1000000 + 5 * uMantissa / 10000000 + 6 * uMantissa / 100000000 
                                + 6 * uMantissa / 1000000000 + 9 * uMantissa / 10000000000 + 9 * uMantissa / 100000000000 + 5 * uMantissa / 1000000000000 
                                + 0 * uMantissa / 10000000000000 + 4 * uMantissa / 100000000000000 + 1 * uMantissa / 1000000000000000 + 5 * uMantissa / 10000000000000000 
                                + 0 * uMantissa / 100000000000000000 + 5 * uMantissa / 1000000000000000000 + 3 * uMantissa / 10000000000000000000 + 2 * uMantissa / 100000000000000000000 
                                + 3 * uMantissa / 1000000000000000000000 + 9 * uMantissa / 10000000000000000000000 + 3 * uMantissa / 100000000000000000000000 + 7 * uMantissa / 1000000000000000000000000 
                                + 8 * uMantissa / 10000000000000000000000000 + 5 * uMantissa / 100000000000000000000000000 + 1 * uMantissa / 1000000000000000000000000000 + 7 * uMantissa / 10000000000000000000000000000; 
                }
            }
        }
    }
}
