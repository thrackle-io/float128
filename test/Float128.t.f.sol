/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/console2.sol";
import "src/Float128.sol";
import "test/FloatUtils.sol";

contract Float128FuzzTest is FloatUtils {
    using Float128 for int256;
    using Float128 for packedFloat;

    function checkResults(int rMan, int rExp, int pyMan, int pyExp) internal pure {
        checkResults(packedFloat.wrap(0), rMan, rExp, pyMan, pyExp, false);
    }

    function checkResults(int rMan, int rExp, int pyMan, int pyExp, bool couldBeOffBy1) internal pure {
        checkResults(packedFloat.wrap(0), rMan, rExp, pyMan, pyExp, couldBeOffBy1);
    }

    function checkResults(packedFloat r, int rMan, int rExp, int pyMan, int pyExp, bool couldBeOffBy1) internal pure {
        console2.log("solResult", packedFloat.unwrap(r));
        console2.log("rMan", rMan);
        console2.log("rExp", rExp);
        console2.log("pyMan", pyMan);
        console2.log("pyExp", pyExp);
        bool isLarge = packedFloat.unwrap(r) & Float128.MANTISSA_L_FLAG_MASK > 0;
        console2.log("isLarge", isLarge);
        // we always check that the result is normalized since this is vital for the library. Only exception is when the result is zero
        uint nDigits = findNumberOfDigits(uint(rMan < 0 ? rMan * -1 : rMan));
        console2.log("nDigits", nDigits);
        if (pyMan != 0) assertTrue(((nDigits == 38) || (nDigits == 72)), "Solidity result is not normalized");
        if (packedFloat.unwrap(r) != 0) nDigits == 38 ? assertFalse(isLarge) : assertTrue(isLarge);
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

    function testEncoded_mul(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "mul", 0);
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);

        packedFloat result = Float128.mul(a, b);
        (int rMan, int rExp) = Float128.decode(result);

        checkResults(result, rMan, rExp, pyMan, pyExp, false);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testEncoded_div(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan == 0 ? int(1) : bMan, bExp, "div", 0);
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);
        console2.log("packedFloat a", packedFloat.unwrap(a));
        console2.log("packedFloat b", packedFloat.unwrap(b));
        if (bMan == 0) {
            vm.expectRevert("float128: division by zero");
        }
        packedFloat result = Float128.div(a, b);
        if (bMan != 0) {
            (int rMan, int rExp) = Float128.decode(result);

            checkResults(result, rMan, rExp, pyMan, pyExp, false);
        }
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testEncoded_divL(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan == 0 ? int(1) : bMan, bExp, "div", 1);
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);
        console2.log("packedFloat a", packedFloat.unwrap(a));
        console2.log("packedFloat b", packedFloat.unwrap(b));
        if (bMan == 0) {
            vm.expectRevert("float128: division by zero");
        }
        packedFloat result = Float128.divL(a, b);
        if (bMan != 0) {
            (int rMan, int rExp) = Float128.decode(result);

            checkResults(result, rMan, rExp, pyMan, pyExp, false);
        }
    }

    function testEncoded_add(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "add", 0);
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);

        packedFloat result = Float128.add(a, b);
        (int rMan, int rExp) = Float128.decode(result);

        checkResults(result, rMan, rExp, pyMan, pyExp, true);
    }

    function testEncoded_sub(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "sub", 0);
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);

        packedFloat result = Float128.sub(a, b);
        (int rMan, int rExp) = Float128.decode(result);

        checkResults(result, rMan, rExp, pyMan, pyExp, true);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testEncoded_sqrt(int aMan, int aExp) public {
        (aMan, aExp, , ) = setBounds(aMan, aExp, 0, 0);
        aExp = bound(aExp, -74, 1); // TODO increse this when finishing sqrt
        string[] memory inputs = _buildFFIMul128(aMan < 0 ? aMan * -1 : aMan, aExp, 0, 0, "sqrt", 0);
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
        packedFloat a = Float128.toPackedFloat(aMan, aExp);

        if (aMan < 0) {
            vm.expectRevert("float128: squareroot of negative");
        }
        packedFloat result = Float128.sqrt(a);
        if (aMan >= 0) {
            (int rMan, int rExp) = Float128.decode(result);

            checkResults(result, rMan, rExp, pyMan, pyExp, false);
        }
    }

    function testLEpackedFloatFuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        packedFloat pA = Float128.toPackedFloat(aMan, aExp);
        packedFloat pB = Float128.toPackedFloat(bMan, bExp);
        bool retVal = Float128.le(pA, pB);
        console2.log("retVal", retVal);

        // Creating the float struct to normalize the mantissas and exponents before doing the comparison
        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "le", 0);
        bytes memory res = vm.ffi(inputs);
        (int pyMan, ) = abi.decode((res), (int256, int256));
        bool pyRes = pyMan > 0;
        assertEq(retVal, pyRes);
    }

    function testLTpackedFloatFuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        packedFloat pA = Float128.toPackedFloat(aMan, aExp);
        packedFloat pB = Float128.toPackedFloat(bMan, bExp);
        bool retVal = Float128.lt(pA, pB);
        console2.log("retVal", retVal);

        // Creating the float struct to normalize the mantissas and exponents before doing the comparison
        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "lt", 0);
        bytes memory res = vm.ffi(inputs);
        (int pyMan, ) = abi.decode((res), (int256, int256));
        bool pyRes = pyMan > 0;
        assertEq(retVal, pyRes);
    }

    function testGTpackedFloatFuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        packedFloat pA = Float128.toPackedFloat(aMan, aExp);
        packedFloat pB = Float128.toPackedFloat(bMan, bExp);
        bool retVal = Float128.gt(pA, pB);
        console2.log("retVal", retVal);

        // Creating the float struct to normalize the mantissas and exponents before doing the comparison
        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "gt", 0);
        bytes memory res = vm.ffi(inputs);
        (int pyMan, ) = abi.decode((res), (int256, int256));
        bool pyRes = pyMan > 0;
        assertEq(retVal, pyRes);
    }

    function testGEpackedFloatFuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        packedFloat pA = Float128.toPackedFloat(aMan, aExp);
        packedFloat pB = Float128.toPackedFloat(bMan, bExp);
        bool retVal = Float128.ge(pA, pB);
        console2.log("retVal", retVal);

        // Creating the float struct to normalize the mantissas and exponents before doing the comparison
        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "ge", 0);
        bytes memory res = vm.ffi(inputs);
        (int pyMan, ) = abi.decode((res), (int256, int256));
        bool pyRes = pyMan > 0;
        assertEq(retVal, pyRes);
    }

    function testToPackedFloatFuzz(int256 man, int256 exp) public pure {
        (man, exp, , ) = setBounds(man, exp, 0, 0);

        packedFloat float = man.toPackedFloat(exp);
        (int manDecode, int expDecode) = Float128.decode(float);
        packedFloat comp = manDecode.toPackedFloat(expDecode - exp);

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

    function testLNPREC() public view {
        // int mantissa = 10000000000001;
        // int exponent = -13;
        int mantissa = 471738548555985204842829168083810940950366912454141453216936305944405297084;
        int exponent = -76;
        packedFloat retVal = Float128.ln_prec(mantissa, exponent);
        (int mantissaF, int exponentF) = Float128.decode(retVal);
        console2.log("mantissaF: ", mantissaF);
        console2.log("exponentF: ", exponentF);
    }
}
