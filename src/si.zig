//defines SI Units

const std = @import("std");
const core = @import("core.zig");

pub fn MakeSiUnitSystem(comptime Num: type) type {
    return struct {
        /// The SI Unit System itself.
        /// Doesn't come with any defined Quantities or Units initially.
        pub const UnitSystem: type = core.MakeUnitSystem(Num);

        /// The 7 SI Base Quantities and their associated Base units.
        /// Sourced from https://en.wikipedia.org/wiki/SI_base_unit.
        /// Not sure I agree with Mole being a Base Unit, but whatever.
        pub const baseUnits: type = struct {
            pub const Time: type = UnitSystem.MakeBaseQuantity("Time");
            pub const Second: type = Time.BaseUnit;

            pub const Distance: type = UnitSystem.MakeBaseQuantity("Length");
            pub const Meter: type = Distance.BaseUnit;

            pub const Mass: type = UnitSystem.MakeBaseQuantity("Mass");
            pub const Kilogram: type = Mass.BaseUnit;

            pub const ElectricCurrent: type = UnitSystem.MakeBaseQuantity("ElectricCurrent");
            pub const Ampere: type = ElectricCurrent.BaseUnit;

            pub const Temperature: type = UnitSystem.MakeBaseQuantity("Temperature");
            pub const Kelvin: type = Temperature.BaseUnit;

            pub const Amount: type = UnitSystem.MakeBaseQuantity("Amount");
            pub const Mole: type = Amount.BaseUnit;

            pub const LuminousIntensity: type = UnitSystem.MakeBaseQuantity("LuminousIntensity");
            pub const Candela: type = Amount.BaseUnit;
        };

        /// Some commonly used SI Derived Quantities and Units.
        /// Sourced from https://en.wikipedia.org/wiki/SI_derived_unit.
        /// Various Quantities and Units are equal to another but used in different contexts.
        /// For example, Frequency and Radioactivity are technically equal.
        pub const derivedUnits: type = struct {
            //named units
            pub const Frequency: type = UnitSystem.Dimensionless.Divide(baseUnits.Time);
            pub const Hertz: type = Frequency.BaseUnit;

            pub const Angle: type = UnitSystem.MakeBaseQuantity("Angle");
            pub const Radian: type = Angle.BaseUnit;

            pub const SolidAngle: type = Angle.Pow(2);
            pub const Steradian: type = SolidAngle.BaseUnit;

            pub const Force: type = baseUnits.Mass.Multiply(baseUnits.Distance).Divide(baseUnits.Time.Pow(2));
            pub const Newton: type = Force.BaseUnit;

            pub const Pressure: type = Force.Divide(Area);
            pub const Pascal: type = Pressure.BaseUnit;

            pub const Energy: type = Force.Multiply(baseUnits.Distance);
            pub const Joule: type = Energy.BaseUnit;

            pub const Power: type = Energy.Divide(baseUnits.Time);
            pub const Watt: type = Power.BaseUnit;

            pub const ElectricCharge: type = baseUnits.Time.Multiply(baseUnits.ElectricCurrent);
            pub const Coulomb: type = ElectricCharge.BaseUnit;

            pub const Voltage: type = Power.Divide(baseUnits.ElectricCurrent);
            pub const Volt: type = Voltage.BaseUnit;

            pub const Capacitance: type = ElectricCharge.Divide(Voltage);
            pub const Farad: type = Capacitance.BaseUnit;

            pub const Resistance: type = Voltage.Divide(baseUnits.ElectricCurrent);
            pub const Ohm: type = Resistance.BaseUnit;

            pub const Conductance: type = baseUnits.ElectricCurrent.Divide(Voltage);
            pub const Siemens: type = Conductance.BaseUnit;

            pub const MagneticFlux: type = Energy.Divide(baseUnits.ElectricCurrent);
            pub const Weber: type = MagneticFlux.BaseUnit;

            pub const MagneticInduction: type = MagneticFlux.Divide(Area);
            pub const Tesla: type = MagneticInduction.BaseUnit;

            pub const Inductance: type = MagneticFlux.Divide(baseUnits.ElectricCurrent);
            pub const Henry: type = Inductance.BaseUnit;

            //pub const DegreeCelsius: type = baseUnits.Kelvin.Derive(1, -273.15); temperature is not defined because "1" and "-273.15" are only sensible numbers for floating point
            //so if you use a different number type, like in examples/customNums, this doesn't compile
            //define it yourself :(

            pub const LuminousFlux: type = baseUnits.LuminousIntensity.Multiply(SolidAngle);
            pub const Lumen: type = LuminousFlux.BaseUnit;

            pub const Illuminance: type = LuminousFlux.Divide(Area);
            pub const Lux: type = Illuminance.BaseUnit;

            pub const Radioactivity: type = Frequency;
            pub const Becquerel: type = Radioactivity.BaseUnit;

            pub const AbsorbedDose: type = Energy.Divide(baseUnits.Mass);
            pub const Gray: type = AbsorbedDose.BaseUnit;

            pub const EquivalentDose: type = AbsorbedDose;
            pub const Sievert: type = EquivalentDose.BaseUnit;

            pub const CatalyticActivity: type = baseUnits.Amount.Divide(baseUnits.Time);
            pub const Katal: type = CatalyticActivity.BaseUnit;

            //named quantities with nameless units
            //kinematics
            pub const Velocity: type = baseUnits.Distance.Divide(baseUnits.Time);
            pub const Acceleration: type = baseUnits.Distance.Divide(baseUnits.Time.Pow(2));
            pub const Jerk: type = baseUnits.Distance.Divide(baseUnits.Time.Pow(3));
            pub const Snap: type = baseUnits.Distance.Divide(baseUnits.Time.Pow(4));
            //mass flow rate is omitted because i'm not sure it's real
            pub const AngularVelocity: type = Angle.Divide(baseUnits.Time);
            pub const AngularAcceleration: type = Angle.Divide(baseUnits.Time.Pow(2));
            pub const FrequencyDrift: type = Frequency.Divide(baseUnits.Time);
            pub const VolumetricFlow: type = Volume.Divide(baseUnits.Time);

            //mechanics
            pub const Area: type = baseUnits.Distance.Pow(2);
            pub const Volume: type = baseUnits.Distance.Pow(3);
            pub const Momentum: type = Force.Multiply(baseUnits.Time);
            pub const AngularMomentum: type = Force.Multiply(baseUnits.Distance).Multiply(baseUnits.Time);
            pub const Torque: type = Force.Multiply(baseUnits.Distance);
            pub const Yank: type = Force.Divide(baseUnits.Time);
            pub const Wavenumber: type = baseUnits.Distance.Pow(-1);
            pub const AreaDensity: type = baseUnits.Mass.Divide(Area);
            pub const Density: type = baseUnits.Mass.Divide(Volume);
            pub const SpecificVolume: type = Volume.Divide(baseUnits.Mass);
            pub const Action: type = Energy.Multiply(baseUnits.Time);
            pub const SpecificEnergy: type = Energy.Divide(baseUnits.Mass);
            pub const EnergyDensity: type = Energy.Divide(Volume);
            pub const SurfaceTension: type = Force.Divide(baseUnits.Distance);
            pub const HeatFluxDensity: type = Power.Divide(Area);
            pub const KinematicViscosity: type = Area.Divide(baseUnits.Time);
            pub const DynamicViscosity: type = Pressure.Multiply(baseUnits.Time);
            pub const LinearMassDensity: type = baseUnits.Mass.Divide(baseUnits.Distance);
            pub const MassFlowRate: type = baseUnits.Mass.Divide(baseUnits.Time);
            pub const Radiance: type = Power.Divide(SolidAngle.Multiply(Area));
            pub const SpectralRadiance: type = Power.Divide(SolidAngle.Multiply(Volume));
            pub const SpectralPower: type = Power.Divide(baseUnits.Distance);
            pub const AbsorbedDoseRate: type = AbsorbedDose.Divide(baseUnits.Time);
            pub const FuelEfficiency: type = baseUnits.Distance.Divide(Volume);
            pub const PowerDensity: type = Power.Divide(Volume);
            pub const EnergyFluxDensity: type = Energy.Divide(Area.Multiply(baseUnits.Time));
            pub const Compressibility: type = Pressure.Pow(-1);
            pub const RadiantExposure: type = Energy.Divide(Area);
            pub const MomentOfInertia: type = baseUnits.Mass.Multiply(baseUnits.Distance.Pow(2));
            pub const SpecificAngularMomentum: type = AngularMomentum.Divide(baseUnits.Mass);
            pub const RadiantIntensity: type = Power.Divide(SolidAngle);
            pub const SpectralIntensity: type = Power.Divide(SolidAngle.Multiply(baseUnits.Distance));

            //chemistry
            pub const Molarity: type = baseUnits.Amount.Divide(Volume);
            pub const MolarVolume: type = Volume.Divide(baseUnits.Amount);
            pub const MolarHeatCapacity: type = Energy.Divide(baseUnits.Temperature.Multiply(baseUnits.Amount));
            pub const MolarEntropy: type = MolarHeatCapacity;
            pub const MolarEnergy: type = Energy.Divide(baseUnits.Amount);
            pub const MolarConductivity: type = Conductance.Multiply(Area).Divide(baseUnits.Amount);
            pub const Molality: type = baseUnits.Amount.Divide(baseUnits.Mass);
            pub const MolarMass: type = baseUnits.Mass.Divide(baseUnits.Amount);
            pub const CatalyticEfficiency: type = Volume.Divide(baseUnits.Amount.Multiply(baseUnits.Time));

            //electromagnetics
            pub const ElectricDisplacement: type = baseUnits.Time.Multiply(baseUnits.ElectricCurrent).Divide(Area);
            pub const ChargeDensity: type = baseUnits.Time.Multiply(baseUnits.ElectricCurrent).Divide(Volume);
            pub const CurrentDensity: type = baseUnits.ElectricCurrent.Divide(Area);
            pub const ElectricalConductivity: type = Conductance.Divide(baseUnits.Distance);
            pub const Permittivity: type = Capacitance.Divide(baseUnits.Distance);
            pub const Permeability: type = Inductance.Divide(baseUnits.Distance);
            pub const ElectricFieldStrength: type = Voltage.Divide(baseUnits.Distance);
            pub const MagneticFieldStrength: type = baseUnits.ElectricCurrent.Divide(baseUnits.Distance);
            pub const Magnetization: type = MagneticFieldStrength;
            pub const Exposure: type = baseUnits.Time.Multiply(baseUnits.ElectricCurrent).Divide(baseUnits.Mass);
            pub const Resistivity: type = Resistance.Multiply(baseUnits.Distance);
            pub const LinearChargeDensity: type = baseUnits.Time.Multiply(baseUnits.ElectricCurrent).Divide(baseUnits.Distance);
            pub const MagneticDipoleMoment: type = Energy.Divide(MagneticInduction);
            pub const ElectronMobility: type = Area.Divide(Voltage.Multiply(baseUnits.Time));
            pub const MagneticReluctance: type = Inductance.Pow(-1);
            pub const MagneticVectorPotential: type = MagneticFlux.Divide(baseUnits.Distance);
            pub const MagneticMoment: type = MagneticFlux.Multiply(baseUnits.Distance);
            pub const MagneticRigidity: type = MagneticInduction.Multiply(baseUnits.Distance);
            pub const MagnetomotiveForce: type = baseUnits.ElectricCurrent;
            pub const MagneticSusceptibility: type = baseUnits.Distance.Divide(Inductance);

            //photometry
            pub const LuminousEnergy: type = baseUnits.Time.Multiply(baseUnits.LuminousIntensity);
            pub const LuminousExposure: type = LuminousEnergy.Divide(Area);
            pub const Luminance: type = baseUnits.LuminousIntensity.Divide(Area);
            pub const LuminousEfficacy: type = baseUnits.LuminousIntensity.Divide(Power);

            //thermodynamics
            pub const HeatCapacity: type = Energy.Divide(baseUnits.Temperature);
            pub const Entropy: type = HeatCapacity;
            pub const SpecificHeatCapacity: type = HeatCapacity.Divide(baseUnits.Mass);
            pub const SpecificEntropy: type = SpecificHeatCapacity;
            pub const ThermalConductivity: type = Power.Divide(baseUnits.Distance.Multiply(baseUnits.Temperature));
            pub const ThermalResistance: type = baseUnits.Temperature.Divide(Power);
            pub const ThermalExpansionCoefficient: type = baseUnits.Temperature.Pow(-1);
            pub const TemperatureGradient: type = baseUnits.Temperature.Divide(baseUnits.Distance);
        };
    };
}

pub const f16System = MakeSiUnitSystem(f16);
pub const f32System = MakeSiUnitSystem(f32);
pub const f64System = MakeSiUnitSystem(f64);
pub const f128System = MakeSiUnitSystem(f128);
pub const comptime_floatSystem = MakeSiUnitSystem(comptime_float);
