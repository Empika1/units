const units = @import("units.zig");
const num = @import("num.zig");

pub fn MakeSiUnitSystem(
    comptime Num: type,
    comptime numAdd: fn (Num, Num) Num,
    comptime numSubtract: fn (Num, Num) Num,
    comptime numMultiply: fn (Num, Num) Num,
    comptime numDivide: fn (Num, Num) Num,
    comptime numPow: fn (Num, comptime comptime_int) Num,
) type {
    comptime return struct {
        pub const UnitSystem: type = units.MakeUnitSystem(Num, numAdd, numSubtract, numMultiply, numDivide, numPow);
        pub const BaseUnits: type = struct {
            pub const Time: type = UnitSystem.MakeBaseQuantity("Time");
            pub const Second: type = Time.baseUnit;

            pub const Distance: type = UnitSystem.MakeBaseQuantity("Length");
            pub const Meter: type = Distance.baseUnit;

            pub const Mass: type = UnitSystem.MakeBaseQuantity("Mass");
            pub const Kilogram: type = Mass.baseUnit;

            pub const ElectricCurrent: type = UnitSystem.MakeBaseQuantity("ElectricCurrent");
            pub const Ampere: type = ElectricCurrent.baseUnit;

            pub const Temperature: type = UnitSystem.MakeBaseQuantity("Temperature");
            pub const Kelvin: type = Temperature.baseUnit;

            pub const Amount: type = UnitSystem.MakeBaseQuantity("Amount");
            pub const Mole: type = Amount.baseUnit;

            pub const LuminousIntensity: type = UnitSystem.MakeBaseQuantity("LuminousIntensity");
            pub const Candela: type = Amount.baseUnit;
        };

        //sourced from https://en.wikipedia.org/wiki/SI_derived_unit
        //various quantities and units are equal to another but used in different contexts
        //for example, frequency and radioactivity have the same base quantities.
        pub const DerivedUnits: type = struct {
            //named units
            pub const Frequency: type = UnitSystem.Dimensionless.divide(BaseUnits.Time);
            pub const Hertz: type = Frequency.baseUnit;

            pub const Angle: type = UnitSystem.MakeBaseQuantity("Angle");
            pub const Radian: type = Angle.baseUnit;

            pub const SolidAngle: type = Angle.pow(2);
            pub const Steradian: type = SolidAngle.baseUnit;

            pub const Force: type = BaseUnits.Mass.multiply(BaseUnits.Distance).divide(BaseUnits.Time.pow(2));
            pub const Newton: type = Force.baseUnit;

            pub const Pressure: type = Force.divide(Area);
            pub const Pascal: type = Pressure.baseUnit;

            pub const Energy: type = Force.multiply(BaseUnits.Distance);
            pub const Joule: type = Energy.baseUnit;

            pub const Power: type = Energy.divide(BaseUnits.Time);
            pub const Watt: type = Power.baseUnit;

            pub const ElectricCharge: type = BaseUnits.Time.multiply(BaseUnits.ElectricCurrent);
            pub const Coulomb: type = ElectricCharge.baseUnit;

            pub const Voltage: type = Power.divide(BaseUnits.ElectricCurrent);
            pub const Volt: type = Voltage.baseUnit;

            pub const Capacitance: type = ElectricCharge.divide(Voltage);
            pub const Farad: type = Capacitance.baseUnit;

            pub const Resistance: type = Voltage.divide(BaseUnits.ElectricCurrent);
            pub const Ohm: type = Resistance.baseUnit;

            pub const Conductance: type = BaseUnits.ElectricCurrent.divide(Voltage);
            pub const Siemens: type = Conductance.baseUnit;

            pub const MagneticFlux: type = Energy.divide(BaseUnits.ElectricCurrent);
            pub const Weber: type = MagneticFlux.baseUnit;

            pub const MagneticInduction: type = MagneticFlux.divide(Area);
            pub const Tesla: type = MagneticInduction.baseUnit;

            pub const Inductance: type = MagneticFlux.divide(BaseUnits.ElectricCurrent);
            pub const Henry: type = Inductance.baseUnit;

            //no base unit, temperature already exists
            pub const DegreeCelsius: type = BaseUnits.Kelvin.Derive(1, -273.15);

            pub const LuminousFlux: type = BaseUnits.LuminousIntensity.multiply(SolidAngle);
            pub const Lumen: type = LuminousFlux.baseUnit;

            pub const Illuminance: type = LuminousFlux.divide(Area);
            pub const Lux: type = Illuminance.baseUnit;

            pub const Radioactivity: type = Frequency;
            pub const Becquerel: type = Radioactivity.baseUnit;

            pub const AbsorbedDose: type = Energy.divide(BaseUnits.Mass);
            pub const Gray: type = AbsorbedDose.baseUnit;

            pub const EquivalentDose: type = AbsorbedDose;
            pub const Sievert: type = EquivalentDose.baseUnit;

            pub const CatalyticActivity: type = BaseUnits.Amount.divide(BaseUnits.Time);
            pub const Katal: type = CatalyticActivity.baseUnit;

            //named quantities with nameless units
            //kinematics
            pub const Velocity: type = BaseUnits.Distance.divide(BaseUnits.Time);
            pub const Acceleration: type = BaseUnits.Distance.divide(BaseUnits.Time.pow(2));
            pub const Jerk: type = BaseUnits.Distance.divide(BaseUnits.Time.pow(3));
            pub const Snap: type = BaseUnits.Distance.divide(BaseUnits.Time.pow(4));
            //mass flow rate is omitted because i'm not sure it's real
            pub const AngularVelocity: type = Angle.divide(BaseUnits.Time);
            pub const AngularAcceleration: type = Angle.divide(BaseUnits.Time.pow(2));
            pub const FrequencyDrift: type = Frequency.divide(BaseUnits.Time);
            pub const VolumetricFlow: type = Volume.divide(BaseUnits.Time);

            //mechanics
            pub const Area: type = BaseUnits.Distance.pow(2);
            pub const Volume: type = BaseUnits.Distance.pow(3);
            pub const Momentum: type = Force.multiply(BaseUnits.Time);
            pub const AngularMomentum: type = Force.multiply(BaseUnits.Distance).multiply(BaseUnits.Time);
            pub const Torque: type = Force.multiply(BaseUnits.Distance);
            pub const Yank: type = Force.divide(BaseUnits.Time);
            pub const Wavenumber: type = BaseUnits.Distance.pow(-1);
            pub const AreaDensity: type = BaseUnits.Mass.divide(Area);
            pub const Density: type = BaseUnits.Mass.divide(Volume);
            pub const SpecificVolume: type = Volume.divide(BaseUnits.Mass);
            pub const Action: type = Energy.multiply(BaseUnits.Time);
            pub const SpecificEnergy: type = Energy.divide(BaseUnits.Mass);
            pub const EnergyDensity: type = Energy.divide(Volume);
            pub const SurfaceTension: type = Force.divide(BaseUnits.Distance);
            pub const HeatFluxDensity: type = Power.divide(Area);
            pub const KinematicViscosity: type = Area.divide(BaseUnits.Time);
            pub const DynamicViscosity: type = Pressure.multiply(BaseUnits.Time);
            pub const LinearMassDensity: type = BaseUnits.Mass.divide(BaseUnits.Distance);
            pub const MassFlowRate: type = BaseUnits.Mass.divide(BaseUnits.Time);
            pub const Radiance: type = Power.divide(SolidAngle.multiply(Area));
            pub const SpectralRadiance: type = Power.divide(SolidAngle.multiply(Volume));
            pub const SpectralPower: type = Power.divide(BaseUnits.Distance);
            pub const AbsorbedDoseRate: type = AbsorbedDose.divide(BaseUnits.Time);
            pub const FuelEfficiency: type = BaseUnits.Distance.divide(Volume);
            pub const PowerDensity: type = Power.divide(Volume);
            pub const EnergyFluxDensity: type = Energy.divide(Area.multiply(BaseUnits.Time));
            pub const Compressibility: type = Pressure.pow(-1);
            pub const RadiantExposure: type = Energy.divide(Area);
            pub const MomentOfInertia: type = BaseUnits.Mass.multiply(BaseUnits.Distance.pow(2));
            pub const SpecificAngularMomentum: type = AngularMomentum.divide(BaseUnits.Mass);
            pub const RadiantIntensity: type = Power.divide(SolidAngle);
            pub const SpectralIntensity: type = Power.divide(SolidAngle.multiply(BaseUnits.Distance));

            //chemistry
            pub const Molarity: type = BaseUnits.Amount.divide(Volume);
            pub const MolarVolume: type = Volume.divide(BaseUnits.Amount);
            pub const MolarHeatCapacity: type = Energy.divide(BaseUnits.Temperature.multiply(BaseUnits.Amount));
            pub const MolarEntropy: type = MolarHeatCapacity;
            pub const MolarEnergy: type = Energy.divide(BaseUnits.Amount);
            pub const MolarConductivity: type = Conductance.multiply(Area).divide(BaseUnits.Amount);
            pub const Molality: type = BaseUnits.Amount.divide(BaseUnits.Mass);
            pub const MolarMass: type = BaseUnits.Mass.divide(BaseUnits.Amount);
            pub const CatalyticEfficiency: type = Volume.divide(BaseUnits.Amount.multiply(BaseUnits.Time));

            //electromagnetics
            pub const ElectricDisplacement: type = BaseUnits.Time.multiply(BaseUnits.ElectricCurrent).divide(Area);
            pub const ChargeDensity: type = BaseUnits.Time.multiply(BaseUnits.ElectricCurrent).divide(Volume);
            pub const CurrentDensity: type = BaseUnits.ElectricCurrent.divide(Area);
            pub const ElectricalConductivity: type = Conductance.divide(BaseUnits.Distance);
            pub const Permittivity: type = Capacitance.divide(BaseUnits.Distance);
            pub const Permeability: type = Inductance.divide(BaseUnits.Distance);
            pub const ElectricFieldStrength: type = Voltage.divide(BaseUnits.Distance);
            pub const MagneticFieldStrength: type = BaseUnits.ElectricCurrent.divide(BaseUnits.Distance);
            pub const Magnetization: type = MagneticFieldStrength;
            pub const Exposure: type = BaseUnits.Time.multiply(BaseUnits.ElectricCurrent).divide(BaseUnits.Mass);
            pub const Resistivity: type = Resistance.multiply(BaseUnits.Distance);
            pub const LinearChargeDensity: type = BaseUnits.Time.multiply(BaseUnits.ElectricCurrent).divide(BaseUnits.Distance);
            pub const MagneticDipoleMoment: type = Energy.divide(MagneticInduction);
            pub const ElectronMobility: type = Area.divide(Voltage.multiply(BaseUnits.Time));
            pub const MagneticReluctance: type = Inductance.pow(-1);
            pub const MagneticVectorPotential: type = MagneticFlux.divide(BaseUnits.Distance);
            pub const MagneticMoment: type = MagneticFlux.multiply(BaseUnits.Distance);
            pub const MagneticRigidity: type = MagneticInduction.multiply(BaseUnits.Distance);
            pub const MagnetomotiveForce: type = BaseUnits.ElectricCurrent;
            pub const MagneticSusceptibility: type = BaseUnits.Distance.divide(Inductance);

            //photometry
            pub const LuminousEnergy: type = BaseUnits.Time.multiply(BaseUnits.LuminousIntensity);
            pub const LuminousExposure: type = LuminousEnergy.divide(Area);
            pub const Luminance: type = BaseUnits.LuminousIntensity.divide(Area);
            pub const LuminousEfficacy: type = BaseUnits.LuminousIntensity.divide(Power);

            //thermodynamics
            pub const HeatCapacity: type = Energy.divide(BaseUnits.Temperature);
            pub const Entropy: type = HeatCapacity;
            pub const SpecificHeatCapacity: type = HeatCapacity.divide(BaseUnits.Mass);
            pub const SpecificEntropy: type = SpecificHeatCapacity;
            pub const ThermalConductivity: type = Power.divide(BaseUnits.Distance.multiply(BaseUnits.Temperature));
            pub const ThermalResistance: type = BaseUnits.Temperature.divide(Power);
            pub const ThermalExpansionCoefficient: type = BaseUnits.Temperature.pow(-1);
            pub const TemperatureGradient: type = BaseUnits.Temperature.divide(BaseUnits.Distance);
        };
    };
}

pub const f64SiUnitSystem = MakeSiUnitSystem(f64, num.f64System.add, num.f64System.subtract, num.f64System.multiply, num.f64System.divide, num.f64System.pow);
