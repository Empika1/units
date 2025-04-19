const std = @import("std");
const units = @import("units.zig");
const siunits = @import("siunits.zig");

const system = siunits.f64SiUnitSystem.UnitSystem;
const base = siunits.f64SiUnitSystem.BaseUnits;
const derived = siunits.f64SiUnitSystem.DerivedUnits;

pub const Foot: type = system.MakeDerivedUnit(base.Distance, 3.28083989501, 0);
pub const Inch: type = system.MakeDerivedUnit(base.Distance, 39.3700787402, 0);
pub const Pound: type = system.MakeDerivedUnit(base.Mass, 2.20462262185, 0);
pub const PoundForce: type = system.MakeDerivedUnit(derived.Force, 0.22480892365, 0);
pub const SquareInch: type = Inch.Pow(2);
pub const PSI: type = PoundForce.Divide(SquareInch);

pub fn main() void {
    @setEvalBranchQuota(10000000);
    const v = PSI{ .number = 1 };
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
