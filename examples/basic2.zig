const std = @import("std");
const units = @import("units");

const si = units.si;
const system = si.f64System.UnitSystem;
const base = si.f64System.baseUnits;
const derived = si.f64System.derivedUnits;

const idHaver = struct {
    const ID: f32 = 0;
};

pub fn main() void {
    const Celcius = base.Kelvin.Derive(1, -273.15);
    const Fahrenheit = Celcius.Derive(1.8, 32);
    const myTemp = base.Kelvin{ .number = 2 };
    std.debug.print("{d} {d} {d}", .{ myTemp.number, myTemp.convert(Celcius).number, myTemp.convert(Fahrenheit).number });
}
