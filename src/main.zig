const std = @import("std");
const interface = @import("interface.zig");
const result = @import("result.zig");

const TypeValuePair = struct {
    t: type,
    v: comptime_int,
};

fn satisfiesQuantity(comptime Impl: type) result.Result {
    comptime {
        const Quantity = struct {
            pub const bases: []const TypeValuePair = undefined;
            pub const baseUnit: type = undefined;
        };

        return interface.satisfiesInterface(Quantity, Impl);
    }
}

fn assertQuantity(comptime Impl: type) void {
    comptime {
        const res = satisfiesQuantity(Impl);
        switch (res) {
            .Yes => {},
            .No => @compileError(res.No),
        }
    }
}

fn satisfiesUnit(comptime Impl: type) result.Result {
    comptime {
        const Unit = struct {
            pub const scale: comptime_float = undefined;
            pub const shift: comptime_float = undefined;
            pub const quantity: type = undefined;
            number: f64,
        };

        return interface.satisfiesInterface(Unit, Impl);
    }
}

fn assertUnit(comptime Impl: type) void {
    comptime {
        const res = satisfiesUnit(Impl);
        switch (res) {
            .Yes => {},
            .No => @compileError(res.No),
        }
    }
}

const Dimensionless: type = MakeBaseQuantity("One");
const One: type = Dimensionless.baseUnit;

fn normalizeBases(comptime bases: []const TypeValuePair) []const TypeValuePair {
    comptime {
        var basesReduced: []const TypeValuePair = &.{};
        for (0..bases.len) |i| {
            assertQuantity(bases[i].t);
            if (bases[i].t == Dimensionless) { //ignore dimensionless quantity
            } else if (bases[i].t.bases.len == 1 and bases[i].t.bases[0].t == bases[i].t) { // base unit
                basesReduced = basesReduced ++ [_]TypeValuePair{bases[i]};
            } else { //composite unit
                for (normalizeBases(bases[i].t.bases)) |baseToAdd| {
                    basesReduced = basesReduced ++ [_]TypeValuePair{.{ .t = baseToAdd.t, .v = baseToAdd.v * bases[i].v }};
                }
            }
        }

        const sortFunc: fn (void, TypeValuePair, TypeValuePair) bool = struct {
            pub fn inner(_: void, a: TypeValuePair, b: TypeValuePair) bool {
                return std.mem.order(u8, @typeName(a.t), @typeName(b.t)) == std.math.Order.gt;
            }
        }.inner;

        var basesSorted: [basesReduced.len]TypeValuePair = basesReduced[0..].*;
        // if (basesSorted.len == 4) {
        //     basesSorted = [_]TypeValuePair{.{ .t = Time, .v = 1 }, .{ .t = Time, .v = 1 }, .{ .t = Time, .v = 1 }, .{ .t = Time, .v = 1 }};
        //     @compileLog(basesSorted);
        // }
        @setEvalBranchQuota(100000);
        std.mem.sort(TypeValuePair, &basesSorted, {}, sortFunc);

        var basesNoRepeats = [_]TypeValuePair{TypeValuePair{ .t = undefined, .v = 0 }} ** basesReduced.len;
        var j = 0;
        var i = 0;
        while (i < basesSorted.len) : (i += 1) {
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
}

fn MakeBaseQuantity(comptime uuid: anytype) type {
    comptime {
        return struct {
            const quantity_ = struct {
                comptime {
                    _ = uuid;
                }
                pub const bases: []const TypeValuePair = &.{.{ .t = quantity_, .v = 1 }};
                pub const baseUnit: type = unit;
            };
            const unit = struct {
                pub const scale: comptime_float = 1;
                pub const shift: comptime_float = 0;
                pub const quantity: type = quantity_;
                number: f64,
            };
        }.quantity_;
    }
}

fn MakeCompositeQuantity(comptime bases_: []const TypeValuePair) type {
    comptime {
        const basesNormalized = normalizeBases(bases_);

        if (basesNormalized.len == 0) {
            return Dimensionless;
        }

        // if (basesNormalized.len == 1 and basesNormalized[0].v == 1) {
        //     return basesNormalized[0].t;
        // }

        return struct {
            const quantity_ = struct {
                pub const bases: []const TypeValuePair = basesNormalized;
                pub const baseUnit: type = unit;
            };
            const unit = struct {
                pub const scale: comptime_float = 1;
                pub const shift: comptime_float = 0;
                pub const quantity: type = quantity_;
                number: f64,
            };
        }.quantity_;
    }
}

fn QuantityMultiply(comptime T1: type, comptime T2: type) type {
    comptime return MakeCompositeQuantity(&.{ .{ .t = T1, .v = 1 }, .{ .t = T2, .v = 1 } });
}

fn QuantityDivide(comptime T1: type, comptime T2: type) type {
    comptime return MakeCompositeQuantity(&.{ .{ .t = T1, .v = 1 }, .{ .t = T2, .v = -1 } });
}

fn QuantityPow(comptime T: type, comptime pow: comptime_int) type {
    comptime return MakeCompositeQuantity(&.{.{ .t = T, .v = pow }});
}

//BaseUnit * shift_ + scale_ = DerivedUnit
fn MakeDerivedUnit(comptime Quantity: type, comptime scale_: comptime_float, comptime shift_: comptime_float) type {
    comptime {
        assertQuantity(Quantity);
        return struct {
            pub const scale: comptime_float = scale_;
            pub const shift: comptime_float = shift_;
            pub const quantity: type = Quantity;
            number: f64,
        };
    }
}

fn GetBaseUnit(comptime Unit: type) type {
    comptime {
        assertUnit(Unit);
        return Unit.quantity.baseUnit;
    }
}

fn assertHaveSameQuantity(comptime Unit1: type, comptime Unit2: type) void {
    comptime {
        assertUnit(Unit1);
        assertUnit(Unit2);
        if (Unit1.quantity != Unit2.quantity) {
            @compileError("T1 and T2 have different quantity types");
        }
    }
}

fn unitConvert(from: anytype, comptime To: type) To {
    comptime assertHaveSameQuantity(@TypeOf(from), To);
    return .{ .number = (from.number - @TypeOf(from).shift) / @TypeOf(from).scale * To.scale + To.shift };
}

fn unitAdd(a: anytype, b: anytype) GetBaseUnit(@TypeOf(a)) {
    comptime assertHaveSameQuantity(@TypeOf(a), @TypeOf(b));
    const aBase = unitConvert(a, @TypeOf(a).quantity.baseUnit);
    const bBase = unitConvert(b, @TypeOf(b).quantity.baseUnit);
    return .{ .number = aBase.number + bBase.number };
}

fn unitSubtract(a: anytype, b: anytype) GetBaseUnit(@TypeOf(a)) {
    comptime assertHaveSameQuantity(@TypeOf(a), @TypeOf(b));
    const aBase = unitConvert(a, @TypeOf(a).quantity.baseUnit);
    const bBase = unitConvert(b, @TypeOf(b).quantity.baseUnit);
    return .{ .number = aBase.number - bBase.number };
}

fn unitMultiply(a: anytype, b: anytype) QuantityMultiply(@TypeOf(a).quantity, @TypeOf(b).quantity).baseUnit {
    const aBase = unitConvert(a, @TypeOf(a).quantity.baseUnit);
    const bBase = unitConvert(b, @TypeOf(b).quantity.baseUnit);
    return .{ .number = aBase.number * bBase.number };
}

fn unitDivide(a: anytype, b: anytype) QuantityDivide(@TypeOf(a).quantity, @TypeOf(b).quantity).baseUnit {
    const aBase = unitConvert(a, @TypeOf(a).quantity.baseUnit);
    const bBase = unitConvert(b, @TypeOf(b).quantity.baseUnit);
    return .{ .number = aBase.number / bBase.number };
}

fn unitPow(a: anytype, comptime pow: comptime_int) QuantityPow(@TypeOf(a).quantity, pow).baseUnit {
    const aBase = unitConvert(a, @TypeOf(a).quantity.baseUnit);
    return .{ .number = std.math.pow(@TypeOf(aBase.number), aBase.number, @floatFromInt(pow)) };
}

const Time: type = MakeBaseQuantity("Time");
const Second: type = Time.baseUnit;

const Distance: type = MakeBaseQuantity("Length");
const Meter: type = Distance.baseUnit;

const Mass: type = MakeBaseQuantity("Mass");
const Kilogram: type = Mass.baseUnit;

const ElectricCurrent: type = MakeBaseQuantity("ElectricCurrent");
const Ampere: type = ElectricCurrent.baseUnit;

const Temperature: type = MakeBaseQuantity("Temperature");
const Kelvin: type = Temperature.baseUnit;

const Amount: type = MakeBaseQuantity("Amount");
const Mole: type = Amount.baseUnit;

const LuminousIntensity: type = MakeBaseQuantity("LuminousIntensity");
const Candela: type = Amount.baseUnit;

//
const Speed: type = QuantityDivide(Distance, Time);

const Acceleration: type = QuantityDivide(Speed, Time);

const Force: type = QuantityMultiply(Mass, Acceleration);
const Newton: type = Force.baseUnit;

const Energy: type = QuantityMultiply(Force, Distance);
const Joule: type = Energy.baseUnit;

const Power: type = QuantityDivide(Energy, Distance);
const Watt: type = Power.baseUnit;

fn gravPotentialEnergy(m: anytype, h: anytype) Joule {
    const g: Acceleration.baseUnit = .{ .number = 9.8 };
    return unitMultiply(unitMultiply(m, g), h);
}

const Foot: type = MakeDerivedUnit(Distance, 3.28083989501, 0);
const Pound: type = MakeDerivedUnit(Mass, 2.20462262185, 0);
const Celcius: type = MakeDerivedUnit(Temperature, 1, -273.15);
const Fahrenheit: type = MakeDerivedUnit(Temperature, 1.8, -459.67);
pub fn main() void {
    //std.debug.print("{d}\n", .{gravPotentialEnergy(Kilogram{ .number = 10 }, Meter{ .number = 5 }).number});
    //std.debug.print("{d}\n", .{gravPotentialEnergy(Pound{ .number = 10 }, Foot{ .number = 5 }).number}); //still correct number in Joules, unit conversion handled
    std.debug.print("{d}\n", .{unitConvert(Meter{ .number = 50 }, Foot).number}); //still correct number in Joules, unit conversion handled

    //std.debug.print("{d}", .{gravPotentialEnergy(Kelvin{ .number = 10 }, Meter{ .number = 5 }).number}); //compile error, because temperature * distance != energy
}
