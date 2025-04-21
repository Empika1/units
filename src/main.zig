const std = @import("std");
const units = @import("units.zig");
const siunits = @import("siunits.zig");

const system = siunits.f64SiUnitSystem.UnitSystem;
const base = siunits.f64SiUnitSystem.BaseUnits;
const derived = siunits.f64SiUnitSystem.DerivedUnits;

pub fn main() void {
    const Unit1 = system.MakeBaseQuantity("Unit1");
    const Unit2 = system.MakeBaseQuantity("Unit1");
    std.debug.print("{}\n", .{Unit1 == Unit2});

    const Foot: type = base.Meter.Derive(3.28083989501, 0);
    const Inch: type = Foot.Derive(12, 0);
    //const Pound: type = base.Kilogram.Derive(2.20462262185, 0);
    const PoundForce: type = derived.Newton.Derive(0.22480892365, 0);
    const SquareInch: type = Inch.Pow(2);
    const PSI: type = PoundForce.Divide(SquareInch);
    const v = PSI{ .number = 3 };
    std.debug.print("{d}", v.convert(derived.Pascal));
}
