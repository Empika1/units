const std = @import("std");
const interface = @import("interface.zig");

const UnitlessQuantity = struct {};
const UnitlessNumber = struct { number: f64 };

const BaseQuantity = struct {
    pub const unit: type = undefined;
};

const BaseUnit = struct {
    pub const quantity: type = undefined;

    number: f64,
};

fn MakeBaseQuantity(comptime uuid: anytype) type {
    return struct {
        const Quantity = struct {
            comptime {
                _ = uuid; //uuid
            }
            pub const unit = Unit;
        };
        const Unit = struct {
            pub const quantity = Quantity;
        };
    }.Quantity;
}

const Time = MakeBaseQuantity("Time");
const Second = Time.unit;

const Length = MakeBaseQuantity("Length");
const Meter = Length.unit;

const Mass = MakeBaseQuantity("Mass");
const Kilogram = Mass.unit;

const ElectricCurrent = MakeBaseQuantity("ElectricCurrent");
const Ampere = ElectricCurrent.unit;

const Temperature = MakeBaseQuantity("Temperature");
const Kelvin = Temperature.unit;

const Amount = MakeBaseQuantity("Amount");
const Mole = Amount.unit;

const LuminousIntensity = MakeBaseQuantity("LuminousIntensity");
const Candela = Amount.unit;

const TypeValuePair = struct {
    t: type,
    v: comptime_int,
};

const CompositeQuantity = struct {
    pub const bases: []const TypeValuePair = undefined;
};

fn getBaseQuantities(comptime bases: []const TypeValuePair) []const TypeValuePair {
    var basesReduced: []const TypeValuePair = &.{};
    for (0..bases.len) |i| {
        switch (interface.satisfiesInterface(CompositeQuantity, bases[i].t)) {
            .Satisfies => {
                for (getBaseQuantities(bases[i].t.bases)) |baseToAdd| {
                    basesReduced = basesReduced ++ [_]TypeValuePair{.{ .t = baseToAdd.t, .v = baseToAdd.v * bases[i].v }};
                }
                continue;
            },
            .Fails => {},
        }
        switch (interface.satisfiesInterface(BaseQuantity, bases[i].t)) {
            .Satisfies => basesReduced = basesReduced ++ [_]TypeValuePair{bases[i]},
            .Fails => @compileError(std.fmt.comptimePrint("{} is not a base or composite quality.", .{bases[i].t})),
        }
    }

    const sortFunc: fn (void, TypeValuePair, TypeValuePair) bool = struct {
        pub fn inner(_: void, a: TypeValuePair, b: TypeValuePair) bool {
            return std.mem.order(u8, @typeName(a.t), @typeName(b.t)) == std.math.Order.gt;
        }
    }.inner;

    var basesSorted: [basesReduced.len]TypeValuePair = basesReduced[0..].*;
    std.mem.sort(TypeValuePair, &basesSorted, {}, sortFunc);

    var basesNoRepeats = [_]TypeValuePair{TypeValuePair{ .t = undefined, .v = 0 }} ** basesReduced.len;
    var j = 0;
    for (0..basesSorted.len) |i| {
        if (i > 0 and basesSorted[i].t == basesSorted[i - 1].t) {
            basesNoRepeats[j - 1].v += basesSorted[i].v;
        } else {
            if (j > 0 and basesNoRepeats[j - 1].v == 0) {
                j -= 1;
            }
            basesNoRepeats[j] = basesSorted[i];
            j += 1;
        }
    }

    const basesConstSlice = basesNoRepeats[0..j].*;
    return &basesConstSlice;
}

fn MakeCompositeQuantity(comptime bases_: []const TypeValuePair) type {
    comptime {
        const basesAsBaseQuantities = getBaseQuantities(bases_);

        if (basesAsBaseQuantities.len == 0) {
            return UnitlessQuantity;
        }

        if (basesAsBaseQuantities.len == 1) {
            return basesAsBaseQuantities[0].t;
        }

        return struct {
            const Quantity = struct {
                pub const bases = basesAsBaseQuantities;
                pub const unit = Unit;
            };
            const Unit = struct {
                pub const quantity = Quantity;
            };
        }.Quantity;
    }
}

const DerivedUnit = struct {
    pub const quantity: type = undefined;
    pub const scaleFactor: f64 = undefined;
    pub const affineShift: f64 = undefined;

    number: f64,
};

fn MakeDerivedUnit(comptime quantity_: type, comptime scaleFactor_: f64, comptime affineShift_: f64) type {
    comptime {
        if (scaleFactor_ == 0) {
            @compileError("scale factor cannot be 0");
        }

        return struct {
            pub const quantity: type = quantity_;
            pub const scaleFactor: f64 = scaleFactor_;
            pub const affineShift: f64 = affineShift_;

            number: f64,
        };
    }
}

const Velocity: type = MakeCompositeQuantity(&.{ .{ .t = Length, .v = 1 }, .{ .t = Time, .v = -1 } });
const Velocity2: type = MakeCompositeQuantity(&.{ .{ .t = Time, .v = -1 }, .{ .t = Length, .v = 1 } });
const Length2: type = MakeCompositeQuantity(&.{ .{ .t = Velocity, .v = 1 }, .{ .t = Time, .v = 1 } });

// const A = struct {
//     pub var a: i8 = 0;
//     pub var b: i9 = 0;

//     pub fn hello(_: []u9) void {}
// };

// const B = struct {
//     pub var a: i8 = 0;
//     pub var b: i9 = 0;

//     pub fn hello(message: []u8) void {
//         std.debug.print("{s}", .{message});
//     }
// };

pub fn main() void {
    @compileLog(Length == Length2);
}
