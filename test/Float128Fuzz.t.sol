/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/console2.sol";
import "src/Float128.sol";
import "test/FloatUtils.sol";

contract Float128FuzzTest is FloatUtils {
    using Float128 for int256;

    function checkResults(int rMan, int rExp, int pyMan, int pyExp) internal pure {
        checkResults(rMan, rExp, pyMan, pyExp, false);
    }

    function checkResults(int rMan, int rExp, int pyMan, int pyExp, bool couldBeOffBy1) internal pure {
        // we always check that the result is normalized since this is vital for the library. Only exception is when the result is zero
        if (pyMan != 0) assertEq(findNumberOfDigits(uint(rMan < 0 ? rMan * -1 : rMan)), 38, "Solidity result is not normalized");
        // we fix the python result due to the imprecision of python's log10. We cut precision where needed
        if (pyExp != rExp) {
            if (pyExp > rExp) {
                ++rExp;
                rMan /= 10;
            } else {
                ++pyExp;
                pyMan /= 10;
            }
        }
        // we only accept off by 1 if explicitly signaled. (addition/subtraction are famous for rounding difference with Python)
        if (couldBeOffBy1) {
            // we could be off by one due to rounding issues. The error should be less than 1/1e76
            if (pyMan != rMan) {
                if (pyMan > rMan) assertEq(pyMan, rMan + 1);
                else assertEq(pyMan + 1, rMan);
            }
        } else {
            assertEq(pyMan, rMan);
        }
        if (pyMan != 0) assertEq(pyExp, rExp);
    }
    function testStruct_mul(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "mul");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        Float memory result = Float128.mul(aMan.toFloat(aExp), bMan.toFloat(bExp));

        int rMan = result.mantissa;
        int rExp = result.exponent;

        checkResults(rMan, rExp, pyMan, pyExp);
    }

    function testEncoded_mul(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "mul");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);

        packedFloat result = Float128.mul(a, b);
        (int rMan, int rExp) = Float128.decode(result);

        checkResults(rMan, rExp, pyMan, pyExp);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testStruct_div(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan == 0 ? int(1) : bMan, bExp, "div");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        Float memory aFloat = aMan.toFloat(aExp);
        Float memory bFloat = bMan.toFloat(bExp);
        if (bMan == 0) {
            vm.expectRevert("float128: division by zero");
        }
        Float memory result = Float128.div(aFloat, bFloat);
        if (bMan != 0) {
            int rMan = result.mantissa;
            int rExp = result.exponent;

            checkResults(rMan, rExp, pyMan, pyExp);
        }
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testEncoded_div(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan == 0 ? int(1) : bMan, bExp, "div");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);
        if (bMan == 0) {
            vm.expectRevert("float128: division by zero");
        }
        packedFloat result = Float128.div(a, b);
        if (bMan != 0) {
            (int rMan, int rExp) = Float128.decode(result);

            checkResults(rMan, rExp, pyMan, pyExp);
        }
    }

    function testEncoded_add(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "add");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);

        packedFloat result = Float128.add(a, b);
        (int rMan, int rExp) = Float128.decode(result);

        checkResults(rMan, rExp, pyMan, pyExp, true);
    }

    function testStruct_add(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "add");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        Float memory result = Float128.add(aMan.toFloat(aExp), bMan.toFloat(bExp));
        int rMan = result.mantissa;
        int rExp = result.exponent;

        checkResults(rMan, rExp, pyMan, pyExp, true);
    }

    function testEncoded_sub(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "sub");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);

        packedFloat result = Float128.sub(a, b);
        (int rMan, int rExp) = Float128.decode(result);

        checkResults(rMan, rExp, pyMan, pyExp, true);
    }

    function testStruct_sub(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "sub");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        Float memory result = Float128.sub(aMan.toFloat(aExp), bMan.toFloat(bExp));
        int rMan = result.mantissa;
        int rExp = result.exponent;
        if (pyMan != 0) assertEq(findNumberOfDigits(uint(rMan < 0 ? rMan * -1 : rMan)), 38, "Solidity result is not normalized");

        checkResults(rMan, rExp, pyMan, pyExp, true);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testEncoded_sqrt(int aMan, int aExp) public {
        (aMan, aExp, , ) = setBounds(aMan, aExp, 0, 0);
        string[] memory inputs = _buildFFIMul128(aMan < 0 ? aMan * -1 : aMan, aExp, 0, 0, "sqrt");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
        packedFloat a = Float128.toPackedFloat(aMan, aExp);

        if (aMan < 0) {
            vm.expectRevert("float128: squareroot of negative");
        }
        packedFloat result = Float128.sqrt(a);
        if (aMan >= 0) {
            (int rMan, int rExp) = Float128.decode(result);

            checkResults(rMan, rExp, pyMan, pyExp);
        }
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testStruct_sqrt(int aMan, int aExp) public {
        (aMan, aExp, , ) = setBounds(aMan, aExp, 0, 0);

        string[] memory inputs = _buildFFIMul128(aMan < 0 ? aMan * -1 : aMan, aExp, 0, 0, "sqrt");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        if (aMan < 0) {
            vm.expectRevert("float128: squareroot of negative");
        }
        Float memory result = Float128.sqrt(aMan.toFloat(aExp));
        int rMan = result.mantissa;
        int rExp = result.exponent;

        checkResults(rMan, rExp, pyMan, pyExp);
    }

    function testLTFloatFuzz(int aMan, int aExp, int bMan, int bExp) public pure {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        Float memory a = Float128.toFloat(aMan, aExp);
        Float memory b = Float128.toFloat(bMan, bExp);
        bool retVal = Float128.lt(a, b);
        bool comparison = false;

        if(a.mantissa == 0 || b.mantissa == 0) {
            if(a.mantissa == 0 && b.mantissa == 0) {
                comparison = false;
            } else if(a.mantissa == 0) {
                if(b.mantissa > 0) {
                    comparison = true;
                }
            } else {
                if(a.mantissa < 0) {
                    comparison = true;
                } 
            }
        } else {
            if(a.exponent < b.exponent) {
                comparison = true;
            } else if(b.exponent < a.exponent) {
                comparison = false;
            } else {
                comparison = a.mantissa < b.mantissa;
            }
        }
        assertEq(retVal, comparison);
    }

    function testLEFloatFuzz(int aMan, int aExp, int bMan, int bExp) public pure {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        Float memory a = Float128.toFloat(aMan, aExp);
        Float memory b = Float128.toFloat(bMan, bExp);
        bool retVal = Float128.le(a, b);
        bool comparison = false;

        if(a.mantissa == 0 || b.mantissa == 0) {
            if(a.mantissa == 0 && b.mantissa == 0) {
                comparison = true;
            } else if(a.mantissa == 0) {
                if(b.mantissa > 0) {
                    comparison = true;
                }
            } else {
                if(a.mantissa < 0) {
                    comparison = true;
                } 
            }
        } else {
            if(a.exponent < b.exponent) {
                comparison = true;
            } else if(b.exponent < a.exponent) {
                comparison = false;
            } else {
                comparison = a.mantissa <= b.mantissa;
            }
        }
        assertEq(retVal, comparison);
    }

    function testGTFloatFuzz(int aMan, int aExp, int bMan, int bExp) public pure {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        Float memory a = Float128.toFloat(aMan, aExp);
        Float memory b = Float128.toFloat(bMan, bExp);
        bool retVal = Float128.gt(a, b);
        bool comparison = false;

        if(a.mantissa == 0 || b.mantissa == 0) {
            if(a.mantissa == 0 && b.mantissa == 0) {
                comparison = false;
            } else if(a.mantissa == 0) {
                if(b.mantissa < 0) {
                    comparison = true;
                }
            } else {
                if(a.mantissa > 0) {
                    comparison = true;
                } 
            }
        } else {
            if(a.exponent > b.exponent) {
                comparison = true;
            } else if(b.exponent > a.exponent) {
                comparison = false;
            } else {
                comparison = a.mantissa > b.mantissa;
            }
        }
        assertEq(retVal, comparison);
    }

    function testGEFloatFuzz(int aMan, int aExp, int bMan, int bExp) public pure {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        Float memory a = Float128.toFloat(aMan, aExp);
        Float memory b = Float128.toFloat(bMan, bExp);
        bool retVal = Float128.ge(a, b);
        bool comparison = false;

        if(a.mantissa == 0 || b.mantissa == 0) {
            if(a.mantissa == 0 && b.mantissa == 0) {
                comparison = true;
            } else if(a.mantissa == 0) {
                if(b.mantissa < 0) {
                    comparison = true;
                }
            } else {
                if(a.mantissa > 0) {
                    comparison = true;
                } 
            }
        } else {
            if(a.exponent > b.exponent) {
                comparison = true;
            } else if(b.exponent > a.exponent) {
                comparison = false;
            } else {
                comparison = a.mantissa >= b.mantissa;
            }
        }
        assertEq(retVal, comparison);
    }

    function testLTpackedFloatFuzz(int aMan, int aExp, int bMan, int bExp) public pure {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        packedFloat pA = Float128.toPackedFloat(aMan, aExp);
        packedFloat pB = Float128.toPackedFloat(bMan, bExp);
        bool retVal = Float128.lt(pA, pB);
        bool comparison = false;

        // Creating the float struct to normalize the mantissas and exponents before doing the comparison
        Float memory floA = Float128.toFloat(aMan, aExp);
        Float memory floB = Float128.toFloat(bMan, bExp);

        if(floA.mantissa == 0 || floB.mantissa == 0) {
            if(floA.mantissa == 0 && floB.mantissa == 0) {
                comparison = false;
            } else if(floA.mantissa == 0) {
                if(floB.mantissa > 0) {
                    comparison = true;
                } else {
                    comparison = false;
                }
            } else {
                if(floA.mantissa > 0) {
                    comparison = false;
                } else {
                    comparison = true;
                }
            }
        } else {
            if(floA.exponent < floB.exponent) {
                comparison = true;
            } else if(floB.exponent < floA.exponent) {
                comparison = false;
            } else {
                comparison = floA.mantissa < floB.mantissa;
            }
        }
        assertEq(retVal, comparison);
    }

    function testLEpackedFloatFuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        packedFloat pA = Float128.toPackedFloat(aMan, aExp);
        packedFloat pB = Float128.toPackedFloat(bMan, bExp);
        bool retVal = Float128.le(pA, pB);
        console2.log("retVal", retVal);

        // Creating the float struct to normalize the mantissas and exponents before doing the comparison
        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "le");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
        bool pyRes = pyMan > 0;
        assertEq(retVal, pyRes);
    }

    function testGTpackedFloatFuzz(int aMan, int aExp, int bMan, int bExp) public pure {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        packedFloat pA = Float128.toPackedFloat(aMan, aExp);
        packedFloat pB = Float128.toPackedFloat(bMan, bExp);
        bool retVal = Float128.gt(pA, pB);
        bool comparison = false;

        // Creating the float struct to normalize the mantissas and exponents before doing the comparison
        Float memory floA = Float128.toFloat(aMan, aExp);
        Float memory floB = Float128.toFloat(bMan, bExp);

       if(floA.mantissa == 0 || floB.mantissa == 0) {
            if(floA.mantissa == 0 && floB.mantissa == 0) {
                comparison = false;
            } else if(floA.mantissa == 0) {
                if(floB.mantissa < 0) {
                    comparison = true;
                } else {
                    comparison = false;
                }
            } else {
                if(floA.mantissa < 0) {
                    comparison = false;
                } else {
                    comparison = true;
                }
            }
        } else {
            if(floA.exponent > floB.exponent) {
                comparison = true;
            } else if(floB.exponent > floA.exponent) {
                comparison = false;
            } else {
                comparison = floA.mantissa > floB.mantissa;
            }
        }
        assertEq(retVal, comparison);
    }

    function testGEpackedFloatFuzz(int aMan, int aExp, int bMan, int bExp) public pure {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        packedFloat pA = Float128.toPackedFloat(aMan, aExp);
        packedFloat pB = Float128.toPackedFloat(bMan, bExp);
        bool retVal = Float128.ge(pA, pB);
        bool comparison = false;

        // Creating the float struct to normalize the mantissas and exponents before doing the comparison
        Float memory floA = Float128.toFloat(aMan, aExp);
        Float memory floB = Float128.toFloat(bMan, bExp);

       if(floA.mantissa == 0 || floB.mantissa == 0) {
            if(floA.mantissa == 0 && floB.mantissa == 0) {
                comparison = true;
            } else if(floA.mantissa == 0) {
                if(floB.mantissa < 0) {
                    comparison = true;
                } else {
                    comparison = false;
                }
            } else {
                if(floA.mantissa < 0) {
                    comparison = false;
                } else {
                    comparison = true;
                }
            }
        } else {
            if(floA.exponent > floB.exponent) {
                comparison = true;
            } else if(floB.exponent > floA.exponent) {
                comparison = false;
            } else {
                comparison = floA.mantissa >= floB.mantissa;
            }
        }
        assertEq(retVal, comparison);
    }

    function testToFloatFuzz(int256 man, int256 exp) public pure {
        (man, exp, , ) = setBounds(man, exp, 0, 0);

        Float memory float = man.toFloat(exp);
        float.exponent = float.exponent - exp;

        int256 retVal = 0;
        if (man != 0) {
            retVal = _reverseNormalize(float);
        }
        assertEq(man, retVal);
    }

    function testToPackedFloatFuzz(int256 man, int256 exp) public pure {
        (man, exp, , ) = setBounds(man, exp, 0, 0);

        packedFloat float = man.toPackedFloat(exp);
        (int manDecode, int expDecode) = Float128.decode(float);
        Float memory comp;
        comp.mantissa = manDecode;
        comp.exponent = expDecode;
        comp.exponent -= exp;

        int256 retVal = 0;
        if (man != 0) {
            retVal = _reverseNormalize(comp);
        }
        assertEq(man, retVal);
    }

    function testConvertToUnpackedFloatFuzz(int256 man, int256 exp) public pure {
        (man, exp, , ) = setBounds(man, exp, 0, 0);

        packedFloat float = man.toPackedFloat(exp);
        Float memory unpacked = Float128.convertToUnpackedFloat(float);
        unpacked.exponent -= exp;

        int256 retVal = 0;
        if (man != 0) {
            retVal = _reverseNormalize(unpacked);
        }
        assertEq(man, retVal);
    }

    function testConvertToPackedFloatFuzz(int256 man, int256 exp) public pure {
        (man, exp, , ) = setBounds(man, exp, 0, 0);

        Float memory unpacked = Float128.toFloat(man, exp);
        packedFloat packed = Float128.convertToPackedFloat(unpacked);

        (int manDecode, int expDecode) = Float128.decode(packed);

        Float memory comp;
        comp.mantissa = manDecode;
        comp.exponent = expDecode;
        comp.exponent -= exp;

        int256 retVal = 0;
        if (man != 0) {
            retVal = _reverseNormalize(comp);
        }

        assertEq(man, retVal);
    }

    function testConvertToNormalizeFuzz(int256 man, int256 exp) public pure {
        (man, exp, , ) = setBounds(man, exp, 0, 0);

        Float memory initial;
        initial.mantissa = man;
        initial.exponent = exp;
        Float memory comp = Float128.normalize(initial);
        comp.exponent -= exp;

        int256 retVal = 0;
        if (man != 0) {
            retVal = _reverseNormalize(comp);
        }

        assertEq(man, retVal);
    }

    function testFindNumbeOfDigits(uint256 man) public pure {
        console2.log(man);
        uint256 comparison = 1;
        uint256 iter = 0;
        while (comparison <= man) {
            comparison *= 10;
            iter += 1;
            if (comparison == 1e77 && comparison < man) {
                iter += 1;
                break;
            }
        }

        uint256 retVal = Float128.findNumberOfDigits(man);

        assertEq(iter, retVal);
    }

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
