const std = @import("std");

const SystemID: type = struct {};
const QuantityID: type = struct {};
const UnitID: type = struct {};

fn hasID(T: type, IdT: type) bool {
    const tInfo = @typeInfo(T);
    switch (tInfo) {
        .@"struct" => {
            var ID: ?std.builtin.Type.Declaration = null;
            inline for (tInfo.@"struct".decls) |decl| {
                if (std.mem.eql(u8, decl.name, "ID")) {
                    ID = decl;
                }
            }
            if (ID == null) {
                return false;
            }
            if (T.ID != IdT) {
                return false;
            }
            return true;
        },
        else => return false,
    }
}

fn assertUnitSystem(System: type, name: []const u8) void {
    if (!hasID(System, SystemID)) {
        @compileError(std.fmt.comptimePrint(
            "{s} ({s}) is not a Unit System. Create a Unit System via MakeUnitSystem.",
            .{ name, @typeName(System) },
        ));
    }
}

fn assertQuantity(Quantity: type, name: []const u8) void {
    if (!hasID(Quantity, QuantityID)) {
        @compileError(std.fmt.comptimePrint(
            "{s} ({s}) is not a Quantity. Create a Quantity via MakeBaseQuantity, MakeCompositeBaseQuantity, or from an existing Quantity or Unit.",
            .{ name, @typeName(Quantity) },
        ));
    }
}

fn assertUnit(Unit: type, name: []const u8) void {
    if (!hasID(Unit, UnitID)) {
        @compileError(std.fmt.comptimePrint(
            "{s} ({s}) is not a Unit. Create a Unit via an existing Quantity or Unit",
            .{ name, @typeName(Unit) },
        ));
    }
}

fn assertRightSystem(T: type, System: type, name: []const u8) void {
    if (T.System != System) {
        @compileError(std.fmt.comptimePrint(
            "{s} ({s}) is from the wrong Unit System.",
            .{ name, @typeName(T) },
        ));
    }
}

fn assertSameQuantity(Unit1: type, Unit2: type, name1: []const u8, name2: []const u8) void {
    if (Unit1.Quantity != Unit2.Quantity) {
        @compileError(std.fmt.comptimePrint(
            "{s} ({s}) has a different Quantity than {s} ({s}).",
            .{ name1, @typeName(Unit1), name2, @typeName(Unit2) },
        ));
    }
}

/// A structure that stores a type and an int together.
pub const TypeIntPair = struct {
    t: type,
    v: comptime_int,
};

/// Makes a Unit System from a base number type and arithmetic functions which act on the number type.
/// All Quantities and Units belong to a Unit System, and Quantities/Units from different Unit Systems cannot be used together.
/// Quantities are things like length, time, and energy: all things which can be measured.
/// Quantities are represented as types which satisfy certain constraints.
/// Units are things like meters, seconds, joules: all things which measure quantities. Units are also represented as types which satisfy certain other constraints.
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
            /// A tag which marks this generated type as a Unit System.
            /// Don't manually add this to a struct.
            pub const ID = SystemID;
            /// A Dimensionless (aka unitless) Quantity.
            pub const Dimensionless: type = MakeBaseQuantity("One");
            /// The Unit which measures a Dimensionless Quantity. Not literally the number 1.
            pub const One: type = Dimensionless.BaseUnit;

            fn normalizeBases(bases: []const TypeIntPair) []const TypeIntPair {
                var basesReduced: []const TypeIntPair = &.{};
                for (0..bases.len) |i| {
                    if (bases[i].t == Dimensionless) { //ignore Dimensionless Quantity
                    } else if (bases[i].t.bases.len == 0) { // Base Unit
                        basesReduced = basesReduced ++ [_]TypeIntPair{bases[i]};
                    } else { //Derived/composite Unit
                        for (normalizeBases(bases[i].t.bases)) |baseToAdd| {
                            basesReduced = basesReduced ++ [_]TypeIntPair{.{ .t = baseToAdd.t, .v = baseToAdd.v * bases[i].v }};
                        }
                    }
                }

                const sortFunc: fn (void, TypeIntPair, TypeIntPair) bool = struct {
                    pub fn inner(_: void, a: TypeIntPair, b: TypeIntPair) bool {
                        return std.mem.order(u8, @typeName(a.t), @typeName(b.t)) == std.math.Order.gt;
                    }
                }.inner;

                var basesSorted: [basesReduced.len]TypeIntPair = basesReduced[0..].*;
                @setEvalBranchQuota(100000); //yikes
                std.mem.sort(TypeIntPair, &basesSorted, {}, sortFunc);

                var basesNoRepeats = [_]TypeIntPair{TypeIntPair{ .t = undefined, .v = 0 }} ** basesReduced.len;
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

            /// Makes a type which represents a Quantity.
            /// A Quantity can be a Base Quantity or a Derived Quantity (which is built from Base Quantities).
            /// For example, Velocity can be built from the Base Quantities of Distance and Time.
            /// Or Volume can be built from the Base Quantity of Distance with a power of 3.
            fn MakeQuantity(uuid: anytype, bases_: []const TypeIntPair) type {
                return struct {
                    const Quantity = struct {
                        comptime {
                            _ = uuid; // Here so calling this function with different uuids actually makes different structs.
                        }
                        /// A tag which marks this generated type as a Quantity.
                        /// Don't manually add this to a struct.
                        pub const ID = QuantityID;
                        /// The Base Quantities (and powers) which this Quantity is built from.
                        /// If this slice has length 0, this is a Base Quantity.
                        /// Otherwise, this is a Derived Quantity.
                        pub const bases: []const TypeIntPair = bases_;
                        /// The Base Unit which measures this Quantity.
                        /// Each Quantity has a Base Unit.
                        pub const BaseUnit: type = Unit;
                        /// The Unit System this Unit is a part of.
                        pub const System: type = System_;

                        /// Multiplies this Quantity by another Quantity to make a new Quantity.
                        /// For example: "Energy = Force.Multiply(Distance)".
                        pub fn Multiply(Other: type) t: {
                            assertQuantity(Other, "Other");
                            assertRightSystem(Other, System, "Other");
                            break :t type;
                        } {
                            return QuantityMultiply(@This(), Other);
                        }

                        /// Divides this Quantity by another Quantity to make a new Quantity.
                        /// For example: "Velocity = Distance.Multiply(Time)".
                        pub fn Divide(Other: type) t: {
                            assertQuantity(Other, "Other");
                            assertRightSystem(Other, System, "Other");
                            break :t type;
                        } {
                            return QuantityDivide(@This(), Other);
                        }

                        /// Exponentiates this Quantity to make a new Quantity.
                        /// For example: "Area = Distance.Pow(2)".
                        pub fn Pow(exp: comptime_int) type {
                            return QuantityPow(@This(), exp);
                        }
                    };

                    /// The Base Unit for the quantity (note the scale of 1 and shift of 0).
                    const Unit = MakeUnit(1, 0, Quantity);
                }.Quantity;
            }

            pub fn MakeBaseQuantity(uuid: anytype) type {
                return MakeQuantity(uuid, &.{});
            }

            pub fn MakeCompositeQuantity(bases_: []const TypeIntPair) type {
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

            /// Makes a type which represents a Unit.
            /// Multiple Units can measure the same Quantity.
            /// For example, both Meter and Foot can measure Distance.
            /// The Unit with scale = 1 and shift = 0 is the "Base Unit".
            /// All other Units (derived Units) of the same Quantity are converted to the Base Unit before math is done on them.
            /// baseUnit.number * derivedUnit.scale + derivedUnit.shift = derivedUnit.number.
            fn MakeUnit(scale_: Num, shift_: Num, Quantity_: type) type {
                return struct {
                    /// A tag which marks this generated type as a Unit.
                    /// Don't manually add this to a struct.
                    pub const ID = UnitID;
                    /// baseUnit.number * derivedUnit.scale + derivedUnit.shift = derivedUnit.number.
                    /// If scale = 1 and shift = 1, this Unit is a Base Unit.
                    pub const scale: Num = scale_;
                    /// baseUnit.number * derivedUnit.scale + derivedUnit.shift = derivedUnit.number.
                    /// If scale = 1 and shift = 1, this Unit is a Base Unit.
                    pub const shift: Num = shift_;
                    /// The Quantity this Unit measures.
                    pub const Quantity: type = Quantity_;
                    /// The Unit System this Unit is a part of.
                    pub const System: type = System_;
                    /// The number this Unit stores.
                    number: Num,

                    /// Reaturns the Base Unit of this Unit's Quantity.
                    pub fn GetBaseUnit() type {
                        return Quantity.BaseUnit;
                    }

                    /// Derives another Unit from this Unit.
                    /// The Derived Unit measures the same Quantity.
                    /// For example, you could write "Centimeter = Meter.Derive(100, 0)".
                    /// Or "Fahrenheit = Celcius.Derive(1.8, 32)".
                    pub fn Derive(scale__: Num, shift__: Num) type {
                        comptime if (scale__ == 0) @compileError("Cannot derive a Unit with a scale__ of 0");
                        return DeriveUnit(@This(), scale__, shift__);
                    }

                    /// Multiplies this Unit by another Unit to create a new Unit.
                    /// For example, you could write "Joule = Newton.Multiply(Meter)".
                    /// Only works with Units whose scales are 0.
                    pub fn Multiply(Other: type) t: {
                        assertUnit(Other, "Other");
                        assertRightSystem(Other, System, "Other");
                        if (shift != 0) @compileError("@This() has a nonzero shift.");
                        if (Other.shift != 0) @compileError("Other has a nonzero shift.");
                        break :t type;
                    } {
                        return UnitMultiply(@This(), Other);
                    }

                    /// Multiplies this Unit by another Unit to create a new Unit.
                    /// For example, you could write "KPH = Kilometer.Divide(Hour)".
                    /// Only works with Units whose scales are 0.
                    pub fn Divide(Other: type) t: {
                        assertUnit(Other, "Other");
                        assertRightSystem(Other, System, "Other");
                        if (shift != 0) @compileError("@This() has a nonzero shift.");
                        if (Other.shift != 0) @compileError("Other has a nonzero shift.");
                        break :t type;
                    } {
                        return UnitDivide(@This(), Other);
                    }

                    /// Exponentiates this Unit to create another Unit.
                    /// For example: "SquareFoot = Foot.Pow(2)".
                    /// Only works with a Unit whose scale is 0.
                    pub fn Pow(exp: comptime_int) t: {
                        if (shift != 0) @compileError("@This() has a nonzero shift.");
                        break :t type;
                    } {
                        comptime if (shift != 0) @compileError("@This() has a nonzero shift.");
                        return UnitPow(@This(), exp);
                    }

                    /// Converts a value from one Unit to another.
                    /// For example, you could write "TemperatureInCelcius = TemperatureInKelvin.Convert(Celcius)".
                    pub fn convert(self: @This(), to: type) t: {
                        assertUnit(to, "to");
                        assertSameQuantity(@This(), to, "@This()", "to");
                        break :t to;
                    } {
                        return unitConvert(self, to);
                    }

                    /// Converts a value from one Unit to its Base Unit.
                    pub fn convertToBase(self: @This()) Quantity.BaseUnit {
                        return unitConvert(self, Quantity.BaseUnit);
                    }

                    /// Adds another value to this.
                    /// Values must measure the same Quantity (but can be different Units).
                    /// For example: "myTotalDistance = myFirstDistance.add(mySecondDistance)".
                    pub fn add(self: @This(), other: anytype) t: {
                        assertUnit(@TypeOf(other), "@TypeOf(other)");
                        assertSameQuantity(@This(), @TypeOf(other), "@This()", "@TypeOf(other)");
                        break :t GetBaseUnit();
                    } {
                        return unitAdd(self, other);
                    }

                    /// Subtracts another value from this.
                    /// Values must measure the same Quantity (but can be different Units).
                    /// For example: "myDeltaT = myStartingTemperature.subtract(myEndingTemperature)".
                    pub fn subtract(self: @This(), other: anytype) t: {
                        assertUnit(@TypeOf(other), "@TypeOf(other)");
                        assertSameQuantity(@This(), @TypeOf(other), "@This()", "@TypeOf(other)");
                        break :t GetBaseUnit();
                    } {
                        return unitSubtract(self, other);
                    }

                    /// Multiplies another value by this.
                    /// Values need not measure the same Quantity.
                    /// For example: "myWork = myForce.multiply(myDistance)".
                    pub fn multiply(self: @This(), other: anytype) t: {
                        assertUnit(@TypeOf(other), "@TypeOf(other)");
                        assertRightSystem(@TypeOf(other), System, "@TypeOf(other)");
                        break :t @TypeOf(self).Quantity.Multiply(@TypeOf(other).Quantity).BaseUnit;
                    } {
                        comptime assertUnit(@TypeOf(other), "@TypeOf(other)");
                        comptime assertRightSystem(@TypeOf(other), System, "@TypeOf(other)");
                        return unitMultiply(self, other);
                    }

                    /// Divides another value by this.
                    /// Values need not measure the same Quantity.
                    /// For example: "myVelocity = myDistance.divide(myTime)".
                    pub fn divide(self: @This(), other: anytype) t: {
                        assertUnit(@TypeOf(other), "@TypeOf(other)");
                        assertRightSystem(@TypeOf(other), System, "@TypeOf(other)");
                        break :t @TypeOf(self).Quantity.Divide(@TypeOf(other).Quantity).BaseUnit;
                    } {
                        return unitDivide(self, other);
                    }

                    /// Exponentiates this value.
                    /// For example: "myCubesArea: CubicMeter = myCubeLength.pow(3)".
                    pub fn pow(self: @This(), exp: comptime_int) @TypeOf(self).Quantity.Pow(exp).BaseUnit {
                        return unitPow(self, exp);
                    }
                };
            }

            fn DeriveUnit(StartingUnit: type, scale_: Num, shift_: Num) type {
                return MakeUnit(StartingUnit.scale * scale_, StartingUnit.shift * scale_ + shift_, StartingUnit.Quantity);
            }

            fn UnitMultiply(A: type, B: type) type {
                return QuantityMultiply(A.Quantity, B.Quantity).BaseUnit.Derive(A.scale * B.scale, 0);
            }

            fn UnitDivide(a: type, b: type) type {
                return QuantityDivide(a.Quantity, b.Quantity).BaseUnit.Derive(a.scale / b.scale, 0);
            }

            fn UnitPow(a: type, exp: comptime_int) type {
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

            fn unitMultiply(a: anytype, b: anytype) QuantityMultiply(@TypeOf(a).Quantity, @TypeOf(b).Quantity).BaseUnit {
                return .{ .number = numMultiply(a.convertToBase().number, b.convertToBase().number) };
            }

            fn unitDivide(a: anytype, b: anytype) QuantityDivide(@TypeOf(a).Quantity, @TypeOf(b).Quantity).BaseUnit {
                return .{ .number = numDivide(a.convertToBase().number, b.convertToBase().number) };
            }

            fn unitPow(a: anytype, exp: comptime_int) QuantityPow(@TypeOf(a).Quantity, exp).BaseUnit {
                return .{ .number = numPow(a.convertToBase().number, exp) };
            }
        };
    }.System_;
}
