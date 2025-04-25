const std = @import("std");
const u = @import("units");

const units = u.units; //TODO: make "units.units" not confusing
const si = u.si;
const system = si.f64System.UnitSystem;
const base = si.f64System.baseUnits;
const derived = si.f64System.derivedUnits;

//a function to return the kinetic energy given mass and
//generic, takes in any valid mass and any valid velocity from the SI unit system
fn kineticEnergyGeneric(mass: anytype, velocity: anytype) t: {
    //a bunch of "type checking" to assert that mass and velocity are what they say they are. returns nice errors if you pass wrong things in.
    //type checking error is in the return type so the nice custom error always prints before any error related to the return type
    //technically this isn't necessary, but passing in invalid types could result in nonsense that's best to avoid
    units.assertUnit(@TypeOf(mass), "@TypeOf(mass)");
    units.assertRightSystem(@TypeOf(mass), system, "@TypeOf(mass)");
    units.assertRightQuantity(@TypeOf(mass), base.Mass, "@TypeOf(mass)", "base.Mass");
    units.assertUnit(@TypeOf(velocity), "TypeOf(velocity)");
    units.assertRightSystem(@TypeOf(velocity), system, "TypeOf(velocity)");
    units.assertRightQuantity(@TypeOf(velocity), derived.Velocity, "TypeOf(velocity)", "derived.Velocity");
    break :t derived.Joule;
} {
    return (system.One{ .number = 0.5 }).multiply(mass).multiply(velocity.pow(2)); //hilariously small function body
}

//alternatively, to avoid all the manual type checking, you can define a function that takes in specific types
//does the same thing
fn kineticEnergySpecific(mass: base.Kilogram, velocity: derived.Velocity.BaseUnit) derived.Joule {
    return (system.One{ .number = 0.5 }).multiply(mass).multiply(velocity.pow(2));
}

//you can imagine defining other functions for other physics formula

pub fn main() void {
    const myMass = base.Kilogram{ .number = 3 };
    const myVelocity = derived.Velocity.BaseUnit{ .number = 5 };
    std.debug.print("Kinetic Energy: {d} Joules\n", .{kineticEnergyGeneric(myMass, myVelocity).number});
    std.debug.print("Kinetic Energy: {d} Joules\n", .{kineticEnergySpecific(myMass, myVelocity).number});

    //std.debug.print("Kinetic Energy: {d} Joules\n", .{kineticEnergy(myVelocity, myMass).number}); //uncomment this line to see a nice custom error message
}
