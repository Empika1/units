const std = @import("std");
const interface = @import("interface.zig");
const result = @import("result.zig");

const UnitlessQuantity = struct {};
const UnitlessNumber = f64;

fn satisfiesUnitlessQuantity(T: type) result.Result {
    switch (@typeInfo(T)) {
        .Float => return .{ .Yes = {} },
        _ => return .{ .No = "T cannot be converted to a UnitlessNumber" },
    }
}

fn satisfiesBaseQuantity(T: type) result.Result {
    comptime {
        const BaseQuantity = struct {
            pub const unit: type = undefined;
        };

        switch (satisfiesCompositeQuantity(T)) {
            .Yes => return .{ .No = "T satisfies composite quality" },
            .No => return interface.satisfiesInterface(BaseQuantity, T),
        }
    }
}

fn assertBaseQuantity(T: type) void {
    comptime {
        const res = satisfiesBaseQuantity(T);
        switch (res) {
            .Yes => {},
            .No => @compileError(res.No),
        }
    }
}

fn satisfiesBaseUnit(T: type) result.Result {
    comptime {
        const BaseUnit = struct {
            pub const quantity: type = undefined;

            number: UnitlessNumber,
        };

        switch (satisfiesDerivedUnit(T)) {
            .Yes => return .{ .No = "T satisfies derived unit" },
            .No => return interface.satisfiesInterface(BaseUnit, T),
        }
    }
}

fn assertBaseUnit(T: type) void {
    comptime {
        const res = satisfiesBaseUnit(T);
        switch (res) {
            .Yes => {},
            .No => @compileError(res.No),
        }
    }
}

fn satisfiesCompositeQuantity(T: type) result.Result {
    comptime {
        const CompositeQuantity = struct {
            pub const bases: []const TypeValuePair = undefined;
        };

        return interface.satisfiesInterface(CompositeQuantity, T);
    }
}

fn assertCompositeQuantity(T: type) void {
    comptime {
        const res = satisfiesCompositeQuantity(T);
        switch (res) {
            .Yes => {},
            .No => @compileError(res.No),
        }
    }
}

fn satisfiesDerivedUnit(T: type) result.Result {
    comptime {
        const DerivedUnit = struct {
            pub const quantity: type = undefined;
            pub const scaleFactor: comptime_float = undefined;
            pub const affineShift: comptime_float = undefined;

            number: UnitlessNumber,
        };

        return interface.satisfiesInterface(DerivedUnit, T);
    }
}

fn assertDerivedUnit(T: type) void {
    comptime {
        const res = satisfiesDerivedUnit(T);
        switch (res) {
            .Yes => {},
            .No => @compileError(res.No),
        }
    }
}

fn satisfiesUnitQuantity(T: type) result.Result {
    comptime {
        switch (satisfiesBaseQuantity(T)) {
            .Yes => return .{ .Yes = {} },
            .No => switch (satisfiesCompositeQuantity(T)) {
                .Yes => return .{ .Yes = {} },
                .No => return .{ .No = "T satisfies neither unit nor base quantity" },
            },
        }
    }
}

fn assertUnitQuantity(T: type) void {
    comptime {
        const res = satisfiesUnitQuantity(T);
        switch (res) {
            .Yes => {},
            .No => @compileError(res.No),
        }
    }
}

fn satisfiesQuantity(T: type) result.Result {
    comptime {
        switch (satisfiesUnitlessQuantity(T)) {
            .Yes => return .{ .Yes = {} },
            .No => switch (satisfiesUnitQuantity(T)) {
                .Yes => return .{ .Yes = {} },
                .No => return .{ .No = "T is not UnitlessQuantity and satisfies neither unit nor base quantity" },
            },
        }
    }
}

fn assertQuantity(T: type) void {
    comptime {
        const res = satisfiesQuantity(T);
        switch (res) {
            .Yes => {},
            .No => @compileError(res.No),
        }
    }
}

fn satisfiesUnit(T: type) result.Result {
    comptime {
        switch (satisfiesBaseUnit(T)) {
            .Yes => return .{ .Yes = {} },
            .No => switch (satisfiesDerivedUnit(T)) {
                .Yes => return .{ .Yes = {} },
                .No => return .{ .No = "T satisfies neither base nor derived unit" },
            },
        }
    }
}

fn assertUnit(T: type) void {
    comptime {
        const res = satisfiesUnit(T);
        switch (res) {
            .Yes => {},
            .No => @compileError(res.No),
        }
    }
}

fn satisfiesNumber(T: type) result.Result {
    comptime {
        if (T == UnitlessNumber) {
            return .{ .Yes = {} };
        }
        switch (satisfiesUnit(T)) {
            .Yes => return .{ .Yes = {} },
            .No => return .{ .No = "T is not UnitlessNumber and satisfies neither base nor derived unit" },
        }
    }
}

fn assertNumber(T: type) void {
    comptime {
        const res = satisfiesNumber(T);
        switch (res) {
            .Yes => {},
            .No => @compileError(res.No),
        }
    }
}

fn MakeBaseQuantity(comptime uuid: anytype) type {
    comptime {
        return struct {
            const Quantity = struct {
                comptime {
                    _ = uuid; //uuid
                }
                pub const unit = Unit;
            };
            const Unit = struct {
                pub const quantity = Quantity;

                number: UnitlessNumber,
            };
        }.Quantity;
    }
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

fn getBaseQuantities(comptime bases: []const TypeValuePair) []const TypeValuePair {
    comptime {
        var basesReduced: []const TypeValuePair = &.{};
        for (0..bases.len) |i| {
            switch (satisfiesCompositeQuantity(bases[i].t)) {
                .Yes => {
                    for (getBaseQuantities(bases[i].t.bases)) |baseToAdd| {
                        basesReduced = basesReduced ++ [_]TypeValuePair{.{ .t = baseToAdd.t, .v = baseToAdd.v * bases[i].v }};
                    }
                    continue;
                },
                .No => {},
            }
            switch (satisfiesBaseQuantity(bases[i].t)) {
                .Yes => basesReduced = basesReduced ++ [_]TypeValuePair{bases[i]},
                .No => @compileError(std.fmt.comptimePrint("bases[{}] ({}) is not a base or composite quality.", .{ i, bases[i].t })),
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
        var i = 0;
        while (i < basesSorted.len) : (i += 1) {
            switch (satisfiesUnitlessQuantity(basesSorted[i].t)) {
                .Yes => i += 1,
                .No => {},
            }
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

                number: UnitlessNumber,
            };
        }.Quantity;
    }
}

fn MakeDerivedUnit(comptime quantity_: type, comptime scaleFactor_: comptime_float, comptime affineShift_: comptime_float) type {
    comptime {
        assertUnitQuantity(quantity_);
        if (scaleFactor_ == 0) {
            @compileError("scaleFactor_ is 0");
        }

        return struct {
            pub const quantity: type = quantity_;

            //to convert from base to derived unit, multiply number by scaleFactor_ then add affineShift_;
            pub const scaleFactor: comptime_float = scaleFactor_;
            pub const affineShift: comptime_float = affineShift_;

            number: UnitlessNumber,
        };
    }
}

fn GetQuantity(comptime T: type) type {
    comptime {
        if (T == UnitlessNumber) {
            return UnitlessQuantity;
        }
        assertUnit(T);
        return T.quantity;
    }
}

fn QuantityMultiply(comptime quantity1: type, comptime quantity2: type) type {
    comptime return MakeCompositeQuantity(&[_]TypeValuePair{ .{ .t = quantity1, .v = 1 }, .{ .t = quantity2, .v = 1 } });
}

fn QuantityDivide(comptime quantity1: type, comptime quantity2: type) type {
    comptime return MakeCompositeQuantity(&[_]TypeValuePair{ .{ .t = quantity1, .v = 1 }, .{ .t = quantity2, .v = -1 } });
}

fn QuantityPow(comptime quantity: type, comptime pow_: comptime_int) type {
    comptime return MakeCompositeQuantity(&[_]TypeValuePair{.{ .t = quantity, .v = pow_ }});
}

fn GetBaseUnitType(comptime T: type) type {
    comptime {
        if (T == UnitlessNumber) {
            return T;
        }
        switch (satisfiesBaseUnit(T)) {
            .Yes => return T,
            .No => {
                assertDerivedUnit(T);
                return T.quantity.unit;
            },
        }
    }
}

fn convertToBaseUnit(a: anytype) GetBaseUnitType(@TypeOf(a)) {
    if (@TypeOf(a) == UnitlessNumber) {
        return a;
    }
    switch (comptime satisfiesBaseUnit(@TypeOf(a))) {
        .Yes => return a,
        .No => return .{ .number = (a.number - @TypeOf(a).affineShift) / @TypeOf(a).scaleFactor },
    }
}

fn convertToUnit(a: anytype, Derived: type) Derived {
    comptime {
        assertUnit(@TypeOf(a));
        assertUnit(Derived);
        if (GetBaseUnitType(@TypeOf(a)) != GetBaseUnitType(Derived)) {
            @compileError("a and Derived have different base unit types");
        }
    }

    if (@TypeOf(a) == Derived) {
        return a;
    }

    switch (comptime satisfiesBaseUnit(Derived)) {
        .Yes => convertToBaseUnit(a),
        .No => {},
    }

    comptime assertDerivedUnit(Derived);

    return .{ .number = convertToBaseUnit(a).number * Derived.scaleFactor + Derived.affineShift };
}

fn add(a: anytype, b: anytype) GetBaseUnitType(@TypeOf(a)) {
    if (@TypeOf(a) == UnitlessNumber and @TypeOf(b) == UnitlessNumber) {
        return a + b;
    }

    comptime {
        assertUnit(@TypeOf(a));
        assertUnit(@TypeOf(b));
        if (GetBaseUnitType(@TypeOf(a)) != GetBaseUnitType(@TypeOf(b))) {
            @compileError("a and b have different base unit types");
        }
    }

    return .{ .number = convertToBaseUnit(a).number + convertToBaseUnit(b).number };
}

fn subtract(a: anytype, b: anytype) GetBaseUnitType(@TypeOf(a)) {
    if (@TypeOf(a) == UnitlessNumber and @TypeOf(b) == UnitlessNumber) {
        return a - b;
    }

    comptime {
        assertUnit(@TypeOf(a));
        assertUnit(@TypeOf(b));
        if (GetBaseUnitType(@TypeOf(a)) != GetBaseUnitType(@TypeOf(b))) {
            @compileError("a and b have different base unit types");
        }
    }

    return .{ .number = convertToBaseUnit(a).number - convertToBaseUnit(b).number };
}

fn multiply(a: anytype, b: anytype) QuantityMultiply(GetQuantity(@TypeOf(a)), GetQuantity(@TypeOf(b))).unit {
    if (@TypeOf(a) == UnitlessNumber and @TypeOf(b) == UnitlessNumber) {
        return a * b;
    }

    if (@TypeOf(a) == UnitlessNumber) {
        return .{ .number = a * convertToBaseUnit(b).number };
    }

    if (@TypeOf(b) == UnitlessNumber) {
        return .{ .number = convertToBaseUnit(a).number * b };
    }

    comptime assertUnit(@TypeOf(a));
    comptime assertUnit(@TypeOf(b));
    return .{ .number = convertToBaseUnit(a).number * convertToBaseUnit(b).number };
}

fn divide(a: anytype, b: anytype) QuantityDivide(GetQuantity(@TypeOf(a)), GetQuantity(@TypeOf(b))).unit {
    if (@TypeOf(a) == UnitlessNumber and @TypeOf(b) == UnitlessNumber) {
        return a / b;
    }

    if (@TypeOf(a) == UnitlessNumber) {
        return .{ .number = a / convertToBaseUnit(b).number };
    }

    if (@TypeOf(b) == UnitlessNumber) {
        return .{ .number = convertToBaseUnit(a).number / b };
    }

    comptime assertUnit(@TypeOf(a));
    comptime assertUnit(@TypeOf(b));
    return .{ .number = convertToBaseUnit(a).number / convertToBaseUnit(b).number };
}

fn pow(a: anytype, comptime b: comptime_int) QuantityPow(GetQuantity(@TypeOf(a)), b).unit {
    if (@TypeOf(a) == UnitlessNumber) {
        return std.math.pow(a, @floatFromInt(b));
    }

    comptime assertUnit(@TypeOf(a));
    return .{ .number = std.math.pow(UnitlessNumber, convertToBaseUnit(a).number, @floatFromInt(b)) };
}

// const Velocity: type = MakeCompositeQuantity(&.{ .{ .t = Length, .v = 1 }, .{ .t = Time, .v = -1 } });
// const Velocity2: type = MakeCompositeQuantity(&.{ .{ .t = Time, .v = -1 }, .{ .t = Length, .v = 1 } });
// const Length2: type = MakeCompositeQuantity(&.{ .{ .t = Velocity, .v = 1 }, .{ .t = Time, .v = 1 } });

const Celcius = MakeDerivedUnit(Temperature, 1, -273.15);
const Fahrenheit = MakeDerivedUnit(Temperature, 1.8, -459.67);

pub fn main() void {
    const c: Kelvin = .{ .number = 50 };
    std.debug.print("{} {d}\n", .{ @TypeOf(c), c.number });
    std.debug.print("{} {d}\n", .{ @TypeOf(multiply(c, 2.5)), multiply(c, 2.5).number });
}
