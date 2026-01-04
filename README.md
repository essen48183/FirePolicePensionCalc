# Fire Police Pension Calculator - iOS

**Version 1.0** - A comprehensive Swift/SwiftUI pension calculator for fire and police departments with actuarial funding calculations.

## Overview

This application calculates pension benefits and required contributions for fire and police department employees. It implements a **100% funding actuarial rule** that ensures adequate funding at retirement time, accounting for investment returns during the accumulation phase and inflation during the payout phase.

**⚠️ IMPORTANT**: This is a simplified actuarial model for planning and analysis purposes. It is NOT a full actuarial valuation. See [ACTUARIAL_ASSUMPTIONS.md](ACTUARIAL_ASSUMPTIONS.md) for important disclosures and limitations.

## Key Features

### Configuration & Input
- **FAC (Final Average Compensation) Calculator**: Calculate FAC from base wage, overtime, and roll-ins over 3 years
- **Pension Options**: Support for 4 actuarially equivalent pension options:
  - Option 1: 100% retiree only, 0% survivor
  - Option 2: Ten year certain survivor (fixed 10 years)
  - Option 3: Joint and Survivor 100% (lifetime survivor benefit)
  - Option 4: Joint and Survivor 66.67% (lifetime survivor benefit)
- **Economic Assumptions**: Configurable expected return rate and inflation rate
- **Employee Contribution**: Configurable employee contribution percentage (default 5%)
- **COLA Settings**: Configurable COLA adjustments (compounding or non-compounding)
- **Data Persistence**: All settings automatically saved and restored

### Calculations
- **Individual Pension Calculations**: Calculate benefits for a fictional new hire with configurable parameters
- **System-Wide Calculations**: Aggregate calculations across all employees using:
  - Actual employee hire dates and ages
  - Actual spouse age differences
  - Individual retirement eligibility for each employee
  - Years of service calculations based on actual employment data
  - Aggregate city contributions and funding verification
- **Actuarial Equivalence**: All pension options are actuarially equivalent to Option 1
- **100% Funding Rule**: Ensures 100% of expected lifetime benefits available at retirement
- **Verification**: Automatic verification that contributions are sufficient (80-120% funding range)

### Results Display
- **Individual Results**: Detailed breakdown of retiree and survivor benefits for a fictional new hire
- **System Results**: Aggregate calculations across all employees including:
  - Total city contributions required
  - Total employee contributions
  - Annual city payments as percent of payroll
  - Funding verification (total available vs. total needed at retirement)
  - Surplus/deficit calculations
- **Buying Power Adjustments**: All costs adjusted to today's buying power
- **COLA Information**: Expected COLA increases displayed

## Project Structure

```
FirePolicePensionCalc/
├── FirePolicePensionCalc/
│   ├── FirePolicePensionCalcApp.swift    # App entry point
│   ├── Models/
│   │   ├── Employee.swift                # Employee data model
│   │   └── PensionConfiguration.swift    # Configuration model (Codable)
│   ├── Calculators/
│   │   ├── PensionCalculatorDisbursements.swift  # Benefit calculations
│   │   └── PensionCalculatorPaymentsInto.swift    # Contribution calculations
│   ├── Services/
│   │   ├── PensionCalculatorService.swift         # Main calculation service
│   │   └── ConfigurationPersistence.swift         # Data persistence
│   ├── Data/
│   │   ├── EmployeeDataLoader.swift               # Employee data loading
│   │   └── employees.json                         # Employee data (JSON)
│   ├── ViewModels/
│   │   └── PensionCalculatorViewModel.swift        # View model
│   └── Views/
│       ├── ContentView.swift                      # Main tab view
│       ├── ConfigurationView.swift                 # Input parameters
│       ├── SystemResultsView.swift                 # System-wide results
│       ├── IndividualResultsView.swift             # Individual results
│       ├── FACCalculatorView.swift                 # FAC calculation tool
│       ├── PensionOptionDescriptionView.swift      # Pension option descriptions
│       ├── EmployeeListView.swift                 # Employee list
│       └── EmployeeEditView.swift                 # Employee editing
├── Documentation/
│   ├── ACTUARIAL_RULE.md                          # 100% funding rule explanation
│   ├── CALCULATION_FLOW.md                         # Calculation process overview
│   ├── ACTUARIAL_MATH_VERIFICATION.md              # Formula verification
│   └── RATE_USAGE_VERIFICATION.md                  # Rate usage documentation
├── Tests/
│   ├── test_pension_calc.swift                     # Unit test script
│   └── verify_contributions.swift                  # Contribution verification
└── README.md
```

## Getting Started

### Prerequisites
- Xcode 14.0 or later
- iOS 15.0 or later
- Swift 5.7 or later

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/essen48183/FirePolicePensionCalc.git
   cd FirePolicePensionCalc
   ```

2. **Open in Xcode**
   - Double-click `FirePolicePensionCalc.xcodeproj`
   - Or open from Xcode: File → Open → Select the `.xcodeproj` file

3. **Build and Run**
   - Select a simulator (iPhone 14 or later recommended)
   - Press **⌘R** or click the **Play** button

### Quick Start Guide

See [QUICK_START.md](QUICK_START.md) for detailed setup instructions.

## Actuarial Methodology

### 100% Funding Rule

The calculator implements a conservative actuarial rule:

> **We must plan to have 100% of the expected lifetime benefits at retirement time. Once a person is retired, we cannot expect investment returns to outpace inflation.**

This means:
- **During Accumulation** (before retirement): Expected return rate (7.25% default) is used for growth
- **During Payout** (after retirement): No discounting - we need the full sum of all payments

### Calculation Flow

1. **Calculate Lifetime Benefit**: Sum of all payments in today's buying power (with COLA and inflation adjustments)
2. **Determine Amount Needed at Retirement**: Full sum of all payments (annual payment × years retired)
3. **Calculate Contributions**: Work backwards to determine required employee and city contributions

See [ACTUARIAL_RULE.md](ACTUARIAL_RULE.md) and [CALCULATION_FLOW.md](CALCULATION_FLOW.md) for detailed explanations.

## Key Calculations

### Pension Benefits
- Annual pension = Base wage (or FAC) × Multiplier × Years of service
- COLA adjustments (compounding or non-compounding)
- Inflation adjustments (buying power)
- Actuarial equivalence across all pension options

### Individual vs. System-Wide Calculations

**Individual Calculations:**
- Uses a fictional new hire with configurable parameters
- Useful for "what-if" scenarios and understanding benefit structures
- Shows detailed breakdown for a single employee

**System-Wide Calculations:**
- Uses actual employee data from `employees.json`:
  - Each employee's hire date and current age
  - Each employee's spouse age difference
  - Individual years of service calculations
  - Individual retirement eligibility based on actual data
- Calculates aggregate requirements:
  - Sum of all employee contributions (with individual FV calculations)
  - Sum of all city contributions needed
  - Total annual city payments as percent of payroll
  - System-wide funding verification

### Contributions
- Employee contributions: Percentage of base wage (default 5%)
- City contributions: Calculated to ensure 100% funding
- Future value calculations using annuity formulas (per employee)
- Present value discounting for today's contribution requirements
- Aggregate calculations sum individual employee requirements

### Verification
- Total available at retirement vs. total needed (aggregate across all employees)
- Funding ratio (target: 100%, acceptable range: 80-120%)
- Percent of payroll calculation (annual city payments / total payroll)
- Automatic adjustment to ensure funding within acceptable range

## Documentation

- **[ACTUARIAL_ASSUMPTIONS.md](ACTUARIAL_ASSUMPTIONS.md)**: **IMPORTANT** - Assumption disclosures and model limitations. This is a simplified model, not a full actuarial valuation.
- **[ACTUARIAL_RULE.md](ACTUARIAL_RULE.md)**: Explanation of the 100% funding actuarial rule
- **[CALCULATION_FLOW.md](CALCULATION_FLOW.md)**: Step-by-step calculation process
- **[ACTUARIAL_MATH_VERIFICATION.md](ACTUARIAL_MATH_VERIFICATION.md)**: Verification of all formulas
- **[RATE_USAGE_VERIFICATION.md](RATE_USAGE_VERIFICATION.md)**: How expected return and inflation rates are used

## Testing

### Unit Tests
Run the test scripts to verify calculations:

```bash
# Test pension calculations
swift test_pension_calc.swift

# Verify contribution sufficiency
swift verify_contributions.swift
```

Both tests should pass and show sufficient funding.

## Configuration

### Default Values
- **Expected Return Rate**: 7.25% (system actuarial assumption)
- **Inflation Rate**: 2.63% (historical average)
- **Employee Contribution**: 5% of base wage
- **Life Expectancy**: 73 years
- **Pension Option**: Option 3 (Joint and Survivor 100%)

### Data Persistence
- All configuration settings are automatically saved to UserDefaults
- Settings persist between app launches
- Manual save/clear buttons available in Configuration tab

## Employee Data

- Employee data is stored in `FirePolicePensionCalc/Data/employees.json`
- Each employee record includes:
  - Hire date and current age
  - Spouse age difference (for survivor benefit calculations)
  - Years of service (calculated from hire date)
- System-wide calculations use this actual data to:
  - Calculate individual retirement eligibility
  - Determine years to retirement for each employee
  - Calculate individual contribution requirements
  - Aggregate all requirements for system-wide totals
- Easy to update without recompiling
- JSON format matches the Employee struct exactly

## Features by Version

### Version 1.0 (Current)
- ✅ 100% funding actuarial rule implementation
- ✅ FAC calculator with 3-year wage averaging
- ✅ 4 pension options with actuarial equivalence
- ✅ Employee contribution percentage configuration
- ✅ Comprehensive documentation
- ✅ All calculations verified and tested
- ✅ Data persistence
- ✅ System-wide and individual calculations
- ✅ Funding verification (80-120% range)

## Technical Details

### Architecture
- **MVVM Pattern**: ViewModels manage state and business logic
- **SwiftUI**: Modern declarative UI framework
- **Codable**: Automatic serialization for persistence
- **Standard Actuarial Formulas**: All calculations use verified formulas

### Key Formulas
- **Future Value of Annuity**: `FV = PMT × (((1 + r)^n - 1) / r)`
- **Present Value from Future Value**: `PV = FV / (1 + r)^n`
- **Annual Payment from Present Value**: `PMT = PV × (r / (1 - (1 + r)^-n))`
- **Amount Needed at Retirement**: `Amount = PMT × n` (100% funding rule)

## Troubleshooting

**Build Errors:**
- Ensure `employees.json` is included in target's "Copy Bundle Resources"
- Verify all Swift files are added to the target

**Configuration Not Saving:**
- Check that PensionConfiguration conforms to Codable (it does)
- Verify UserDefaults is accessible

**Calculations Seem Incorrect:**
- Review the actuarial rule documentation
- Check that expected return and inflation rates are set correctly
- Verify employee data is loaded correctly

## Contributing

This is a specialized actuarial calculator. When making changes:
1. Ensure all calculations maintain actuarial equivalence
2. Update documentation for any formula changes
3. Run test scripts to verify calculations
4. Maintain the 100% funding rule

## License

[Add your license here]

## Contact

[Add contact information here]

---

**Version 1.0** - Complete pension calculator with 100% funding actuarial rule
