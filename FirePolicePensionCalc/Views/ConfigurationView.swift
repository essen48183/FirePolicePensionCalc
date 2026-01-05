//
//  ConfigurationView.swift
//  FirePolicePensionCalc
//
//  View for configuring pension parameters
//

import SwiftUI

struct ConfigurationView: View {
    @ObservedObject var viewModel: PensionCalculatorViewModel
    @State private var showFACTooltip = false
    @State private var showVestmentTooltip = false
    @State private var showFACCalculator = false
    @State private var showSystemFACCalculator = false
    @State private var showPensionOptionDescription = false
    @State private var showValidationError = false
    @State private var validationErrorMessage = ""
    
    private func validateRetirementEligibility() -> Bool {
        let config = viewModel.config
        let yearsOfWork = config.fictionalYearsOfWork
        
        // Must be vested
        if yearsOfWork < config.yearsUntilVestment {
            validationErrorMessage = "Years of Work (\(yearsOfWork)) must be at least equal to Years Until Vestment (\(config.yearsUntilVestment))."
            return false
        }
        
        // Always allow calculation - eligibility warnings will be shown in results
        return true
    }
    
    var body: some View {
        NavigationView {
            Form {
                individualInfoSection
                
                multiplierAndCOLASection
                
                retirementEligibilitySection
                
                systemWideWageSection
                
                economicAssumptionsSection
                
                calculationsSection
            }
        .navigationTitle("Fire/Police Pension Calculator")
        .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showFACCalculator) {
            FACCalculatorView(viewModel: viewModel, facWage: $viewModel.config.facWage)
        }
        .sheet(isPresented: $showSystemFACCalculator) {
            FACCalculatorView(viewModel: viewModel, facWage: $viewModel.config.systemWideFacWage)
        }
        .sheet(isPresented: $showPensionOptionDescription) {
            PensionOptionDescriptionView()
        }
        .alert("Years Until Vestment", isPresented: $showVestmentTooltip) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Employees must work this many years before becoming eligible for pension benefits.\n\nNote: If you are opening a new pension system where all inductees are immediately vested, you can temporarily set this value to 1 for calculations.")
        }
        .alert("FAC Wage", isPresented: $showFACTooltip) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Final Average Compensation is the contractually agreed upon number with which a pension is calculate upon")
        }
        .alert("Retirement Eligibility Error", isPresented: $showValidationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationErrorMessage)
        }
        .onChange(of: viewModel.config.baseWage) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.facWage) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.systemWideBaseWage) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.systemWideFacWage) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.systemWideAverageWage) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.multiplier) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.multiplierBasedOnFAC) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.isColaCompounding) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.colaNumber) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.colaSpacing) { newValue in
            // Prevent divide by zero error - ensure colaSpacing is at least 1
            if newValue <= 0 {
                viewModel.config.colaSpacing = 1
            }
            handleConfigChange()
        }
        .onChange(of: viewModel.config.colaPercent) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.yearsUntilVestment) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.retirementAge) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.careerYearsService) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.minAgeForYearsService) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.expectedFutureInflationRate) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.expectedSystemFutureRateReturn) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.employeeContributionPercent) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.lifeExpectancyMale) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.lifeExpectancyFemale) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.fictionalEmployeeSex) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.fictionalSpouseSex) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.pensionOption) { _ in handleConfigChange() }
        .onAppear {
            // Initialize derived values on appear
            viewModel.config.fictionalNewHireAge = viewModel.config.fictionalHiredYear - viewModel.config.fictionalBirthYear
            viewModel.config.fictionalSpouseAgeDiff = viewModel.config.fictionalSpouseBirthYear - viewModel.config.fictionalBirthYear
        }
        .onChange(of: viewModel.config.fictionalHiredYear) { _ in
            // Calculate hire age from year hired and year born
            viewModel.config.fictionalNewHireAge = viewModel.config.fictionalHiredYear - viewModel.config.fictionalBirthYear
            handleConfigChange()
        }
        .onChange(of: viewModel.config.fictionalBirthYear) { _ in
            // Calculate hire age and spouse age diff when birth year changes
            viewModel.config.fictionalNewHireAge = viewModel.config.fictionalHiredYear - viewModel.config.fictionalBirthYear
            viewModel.config.fictionalSpouseAgeDiff = viewModel.config.fictionalSpouseBirthYear - viewModel.config.fictionalBirthYear
            handleConfigChange()
        }
        .onChange(of: viewModel.config.fictionalSpouseBirthYear) { _ in
            // Calculate spouse age diff from birth years
            viewModel.config.fictionalSpouseAgeDiff = viewModel.config.fictionalSpouseBirthYear - viewModel.config.fictionalBirthYear
            handleConfigChange()
        }
        .onChange(of: viewModel.config.fictionalYearsOfWork) { _ in handleConfigChange() }
    }
    
    private var individualInfoSection: some View {
        Section {
                    VStack(spacing: 0) {
                        // Header label inside blue box
                        Text("Individual Info (excluded from system-wide results)")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 8)
                        
                        // Calculate All button at top
                        Button(action: {
                            if validateRetirementEligibility() {
                                viewModel.saveConfiguration()
                                viewModel.calculateAll()
                            } else {
                                showValidationError = true
                            }
                        }) {
                            HStack {
                                Spacer()
                                Text("Calculate All")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom, 12)
                        
                        // Wage Settings inside blue box
                        HStack {
                            Text("Fixed/Base Wage")
                            Spacer()
                             NumberInputField(
                                title: "Fixed/Base Wage",
                                value: $viewModel.config.baseWage,
                                defaultValue: 85000,
                                format: .number,
                                keyboardType: .decimalPad
                            )
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Text("FAC Wage")
                            Button(action: {
                                showFACTooltip = true
                            }) {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                                .frame(width: 8)
                            Button(action: {
                                showFACCalculator = true
                            }) {
                                Text("Estimate FAC")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .fixedSize()
                            Spacer()
                            NumberInputField(
                                title: "FAC Wage",
                                value: $viewModel.config.facWage,
                                defaultValue: 98000,
                                format: .number,
                                keyboardType: .decimalPad
                            )
                        }
                        .padding(.vertical, 4)
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Real employee data fields
                        HStack {
                            Text("Year Hired")
                            Spacer()
                            IntegerInputField(
                                title: "Year Hired",
                                value: $viewModel.config.fictionalHiredYear,
                                defaultValue: 2025,
                                keyboardType: .numberPad
                            )
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Text("Year Born")
                            Spacer()
                            IntegerInputField(
                                title: "Year Born",
                                value: $viewModel.config.fictionalBirthYear,
                                defaultValue: 2000,
                                keyboardType: .numberPad
                            )
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Text("Sex")
                            Spacer()
                            Picker("", selection: $viewModel.config.fictionalEmployeeSex) {
                                Text("M").tag(Sex.male)
                                Text("F").tag(Sex.female)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 120)
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Text("Spouse Year Born")
                            Spacer()
                            IntegerInputField(
                                title: "Spouse Year Born",
                                value: $viewModel.config.fictionalSpouseBirthYear,
                                defaultValue: 1998,
                                keyboardType: .numberPad
                            )
                        }
                        .padding(.vertical, 4)
                        
                        if viewModel.config.fictionalSpouseBirthYear > 0 {
                            HStack {
                                Text("Spouse Sex")
                                Spacer()
                                Picker("", selection: $viewModel.config.fictionalSpouseSex) {
                                    Text("M").tag(Sex.male)
                                    Text("F").tag(Sex.female)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 120)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        HStack {
                            Text("Years of Work")
                            Spacer()
                            IntegerInputField(
                                title: "Years of Work",
                                value: $viewModel.config.fictionalYearsOfWork,
                                defaultValue: 25,
                                keyboardType: .numberPad
                            )
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Text("Pension Option")
                            Button(action: {
                                showPensionOptionDescription = true
                            }) {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Picker( "",selection: $viewModel.config.pensionOption) {
                                ForEach(PensionOption.allCases, id: \.self) { option in
                                    Text(option.displayName).tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        .padding(.vertical, 4)
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .cornerRadius(8)
                }
    }
    
    private var multiplierAndCOLASection: some View {
        Section {
                    VStack(spacing: 0) {
                        // Multiplier Settings
                        HStack {
                            Text("Multiplier (%)")
                            Spacer()
                            NumberInputField(
                                title: "Multiplier (%)",
                                value: $viewModel.config.multiplier,
                                defaultValue: 2.5,
                                format: .number,
                                keyboardType: .decimalPad
                            )
                        }
                        .padding(.vertical, 4)
                        
                        Toggle("Pension Based on FAC (otherwise base on Fixed Wage)", isOn: $viewModel.config.multiplierBasedOnFAC)
                            .padding(.vertical, 4)
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        
                        HStack {
                            // COLA Settings
                            Text("Number of COLAs")
                            Spacer()
                            IntegerInputField(
                                title: "Number of COLAs",
                                value: $viewModel.config.colaNumber,
                                defaultValue: 2,
                                keyboardType: .numberPad
                            )
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Text("COLA Spacing (years)")
                            Spacer()
                            IntegerInputField(
                                title: "COLA Spacing (years)",
                                value: $viewModel.config.colaSpacing,
                                defaultValue: 5,
                                keyboardType: .numberPad,
                                minimumValue: 1
                            )
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Text("COLA Percent (%)")
                            Spacer()
                            NumberInputField(
                                title: "COLA Percent (%)",
                                value: $viewModel.config.colaPercent,
                                defaultValue: 6.0,
                                format: .number,
                                keyboardType: .decimalPad
                            )
                        }
                        .padding(.vertical, 4)
                        
                        Toggle("COLA is Compounding?", isOn: $viewModel.config.isColaCompounding)
                            .padding(.vertical, 4)
                        
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .cornerRadius(8)
                }
    }
    
    private var retirementEligibilitySection: some View {
        Section(header: Text("Retirement Eligibility")) {
                    HStack {
                        HStack(spacing: 4) {
                            Text("Years Until Vestment")
                            Button(action: {
                                showVestmentTooltip = true
                            }) {
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        Spacer()
                        IntegerInputField(
                            title: "Years Until Vestment",
                            value: $viewModel.config.yearsUntilVestment,
                            defaultValue: 5,
                            keyboardType: .numberPad
                        )
                    }
                    HStack {
                        Text("Retirement Age (Age Triggered After Vestment Attained)")
                        Spacer()
                        IntegerInputField(
                            title: "Retirement Age",
                            value: $viewModel.config.retirementAge,
                            defaultValue: 55,
                            keyboardType: .numberPad
                        )
                    }
                    HStack {
                        Text("Years of Service (To Retire/Draw Immediately)")
                        Spacer()
                        IntegerInputField(
                            title: "Years of Service",
                            value: $viewModel.config.careerYearsService,
                            defaultValue: 20,
                            keyboardType: .numberPad
                        )
                    }
                    HStack {
                        Text("Min Age for Years of Service Retirement")
                        Spacer()
                        IntegerInputField(
                            title: "Min Age for Years of Service",
                            value: $viewModel.config.minAgeForYearsService,
                            defaultValue: 50,
                            keyboardType: .numberPad
                        )
                    }
                }
    }
    
    private var systemWideWageSection: some View {
        Section(header: Text("System-Wide Wage Assumptions")) {
                    HStack {
                        Text("System-Wide Avg Retiree Base Wage")
                        Spacer()
                        NumberInputField(
                            title: "System-Wide Avg Retiree Base Wage",
                            value: $viewModel.config.systemWideBaseWage,
                            defaultValue: 85000,
                            format: .number,
                            keyboardType: .decimalPad
                        )
                    }
                    HStack {
                        Text("System-Wide Avg Retiree FAC Wage")
                        Spacer()
                            .frame(width: 8)
                        Button(action: {
                            showSystemFACCalculator = true
                        }) {
                            Text("Estimate FAC")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .fixedSize()
                        Spacer()
                        NumberInputField(
                            title: "System-Wide Avg Retiree FAC Wage",
                            value: $viewModel.config.systemWideFacWage,
                            defaultValue: 98000,
                            format: .number,
                            keyboardType: .decimalPad
                        )
                    }
                    HStack {
                        Text("System-Wide Average Wage (budgetary payroll including all wage, bonus an OT for the system divided by # of active employees for most accurate math)  this only determines the percent of payroll that the of employer contributions are.  you can leave it default. ")
                        Spacer()
                        NumberInputField(
                            title: "System-Wide Average Wage",
                            value: $viewModel.config.systemWideAverageWage,
                            defaultValue: 60000,
                            format: .number,
                            keyboardType: .decimalPad
                        )
                    }
                }
    }
    
    private var economicAssumptionsSection: some View {
        Section(header: Text("Actuarial Economic Assumptions")) {
                    HStack {
                        Text("Inflation Rate (%) Actuary uses for your system (2.63 is the historical average)")
                        Spacer()
                        NumberInputField(
                            title: "Inflation Rate (%)",
                            value: $viewModel.config.expectedFutureInflationRate,
                            defaultValue: 2.63,
                            format: .number,
                            keyboardType: .decimalPad
                        )
                    }
                    HStack {
                        Text("Expected Return (%) - system actuarial assumption, often between 7 and 7.5")
                        Spacer()
                        NumberInputField(
                            title: "Expected Return (%)",
                            value: $viewModel.config.expectedSystemFutureRateReturn,
                            defaultValue: 7.25,
                            format: .number,
                            keyboardType: .decimalPad
                        )
                    }
                    HStack {
                        Text("Employee Contribution (%) - if your employee contributions go to a separate annuity, not the pension fund, set this to 0")
                        Spacer()
                        NumberInputField(
                            title: "Employee Contribution (%)",
                            value: $viewModel.config.employeeContributionPercent,
                            defaultValue: 5.0,
                            format: .number,
                            keyboardType: .decimalPad
                        )
                    }
                    HStack {
                        Text("Male Life Expectancy - adjust only if your system uses different figures")
                        Spacer()
                        IntegerInputField(
                            title: "Male Life Expectancy (years)",
                            value: $viewModel.config.lifeExpectancyMale,
                            defaultValue: 73,
                            keyboardType: .numberPad
                        )
                    }
                    HStack {
                        Text("Female Life Expectancy - adjust only if your system uses different figures")
                        Spacer()
                        IntegerInputField(
                            title: "Female Life Expectancy (years)",
                            value: $viewModel.config.lifeExpectancyFemale,
                            defaultValue: 79,
                            keyboardType: .numberPad
                        )
                    }
                }
    }
    
    private var calculationsSection: some View {
        Section(header: Text("Calculations")) {
                    Button(action: {
                        if validateRetirementEligibility() {
                            viewModel.saveConfiguration()
                            viewModel.calculateAll()
                        } else {
                            showValidationError = true
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Calculate All")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
    }
    
    private func handleConfigChange() {
        viewModel.saveConfiguration()
        viewModel.markConfigChanged()
    }
}
