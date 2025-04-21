const std = @import("std");
const units = @import("units.zig");
const siunits = @import("siunits.zig");

const system = siunits.f64System.UnitSystem;
const base = siunits.f64System.BaseUnits;
const derived = siunits.f64System.DerivedUnits;

pub fn main() void {
    const Celcius = base.Kelvin.Derive(1, -273.15);
    const Fahrenheit = Celcius.Derive(1.8, 32);
    const myTemp = base.Kelvin{ .number = 1000 };
    std.debug.print("{d} {d} {d}", .{ myTemp.number, myTemp.convert(Celcius).number, myTemp.convert(Fahrenheit).number });
}
