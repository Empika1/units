//the heart of the package
//defines how Unit Systems, Quantities, and Units work

const std = @import("std");

const SystemID: type = struct {};
const QuantityID: type = struct {};
const UnitID: type = struct {};

/// For type checking.
/// Checks if a struct passed in has a const decl called "ID" with a value of IdT.
pub fn hasID(T: type, IdT: type) bool {
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
            if (!@typeInfo(@TypeOf(&T.ID)).pointer.is_const) {
                return false;
            }
            if (@TypeOf(T.ID) != type) {
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

/// For type checking.
/// Asserts that the System type passed in a Unit System.
/// name is the name of the System. Used for a better error message
pub fn assertUnitSystem(System: type, name: []const u8) void {
    if (!hasID(System, SystemID)) {
        @compileError(std.fmt.comptimePrint(
            "{s} ({s}) is not a Unit System. Create a Unit System via MakeUnitSystem.",
            .{ name, @typeName(System) },
        ));
    }
}

/// For type checking.
/// Asserts that the Quantity type passed in a Quantity.
/// name is the name of the Quantity. Used for a better error message
pub fn assertQuantity(Quantity: type, name: []const u8) void {
    if (!hasID(Quantity, QuantityID)) {
        @compileError(std.fmt.comptimePrint(
            "{s} ({s}) is not a Quantity. Create a Quantity via MakeBaseQuantity, MakeCompositeBaseQuantity, or from an existing Quantity or Unit.",
            .{ name, @typeName(Quantity) },
        ));
    }
}

/// For type checking.
/// Asserts that the Unit type passed in a Unit.
/// name is the name of the Unit. Used for a better error message
pub fn assertUnit(Unit: type, name: []const u8) void {
    if (!hasID(Unit, UnitID)) {
        @compileError(std.fmt.comptimePrint(
            "{s} ({s}) is not a Unit. Create a Unit via an existing Quantity or Unit",
            .{ name, @typeName(Unit) },
        ));
    }
}

/// For type checking.
/// Assumes you have already verified that T is a Quantity or Unit.
/// Asserts that the Quantity/Unit T is from the right Unit System.
/// name is the name of the Quantity/Unit. Used for a better error message.
pub fn assertRightSystem(comptime T: type, comptime System: type, comptime name: []const u8) void {
    if (T.System != System) {
        @compileError(std.fmt.comptimePrint(
            "{s} ({s}) is from the wrong Unit System.",
            .{ name, @typeName(T) },
        ));
    }
}

/// For type checking.
/// Assumes you have already verified that T1 and T2 are Quantities or Units.
/// Asserts that T1 and T2 are from the same Unit System.
/// name1 and name2 are the names of T1 and T2. Used for a better error message.
pub fn assertSameSystem(comptime T1: type, comptime T2: type, comptime name1: []const u8, comptime name2: []const u8) void {
    if (T1.System != T2.System) {
        @compileError(std.fmt.comptimePrint(
            "{s} ({s}) is from a different unit system than {s} ({s}).",
            .{ name1, @typeName(T1), name2, @typeName(T2) },
        ));
    }
}

/// For type checking.
/// Assumes you have already verified that Unit is a Unit and Quantity is a Quantity.
/// Asserts that Unit has a Quantity of Quantity.
/// unitName and quantityName are the names of Unit and Quantity. Used for a better error message.
pub fn assertRightQuantity(comptime Unit: type, comptime Quantity: type, comptime unitName: []const u8, comptime quantityName: []const u8) void {
    if (Unit.Quantity != Quantity) {
        @compileError(std.fmt.comptimePrint(
            "{s} ({s})'s Quantity is not {s} ({s}).",
            .{ unitName, @typeName(Unit), quantityName, @typeName(Quantity) },
        ));
    }
}

/// For type checking.
/// Assumes you have already verified that Unit1 and Unit2 are Units.
/// Asserts that Unit1 and Unit2 have the same Quantity.
/// name1 and name2 are the names of T1 and T2. Used for a better error message.
pub fn assertSameQuantity(comptime Unit1: type, comptime Unit2: type, comptime name1: []const u8, comptime name2: []const u8) void {
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
    comptime Num: type,
    comptime numAdd: fn (Num, Num) Num,
    comptime numSubtract: fn (Num, Num) Num,
    comptime numMultiply: fn (Num, Num) Num,
    comptime numDivide: fn (Num, Num) Num,
    comptime numPow: fn (Num, comptime_int) Num,
    comptime numOrder: fn (Num, Num) std.math.Order,
) type {
    @setEvalBranchQuota(1000000);
    return struct {
        const System_ = struct {
            /// A tag which marks this generated type as a Unit System.
            /// Don't manually add this to a struct.
            pub const ID = SystemID;
            /// The number type this system uses.
            pub const NumType = Num;
            /// A Dimensionless (aka unitless) Quantity.
            pub const Dimensionless: type = MakeBaseQuantity("One");
            /// The Unit which measures a Dimensionless Quantity. Not literally the number 1.
            pub const One: type = Dimensionless.BaseUnit;

            ///"normalizes" the bases passed in into base quantities, in a single, sorted, combined, order
            fn normalizeBases(comptime bases: []const TypeIntPair) []const TypeIntPair {
                //get all the base quantities
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

                //sort all the bases so repeats can be removed
                const sortFunc: fn (void, TypeIntPair, TypeIntPair) bool = struct {
                    pub fn inner(_: void, a: TypeIntPair, b: TypeIntPair) bool {
                        return std.mem.order(u8, @typeName(a.t), @typeName(b.t)) == std.math.Order.gt;
                    }
                }.inner;
                var basesSorted: [basesReduced.len]TypeIntPair = basesReduced[0..].*;
                @setEvalBranchQuota(100000); //yikes
                std.mem.sort(TypeIntPair, &basesSorted, {}, sortFunc);

                //remove the repeats and bases with a value of 0
                var basesNoRepeats = [_]TypeIntPair{TypeIntPair{ .t = undefined, .v = 0 }} ** basesReduced.len;
                var i = 0;
                var j = -1;
                while (i < basesSorted.len) : (i += 1) {
                    if (i == 0 or basesSorted[i].t != basesSorted[i - 1].t) {
                        if (j < 0 or basesNoRepeats[j].v != 0) {
                            j += 1;
                        }
                        basesNoRepeats[j] = basesSorted[i];
                    } else {
                        basesNoRepeats[j].v += basesSorted[i].v;
                    }
                }
                if (j < 0 or basesNoRepeats[j].v != 0) {
                    j += 1;
                }

                const basesConstSlice = basesNoRepeats[0..j].*;
                return &basesConstSlice;
            }

            /// Makes a type which represents a Quantity.
            /// A Quantity can be a Base Quantity or a Derived Quantity (which is built from Base Quantities).
            /// For example, Velocity can be built from the Base Quantities of Distance and Time.
            /// Or Volume can be built from the Base Quantity of Distance with a power of 3.
            fn MakeQuantity(comptime uuid: anytype, comptime bases_: []const TypeIntPair) type {
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
                        pub fn Multiply(comptime Other: type) t: {
                            assertQuantity(Other, "Other");
                            assertRightSystem(Other, System, "Other");
                            break :t type;
                        } {
                            return QuantityMultiply(@This(), Other);
                        }

                        /// Divides this Quantity by another Quantity to make a new Quantity.
                        /// For example: "Velocity = Distance.Multiply(Time)".
                        pub fn Divide(comptime Other: type) t: {
                            assertQuantity(Other, "Other");
                            assertRightSystem(Other, System, "Other");
                            break :t type;
                        } {
                            return QuantityDivide(@This(), Other);
                        }

                        /// Exponentiates this Quantity to make a new Quantity.
                        /// For example: "Area = Distance.Pow(2)".
                        pub fn Pow(comptime exp: comptime_int) type {
                            return QuantityPow(@This(), exp);
                        }
                    };

                    /// The Base Unit for the quantity (note the scale of 1 and shift of 0).
                    const Unit = MakeUnit(1, 0, Quantity);
                }.Quantity;
            }

            pub fn MakeBaseQuantity(comptime uuid: anytype) type {
                return MakeQuantity(uuid, &.{});
            }

            pub fn MakeCompositeQuantity(comptime bases_: []const TypeIntPair) type {
                const basesNormalized = normalizeBases(bases_);
                if (basesNormalized.len == 0) {
                    return Dimensionless;
                }

                return MakeQuantity(0, basesNormalized);
            }

            fn QuantityMultiply(comptime T1: type, comptime T2: type) type {
                return MakeCompositeQuantity(&.{ .{ .t = T1, .v = 1 }, .{ .t = T2, .v = 1 } });
            }

            fn QuantityDivide(comptime T1: type, comptime T2: type) type {
                return MakeCompositeQuantity(&.{ .{ .t = T1, .v = 1 }, .{ .t = T2, .v = -1 } });
            }

            fn QuantityPow(comptime T: type, comptime exp: comptime_int) type {
                return MakeCompositeQuantity(&.{.{ .t = T, .v = exp }});
            }

            /// Makes a type which represents a Unit.
            /// Multiple Units can measure the same Quantity.
            /// For example, both Meter and Foot can measure Distance.
            /// The Unit with scale = 1 and shift = 0 is the "Base Unit".
            /// All other Units (derived Units) of the same Quantity are converted to the Base Unit before math is done on them.
            /// baseUnit.number * derivedUnit.scale + derivedUnit.shift = derivedUnit.number.
            fn MakeUnit(comptime scale_: Num, comptime shift_: Num, comptime Quantity_: type) type {
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
                    pub fn Derive(comptime scale__: Num, comptime shift__: Num) type {
                        comptime if (scale__ == 0) @compileError("Cannot derive a Unit with a scale__ of 0");
                        return DeriveUnit(@This(), scale__, shift__);
                    }

                    /// Multiplies this Unit by another Unit to create a new Unit.
                    /// For example, you could write "Joule = Newton.Multiply(Meter)".
                    /// Only works with Units whose scales are 0.
                    pub fn Multiply(comptime Other: type) t: {
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
                    pub fn Divide(comptime Other: type) t: {
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
                    pub fn Pow(comptime exp: comptime_int) t: {
                        if (shift != 0) @compileError("@This() has a nonzero shift.");
                        break :t type;
                    } {
                        comptime if (shift != 0) @compileError("@This() has a nonzero shift.");
                        return UnitPow(@This(), exp);
                    }

                    /// Converts a value from one Unit to another.
                    /// For example, you could write "TemperatureInCelcius = TemperatureInKelvin.Convert(Celcius)".
                    pub fn convert(self: @This(), comptime to: type) t: {
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
                    pub fn pow(self: @This(), comptime exp: comptime_int) @TypeOf(self).Quantity.Pow(exp).BaseUnit {
                        return unitPow(self, exp);
                    }

                    /// Orders self and other.
                    pub fn order(self: @This(), other: anytype) t: {
                        assertUnit(@TypeOf(other), "@TypeOf(other)");
                        assertSameQuantity(@This(), @TypeOf(other), "@This()", "@TypeOf(other)");
                        break :t std.math.Order;
                    } {
                        return unitOrder(self, other);
                    }

                    /// Checks if self < other.
                    pub fn less(self: @This(), other: anytype) t: {
                        assertUnit(@TypeOf(other), "@TypeOf(other)");
                        assertSameQuantity(@This(), @TypeOf(other), "@This()", "@TypeOf(other)");
                        break :t bool;
                    } {
                        return unitLess(self, other);
                    }

                    /// Checks if self <= other.
                    pub fn lessOrEqual(self: @This(), other: anytype) t: {
                        assertUnit(@TypeOf(other), "@TypeOf(other)");
                        assertSameQuantity(@This(), @TypeOf(other), "@This()", "@TypeOf(other)");
                        break :t bool;
                    } {
                        return unitLessOrEqual(self, other);
                    }

                    /// Checks if self == other.
                    pub fn equal(self: @This(), other: anytype) t: {
                        assertUnit(@TypeOf(other), "@TypeOf(other)");
                        assertSameQuantity(@This(), @TypeOf(other), "@This()", "@TypeOf(other)");
                        break :t bool;
                    } {
                        return unitEqual(self, other);
                    }

                    /// Checks if self >= other.
                    pub fn greaterOrEqual(self: @This(), other: anytype) t: {
                        assertUnit(@TypeOf(other), "@TypeOf(other)");
                        assertSameQuantity(@This(), @TypeOf(other), "@This()", "@TypeOf(other)");
                        break :t bool;
                    } {
                        return unitGreaterOrEqual(self, other);
                    }

                    /// Checks if self > other.
                    pub fn greater(self: @This(), other: anytype) t: {
                        assertUnit(@TypeOf(other), "@TypeOf(other)");
                        assertSameQuantity(@This(), @TypeOf(other), "@This()", "@TypeOf(other)");
                        break :t bool;
                    } {
                        return unitGreater(self, other);
                    }
                };
            }

            fn DeriveUnit(comptime StartingUnit: type, comptime scale_: Num, comptime shift_: Num) type {
                return MakeUnit(numMultiply(StartingUnit.scale, scale_), numAdd(numMultiply(StartingUnit.shift, scale_), shift_), StartingUnit.Quantity);
            }

            fn UnitMultiply(comptime A: type, comptime B: type) type {
                return QuantityMultiply(A.Quantity, B.Quantity).BaseUnit.Derive(numMultiply(A.scale, B.scale), 0);
            }

            fn UnitDivide(comptime A: type, comptime B: type) type {
                return QuantityDivide(A.Quantity, B.Quantity).BaseUnit.Derive(numDivide(A.scale, B.scale), 0);
            }

            fn UnitPow(comptime A: type, comptime exp: comptime_int) type {
                return QuantityPow(A.Quantity, exp).BaseUnit.Derive(numPow(A.scale, exp), 0);
            }

            fn unitConvert(from: anytype, comptime To: type) To {
                return .{ .number = numDivide(numSubtract(from.number, @TypeOf(from).shift), numAdd(numMultiply(@TypeOf(from).scale, To.scale), To.shift)) };
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

            fn unitPow(a: anytype, comptime exp: comptime_int) QuantityPow(@TypeOf(a).Quantity, exp).BaseUnit {
                return .{ .number = numPow(a.convertToBase().number, exp) };
            }

            fn unitOrder(a: anytype, b: anytype) std.math.Order {
                return numOrder(a.convertToBase().number, b.convertToBase().number);
            }

            fn unitLess(a: anytype, b: anytype) bool {
                return switch (unitOrder(a, b)) {
                    .lt => true,
                    .eq => false,
                    .gt => false,
                };
            }

            fn unitLessOrEqual(a: anytype, b: anytype) bool {
                return switch (unitOrder(a, b)) {
                    .lt => true,
                    .eq => true,
                    .gt => false,
                };
            }

            fn unitEqual(a: anytype, b: anytype) bool {
                return switch (unitOrder(a, b)) {
                    .lt => false,
                    .eq => true,
                    .gt => false,
                };
            }

            fn unitGreaterOrEqual(a: anytype, b: anytype) bool {
                return switch (unitOrder(a, b)) {
                    .lt => false,
                    .eq => true,
                    .gt => true,
                };
            }

            fn unitGreater(a: anytype, b: anytype) bool {
                return switch (unitOrder(a, b)) {
                    .lt => false,
                    .eq => false,
                    .gt => true,
                };
            }
        };
    }.System_;
}
