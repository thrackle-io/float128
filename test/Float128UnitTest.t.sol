/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/console2.sol";
import "src/Float128.sol";
import "test/FloatUtils.sol";

contract Float128UnitTest is FloatUtils {
    using Float128 for int256;

    function testToFloatLessThan38() public pure {
        int256 man = 1;
        int256 exp = 1;

        Float memory float = man.toFloat(exp);
        assertEq(float.mantissa, 10000000000000000000000000000000000000);
        assertEq(float.exponent, -36);
        float.exponent -= exp;
        int256 retVal = _reverseNormalize(float);
        assertEq(man, retVal);
    } 

    function testToFloatExactly38() public pure {
        int256 man = 12341234123412341234123412341234123412;
        int256 exp = 1000;

        Float memory float = man.toFloat(exp);
        assertEq(float.mantissa, 12341234123412341234123412341234123412);
        assertEq(float.exponent, 1000);
        float.exponent -= exp;
        int256 retVal = _reverseNormalize(float);
        assertEq(man, retVal);
    } 

    function testToFloatMoreThan38() public pure {
        int256 man = 5789604461865809771178549250434395392663499233282028201972879200395656481996;
        int256 exp = 1000;

        Float memory float = man.toFloat(exp);
        assertEq(float.mantissa, 57896044618658097711785492504343953926);
        assertEq(float.exponent, 1038);
        float.exponent -= exp;

        // Expect to lose one point of precision 
        int256 retVal = _reverseNormalize(float);
        assertEq(5789604461865809771178549250434395392600000000000000000000000000000000000000, retVal);
    } 

    function testToPackedFloatLessThan38() public pure {
        int256 man = 1234123412341234123412341234123412341;
        int256 exp = 1000;

        packedFloat float = man.toPackedFloat(exp);
        Float memory retVal = Float128.convertToUnpackedFloat(float);


        assertEq(12341234123412341234123412341234123410, retVal.mantissa);
        assertEq(999, retVal.exponent);
    }

    function testToPackedFloatExactly38() public pure {
        int256 man = 12341234123412341234123412341234123412;
        int256 exp = 1000;

        packedFloat float = man.toPackedFloat(exp);
        Float memory retVal = Float128.convertToUnpackedFloat(float);

        assertEq(12341234123412341234123412341234123412, retVal.mantissa);
    }

    function testToPackedFloatMoreThan38() public pure {
        int256 man = 5789604461865809771178549250434395392663499233282028201972879200395656481996;
        int256 exp = 1000;

        packedFloat float = man.toPackedFloat(exp);
        Float memory retVal = Float128.convertToUnpackedFloat(float);

        // Expect to lose two points of precision
        assertEq(57896044618658097711785492504343953926, retVal.mantissa);
        assertEq(1038, retVal.exponent);
    }

    function testConvertToUnpackedFloatExactly38() public pure {
        int256 man = 12341234123412341234123412341234123412;
        int256 exp = 1000;

        packedFloat float = man.toPackedFloat(exp);
        Float memory unpacked = Float128.convertToUnpackedFloat(float);

        assertEq(12341234123412341234123412341234123412, unpacked.mantissa);
    }

    function testConvertToUnpackedFloatLessThan38() public pure {
        int256 man = 123412341234123412341234123412341234;
        int256 exp = 1000;

        packedFloat float = man.toPackedFloat(exp);
        Float memory unpacked = Float128.convertToUnpackedFloat(float);
        assertEq(12341234123412341234123412341234123400, unpacked.mantissa);
        assertEq(998, unpacked.exponent);
    }

    function testConvertToUnpackedFloatMoreThan38() public pure {
        int256 man = 5789604461865809771178549250434395392663499233282028201972879200395656481996;
        int256 exp = 1000;

        packedFloat float = man.toPackedFloat(exp);
        Float memory unpacked = Float128.convertToUnpackedFloat(float);
        assertEq(57896044618658097711785492504343953926, unpacked.mantissa);
        assertEq(1038, unpacked.exponent);
    }

    function testConvertToPackedFloatPlusDecodeExactly38() public pure {
        int256 man = 12341234123412341234123412341234123412;
        int256 exp = 1000;

        Float memory unpacked;
        unpacked.mantissa = man;
        unpacked.exponent = exp;
        packedFloat packed = Float128.convertToPackedFloat(unpacked);

        Float memory retVal = Float128.convertToUnpackedFloat(packed);

        assertEq(12341234123412341234123412341234123412, retVal.mantissa);
        assertEq(1000, retVal.exponent);
    }

    function testConvertToPackedFloatPlusDecodeLessThan38() public pure {
        int256 man = 12341234123412341234123412341234;
        int256 exp = 1000;

        Float memory unpacked;
        unpacked.mantissa = man;
        unpacked.exponent = exp;
        packedFloat packed = Float128.convertToPackedFloat(unpacked);

        Float memory retVal = Float128.convertToUnpackedFloat(packed);

        assertEq(12341234123412341234123412341234000000, retVal.mantissa);
        assertEq(994, retVal.exponent);
    }

    function testConvertToPackedFloatPlusDecodeMoreThan38() public pure {
        int256 man = 5789604461865809771178549250434395392663499233282028201972879200395656481996;
        int256 exp = 1000;

        Float memory unpacked;
        unpacked.mantissa = man;
        unpacked.exponent = exp;
        packedFloat packed = Float128.convertToPackedFloat(unpacked);

        Float memory retVal = Float128.convertToUnpackedFloat(packed);

        assertEq(57896044618658097711785492504343953926, retVal.mantissa);
        assertEq(1038, retVal.exponent);
    }

    function testNormalizeExactly38() public pure {
        int256 man = 12341234123412341234123412341234123412;
        int256 exp = 1000;

        Float memory initial;
        initial.mantissa = man;
        initial.exponent = exp;
        Float memory retVal = Float128.normalize(initial);

        assertEq(12341234123412341234123412341234123412, retVal.mantissa);
        assertEq(1000, retVal.exponent);
    }

    function testNormalizeLessThan38() public pure {
        int256 man = 12341234123412341234123412341;
        int256 exp = 1000;

        Float memory initial;
        initial.mantissa = man;
        initial.exponent = exp;
        Float memory retVal = Float128.normalize(initial);

        assertEq(12341234123412341234123412341000000000, retVal.mantissa);
        assertEq(991, retVal.exponent);
    }

    function testNormalizeMoreThan38() public pure {
        int256 man = 5789604461865809771178549250434395392663499233282028201972879200395656481996;
        int256 exp = 1000;
        Float memory initial;
        initial.mantissa = man;
        initial.exponent = exp;
        Float memory retVal = Float128.normalize(initial);
        
        assertEq(57896044618658097711785492504343953926, retVal.mantissa);
        assertEq(1038, retVal.exponent);
    }
}