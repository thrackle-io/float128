/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "src/Float128.sol";

contract FloatUtils is Test {
    function _buildFFIMul128(int aMan, int aExp, int bMan, int bExp, string memory operation) internal pure returns (string[] memory) {
        string[] memory inputs = new string[](7);
        inputs[0] = "python3";
        inputs[1] = "script/float128_test.py";
        inputs[2] = vm.toString(aMan);
        inputs[3] = vm.toString(aExp);
        inputs[4] = vm.toString(bMan);
        inputs[5] = vm.toString(bExp);
        inputs[6] = operation;
        return inputs;
    }

    function _reverseNormalize(Float memory float) internal pure returns (int256 mantissa) {
        int256 normalizedExponent = float.exponent;
        bool negative = false;
        if (float.exponent < 0) {
            normalizedExponent = normalizedExponent * -1;
            negative = true;
        }
        int256 expo = 1;
        for (int i = 0; i < normalizedExponent; i++) {
            expo = expo * 10;
        }
        mantissa = float.mantissa;
        if (negative) {
            mantissa = mantissa / expo;
        } else {
            mantissa = mantissa * expo;
        }
    }

    function setBounds(int aMan, int aExp, int bMan, int bExp) internal pure returns (int _aMan, int _aExp, int _bMan, int _bExp) {
        // numbers with more than 38 digits lose precision
        _aMan = bound(aMan, -99999999999999999999999999999999999999, 99999999999999999999999999999999999999);
        _aExp = bound(aExp, -74, 74);
        _bMan = bound(bMan, -99999999999999999999999999999999999999, 99999999999999999999999999999999999999);
        _bExp = bound(bExp, -74, 74);
    }
}
