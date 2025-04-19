const std = @import("std");

pub fn MakeNumSystem(NumType: type) type {
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

pub const f32System = MakeNumSystem(f32);
pub const f64System = MakeNumSystem(f64);
pub const f128System = MakeNumSystem(f128);
