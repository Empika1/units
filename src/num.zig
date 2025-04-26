// defines some number systems that can be used to make Unit Systems

const std = @import("std");

//uses the exponentiation by squaring algorithm
pub fn powFloatInt(
    x: anytype, // Base
    comptime n: comptime_int, // Exponent
) @TypeOf(x) {
    const T = @TypeOf(x);

    var m: isize = n;
    var base: T = x;
    var result: T = 1;

    // handle negative exponents by inverting the base
    if (m < 0) {
        base = 1 / base;
        m = -m;
    }

    // main loop: exponentiation by squaring
    while (m != 0) : (m >>= 1) {
        if ((m & 1) != 0) {
            result *= base;
        }
        base *= base;
    }

    return result;
}

/// Makes a number system from a floating point type.
pub fn MakeNumSystem(NumType: type) type {
    switch (@typeInfo(NumType)) {
        .float => {},
        .comptime_float => {},
        else => @compileError(@typeName(NumType) ++ "is not a float type."),
    }

    return struct {
        pub fn add(a: NumType, b: NumType) NumType {
            return a + b;
        }

        pub fn subtract(a: NumType, b: NumType) NumType {
            return a - b;
        }

        pub fn multiply(a: NumType, b: NumType) NumType {
            return a * b;
        }

        pub fn divide(a: NumType, b: NumType) NumType {
            return a / b;
        }

        pub fn pow(a: NumType, b: comptime_int) NumType {
            return powFloatInt(a, b);
        }

        pub fn order(a: NumType, b: NumType) std.math.Order {
            return std.math.order(a, b);
        }
    };
}

pub const f16System = MakeNumSystem(f16);
pub const f32System = MakeNumSystem(f32);
pub const f64System = MakeNumSystem(f64);
pub const f128System = MakeNumSystem(f128);
pub const comptime_floatSystem = MakeNumSystem(comptime_float);
