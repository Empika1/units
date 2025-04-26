//uses the exponentiation by squaring algorithm
pub fn powFloatInt(
    x: anytype, // Base
    comptime n: comptime_int, // Exponent
) t: {
    const T = @TypeOf(x);
    switch (@typeInfo(T)) {
        .float => {},
        .comptime_float => {},
        else => @compileError(@typeName(T) ++ "is not a float type."),
    }
    break :t T;
} {
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
