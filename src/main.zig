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
    const v = PSI{ .number = 2 };
    std.debug.print("{d}", v.convert(derived.Pascal));

    // const A = MakeUniqueStruct("a");
    // const B = MakeUniqueStruct("b");
    // const C = MakeUniqueStruct("a");

    // @compileLog(A == B);
    // @compileLog(A == C);

    // const m = base.Kilogram{ .number = 5 };
    // const h = base.Meter{ .number = 4 };
    // const s = derived.Hertz{ .number = 1 };
    //@compileLog(@TypeOf(m.multiply(m).multiply(h).multiply(s)).quantity.bases);
    // comptime {
    //     for (@typeInfo(base).@"struct".decls) |decl1| {
    //         for (@typeInfo(base).@"struct".decls) |decl2| {
    //             if (std.mem.eql(u8, decl1.name, decl2.name)) {
    //                 continue;
    //             }
    //             if (@field(base, decl1.name) == @field(base, decl2.name)) {
    //                 @compileLog("equal fields!", decl1.name, decl2.name);
    //             }
    //         }
    //     }
    //     for (@typeInfo(base).@"struct".decls) |decl1| {
    //         for (@typeInfo(derived).@"struct".decls) |decl2| {
    //             if (std.mem.eql(u8, decl1.name, decl2.name)) {
    //                 continue;
    //             }
    //             if (@field(base, decl1.name) == @field(derived, decl2.name)) {
    //                 @compileLog("equal fields!", decl1.name, decl2.name);
    //             }
    //         }
    //     }
    //     for (@typeInfo(derived).@"struct".decls) |decl1| {
    //         for (@typeInfo(base).@"struct".decls) |decl2| {
    //             if (std.mem.eql(u8, decl1.name, decl2.name)) {
    //                 continue;
    //             }
    //             if (@field(derived, decl1.name) == @field(base, decl2.name)) {
    //                 @compileLog("equal fields!", decl1.name, decl2.name);
    //             }
    //         }
    //     }
    //     for (@typeInfo(derived).@"struct".decls) |decl1| {
    //         for (@typeInfo(derived).@"struct".decls) |decl2| {
    //             if (std.mem.eql(u8, decl1.name, decl2.name)) {
    //                 continue;
    //             }
    //             if (@field(derived, decl1.name) == @field(derived, decl2.name)) {
    //                 @compileLog("equal fields!", decl1.name, decl2.name);
    //             }
    //         }
    //     }
    // }
}
