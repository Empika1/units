const std = @import("std");
const interface = @import("interface.zig");
const result = @import("result.zig");

const TypeValuePair = struct {
    t: type,
    v: comptime_int,
};

// fn satisfiesQuantity(comptime Impl: type) result.Result {
//     comptime {
//         const Quantity = struct {
//             pub const bases: []const TypeValuePair = undefined;
//             pub const baseUnit: type = undefined;
//         };

//         return interface.satisfiesInterface(Quantity, Impl);
//     }
// }

// fn assertQuantity(comptime Impl: type) void {
//     comptime {
//         const res = satisfiesQuantity(Impl);
//         switch (res) {
//             .Yes => {},
//             .No => @compileError(res.No),
//         }
//     }
// }

// fn satisfiesUnit(comptime Impl: type) result.Result {
//     comptime {
//         const Unit = struct {
//             pub const scale: Num = undefined;
//             pub const shift: Num = undefined;
//             pub const quantity: type = undefined;
//             number: f64,
//         };

//         return interface.satisfiesInterface(Unit, Impl);
//     }
// }

// fn assertUnit(comptime Impl: type) void {
//     comptime {
//         const res = satisfiesUnit(Impl);
//         switch (res) {
//             .Yes => {},
//             .No => @compileError(res.No),
//         }
//     }
// }

pub fn MakeUnitSystem(
    Num: type,
    numAdd: fn (Num, Num) Num,
    numSubtract: fn (Num, Num) Num,
    numMultiply: fn (Num, Num) Num,
    numDivide: fn (Num, Num) Num,
    numPow: fn (Num, comptime_int) Num,
) type {
    return struct {
        const system_ = struct {
            pub const Dimensionless: type = MakeBaseQuantity("One");
            pub const One: type = Dimensionless.baseUnit;

            fn normalizeBases(bases: []const TypeValuePair) []const TypeValuePair {
                var basesReduced: []const TypeValuePair = &.{};
                for (0..bases.len) |i| {
                    //assertQuantity(bases[i].t);
                    if (bases[i].t == Dimensionless) { //ignore dimensionless quantity
                    } else if (bases[i].t.bases.len == 0) { // base unit
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
                @setEvalBranchQuota(100000); //yikes
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

            fn MakeQuantity(uuid: anytype, bases_: []const TypeValuePair) type {
                return struct {
                    const quantity_ = struct {
                        comptime {
                            _ = uuid;
                        }
                        pub const bases: []const TypeValuePair = bases_;
                        pub const baseUnit: type = unit;
                        pub const system: type = system_;

                        pub fn multiply(other: type) type {
                            return QuantityMultiply(@This(), other);
                        }

                        pub fn divide(other: type) type {
                            return QuantityDivide(@This(), other);
                        }

                        pub fn pow(other: comptime_int) type {
                            return QuantityPow(@This(), other);
                        }
                    };
                    const unit = MakeUnit(1, 0, quantity_);
                }.quantity_;
            }

            pub fn MakeBaseQuantity(uuid: anytype) type {
                return MakeQuantity(uuid, &.{});
            }

            pub fn MakeCompositeQuantity(bases_: []const TypeValuePair) type {
                const basesNormalized = normalizeBases(bases_);
                if (basesNormalized.len == 0) {
                    return Dimensionless;
                }

                return MakeQuantity(0, basesNormalized);
            }

            fn QuantityMultiply(T1: type, T2: type) type {
                return MakeCompositeQuantity(&.{ .{ .t = T1, .v = 1 }, .{ .t = T2, .v = 1 } });
            }

            fn QuantityDivide(T1: type, T2: type) type {
                return MakeCompositeQuantity(&.{ .{ .t = T1, .v = 1 }, .{ .t = T2, .v = -1 } });
            }

            fn QuantityPow(T: type, pow: comptime_int) type {
                return MakeCompositeQuantity(&.{.{ .t = T, .v = pow }});
            }

            fn MakeUnit(scale_: Num, shift_: Num, quantity_: type) type {
                return struct {
                    //BaseUnit.number * scale_ + shift_ = number
                    pub const scale: Num = scale_;
                    pub const shift: Num = shift_;
                    pub const quantity: type = quantity_;
                    pub const system: type = system_;
                    number: Num,

                    pub fn GetBaseUnit() type {
                        return quantity.baseUnit;
                    }

                    pub fn Derive(scale__: Num, shift__: Num) type {
                        return DeriveUnit(@This(), scale__, shift__);
                    }

                    pub fn Multiply(other: type) type {
                        return UnitMultiply(@This(), other);
                    }

                    pub fn Divide(other: type) type {
                        return UnitDivide(@This(), other);
                    }

                    pub fn Pow(other: comptime_int) type {
                        return UnitPow(@This(), other);
                    }

                    pub fn convert(self: @This(), to: type) to {
                        return unitConvert(self, to);
                    }

                    pub fn convertToBase(self: @This()) quantity.baseUnit {
                        return unitConvert(self, quantity.baseUnit);
                    }

                    pub fn add(self: @This(), other: anytype) GetBaseUnit() {
                        return unitAdd(self, other);
                    }

                    pub fn subtract(self: @This(), other: anytype) GetBaseUnit() {
                        return unitSubtract(self, other);
                    }

                    pub fn multiply(self: @This(), other: anytype) @TypeOf(self).quantity.Multiply(@TypeOf(other).quantity).baseUnit {
                        return unitMultiply(self, other);
                    }

                    pub fn divide(self: @This(), other: anytype) @TypeOf(self).quantity.Divide(@TypeOf(other).quantity).baseUnit {
                        return unitDivide(self, other);
                    }

                    pub fn pow(self: @This(), other: comptime_int) @TypeOf(self).quantity.Pow(other).baseUnit {
                        return unitPow(self, other);
                    }
                };
            }

            //BaseUnit.number * scale_ + shift_ = DerivedUnit.number
            fn DeriveUnit(StartingUnit: type, scale_: Num, shift_: Num) type {
                //assertQuantity(Quantity);

                //(BaseUnit.number * StartingUnit.scale + StartingUnit.shift) * scale_ + shift_ = DerivedUnit
                //BaseUnit.number * StartingUnit.scale * scale_ + StartingUnit.shift * scale_ + shift_ = DerivedUnit
                //scale = StartingUnit.scale * scale_, shift = StartingUnit.shift * scale_ + shift_

                return MakeUnit(StartingUnit.scale * scale_, StartingUnit.shift * scale_ + shift_, StartingUnit.quantity);
            }

            // fn assertHaveSameQuantity(comptime Unit1: type, comptime Unit2: type) void {
            //     comptime {
            //         assertUnit(Unit1);
            //         assertUnit(Unit2);
            //         if (Unit1.quantity != Unit2.quantity) {
            //             @compileError("T1 and T2 have different quantity types");
            //         }
            //     }
            // }

            fn UnitMultiply(a: type, b: type) type {
                if (a.shift != 0) {
                    @compileError("Cannot multiply a unit (a) with a nonzero shift");
                }
                if (b.shift != 0) {
                    @compileError("Cannot multiply a unit (b) with a nonzero shift");
                }

                return QuantityMultiply(a.quantity, b.quantity).baseUnit.Derive(a.scale * b.scale, 0);
            }

            fn UnitDivide(a: type, b: type) type {
                if (a.shift != 0) {
                    @compileError("Cannot divide a unit (a) with a nonzero shift");
                }
                if (b.shift != 0) {
                    @compileError("Cannot divide a unit (b) with a nonzero shift");
                }

                return QuantityDivide(a.quantity, b.quantity).baseUnit.Derive(a.scale / b.scale, 0);
            }

            fn UnitPow(a: type, pow: comptime_int) type {
                if (a.shift != 0) {
                    @compileError("Cannot exponentiate a unit (a) with a nonzero shift");
                }

                return QuantityPow(a.quantity, pow).baseUnit.Derive(numPow(a.scale, pow), 0);
            }

            fn unitConvert(from: anytype, To: type) To {
                //comptime assertHaveSameQuantity(@TypeOf(from), To);
                return .{ .number = (from.number - @TypeOf(from).shift) / @TypeOf(from).scale * To.scale + To.shift };
            }

            fn unitAdd(a: anytype, b: anytype) @TypeOf(a).GetBaseUnit() {
                //comptime assertHaveSameQuantity(@TypeOf(a), @TypeOf(b));
                return .{ .number = numAdd(a.convertToBase().number, b.convertToBase().number) };
            }

            fn unitSubtract(a: anytype, b: anytype) @TypeOf(a).GetBaseUnit() {
                //comptime assertHaveSameQuantity(@TypeOf(a), @TypeOf(b));
                return .{ .number = numSubtract(a.convertToBase().number, b.convertToBase().number) };
            }

            fn unitMultiply(a: anytype, b: anytype) QuantityMultiply(@TypeOf(a).quantity, @TypeOf(b).quantity).baseUnit {
                return .{ .number = numMultiply(a.convertToBase().number, b.convertToBase().number) };
            }

            fn unitDivide(a: anytype, b: anytype) QuantityDivide(@TypeOf(a).quantity, @TypeOf(b).quantity).baseUnit {
                return .{ .number = numDivide(a.convertToBase().number, b.convertToBase().number) };
            }

            fn unitPow(a: anytype, pow: comptime_int) QuantityPow(@TypeOf(a).quantity, pow).baseUnit {
                return .{ .number = numPow(a.convertToBase().number, pow) };
            }
        };
    }.system_;
}

// //
// pub const Speed: type = UnitSystem.QuantityDivide(Distance, Time);

// pub const Acceleration: type = UnitSystem.QuantityDivide(Speed, Time);

// pub const Force: type = UnitSystem.QuantityMultiply(Mass, Acceleration);
// pub const Newton: type = Force.baseUnit;

// pub const Energy: type = UnitSystem.QuantityMultiply(Force, Distance);
// pub const Joule: type = Energy.baseUnit;

// pub const Power: type = UnitSystem.QuantityDivide(Energy, Distance);
// pub const Watt: type = Power.baseUnit;

// pub fn gravPotentialEnergy(m: anytype, h: anytype) Joule {
//     const g: Acceleration.baseUnit = .{ .number = 9.8 };
//     return m.multiply(g).multiply(h);
// }

// pub const Foot: type = UnitSystem.MakeDerivedUnit(Distance, 3.28083989501, 0);
// pub const Pound: type = UnitSystem.MakeDerivedUnit(Mass, 2.20462262185, 0);
// pub const Celcius: type = UnitSystem.MakeDerivedUnit(Temperature, 1, -273.15);
// pub const Fahrenheit: type = UnitSystem.MakeDerivedUnit(Temperature, 1.8, -459.67);
