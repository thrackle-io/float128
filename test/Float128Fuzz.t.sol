/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "test/FloatCommon.sol";
import "forge-std/console2.sol";
import "src/Float128.sol";
import {Ln} from "src/Ln.sol";
import "test/FloatUtils.sol";

contract Float128FuzzTest is FloatCommon {
    using Float128 for int256;
    using Float128 for packedFloat;
    using Ln for packedFloat;

    function checkResults(int rMan, int rExp, int pyMan, int pyExp) internal pure {
        checkResults(packedFloat.wrap(0), rMan, rExp, pyMan, pyExp, 0);
    }

    function checkResults(int rMan, int rExp, int pyMan, int pyExp, uint _ulpsOfTolerance) internal pure {
        checkResults(packedFloat.wrap(0), rMan, rExp, pyMan, pyExp, _ulpsOfTolerance);
    }

    function checkResults(packedFloat r, int rMan, int rExp, int pyMan, int pyExp, uint _ulpsOfTolerance) internal pure {
        int ulpsOfTolerance = int(_ulpsOfTolerance);
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
        if (pyMan == 0) {
            assertEq(rMan, 0, "Solidity result is not zero");
            assertEq(rExp, ZERO_OFFSET_NEG, "Solidity result is not zero");
        }
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
        if (ulpsOfTolerance > 0) {
            // we could be off by one due to rounding issues. The error should be less than 1/1e76
            if (pyMan != rMan) {
                console2.log("ulpsOfTolerance", ulpsOfTolerance);
                if (pyMan > rMan) assertLe(pyMan, rMan + ulpsOfTolerance);
                else assertGe(pyMan + ulpsOfTolerance, rMan);
            }
        } else {
            assertEq(pyMan, rMan);
        }
        if (pyMan != 0) assertEq(pyExp, rExp);
    }

    function testEncoded_add_maliciousEncoding(uint8 distanceFromExpBound) public {
        int bExp = 0;
        int bMan = 1;
        packedFloat b = bMan.toPackedFloat(bExp);
        {
            // very negative exponent
            uint encodedNegativeExp = uint(distanceFromExpBound) << Float128.EXPONENT_BIT;
            uint maliciousMantissa = 1;
            int aMan = int(maliciousMantissa);
            uint maliciousFloatEncoded = encodedNegativeExp | maliciousMantissa;
            int aExp = int(uint(distanceFromExpBound)) - int(Float128.ZERO_OFFSET);
            packedFloat a = packedFloat.wrap(maliciousFloatEncoded);
            if (distanceFromExpBound < Float128.MAX_DIGITS_M_X_2) vm.expectRevert("float128: underflow");
            packedFloat result = a.add(b);
            string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "add", 0);
            bytes memory res = vm.ffi(inputs);
            (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
            (int rMan, int rExp) = Float128.decode(result);

            checkResults(result, rMan, rExp, pyMan, pyExp, 1);
        }
        {
            // very positive exponent
            /// @notice there is no overflow risk since normalization can only make the exponent smaller. Never bigger.
            uint encodedPositiveExp = ((2 ** 14 - 1) - uint(distanceFromExpBound)) << Float128.EXPONENT_BIT;
            int aMan = int(1e71);
            uint maliciousFloatEncoded = encodedPositiveExp | uint(aMan) | Float128.MANTISSA_L_FLAG_MASK;
            int aExp = int(Float128.ZERO_OFFSET) - int(uint(distanceFromExpBound)) - 1;
            packedFloat a = packedFloat.wrap(maliciousFloatEncoded);

            packedFloat result = a.add(b);
            string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "add", 0);
            bytes memory res = vm.ffi(inputs);
            (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
            (int rMan, int rExp) = Float128.decode(result);
            checkResults(result, rMan, rExp, pyMan, pyExp, 1);
        }
    }

    function testEncoded_sub_maliciousEncoding(uint8 distanceFromExpBound) public {
        int bExp = 0;
        int bMan = 1;
        packedFloat b = bMan.toPackedFloat(bExp);
        {
            // very negative exponent
            uint encodedNegativeExp = uint(distanceFromExpBound) << Float128.EXPONENT_BIT;
            uint maliciousMantissa = 1;
            int aMan = int(maliciousMantissa);
            uint maliciousFloatEncoded = encodedNegativeExp | maliciousMantissa;
            int aExp = int(uint(distanceFromExpBound)) - int(Float128.ZERO_OFFSET);
            packedFloat a = packedFloat.wrap(maliciousFloatEncoded);
            if (distanceFromExpBound < Float128.MAX_DIGITS_M_X_2) vm.expectRevert("float128: underflow");
            packedFloat result = a.sub(b);
            string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "sub", 0);
            bytes memory res = vm.ffi(inputs);
            (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
            (int rMan, int rExp) = Float128.decode(result);

            checkResults(result, rMan, rExp, pyMan, pyExp, 1);
        }
        {
            // very positive exponent
            /// @notice there is no overflow risk since normalization can only make the exponent smaller. Never bigger.
            uint encodedPositiveExp = ((2 ** 14 - 1) - uint(distanceFromExpBound)) << Float128.EXPONENT_BIT;
            int aMan = int(1e71);
            uint maliciousFloatEncoded = encodedPositiveExp | uint(aMan) | Float128.MANTISSA_L_FLAG_MASK;
            int aExp = int(Float128.ZERO_OFFSET) - int(uint(distanceFromExpBound)) - 1;
            packedFloat a = packedFloat.wrap(maliciousFloatEncoded);

            packedFloat result = a.sub(b);
            string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "sub", 0);
            bytes memory res = vm.ffi(inputs);
            (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
            (int rMan, int rExp) = Float128.decode(result);
            checkResults(result, rMan, rExp, pyMan, pyExp, 1);
        }
    }

    function testEncoded_mul_maliciousEncoding(uint8 distanceFromExpBound) public {
        int bExp = 0;
        int bMan = 1;
        packedFloat b = bMan.toPackedFloat(bExp);
        {
            // very negative exponent
            uint encodedNegativeExp = uint(distanceFromExpBound) << Float128.EXPONENT_BIT;
            uint maliciousMantissa = 1e37;
            int aMan = int(maliciousMantissa);
            uint maliciousFloatEncoded = encodedNegativeExp | maliciousMantissa;
            int aExp = int(uint(distanceFromExpBound)) - int(Float128.ZERO_OFFSET);
            packedFloat a = packedFloat.wrap(maliciousFloatEncoded);
            if (distanceFromExpBound < Float128.MAX_DIGITS_M_X_2) vm.expectRevert("float128: underflow");
            packedFloat result = a.mul(b);
            string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "mul", 0);
            bytes memory res = vm.ffi(inputs);
            (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
            (int rMan, int rExp) = Float128.decode(result);

            checkResults(result, rMan, rExp, pyMan, pyExp, 1);
        }
        {
            // very positive exponent
            /// @notice there is no overflow risk since normalization can only make the exponent smaller. Never bigger.
            uint encodedPositiveExp = ((2 ** 14 - 1) - uint(distanceFromExpBound)) << Float128.EXPONENT_BIT;
            int aMan = int(1e71);
            uint maliciousFloatEncoded = encodedPositiveExp | uint(aMan) | Float128.MANTISSA_L_FLAG_MASK;
            int aExp = int(Float128.ZERO_OFFSET) - int(uint(distanceFromExpBound)) - 1;
            packedFloat a = packedFloat.wrap(maliciousFloatEncoded);

            packedFloat result = a.mul(b);
            string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "mul", 0);
            bytes memory res = vm.ffi(inputs);
            (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
            (int rMan, int rExp) = Float128.decode(result);
            checkResults(result, rMan, rExp, pyMan, pyExp, 1);
        }
    }

    function testEncoded_div_maliciousEncoding(uint8 distanceFromExpBound) public {
        int bExp = 0;
        int bMan = 1;
        packedFloat b = bMan.toPackedFloat(bExp);
        {
            // very negative exponent
            uint encodedNegativeExp = uint(distanceFromExpBound) << Float128.EXPONENT_BIT;
            uint maliciousMantissa = 1e37;
            int aMan = int(maliciousMantissa);
            uint maliciousFloatEncoded = encodedNegativeExp | maliciousMantissa;
            int aExp = int(uint(distanceFromExpBound)) - int(Float128.ZERO_OFFSET);
            packedFloat a = packedFloat.wrap(maliciousFloatEncoded);
            if (distanceFromExpBound < Float128.MAX_DIGITS_M_X_2) vm.expectRevert("float128: underflow");
            packedFloat result = a.div(b);
            string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "div", 0);
            bytes memory res = vm.ffi(inputs);
            (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
            (int rMan, int rExp) = Float128.decode(result);

            checkResults(result, rMan, rExp, pyMan, pyExp, 1);
        }
        {
            // very positive exponent
            /// @notice there is no overflow risk since normalization can only make the exponent smaller. Never bigger.
            uint encodedPositiveExp = ((2 ** 14 - 1) - uint(distanceFromExpBound)) << Float128.EXPONENT_BIT;
            int aMan = int(1e71);
            uint maliciousFloatEncoded = encodedPositiveExp | uint(aMan) | Float128.MANTISSA_L_FLAG_MASK;
            int aExp = int(Float128.ZERO_OFFSET) - int(uint(distanceFromExpBound)) - 1;
            packedFloat a = packedFloat.wrap(maliciousFloatEncoded);

            packedFloat result = a.div(b);
            string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "div", 0);
            bytes memory res = vm.ffi(inputs);
            (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
            (int rMan, int rExp) = Float128.decode(result);
            checkResults(result, rMan, rExp, pyMan, pyExp, 1);
        }
    }

    function testEncoded_sqrt_maliciousEncoding(uint8 distanceFromExpBound) public {
        {
            // very negative exponent
            /// @notice the way sqrt handles the exponent makes it impossible for it to underflow
            uint encodedNegativeExp = uint(distanceFromExpBound) << Float128.EXPONENT_BIT;
            uint maliciousMantissa = 1e37;
            int aMan = int(maliciousMantissa);
            uint maliciousFloatEncoded = encodedNegativeExp | maliciousMantissa;
            int aExp = int(uint(distanceFromExpBound)) - int(Float128.ZERO_OFFSET);
            packedFloat a = packedFloat.wrap(maliciousFloatEncoded);
            packedFloat result = a.sqrt();
            string[] memory inputs = _buildFFIMul128(aMan, aExp, 0, 0, "sqrt", 0);
            bytes memory res = vm.ffi(inputs);
            (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
            (int rMan, int rExp) = Float128.decode(result);
            checkResults(result, rMan, rExp, pyMan, pyExp, 0);
        }
        {
            // very positive exponent
            /// @notice there is no overflow risk since normalization can only make the exponent smaller. Never bigger.
            uint encodedPositiveExp = ((2 ** 14 - 1) - uint(distanceFromExpBound)) << Float128.EXPONENT_BIT;
            int aMan = int(1e71);
            uint maliciousFloatEncoded = encodedPositiveExp | uint(aMan) | Float128.MANTISSA_L_FLAG_MASK;
            int aExp = int(Float128.ZERO_OFFSET) - int(uint(distanceFromExpBound)) - 1;
            packedFloat a = packedFloat.wrap(maliciousFloatEncoded);

            packedFloat result = a.sqrt();
            string[] memory inputs = _buildFFIMul128(aMan, aExp, 0, 0, "sqrt", 0);
            bytes memory res = vm.ffi(inputs);
            (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
            (int rMan, int rExp) = Float128.decode(result);
            checkResults(result, rMan, rExp, pyMan, pyExp, 1);
        }
    }

    function testEncoded_toPackedFloat_maliciousEncoding(uint8 distanceFromExpBound, int aMan) public {
        aMan = bound(aMan, -int(Float128.MAX_76_DIGIT_NUMBER), int(Float128.MAX_76_DIGIT_NUMBER));
        {
            // very negative exponent
            int aExp = int(uint(distanceFromExpBound)) - int(Float128.ZERO_OFFSET);
            if (distanceFromExpBound < Float128.MAX_DIGITS_M_X_2 && aMan != 0) vm.expectRevert("float128: underflow");
            packedFloat a = aMan.toPackedFloat(aExp);
            (int rMan, int rExp) = a.decode();
            (aMan, aExp) = emulateNormalization(aMan, aExp);
            assertEq(rMan, aMan, "different mantissas");
            assertEq(rExp, aExp, "different exponents");
        }
        {
            // very positive exponent
            /// @notice there is no overflow risk since normalization can only make the exponent smaller. Never bigger.
            int aExp = int(Float128.ZERO_OFFSET) - int(uint(distanceFromExpBound)) - 1;
            packedFloat a = aMan.toPackedFloat(aExp);
            (int rMan, int rExp) = a.decode();
            (aMan, aExp) = emulateNormalization(aMan, aExp);
            assertEq(rMan, aMan, "different mantissas");
            assertEq(rExp, aExp, "different exponents");
        }
    }

    /**
     * @dev pure Solidity implementation of the normalization procedure that takes place in toPackedFloat function.
     */
    function emulateNormalization(int man, int exp) internal pure returns (int mantissa, int exponent) {
        if (man == 0) return (0, -8192);
        mantissa = man;
        exponent = exp;
        uint nDigits = findNumberOfDigits(uint(man < 0 ? -1 * man : man));
        if (nDigits != 38 && nDigits != 72) {
            int adj = int(Float128.MAX_DIGITS_M) - int(nDigits);
            exponent = exp - adj;
            if (exponent > Float128.MAXIMUM_EXPONENT) {
                if (adj > 0) {
                    exponent -= int(Float128.DIGIT_DIFF_L_M);
                    mantissa *= (int(Float128.BASE_TO_THE_DIGIT_DIFF * Float128.BASE ** uint(adj)));
                } else {
                    exponent += int(Float128.DIGIT_DIFF_L_M);
                    mantissa /= (int(Float128.BASE_TO_THE_DIGIT_DIFF) / int(Float128.BASE ** uint(-adj)));
                }
            } else {
                if (adj > 0) {
                    mantissa *= int(Float128.BASE ** uint(adj));
                } else {
                    mantissa /= int(Float128.BASE ** uint(-adj));
                }
            }
        } else if (nDigits == 38 && exponent > Float128.MAXIMUM_EXPONENT) {
            exponent -= int(Float128.DIGIT_DIFF_L_M);
            mantissa *= (int(Float128.BASE_TO_THE_DIGIT_DIFF));
        }
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

        checkResults(result, rMan, rExp, pyMan, pyExp, 0);
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

            checkResults(result, rMan, rExp, pyMan, pyExp, 0);
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

            checkResults(result, rMan, rExp, pyMan, pyExp, 0);
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

        checkResults(result, rMan, rExp, pyMan, pyExp, 1);
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

        checkResults(result, rMan, rExp, pyMan, pyExp, 1);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testEncoded_sqrt(int aMan, int aExp) public {
        (aMan, aExp, , ) = setBounds(aMan, aExp, 0, 0);
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

            checkResults(result, rMan, rExp, pyMan, pyExp, 0);
        }
    }

    function testLEpackedFloatFuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        packedFloat pA = Float128.toPackedFloat(aMan, aExp);
        packedFloat pB = Float128.toPackedFloat(bMan, bExp);
        bool retVal = Float128.le(pA, pB);
        console2.log("retVal", retVal);

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

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "ge", 0);
        bytes memory res = vm.ffi(inputs);
        (int pyMan, ) = abi.decode((res), (int256, int256));
        bool pyRes = pyMan > 0;
        assertEq(retVal, pyRes);
    }

    function testLnpackedFloatFuzzRange1To1Point2(int aMan, int aExp) public {
        aMan = bound(aMan, 10000000000000000000000000000000000000, 10200000000000000000000000000000000000);
        console2.log("aMan", aMan);
        uint digits = findNumberOfDigits(aMan < 0 ? uint(aMan * -1) : uint(aMan));
        aExp = 1 - int(digits);
        console2.log("aExp", aExp);

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        (int manNorm, int expNorm) = Float128.decode(a);
        console2.log("manNorm", manNorm);
        console2.log("expNorm", expNorm);

        packedFloat retVal = Ln.ln(a);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, 0, 0, "ln", 0);
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
        (int rMan, int rExp) = Float128.decode(retVal);
        console2.log("rMan", rMan);
        console2.log("rExp", rExp);
        if (rMan == 0 && pyMan != 0) {
            // we might have cases for when truncation will make a number 1.0, but Python will take
            // the full number. In those cases, Solidity result will be zero, so we just check the
            // exponent of the Python response to make sure it stays within tolerance
            assertLe(pyExp, -75);
        } else {
            checkResults(retVal, rMan, rExp, pyMan, pyExp, 106);
        }
    }

    function testLnpackedFloatFuzzRange1Point2To3(int aMan, int aExp) public {
        aMan = bound(aMan, 102000000000000000000000000000000000000000000000000000000000000000000000, 300000000000000000000000000000000000000000000000000000000000000000000000);
        console2.log("aMan", aMan);
        uint digits = findNumberOfDigits(aMan < 0 ? uint(aMan * -1) : uint(aMan));
        aExp = 1 - int(digits);
        console2.log("aExp", aExp);

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        (int manNorm, int expNorm) = Float128.decode(a);
        console2.log("manNorm", manNorm);
        console2.log("expNorm", expNorm);

        packedFloat retVal = Ln.ln(a);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, 0, 0, "ln", 0);
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
        (int rMan, int rExp) = Float128.decode(retVal);
        console2.log("rMan", rMan);
        console2.log("rExp", rExp);
        if (rMan == 0 && pyMan != 0) {
            // we might have cases for when truncation will make a number 1.0, but Python will take
            // the full number. In those cases, Solidity result will be zero, so we just check the
            // exponent of the Python response to make sure it stays within tolerance
            assertLe(pyExp, -75);
        } else {
            checkResults(retVal, rMan, rExp, pyMan, pyExp, 72);
        }
    }

    function testLnpackedFloatFuzzRange0To1(int aMan, int aExp) public {
        aMan = bound(aMan, 1, 999999999999999999999999999999999999999999999999999999999999999999999999);
        console2.log("aMan", aMan);
        uint digits = findNumberOfDigits(aMan < 0 ? uint(aMan * -1) : uint(aMan));
        aExp = bound(aExp, -3000, 0 - int(digits));
        console2.log("aExp", aExp);

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        (int manNorm, int expNorm) = Float128.decode(a);
        console2.log("manNorm", manNorm);
        console2.log("expNorm", expNorm);

        packedFloat retVal = Ln.ln(a);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, 0, 0, "ln", 0);
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
        (int rMan, int rExp) = Float128.decode(retVal);
        console2.log("rMan", rMan);
        console2.log("rExp", rExp);
        if (rMan == 0 && pyMan != 0) {
            // we might have cases for when truncation will make a number 1.0, but Python will take
            // the full number. In those cases, Solidity result will be zero, so we just check the
            // exponent of the Python response to make sure it stays within tolerance
            assertLe(pyExp, -75);
        } else {
            checkResults(retVal, rMan, rExp, pyMan, pyExp, 72);
        }
    }

    function testLnpackedFloatFuzzRange2ToInfinity(int aMan, int aExp) public {
        aMan = bound(aMan, 200000000000000000000000000000000000000000000000000000000000000000000000, 9999999999999999999999999999999999999999999999999999999999999999999999999999);
        console2.log("aMan", aMan);
        uint digits = findNumberOfDigits(aMan < 0 ? uint(aMan * -1) : uint(aMan));
        aExp = bound(aExp, 1 - int(digits), 3000);
        console2.log("aExp", aExp);

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        (int manNorm, int expNorm) = Float128.decode(a);
        console2.log("manNorm", manNorm);
        console2.log("expNorm", expNorm);

        packedFloat retVal = Ln.ln(a);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, 0, 0, "ln", 0);
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
        (int rMan, int rExp) = Float128.decode(retVal);
        console2.log("rMan", rMan);
        console2.log("rExp", rExp);
        if (rMan == 0 && pyMan != 0) {
            // we might have cases for when truncation will make a number 1.0, but Python will take
            // the full number. In those cases, Solidity result will be zero, so we just check the
            // exponent of the Python response to make sure it stays within tolerance
            assertLe(pyExp, -75);
        } else {
            checkResults(retVal, rMan, rExp, pyMan, pyExp, 72);
        }
    }

    function testLnpackedFloatFuzzAllRanges(int aMan, int aExp) public {
        (aMan, aExp, , ) = setBounds(aMan, aExp, 0, 0);
        console2.log("aMan", aMan);

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        (int manNorm, int expNorm) = Float128.decode(a);
        console2.log("manNorm", manNorm);
        console2.log("expNorm", expNorm);

        if (a.le(int(0).toPackedFloat(0))) vm.expectRevert("float128: ln undefined");
        packedFloat retVal = Ln.ln(a);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, 0, 0, "ln", 0);
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
        (int rMan, int rExp) = Float128.decode(retVal);
        console2.log("rMan", rMan);
        console2.log("rExp", rExp);
        if (rMan == 0 && pyMan != 0) {
            // we might have cases for when truncation will make a number 1.0, but Python will take
            // the full number. In those cases, Solidity result will be zero, so we just check the
            // exponent of the Python response to make sure it stays within tolerance
            assertLe(pyExp, -75);
        } else {
            checkResults(retVal, rMan, rExp, pyMan, pyExp, 72);
        }
    }

    function testLnpackedFloatUnit() public {
        int aMan = 10089492627524701326248021367100041644;
        int aExp = -37;

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        (int manNorm, int expNorm) = Float128.decode(a);
        console2.log("manNorm", manNorm);
        console2.log("expNorm", expNorm);

        packedFloat retVal = Ln.ln(a);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, 0, 0, "ln", 0);
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));
        (int rMan, int rExp) = Float128.decode(retVal);
        console2.log("rMan", rMan);
        console2.log("rExp", rExp);
        if (rMan == 0 && pyMan != 0) {
            // we might have cases for when truncation will make a number 1.0, but Python will take
            // the full number. In those cases, Solidity result will be zero, so we just check the
            // exponent of the Python response to make sure it stays within tolerance
            assertLe(pyExp, -75);
        } else {
            checkResults(retVal, rMan, rExp, pyMan, pyExp, 106);
        }
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
            if (comparison == 1e77 && comparison <= man) {
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

    function testLNCaseOne() public pure {
        // Test Case 1:
        int mantissa = 339046758471559584917568900955540863464438633576559162723246173766731092;
        int exponent = -84;
        int expectedResultMantissa = -28712638366447213800267852694553857212;
        int expectedResultExp = -36;
        packedFloat a = Float128.toPackedFloat(mantissa, exponent);

        packedFloat retVal = Ln.ln(a);
        (int mantissaF, int exponentF) = Float128.decode(retVal);
        assertEq(mantissaF, expectedResultMantissa);
        assertEq(exponentF, expectedResultExp);
    }

    function testLNCaseTwo() public pure {
        // Test Case 2:
        int mantissa = 419133353677143729020445529447665547757094903875495880378394873359780286;
        int exponent = -72;
        int expectedResultMantissa = -86956614316348604164580027803497950664;
        int expectedResultExp = -38;
        packedFloat a = Float128.toPackedFloat(mantissa, exponent);

        packedFloat retVal = Ln.ln(a);
        (int mantissaF, int exponentF) = Float128.decode(retVal);
        assertEq(mantissaF, expectedResultMantissa);
        assertEq(exponentF, expectedResultExp);
    }

    function testLNCaseThree() public pure {
        // Test Case 3:
        int mantissa = 471738548555985204842829168083810940950366912454141453216936305944405297;
        int exponent = -73;
        int expectedResultMantissa = -30539154624132792807849865290472860264;
        int expectedResultExp = -37;
        packedFloat a = Float128.toPackedFloat(mantissa, exponent);

        packedFloat retVal = Ln.ln(a);
        (int mantissaF, int exponentF) = Float128.decode(retVal);
        assertEq(mantissaF, expectedResultMantissa);
        assertEq(exponentF, expectedResultExp);
    }

    function testLNCaseFour() public pure {
        // Test Case 1:
        int mantissa = 100000000000000000000000000000000000000000000000000000000000000000000000;
        int exponent = -71;
        int expectedResultMantissa = 0;
        int expectedResultExp = -8192;
        packedFloat a = Float128.toPackedFloat(mantissa, exponent);

        packedFloat retVal = Ln.ln(a);
        (int mantissaF, int exponentF) = Float128.decode(retVal);
        assertEq(mantissaF, expectedResultMantissa);
        assertEq(exponentF, expectedResultExp);
    }

    function testEqDifferentRepresentationsPositive(int aMan, int aExp) public pure {
        // Case positive a:
        aMan = bound(aMan, 10000000000000000000000000000000000000, 99999999999999999999999999999999999999);
        aExp = bound(aExp, -8000, 8000);
        int bMan = aMan * int(Float128.BASE_TO_THE_DIGIT_DIFF);
        int bExp = aExp - int(Float128.DIGIT_DIFF_L_M);
        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);

        bool retVal = Float128.eq(a, b);
        assertTrue(retVal);
    }

    function testEqDifferentRepresentationsNegative(int aMan, int aExp) public pure {
        // Case negative b:
        aMan = bound(aMan, 10000000000000000000000000000000000000, 99999999999999999999999999999999999999);
        aExp = bound(aExp, -8000, 8000);
        int bMan = -aMan * int(Float128.BASE_TO_THE_DIGIT_DIFF);
        int bExp = aExp - int(Float128.DIGIT_DIFF_L_M);
        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);

        bool retVal = Float128.eq(a, b);
        assertFalse(retVal);
    }

    function testExponentiationOverflow_DivisionOfLNumberByOverflowedExpReturnsZero() public pure {
        uint r;
        uint BASE = Float128.BASE;
        uint MAX_L_DIGIT_NUMBER = Float128.MAX_L_DIGIT_NUMBER;
        // we test the whole range of overflowed exponentiation which goes from 10**77 to 10**(exponent whole range)
        for (uint i = 77; i < Float128.ZERO_OFFSET * 2; i++) {
            // since all the overflowed exponentiations are greater than MAX_L_DIGIT_NUMBER, the result will always be zero
            assembly {
                r := div(MAX_L_DIGIT_NUMBER, exp(BASE, i))
            }
            assertEq(r, 0, "dividing an L number by an overflowed power of BASE does not return zero");
        }
    }

    function testExponentiationOverflow_ExpReturnsZeroForExponentsGreaterThan255() public pure {
        uint r;
        uint BASE = Float128.BASE;
        for (uint i = 256; i < Float128.ZERO_OFFSET * 2; i++) {
            assembly {
                r := exp(BASE, i)
            }
            assertEq(r, 0, "BASE to a power greater than 256 is not 0");
        }
    }
}
