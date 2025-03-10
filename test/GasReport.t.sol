// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {GasHelpers} from "test/GasHelpers.sol";
import "lib/forge-std/src/console2.sol";
import "src/LN.sol";
import {Float, packedFloat, Float128} from "src/Float128.sol";

contract GasReport is Test, GasHelpers {
    using Float128 for Float;
    using LN for uint256;

    function testGasUsedStructs_add() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -36, mantissa: int(22345000000000000000000000000000000000)});
        Float memory B = Float({exponent: -26, mantissa: int(33678000000000000000000000000000000000)});
        startMeasuringGas("Gas used - structs");
        Float128.add(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("add Float structs: ", gasUsed);
    }

    function testGasUsedStructs_add_matching_exponents() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -36, mantissa: int(22345000000000000000000000000000000000)});
        Float memory B = Float({exponent: -36, mantissa: int(33678000000000000000000000000000000000)});
        startMeasuringGas("Gas used - structs");
        Float128.add(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("add Float structs (matching exponents): ", gasUsed);
    }

    function testGasUsedStructs_add_sub() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -36, mantissa: int(22345000000000000000000000000000000000)});
        Float memory B = Float({exponent: -26, mantissa: int(-33678000000000000000000000000000000000)});
        startMeasuringGas("Gas used - structs");
        Float128.add(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("add Float structs (subtraction via addition): ", gasUsed);
    }

    function testGasUsedStructs_sub() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -26, mantissa: int(22345000000000000000000000000000000000)});
        Float memory B = Float({exponent: -36, mantissa: int(33678000000000000000000000000000000000)});
        startMeasuringGas("Gas used - structs");
        Float128.sub(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("subtract Float structs: ", gasUsed);
    }

    function testGasUsedStructs_sub_matching_exponents() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -26, mantissa: int(22345000000000000000000000000000000000)});
        Float memory B = Float({exponent: -26, mantissa: int(13678000000000000000000000000000000000)});
        startMeasuringGas("Gas used - structs");
        Float128.sub(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("subtract Float structs (matching exponents): ", gasUsed);
    }

    function testGasUsedStructs_sub_add() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -26, mantissa: int(22345000000000000000000000000000000000)});
        Float memory B = Float({exponent: -36, mantissa: int(-33678000000000000000000000000000000000)});
        startMeasuringGas("Gas used - structs");
        Float128.sub(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("subtract Float structs (addition via subtraction): ", gasUsed);
    }

    function testGasUsedStructs_mul() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -26, mantissa: int(22345000000000000000000000000000000000)});
        Float memory B = Float({exponent: -36, mantissa: int(33678000000000000000000000000000000000)});
        startMeasuringGas("Gas used - structs");
        Float128.mul(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("multiply Float structs: ", gasUsed);
    }

    function testGasUsedStructs_mul_by_zero() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -26, mantissa: int(22345000000000000000000000000000000000)});
        Float memory B = Float({exponent: -16384, mantissa: int(0)});
        startMeasuringGas("Gas used - structs");
        Float128.mul(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("multiply Float structs (mul by 0): ", gasUsed);
    }

    function testGasUsedStructs_div() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -36, mantissa: int(22345000000000000000000000000000000000)});
        Float memory B = Float({exponent: -36, mantissa: int(33678000000000000000000000000000000000)});
        startMeasuringGas("Gas used - structs");
        Float128.div(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("divide Float structs: ", gasUsed);
    }

    function testGasUsedStructs_div_zero_num() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -16384, mantissa: int(0)});
        Float memory B = Float({exponent: -36, mantissa: int(33678000000000000000000000000000000000)});
        startMeasuringGas("Gas used - structs");
        Float128.div(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("divide Float structs (numerator is 0): ", gasUsed);
    }

    function testGasUsedStructs_sqrt() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -36, mantissa: int(22345000000000000000000000000000000000)});

        startMeasuringGas("Gas used - sqrt128");
        Float128.sqrt(A);

        gasUsed = stopMeasuringGas();
        console2.log("sqrt: ", gasUsed);
    }

    function testGasUsedStructs_lt() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -36, mantissa: int(22345000000000000000000000000000000000)});
        Float memory B = Float({exponent: -36, mantissa: int(33678000000000000000000000000000000000)});
        startMeasuringGas("Gas used - structs");
        Float128.lt(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("lt Float structs: ", gasUsed);
    }

    function testGasUsedStructs_le() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -36, mantissa: int(22345000000000000000000000000000000000)});
        Float memory B = Float({exponent: -36, mantissa: int(33678000000000000000000000000000000000)});
        startMeasuringGas("Gas used - structs");
        Float128.le(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("le Float structs: ", gasUsed);
    }

    function testGasUsedStructs_gt() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -36, mantissa: int(22345000000000000000000000000000000000)});
        Float memory B = Float({exponent: -36, mantissa: int(33678000000000000000000000000000000000)});
        startMeasuringGas("Gas used - structs");
        Float128.gt(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("gt Float structs: ", gasUsed);
    }

    function testGasUsedStructs_ge() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -36, mantissa: int(22345000000000000000000000000000000000)});
        Float memory B = Float({exponent: -36, mantissa: int(33678000000000000000000000000000000000)});
        startMeasuringGas("Gas used - structs");
        Float128.ge(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("ge Float structs: ", gasUsed);
    }

    function testGasUsedUints() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(33678000000000000000000000000000000000, -36);

        startMeasuringGas("Gas used - uints");
        Float128.add(a, b);
        gasUsed = stopMeasuringGas();
        console2.log("2 uints: ", gasUsed);
    }

    function testGasUsedLog10() public {
        _primer();
        uint256 gasUsed = 0;

        uint256 x = type(uint208).max;
        startMeasuringGas("Gas used - log10");

        Float128.findNumberOfDigits(x);
        gasUsed = stopMeasuringGas();
        console2.log("log10: ", gasUsed);
    }

    function testGasUsedEncoded_mul() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(33678000000000000000000000000000000000, -36);

        startMeasuringGas("Gas used - mul128");
        Float128.mul(a, b);

        gasUsed = stopMeasuringGas();
        console2.log("mul128: ", gasUsed);
    }

    function testGasUsedEncoded_mul_by_zero() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(0, -16384);

        startMeasuringGas("Gas used - mul128");
        Float128.mul(a, b);

        gasUsed = stopMeasuringGas();
        console2.log("mul128 (multiply by 0): ", gasUsed);
    }

    function testGasUsedEncoded_div() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(33678000000000000000000000000000000000, -36);

        startMeasuringGas("Gas used - div128");
        Float128.div(a, b);

        gasUsed = stopMeasuringGas();
        console2.log("div128: ", gasUsed);
    }

    function testGasUsedEncoded_div_numerator_zero() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(0, -16384);
        packedFloat b = Float128.toPackedFloat(33678000000000000000000000000000000000, -36);

        startMeasuringGas("Gas used - div128");
        Float128.div(a, b);

        gasUsed = stopMeasuringGas();
        console2.log("div128 (numerator is 0): ", gasUsed);
    }

    function testGasUsedEncoded_sub() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(33678000000000000000000000000000000000, -36);

        startMeasuringGas("Gas used - sub128");
        Float128.sub(a, b);

        gasUsed = stopMeasuringGas();
        console2.log("sub: ", gasUsed);
    }

    function testGasUsedEncoded_sub_matching_exponents() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(13678000000000000000000000000000000000, -26);

        startMeasuringGas("Gas used - sub128");
        Float128.sub(a, b);

        gasUsed = stopMeasuringGas();
        console2.log("sub (matching exponents): ", gasUsed);
    }

    function testGasUsedEncoded_sub_add() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(-33678000000000000000000000000000000000, -36);

        startMeasuringGas("Gas used - sub128");
        Float128.sub(a, b);

        gasUsed = stopMeasuringGas();
        console2.log("sub (addition via subtraction): ", gasUsed);
    }

    function testGasUsedEncoded_add() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(33678000000000000000000000000000000000, -36);

        startMeasuringGas("Gas used - add128");
        Float128.add(a, b);

        gasUsed = stopMeasuringGas();
        console2.log("add: ", gasUsed);
    }

    function testGasUsedEncoded_add_matching_exponents() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(33678000000000000000000000000000000000, -26);

        startMeasuringGas("Gas used - add128");
        Float128.add(a, b);

        gasUsed = stopMeasuringGas();
        console2.log("add (matching exponents): ", gasUsed);
    }

    function testGasUsedEncoded_add_sub() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(-33678000000000000000000000000000000000, -36);

        startMeasuringGas("Gas used - add128");
        Float128.add(a, b);

        gasUsed = stopMeasuringGas();
        console2.log("add (subtraction via addition): ", gasUsed);
    }

    function testGasUsedEncoded_sqrt() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);

        startMeasuringGas("Gas used - sqrt128");
        Float128.sqrt(a);

        gasUsed = stopMeasuringGas();
        console2.log("sqrt: ", gasUsed);
    }

    function testGasUsedEncoded_lt() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(33678000000000000000000000000000000000, -36);

        startMeasuringGas("Gas used - lt");
        Float128.lt(a, b);

        gasUsed = stopMeasuringGas();
        console2.log("lt: ", gasUsed);
    }

    function testGasUsedEncoded_le() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(33678000000000000000000000000000000000, -36);

        startMeasuringGas("Gas used - le");
        Float128.le(a, b);

        gasUsed = stopMeasuringGas();
        console2.log("le: ", gasUsed);
    }

    function testGasUsedEncoded_gt() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(33678000000000000000000000000000000000, -36);

        startMeasuringGas("Gas used - gt");
        Float128.gt(a, b);

        gasUsed = stopMeasuringGas();
        console2.log("gt: ", gasUsed);
    }

    function testGasUsedEncoded_ge() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(33678000000000000000000000000000000000, -36);

        startMeasuringGas("Gas used - ge");
        Float128.ge(a, b);

        gasUsed = stopMeasuringGas();
        console2.log("ge: ", gasUsed);
    }

    function testGasUsed_toFloat() public {
        _primer();
        uint256 gasUsed = 0;
        Float memory a;
        startMeasuringGas("Gas used - convertToPackedFloat");
        a = Float128.toFloat(223450000000000000000000000000000000, -26);
        gasUsed = stopMeasuringGas();
        console2.log("toFloat: ", gasUsed);
    }

    function testGasUsed_toFloat_alreadyNormalized() public {
        _primer();
        uint256 gasUsed = 0;
        Float memory a;
        startMeasuringGas("Gas used - convertToPackedFloat");
        a = Float128.toFloat(22345000000000000000000000000000000000, -26);
        gasUsed = stopMeasuringGas();
        console2.log("toFloat (already Normalized): ", gasUsed);
    }

    function testGasUsed_convertToPackedFloat() public {
        _primer();
        uint256 gasUsed = 0;
        Float memory a = Float128.toFloat(223450000000000000000000000000000000, -26);
        packedFloat flo;
        startMeasuringGas("Gas used - convertToPackedFloat");
        flo = a.convertToPackedFloat();
        gasUsed = stopMeasuringGas();
        console2.log("convertToPackedFloat: ", gasUsed);
    }

    function testGasUsed_convertToUnpackedFloat() public {
        _primer();
        uint256 gasUsed = 0;
        packedFloat flo;
        Float memory a = Float128.toFloat(223450000000000000000000000000000000, -26);
        flo = a.convertToPackedFloat();
        startMeasuringGas("Gas used - convertToUnpackedFloat");
        Float memory retVal = Float128.convertToUnpackedFloat(flo);
        gasUsed = stopMeasuringGas();
        console2.log("convertToUnpackedFloat: ", gasUsed);
    }

    function testGasUsed_LN() public {
        uint x = 12345678901234567890123456789012345;
        uint256 gasUsed = 0;
        _primer();
        startMeasuringGas("Gas used - lnWAD2Negative");
        x.lnWAD2Negative();
        gasUsed = stopMeasuringGas();
        console2.log("convertToUnpackedFloat: ", gasUsed);
    }
}
