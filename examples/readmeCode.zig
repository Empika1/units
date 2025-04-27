pub fn ex1() void {
    const std = @import("std");

    const units = @import("units");
    const core = units.core;

    //define a Unit System based on any float type
    const System = core.MakeUnitSystem(f64);

    //define some base Quantities and Units for your system
    const Distance = System.MakeBaseQuantity("Distance");
    const Meter = Distance.BaseUnit;

    const Mass = System.MakeBaseQuantity("Mass");
    const Kilogram = Mass.BaseUnit;

    const Time = System.MakeBaseQuantity("Time");
    const Second = Time.BaseUnit;

    //derive some more Quantities from your base Units
    const AstronomicalUnit = Meter.Derive(6.6846e-12, 0);

    const SolarMass = Kilogram.Derive(5.02785e-31, 0);

    const Minute = Second.Derive(1.0 / 60.0, 0);
    const Hour = Minute.Derive(1.0 / 60.0, 0);
    const Day = Hour.Derive(1.0 / 24.0, 0);
    const Year = Day.Derive(1.0 / 365.0, 0);

    const Joule = Kilogram.Multiply(Meter.Pow(2)).Divide(Second.Pow(2));
    const Gigajoule = Joule.Derive(1e-9, 0);

    //do some math with your Units
    //do you wanna know how much kinetic energy a star 5x the mass of the sun moving at 0.5 AU per year would have?
    const starMass = SolarMass{ .number = 5 };
    const starVelocity = AstronomicalUnit.Divide(Year){ .number = 0.5 }; //this has a Quantity of velocity, even though it was never explicitly defined
    const starEnergy = starMass.multiply(starVelocity.pow(2)).divide(System.One{ .number = 2 }); //and this is in Joules
    std.debug.print("{}", .{starEnergy.convert(Gigajoule).number}); //you can also convert Units manually: mainly useful for display
}

pub fn ex2() void {
    const units = @import("units");
    const core = units.core;
    const si = units.si;

    //alternatively, use a predefined SI Unit System
    const System = si.f64System.UnitSystem;
    const baseUnits = si.f64System.baseUnits;
    const derivedUnits = si.f64System.derivedUnits;

    //you can still define your own base or derived Units to use with the system
    const Foot = baseUnits.Meter.Derive(3.28084, 0);
    const Celcius = baseUnits.Kelvin.Derive(1, -273.15);

    _ = core;
    _ = System;
    _ = derivedUnits;
    _ = Foot;
    _ = Celcius;
}

pub fn main() void {
    ex1();
    ex2();
}
