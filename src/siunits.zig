const units = @import("units.zig");
const num = @import("num.zig");

pub fn MakeSiUnitSystem(
    Num: type,
    numAdd: fn (Num, Num) Num,
    numSubtract: fn (Num, Num) Num,
    numMultiply: fn (Num, Num) Num,
    numDivide: fn (Num, Num) Num,
    numPow: fn (Num, comptime_int) Num,
) type {
    return struct {
        /// The SI Unit System itself.
        /// Doesn't come with any defined Quantities or Units initially.
        pub const UnitSystem: type = units.MakeUnitSystem(Num, numAdd, numSubtract, numMultiply, numDivide, numPow);

        /// The 7 SI Base Quantities and their associated Base units.
        /// Sourced from https://en.wikipedia.org/wiki/SI_base_unit.
        /// Not sure I agree with Mole being a Base Unit, but whatever.
        pub const BaseUnits: type = struct {
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
        pub const DerivedUnits: type = struct {
            //named units
            pub const Frequency: type = UnitSystem.Dimensionless.Divide(BaseUnits.Time);
            pub const Hertz: type = Frequency.BaseUnit;

            pub const Angle: type = UnitSystem.MakeBaseQuantity("Angle");
            pub const Radian: type = Angle.BaseUnit;

            pub const SolidAngle: type = Angle.Pow(2);
            pub const Steradian: type = SolidAngle.BaseUnit;

            pub const Force: type = BaseUnits.Mass.Multiply(BaseUnits.Distance).Divide(BaseUnits.Time.Pow(2));
            pub const Newton: type = Force.BaseUnit;

            pub const Pressure: type = Force.Divide(Area);
            pub const Pascal: type = Pressure.BaseUnit;

            pub const Energy: type = Force.Multiply(BaseUnits.Distance);
            pub const Joule: type = Energy.BaseUnit;

            pub const Power: type = Energy.Divide(BaseUnits.Time);
            pub const Watt: type = Power.BaseUnit;

            pub const ElectricCharge: type = BaseUnits.Time.Multiply(BaseUnits.ElectricCurrent);
            pub const Coulomb: type = ElectricCharge.BaseUnit;

            pub const Voltage: type = Power.Divide(BaseUnits.ElectricCurrent);
            pub const Volt: type = Voltage.BaseUnit;

            pub const Capacitance: type = ElectricCharge.Divide(Voltage);
            pub const Farad: type = Capacitance.BaseUnit;

            pub const Resistance: type = Voltage.Divide(BaseUnits.ElectricCurrent);
            pub const Ohm: type = Resistance.BaseUnit;

            pub const Conductance: type = BaseUnits.ElectricCurrent.Divide(Voltage);
            pub const Siemens: type = Conductance.BaseUnit;

            pub const MagneticFlux: type = Energy.Divide(BaseUnits.ElectricCurrent);
            pub const Weber: type = MagneticFlux.BaseUnit;

            pub const MagneticInduction: type = MagneticFlux.Divide(Area);
            pub const Tesla: type = MagneticInduction.BaseUnit;

            pub const Inductance: type = MagneticFlux.Divide(BaseUnits.ElectricCurrent);
            pub const Henry: type = Inductance.BaseUnit;

            /// Temperature already exists as a Base Quantity, so no new Quantity is needed.
            pub const DegreeCelsius: type = BaseUnits.Kelvin.Derive(1, -273.15);

            pub const LuminousFlux: type = BaseUnits.LuminousIntensity.Multiply(SolidAngle);
            pub const Lumen: type = LuminousFlux.BaseUnit;

            pub const Illuminance: type = LuminousFlux.Divide(Area);
            pub const Lux: type = Illuminance.BaseUnit;

            pub const Radioactivity: type = Frequency;
            pub const Becquerel: type = Radioactivity.BaseUnit;

            pub const AbsorbedDose: type = Energy.Divide(BaseUnits.Mass);
            pub const Gray: type = AbsorbedDose.BaseUnit;

            pub const EquivalentDose: type = AbsorbedDose;
            pub const Sievert: type = EquivalentDose.BaseUnit;

            pub const CatalyticActivity: type = BaseUnits.Amount.Divide(BaseUnits.Time);
            pub const Katal: type = CatalyticActivity.BaseUnit;

            //named quantities with nameless units
            //kinematics
            pub const Velocity: type = BaseUnits.Distance.Divide(BaseUnits.Time);
            pub const Acceleration: type = BaseUnits.Distance.Divide(BaseUnits.Time.Pow(2));
            pub const Jerk: type = BaseUnits.Distance.Divide(BaseUnits.Time.Pow(3));
            pub const Snap: type = BaseUnits.Distance.Divide(BaseUnits.Time.Pow(4));
            //mass flow rate is omitted because i'm not sure it's real
            pub const AngularVelocity: type = Angle.Divide(BaseUnits.Time);
            pub const AngularAcceleration: type = Angle.Divide(BaseUnits.Time.Pow(2));
            pub const FrequencyDrift: type = Frequency.Divide(BaseUnits.Time);
            pub const VolumetricFlow: type = Volume.Divide(BaseUnits.Time);

            //mechanics
            pub const Area: type = BaseUnits.Distance.Pow(2);
            pub const Volume: type = BaseUnits.Distance.Pow(3);
            pub const Momentum: type = Force.Multiply(BaseUnits.Time);
            pub const AngularMomentum: type = Force.Multiply(BaseUnits.Distance).Multiply(BaseUnits.Time);
            pub const Torque: type = Force.Multiply(BaseUnits.Distance);
            pub const Yank: type = Force.Divide(BaseUnits.Time);
            pub const Wavenumber: type = BaseUnits.Distance.Pow(-1);
            pub const AreaDensity: type = BaseUnits.Mass.Divide(Area);
            pub const Density: type = BaseUnits.Mass.Divide(Volume);
            pub const SpecificVolume: type = Volume.Divide(BaseUnits.Mass);
            pub const Action: type = Energy.Multiply(BaseUnits.Time);
            pub const SpecificEnergy: type = Energy.Divide(BaseUnits.Mass);
            pub const EnergyDensity: type = Energy.Divide(Volume);
            pub const SurfaceTension: type = Force.Divide(BaseUnits.Distance);
            pub const HeatFluxDensity: type = Power.Divide(Area);
            pub const KinematicViscosity: type = Area.Divide(BaseUnits.Time);
            pub const DynamicViscosity: type = Pressure.Multiply(BaseUnits.Time);
            pub const LinearMassDensity: type = BaseUnits.Mass.Divide(BaseUnits.Distance);
            pub const MassFlowRate: type = BaseUnits.Mass.Divide(BaseUnits.Time);
            pub const Radiance: type = Power.Divide(SolidAngle.Multiply(Area));
            pub const SpectralRadiance: type = Power.Divide(SolidAngle.Multiply(Volume));
            pub const SpectralPower: type = Power.Divide(BaseUnits.Distance);
            pub const AbsorbedDoseRate: type = AbsorbedDose.Divide(BaseUnits.Time);
            pub const FuelEfficiency: type = BaseUnits.Distance.Divide(Volume);
            pub const PowerDensity: type = Power.Divide(Volume);
            pub const EnergyFluxDensity: type = Energy.Divide(Area.Multiply(BaseUnits.Time));
            pub const Compressibility: type = Pressure.Pow(-1);
            pub const RadiantExposure: type = Energy.Divide(Area);
            pub const MomentOfInertia: type = BaseUnits.Mass.Multiply(BaseUnits.Distance.Pow(2));
            pub const SpecificAngularMomentum: type = AngularMomentum.Divide(BaseUnits.Mass);
            pub const RadiantIntensity: type = Power.Divide(SolidAngle);
            pub const SpectralIntensity: type = Power.Divide(SolidAngle.Multiply(BaseUnits.Distance));

            //chemistry
            pub const Molarity: type = BaseUnits.Amount.Divide(Volume);
            pub const MolarVolume: type = Volume.Divide(BaseUnits.Amount);
            pub const MolarHeatCapacity: type = Energy.Divide(BaseUnits.Temperature.Multiply(BaseUnits.Amount));
            pub const MolarEntropy: type = MolarHeatCapacity;
            pub const MolarEnergy: type = Energy.Divide(BaseUnits.Amount);
            pub const MolarConductivity: type = Conductance.Multiply(Area).Divide(BaseUnits.Amount);
            pub const Molality: type = BaseUnits.Amount.Divide(BaseUnits.Mass);
            pub const MolarMass: type = BaseUnits.Mass.Divide(BaseUnits.Amount);
            pub const CatalyticEfficiency: type = Volume.Divide(BaseUnits.Amount.Multiply(BaseUnits.Time));

            //electromagnetics
            pub const ElectricDisplacement: type = BaseUnits.Time.Multiply(BaseUnits.ElectricCurrent).Divide(Area);
            pub const ChargeDensity: type = BaseUnits.Time.Multiply(BaseUnits.ElectricCurrent).Divide(Volume);
            pub const CurrentDensity: type = BaseUnits.ElectricCurrent.Divide(Area);
            pub const ElectricalConductivity: type = Conductance.Divide(BaseUnits.Distance);
            pub const Permittivity: type = Capacitance.Divide(BaseUnits.Distance);
            pub const Permeability: type = Inductance.Divide(BaseUnits.Distance);
            pub const ElectricFieldStrength: type = Voltage.Divide(BaseUnits.Distance);
            pub const MagneticFieldStrength: type = BaseUnits.ElectricCurrent.Divide(BaseUnits.Distance);
            pub const Magnetization: type = MagneticFieldStrength;
            pub const Exposure: type = BaseUnits.Time.Multiply(BaseUnits.ElectricCurrent).Divide(BaseUnits.Mass);
            pub const Resistivity: type = Resistance.Multiply(BaseUnits.Distance);
            pub const LinearChargeDensity: type = BaseUnits.Time.Multiply(BaseUnits.ElectricCurrent).Divide(BaseUnits.Distance);
            pub const MagneticDipoleMoment: type = Energy.Divide(MagneticInduction);
            pub const ElectronMobility: type = Area.Divide(Voltage.Multiply(BaseUnits.Time));
            pub const MagneticReluctance: type = Inductance.Pow(-1);
            pub const MagneticVectorPotential: type = MagneticFlux.Divide(BaseUnits.Distance);
            pub const MagneticMoment: type = MagneticFlux.Multiply(BaseUnits.Distance);
            pub const MagneticRigidity: type = MagneticInduction.Multiply(BaseUnits.Distance);
            pub const MagnetomotiveForce: type = BaseUnits.ElectricCurrent;
            pub const MagneticSusceptibility: type = BaseUnits.Distance.Divide(Inductance);

            //photometry
            pub const LuminousEnergy: type = BaseUnits.Time.Multiply(BaseUnits.LuminousIntensity);
            pub const LuminousExposure: type = LuminousEnergy.Divide(Area);
            pub const Luminance: type = BaseUnits.LuminousIntensity.Divide(Area);
            pub const LuminousEfficacy: type = BaseUnits.LuminousIntensity.Divide(Power);

            //thermodynamics
            pub const HeatCapacity: type = Energy.Divide(BaseUnits.Temperature);
            pub const Entropy: type = HeatCapacity;
            pub const SpecificHeatCapacity: type = HeatCapacity.Divide(BaseUnits.Mass);
            pub const SpecificEntropy: type = SpecificHeatCapacity;
            pub const ThermalConductivity: type = Power.Divide(BaseUnits.Distance.Multiply(BaseUnits.Temperature));
            pub const ThermalResistance: type = BaseUnits.Temperature.Divide(Power);
            pub const ThermalExpansionCoefficient: type = BaseUnits.Temperature.Pow(-1);
            pub const TemperatureGradient: type = BaseUnits.Temperature.Divide(BaseUnits.Distance);
        };
    };
}

/// The SI System with f32 as its number type.
pub const f32System = MakeSiUnitSystem(f32, num.f32System.add, num.f32System.subtract, num.f32System.multiply, num.f32System.divide, num.f32System.pow);
/// The SI System with f64 as its number type.
pub const f64System = MakeSiUnitSystem(f64, num.f64System.add, num.f64System.subtract, num.f64System.multiply, num.f64System.divide, num.f64System.pow);
