const std = @import("std");

/// Makes a number system from a floating point type.
/// Currently only works with f32 and f64 because std.math.pow only works with those two.
pub fn MakeNumSystem(NumType: type) type {
    //very useful function, i know...
    if (NumType != f32 and NumType != f64) {
        @compileError("Unsupported");
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
            return std.math.pow(NumType, a, @floatFromInt(b));
        }
    };
}

/// A number system made from f32.
pub const f32System = MakeNumSystem(f32);
/// A number system made from f64.
pub const f64System = MakeNumSystem(f64);
