const std = @import("std");
const interface = @import("interface.zig");
const result = @import("result.zig");

const TypeValuePair = struct {
    t: type,
    v: comptime_int,
};

pub fn MakeUnitSystem(
    Num: type,
    numAdd: fn (Num, Num) Num,
    numSubtract: fn (Num, Num) Num,
    numMultiply: fn (Num, Num) Num,
    numDivide: fn (Num, Num) Num,
    numPow: fn (Num, comptime_int) Num,
) type {
    return struct {
        const System_ = struct {
            pub const Dimensionless: type = MakeBaseQuantity("One");
            pub const One: type = Dimensionless.BaseUnit;

            fn normalizeBases(bases: []const TypeValuePair) []const TypeValuePair {
                var basesReduced: []const TypeValuePair = &.{};
                for (0..bases.len) |i| {
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
                    const Quantity = struct {
                        comptime {
                            _ = uuid;
                        }
                        pub const bases: []const TypeValuePair = bases_;
                        pub const BaseUnit: type = Unit;
                        pub const System: type = System_;

                        pub fn Multiply(Other: type) type {
                            return QuantityMultiply(@This(), Other);
                        }

                        pub fn Divide(Other: type) type {
                            return QuantityDivide(@This(), Other);
                        }

                        pub fn Pow(exp: comptime_int) type {
                            return QuantityPow(@This(), exp);
                        }
                    };
                    const Unit = MakeUnit(1, 0, Quantity);
                }.Quantity;
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

            fn QuantityPow(T: type, exp: comptime_int) type {
                return MakeCompositeQuantity(&.{.{ .t = T, .v = exp }});
            }

            fn MakeUnit(scale_: Num, shift_: Num, Quantity_: type) type {
                return struct {
                    //BaseUnit.number * scale_ + shift_ = number
                    pub const scale: Num = scale_;
                    pub const shift: Num = shift_;
                    pub const Quantity: type = Quantity_;
                    pub const System: type = System_;
                    number: Num,

                    pub fn GetBaseUnit() type {
                        return Quantity.baseUnit;
                    }

                    pub fn Derive(scale__: Num, shift__: Num) type {
                        return DeriveUnit(@This(), scale__, shift__);
                    }

                    pub fn Multiply(Other: type) type {
                        return UnitMultiply(@This(), Other);
                    }

                    pub fn Divide(Other: type) type {
                        return UnitDivide(@This(), Other);
                    }

                    pub fn Pow(exp: comptime_int) type {
                        return UnitPow(@This(), exp);
                    }

                    pub fn convert(self: @This(), to: type) to {
                        return unitConvert(self, to);
                    }

                    pub fn convertToBase(self: @This()) Quantity.baseUnit {
                        return unitConvert(self, Quantity.baseUnit);
                    }

                    pub fn add(self: @This(), other: anytype) GetBaseUnit() {
                        return unitAdd(self, other);
                    }

                    pub fn subtract(self: @This(), other: anytype) GetBaseUnit() {
                        return unitSubtract(self, other);
                    }

                    pub fn multiply(self: @This(), other: anytype) @TypeOf(self).Quantity.multiply(@TypeOf(other).quantity).baseUnit {
                        return unitMultiply(self, other);
                    }

                    pub fn divide(self: @This(), other: anytype) @TypeOf(self).Quantity.divide(@TypeOf(other).quantity).baseUnit {
                        return unitDivide(self, other);
                    }

                    pub fn pow(self: @This(), exp: comptime_int) @TypeOf(self).Quantity.pow(exp).baseUnit {
                        return unitPow(self, exp);
                    }
                };
            }

            fn DeriveUnit(StartingUnit: type, scale_: Num, shift_: Num) type {
                return MakeUnit(StartingUnit.scale * scale_, StartingUnit.shift * scale_ + shift_, StartingUnit.Quantity);
            }

            fn UnitMultiply(A: type, B: type) type {
                if (A.shift != 0) {
                    @compileError("Cannot multiply a unit (a) with a nonzero shift");
                }
                if (B.shift != 0) {
                    @compileError("Cannot multiply a unit (b) with a nonzero shift");
                }

                return QuantityMultiply(A.Quantity, B.Quantity).BaseUnit.Derive(A.scale * B.scale, 0);
            }

            fn UnitDivide(a: type, b: type) type {
                if (a.shift != 0) {
                    @compileError("Cannot divide a unit (a) with a nonzero shift");
                }
                if (b.shift != 0) {
                    @compileError("Cannot divide a unit (b) with a nonzero shift");
                }

                return QuantityDivide(a.Quantity, b.Quantity).BaseUnit.Derive(a.scale / b.scale, 0);
            }

            fn UnitPow(a: type, exp: comptime_int) type {
                if (a.shift != 0) {
                    @compileError("Cannot exponentiate a unit (a) with a nonzero shift");
                }

                return QuantityPow(a.Quantity, exp).BaseUnit.Derive(numPow(a.scale, exp), 0);
            }

            fn unitConvert(from: anytype, To: type) To {
                return .{ .number = (from.number - @TypeOf(from).shift) / @TypeOf(from).scale * To.scale + To.shift };
            }

            fn unitAdd(a: anytype, b: anytype) @TypeOf(a).GetBaseUnit() {
                return .{ .number = numAdd(a.convertToBase().number, b.convertToBase().number) };
            }

            fn unitSubtract(a: anytype, b: anytype) @TypeOf(a).GetBaseUnit() {
                return .{ .number = numSubtract(a.convertToBase().number, b.convertToBase().number) };
            }

            fn unitMultiply(a: anytype, b: anytype) QuantityMultiply(@TypeOf(a).Quantity, @TypeOf(b).quantity).BaseUnit {
                return .{ .number = numMultiply(a.convertToBase().number, b.convertToBase().number) };
            }

            fn unitDivide(a: anytype, b: anytype) QuantityDivide(@TypeOf(a).Quantity, @TypeOf(b).quantity).BaseUnit {
                return .{ .number = numDivide(a.convertToBase().number, b.convertToBase().number) };
            }

            fn unitPow(a: anytype, exp: comptime_int) QuantityPow(@TypeOf(a).Quantity, exp).BaseUnit {
                return .{ .number = numPow(a.convertToBase().number, exp) };
            }
        };
    }.System_;
}
