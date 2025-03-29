# Float128 Solidity Library

## Overview

This is a signed floating-point library optimized for Solidity.

#### General floating-point concepts

a floating point number is a way to represent numbers in an efficient way. It is composed of 3 elements:

- **The mantissa**: the significant digits of the number. It is an integer that is later multiplied by the base elevated to the exponent's power.
- **The base**: generally either 2 or 10. It determines the base of the multiplier factor.
- **The exponent**: the amount of times the base will multiply/divide itself to later be applied to the mantissa.

Some examples:

- -0.0001 can be expressed as -1 x $10^{-4}$.

  - Mantissa: -1
  - Base: 10
  - Exponent: -4

- 2222000000000000 can be expressed as 2222 x $10^{12}$.
  - Mantissa: 2222
  - Base: 10
  - Exponent: 12

Floating point numbers can represent the same number in infinite ways by playing with the exponent. For instance, the first example could be also represented by -10 x $10^{-5}$, -100 x $10^{-6}$, -1000 x $10^{-7}$, etc.

### WARNING
This library will only handle numbers with exponents within the range of **-3000** to **3000**. Larger or smaller numbers may result in precision loss and/or overflow/underflow.

#### Library main features

- Base: 10
- Significant digits: 38
- Exponent range: -8192 and +8191

Available operations:

- Addition (add)
- Subtraction (sub)
- Multiplication (mul)
- Division (div)
- Square root (sqrt)

#### Types

This library uses 2 types. Although their gas usage is very similar, one of them is optimized for storage, and the other one is optimized for operations:

- **Float**: a struct that uses 2 256-bit words. Optimized for operations.
- **packedFloat**: a 256-bit word. Optimized for storage.

```Solidity
type packedFloat is uint256;

struct Float {
    int mantissa;
    int exponent;
}
```

All of the operations are available for both types. Their usages are exactly the same for both, and there are conversion functions to go back and forth between them:

```Solidity
function convertToPackedFloat(Float memory _float) internal pure returns(packedFloat float);

function convertToUnpackedFloat(packedFloat _float) internal pure returns(Float memory float);
```

## Usage

Imagine you need to express a fractional number in Solidity such as 12345.678. The way to achieve that is:

Float version:

```Solidity
import "lib/Float128.sol"

contract Mathing{
    using Float128 for Float;

    ...

    int mantissa = 12345678;
    int exponent = -3;
    Float memory n = mantissa.toFloat(exponent);

    ...

}

```

packedFloat version:

```Solidity
import "lib/Float128.sol"

contract Mathing{
    using Float128 for packedFloat;

    ...

    int mantissa = 12345678;
    int exponent = -3;
    packedFloat n = mantissa.toPackedFloat(exponent);

    ...

}
```

Once you have your floating-point numbers in the correct format, you can start using them to carry out calculations:

```Solidity
    ...

    packedFloat E = m.mul(C.mul(C));

    ...

    Float memory c = (a.mul(a).add(b.mul(b))).sqrt();
```

## Normalization

Normalization is a **vital** step to ensure the highest gas efficiency and precision in this library. Normalization in this context means that the number is always expressed using 38 significant digits without leading zeros. Never more, and never less. The way to achieve this is by playing with the exponent.

For example, the number 12345.678 will have only one proper representation in this library: 12345678000000000000000000000000000000 x $10^{-33}$

For this reason, it is important to use the functions `toFloat()` and `toPackedFloat()` since these functions will normalize the numbers automatically.

_Note: It is encouraged to store the numbers as floating-point values, and not to convert them to fixed-point numbers or any other conversion that might truncate the significant digits as this will mean nothing less than loss of precision._

_Note: Additionally when using constants (i.e. multiplcation or division by 2) it is most efficient from a gas perspective to normalize beforehand._

### Representation of zero

Zero is a special case in this library. It is the only number which mantissa is represented by all zeros. Its exponent is the smallest possible which is -8192.

### Gas Profile

To run the gas estimates from the repo use the following command:

```c
forge test --ffi -vv --match-contract GasReport
```

Here are the current Gas Results:

#### Gas Report - functions using Float structs

| Function (and scenario)                | Min  | Average | Max  |
| -------------------------------------- | ---- | ------- | ---- |
| Addition                               | 596  | 1174    | 1778 |
| Addition (matching exponents)          | 499  | 941     | 1556 |
| Addition (subtraction via addition)    | 609  | 1331    | 1791 |
| Subtraction                            | 577  | 1175    | 1769 |
| Subtraction (matching exponents)       | 491  | 928     | 1567 |
| Subtraction (addition via subtraction) | 604  | 1018    | 1784 |
| Multiplication                         | 295  | 575     | 856  |
| Multiplication (by zero)               | 295  | 576     | 858  |
| Division                               | 296  | 590     | 886  |
| Division (numerator is zero)           | 295  | 577     | 860  |
| Square Root                            | 1247 | 1416    | 1588 |

#### Gas Report - functions using packedFloats

| Function (and scenario)                | Min | Average | Max  |
| -------------------------------------- | --- | ------- | ---- |
| Addition                               | 472 | 841     | 1158 |
| Addition (matching exponents)          | 437 | 581     | 1158 |
| Addition (subtraction via addition)    | 481 | 982     | 1152 |
| Subtraction                            | 469 | 840     | 1157 |
| Subtraction (matching exponents)       | 434 | 589     | 1158 |
| Subtraction (addition via subtraction) | 434 | 675     | 1149 |
| Multiplication                         | 301 | 302     | 303  |
| Multiplication (by zero)               | 118 | 118     | 118  |
| Division                               | 269 | 283     | 299  |
| Division (numerator is zero)           | 123 | 123     | 123  |
| Square Root                            | 932 | 951     | 970  |

#### Gas Report - Builder + Conversion functions

| Function (and scenario)      | Min | Average | Max  |
| ---------------------------- | --- | ------- | ---- |
| toFloat                      | 456 | 1416    | 2749 |
| toFloat (already normalized) | 458 | 1401    | 2353 |
| convertToPackedFloat         | 281 | 343     | 764  |
| convertToUnpackedFloat       | 307 | 596     | 886  |
| Log10                        | 345 | 346     | 351  |
