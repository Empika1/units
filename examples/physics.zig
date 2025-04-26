//this file uses the unit system to solve a simple physics question

const std = @import("std");
const units = @import("units");

const core = units.core;
const si = units.si;

const system = si.f64System.UnitSystem;
const base = si.f64System.baseUnits;
const derived = si.f64System.derivedUnits;

//a function to return the kinetic energy given mass and velocity
//generic, takes in any valid mass and any valid velocity from the SI unit system
fn kineticEnergyGeneric(mass: anytype, velocity: anytype) t: {
    //a bunch of "type checking" to assert that mass and velocity are what they say they are. returns nice errors if you pass wrong things in.
    //type checking error is in the return type so the nice custom error always prints before any error related to the return type
    //technically this isn't necessary, but passing in invalid types could result in nonsense that's best to avoid
    core.assertUnit(@TypeOf(mass), "@TypeOf(mass)");
    core.assertRightSystem(@TypeOf(mass), system, "@TypeOf(mass)");
    core.assertRightQuantity(@TypeOf(mass), base.Mass, "@TypeOf(mass)", "base.Mass");
    core.assertUnit(@TypeOf(velocity), "TypeOf(velocity)");
    core.assertRightSystem(@TypeOf(velocity), system, "TypeOf(velocity)");
    core.assertRightQuantity(@TypeOf(velocity), derived.Velocity, "TypeOf(velocity)", "derived.Velocity");
    break :t derived.Joule;
} {
    //hilariously small function body
    return (system.One{ .number = 0.5 }).multiply(mass).multiply(velocity.pow(2)); //One and Dimensionless are the Unit and Quantity respectively for dimensionless numbers (like 0.5)
}

//alternatively, to avoid all the manual type checking, you can define a function that takes in specific types
//does the same thing
fn kineticEnergySpecific(mass: base.Kilogram, velocity: derived.Velocity.BaseUnit) derived.Joule {
    return (system.One{ .number = 0.5 }).multiply(mass).multiply(velocity.pow(2));
}

//a similar function but it calculates potential energy
fn gravitationalPotentialEnergyGeneric(mass: anytype, height: anytype) t: {
    core.assertUnit(@TypeOf(mass), "@TypeOf(mass)");
    core.assertRightSystem(@TypeOf(mass), system, "@TypeOf(mass)");
    core.assertRightQuantity(@TypeOf(mass), base.Mass, "@TypeOf(mass)", "base.Mass");
    core.assertUnit(@TypeOf(height), "TypeOf(height)");
    core.assertRightSystem(@TypeOf(height), system, "TypeOf(height)");
    core.assertRightQuantity(@TypeOf(height), base.Distance, "TypeOf(height)", "base.Distance");
    break :t derived.Joule;
} {
    return (derived.Acceleration.BaseUnit{ .number = 9.8 }).multiply(mass).multiply(height);
}

fn gravitationalPotentialEnergySpecific(mass: base.Kilogram, height: base.Meter) derived.Joule {
    return (derived.Acceleration.BaseUnit{ .number = 9.8 }).multiply(mass).multiply(height);
}

//you can imagine defining other functions for other physics formula

pub fn main() void {
    //PROBLEM:
    //you have a 3 pound mass moving at 50 kilometers per hour. can it get to the top of a 30 foot frictionless ramp?

    //define all your units
    const Pound = base.Kilogram.Derive(2.20462262185, 0);
    const Kilometer = base.Meter.Derive(1.0 / 1000.0, 0);
    const Hour = base.Second.Derive(1.0 / 3600.0, 0);
    const Foot = base.Meter.Derive(3.28083989501, 0);

    //define your variables
    const mass = Pound{ .number = 3 };
    const speed = Kilometer.Divide(Hour){ .number = 50 };
    const height = Foot{ .number = 30 };

    //calculating using generic functions:
    const kineticEnergy1 = kineticEnergyGeneric(mass, speed);
    const potentialEnergyNeeded1 = gravitationalPotentialEnergyGeneric(mass, height);
    if (kineticEnergy1.less(potentialEnergyNeeded1)) {
        std.debug.print("Can't make it :(. Kinetic energy is {d} Joules but you need {d} Joules\n", .{ kineticEnergy1.number, potentialEnergyNeeded1.number });
    } else {
        std.debug.print("Can make it :) Kinetic energy is {d} Joules and you only need {d} Joules\n", .{ kineticEnergy1.number, potentialEnergyNeeded1.number });
    }

    //calculating using specific functions:
    //have to convert values to base before passing them in, because the function need specific units
    const kineticEnergy2 = kineticEnergySpecific(mass.convertToBase(), speed.convertToBase());
    const potentialEnergyNeeded2 = gravitationalPotentialEnergySpecific(mass.convertToBase(), height.convertToBase());
    if (kineticEnergy2.less(potentialEnergyNeeded2)) {
        std.debug.print("Can't make it :(. Kinetic energy is {d} Joules but you need {d} Joules\n", .{ kineticEnergy2.number, potentialEnergyNeeded2.number });
    } else {
        std.debug.print("Can make it :) Kinetic energy is {d} Joules and you only need {d} Joules\n", .{ kineticEnergy2.number, potentialEnergyNeeded2.number });
    }

    //_ = kineticEnergyGeneric(height, speed); //uncomment this line to see a nice custom error message
}
