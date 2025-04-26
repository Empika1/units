//this file shows off some of the custom errors in the unit system

const std = @import("std");
const units = @import("units");

const core = units.core;
const si = units.si;

const f32system = si.f32System; //two incompatible unit systems
const f64system = si.f64System;

//uncomment each line to see a different error
//not all possible errors are shown but whatever
pub fn main() void {
    //_ = f32system.baseUnits.Distance.Multiply(f32); //f32 is not a Quantity

    //_ = f32system.baseUnits.Meter.Multiply(f32); //f32 is also not a Unit

    //_ = f32system.baseUnits.Distance.Multiply(f64system.baseUnits.Distance); //parameter is from the wrong Unit System

    //_ = (f32system.baseUnits.Meter{ .number = 1 }).add(f32system.baseUnits.Kilogram{ .number = 1 }); //Meter and Kilogram have different Quantities.
}
