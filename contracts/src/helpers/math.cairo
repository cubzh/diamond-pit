//! # Fast power algorithm

const POWER_0: u128 = 1;
const POWER_8: u128 = 256;
const POWER_12: u128 = 4096;
const POWER_16: u128 = 65536;
const POWER_24: u128 = 16777216;
const POWER_32: u128 = 4294967296;
const POWER_36: u128 = 68719476736;
const POWER_40: u128 = 1099511627776;
const POWER_48: u128 = 281474976710656;
const POWER_56: u128 = 72057594037927936;
const POWER_60: u128 = 1152921504606846976;
const POWER_64: u128 = 18446744073709551616;
const POWER_72: u128 = 4722366482869645213696;
const POWER_80: u128 = 1208925819614629174706176;
const POWER_84: u128 = 19351404648857559107072000;
const POWER_88: u128 = 309485009821345068724781056;
const POWER_96: u128 = 79228162514264337593543950336;
const POWER_104: u128 = 1267650600228229401496703205376;
const POWER_108: u128 = 324518553658426726783156020576256;
const POWER_112: u128 = 5192296858534827628530496329220096;
const POWER_120: u128 = 21267647932558653966460912964485513216;

pub fn fast_power_2(power: u128) -> u128 {
    if power == 0 {
        POWER_0
    } else if power == 8 {
        POWER_8
    } else if power == 12 {
        POWER_12
    } else if power == 16 {
        POWER_16
    } else if power == 24 {
        POWER_24
    } else if power == 32 {
        POWER_32
    } else if power == 36 {
        POWER_36
    } else if power == 40 {
        POWER_40
    } else if power == 48 {
        POWER_48
    } else if power == 56 {
        POWER_56
    } else if power == 60 {
        POWER_60
    } else if power == 64 {
        POWER_64
    } else if power == 72 {
        POWER_72
    } else if power == 80 {
        POWER_80
    } else if power == 84 {
        POWER_84
    } else if power == 88 {
        POWER_88
    } else if power == 96 {
        POWER_96
    } else if power == 104 {
        POWER_104
    } else if power == 108 {
        POWER_108
    } else if power == 112 {
        POWER_112
    } else if power == 120 {
        POWER_120
    } else {
        fast_power(2, power)
    }
}

/// Calculate the base ^ power
/// using the fast powering algorithm
/// # Arguments
/// * ` base ` - The base of the exponentiation
/// * ` power ` - The power of the exponentiation
/// # Returns
/// * ` T ` - The result of base ^ power
/// # Panics
/// * ` base ` is 0
pub fn fast_power<
    T,
    +Div<T>,
    +Rem<T>,
    +Into<u8, T>,
    +Into<T, u256>,
    +TryInto<u256, T>,
    +PartialEq<T>,
    +Copy<T>,
    +Drop<T>
>(
    base: T, mut power: T
) -> T {
    assert!(base != 0_u8.into(), "fast_power: invalid input");

    let mut base: u256 = base.into();
    let mut result: u256 = 1;

    loop {
        if power % 2_u8.into() != 0_u8.into() {
            result *= base;
        }
        power = power / 2_u8.into();
        if (power == 0_u8.into()) {
            break;
        }
        base *= base;
    };

    result.try_into().expect('too large to fit output type')
}