//this file shows off the basics of the unit system

const std = @import("std");
const units = @import("units");

const si = units.si; //file defining the SI unit system and related things

const system = si.f64System.UnitSystem; //the actual unit system
const base = si.f64System.baseUnits; //the SI base units
const derived = si.f64System.derivedUnits; //the SI derived units (not used here)

pub fn main() void {
    const Celcius = base.Kelvin.Derive(1, -273.15); //define a new unit "Celcius" with Quantity of Temperature
    const Fahrenheit = Celcius.Derive(1.8, 32); //define a new unit "Fahrenheit" with Quantity of Temperature
    const myTemp = base.Kelvin{ .number = 1000 }; //define a temperature in Kelvin
    std.debug.print("Temp: {d} Kelvin = {d} Celcius = {d} Fahrenheit\n", .{ myTemp.number, myTemp.convert(Celcius).number, myTemp.convert(Fahrenheit).number }); //convert
}
