# Quick Start Guide

## Opening the Project

1. **Double-click** `FirePolicePensionCalc.xcodeproj` to open in Xcode
2. Select a simulator (iPhone 14 or later recommended)
3. Press **⌘R** or click the **Play** button to build and run

## Features Added

### ✅ JSON Employee Data
- Employee data is now stored in `employees.json`
- Easy to update employee information without recompiling
- Located in `FirePolicePensionCalc/Data/employees.json`

### ✅ Data Persistence
- Configuration settings are automatically saved to UserDefaults
- Settings persist between app launches
- Auto-saves when you change any value in the Configuration tab
- Manual save/clear buttons available in Configuration tab

### ✅ Xcode Project File
- Complete `.xcodeproj` file ready to use
- All files properly linked
- Build settings configured for iOS 15.0+

## Project Structure

```
FirePolicePensionCalc/
├── FirePolicePensionCalc.xcodeproj/    # Xcode project file
├── FirePolicePensionCalc/
│   ├── FirePolicePensionCalcApp.swift
│   ├── Models/
│   │   ├── Employee.swift
│   │   └── PensionConfiguration.swift (Codable for persistence)
│   ├── Calculators/
│   │   ├── PensionCalculatorDisbursements.swift
│   │   └── PensionCalculatorPaymentsInto.swift
│   ├── Services/
│   │   ├── PensionCalculatorService.swift
│   │   └── ConfigurationPersistence.swift (NEW - handles saving/loading)
│   ├── Data/
│   │   ├── EmployeeDataLoader.swift (updated to read JSON)
│   │   └── employees.json (NEW - employee data)
│   ├── ViewModels/
│   │   └── PensionCalculatorViewModel.swift (updated with persistence)
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── ConfigurationView.swift (updated with auto-save)
│   │   ├── SystemResultsView.swift
│   │   └── IndividualResultsView.swift
│   └── Assets.xcassets/
└── README.md
```

## How It Works

### Data Persistence
- When you change any configuration value, it automatically saves
- On app launch, saved configuration is loaded automatically
- Use "Clear Saved Configuration" to reset to defaults

### Employee Data
- Employees are loaded from `employees.json` at app startup
- To update employee data, edit the JSON file and rebuild
- JSON format matches the Employee struct exactly

## Troubleshooting

**Build Errors:**
- Make sure `employees.json` is included in the target's "Copy Bundle Resources"
- Check that all Swift files are added to the target

**Configuration Not Saving:**
- Check that PensionConfiguration conforms to Codable (it does)
- Verify UserDefaults is accessible (should work by default)

**Employees Not Loading:**
- Verify `employees.json` is in the Data folder
- Check that it's added to the target's resources
- Look for console errors when the app launches

## Next Steps

- Add export functionality for results
- Add charts/visualizations
- Add ability to edit employee data in-app
- Add multiple saved configuration presets

