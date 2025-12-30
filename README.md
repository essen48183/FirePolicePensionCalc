# Fire Police Pension Calculator - iOS

A Swift/SwiftUI port of the Java pension calculator for iOS devices.

## Project Structure

```
FirePolicePensionCalc/
├── FirePolicePensionCalc/
│   ├── FirePolicePensionCalcApp.swift    # App entry point
│   ├── Models/
│   │   ├── Employee.swift                # Employee data model
│   │   └── PensionConfiguration.swift    # Configuration model
│   ├── Calculators/
│   │   ├── PensionCalculatorDisbursements.swift  # Benefit calculations
│   │   └── PensionCalculatorPaymentsInto.swift    # Contribution calculations
│   ├── Services/
│   │   └── PensionCalculatorService.swift         # Main calculation service
│   ├── Data/
│   │   └── EmployeeDataLoader.swift               # Employee data loading
│   ├── ViewModels/
│   │   └── PensionCalculatorViewModel.swift        # View model
│   └── Views/
│       ├── ContentView.swift                      # Main tab view
│       ├── ConfigurationView.swift                 # Input parameters
│       ├── SystemResultsView.swift                 # System-wide results
│       └── IndividualResultsView.swift             # Individual results
└── README.md
```

## Setting Up in Xcode

1. Open Xcode
2. Create a new iOS App project:
   - Product Name: `FirePolicePensionCalc`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum iOS: 15.0 (or higher)

3. Replace the default files with the files from this repository, maintaining the folder structure shown above.

4. Build and run the project.

## Features

- **Configuration Tab**: Input all pension parameters (wages, multipliers, COLA settings, retirement eligibility, economic assumptions)
- **System Results Tab**: View aggregate calculations across all 61 employees
- **Individual Results Tab**: Calculate pension for a fictional new hire

## Key Differences from Java Version

- **UI**: SwiftUI interface instead of console input/output
- **Data Loading**: Employees are hardcoded in `EmployeeDataLoader.swift` (can be converted to plist/JSON later)
- **Async Calculations**: Heavy calculations run on background threads
- **Modern Swift**: Uses Swift's type system, optionals, and modern patterns

## Calculation Logic

The calculation logic matches the original Java implementation:
- Pension disbursements with COLA adjustments (compounding or non-compounding)
- Inflation adjustments
- Survivor benefits (60% for spouse)
- Present value calculations for required contributions
- System-wide aggregation

## Notes

- The employee data is currently hardcoded in `EmployeeDataLoader.swift`. For production, consider loading from a plist or JSON file.
- All calculations match the Java version's logic.
- The UI is designed for iOS with SwiftUI best practices.

