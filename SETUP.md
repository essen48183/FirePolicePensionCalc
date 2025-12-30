# Setup Instructions for Xcode

## Quick Start

1. **Open Xcode** and create a new project:
   - File → New → Project
   - Choose "iOS" → "App"
   - Product Name: `FirePolicePensionCalc`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployment: **iOS 15.0** or higher

2. **Delete the default files** Xcode creates:
   - Delete `ContentView.swift` (we have our own)
   - Delete `FirePolicePensionCalcApp.swift` (we have our own)

3. **Add the project files**:
   - Right-click on the project in the navigator
   - Select "Add Files to FirePolicePensionCalc..."
   - Navigate to the `FirePolicePensionCalc` folder
   - Select all the subfolders (Models, Calculators, Services, Data, ViewModels, Views)
   - Make sure "Copy items if needed" is **unchecked** (files are already in the right place)
   - Make sure "Create groups" is selected
   - Click "Add"

4. **Verify the file structure** in Xcode should look like:
   ```
   FirePolicePensionCalc
   ├── FirePolicePensionCalcApp.swift
   ├── Models/
   │   ├── Employee.swift
   │   └── PensionConfiguration.swift
   ├── Calculators/
   │   ├── PensionCalculatorDisbursements.swift
   │   └── PensionCalculatorPaymentsInto.swift
   ├── Services/
   │   └── PensionCalculatorService.swift
   ├── Data/
   │   └── EmployeeDataLoader.swift
   ├── ViewModels/
   │   └── PensionCalculatorViewModel.swift
   └── Views/
       ├── ContentView.swift
       ├── ConfigurationView.swift
       ├── SystemResultsView.swift
       └── IndividualResultsView.swift
   ```

5. **Build and Run**:
   - Select a simulator (iPhone 14 or later recommended)
   - Press ⌘R or click the Play button
   - The app should launch with three tabs: Configuration, System Results, and Individual

## Testing

1. Go to the **Configuration** tab
2. Adjust any parameters (or use defaults)
3. Tap **"Calculate System Costs"** to see aggregate results
4. Tap **"Calculate Individual Pension"** to see individual calculation
5. Switch to the **System Results** or **Individual Results** tabs to view the calculations

## Troubleshooting

- **Build errors**: Make sure all files are added to the target. Select each file and check the "Target Membership" in the File Inspector.
- **Missing files**: Verify all files are in the correct folders and added to the Xcode project.
- **Swift version**: This code requires Swift 5.5+ (comes with Xcode 13+)

## Next Steps

- Consider converting employee data to a plist or JSON file for easier updates
- Add data persistence for configuration settings
- Add export functionality for results
- Add charts/visualizations for better data presentation

