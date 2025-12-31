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
    @State private var showFACCalculator = false
    @State private var showSystemFACCalculator = false
    @State private var showPensionOptionDescription = false
    @State private var showValidationError = false
    @State private var validationErrorMessage = ""
    
    private func validateRetirementEligibility() -> Bool {
        let config = viewModel.config
        let hireAge = config.fictionalHiredYear - config.fictionalBirthYear
        let yearsOfWork = config.fictionalYearsOfWork
        let retirementAgeAtWorkEnd = hireAge + yearsOfWork
        
        // Must be vested
        if yearsOfWork < config.yearsUntilVestment {
            validationErrorMessage = "Years of Work (\(yearsOfWork)) must be at least equal to Years Until Vestment (\(config.yearsUntilVestment))."
            return false
        }
        
        // Must meet retirement eligibility: either normal retirement age OR early retirement authorized OR early retirement (min age + years of service)
        // Note: Uses >= so exact match passes (e.g., 20 years of work passes when careerYearsService is 20)
        let meetsNormalRetirement = retirementAgeAtWorkEnd >= config.retirementAge
        let meetsEarlyRetirement = retirementAgeAtWorkEnd >= config.minAgeForYearsService && yearsOfWork >= config.careerYearsService
        
        if !meetsNormalRetirement && !config.earlyRetirementAuthorized && !meetsEarlyRetirement {
            validationErrorMessage = "Retirement eligibility not met. At \(retirementAgeAtWorkEnd) years old with \(yearsOfWork) years of service:\n\n" +
                "• Must be at least \(config.retirementAge) years old (normal retirement), OR\n" +
                "• Must have 'Early Retirement Authorized' checked, OR\n" +
                "• Must be at least \(config.minAgeForYearsService) years old AND have at least \(config.careerYearsService) years of service (early retirement)."
            return false
        }
        
        return true
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Individual Calc section at the top with Wage Settings inside blue box
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
                            TextField("87000", value: $viewModel.config.baseWage, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
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
                            Spacer()
                            TextField("97000", value: $viewModel.config.facWage, format: .number.precision(.fractionLength(0)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                        .padding(.vertical, 4)
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Real employee data fields
                        HStack {
                            Text("Year Hired")
                            Spacer()
                            TextField("2024", value: $viewModel.config.fictionalHiredYear, format: .number.grouping(.never))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Text("Year Born")
                            Spacer()
                            TextField("1999", value: $viewModel.config.fictionalBirthYear, format: .number.grouping(.never))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Text("Spouse Year Born")
                            Spacer()
                            TextField("1997", value: $viewModel.config.fictionalSpouseBirthYear, format: .number.grouping(.never))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Text("Years of Work")
                            Spacer()
                            TextField("20", value: $viewModel.config.fictionalYearsOfWork, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                        .padding(.vertical, 4)
                        
                        Toggle("Early Retirement Authorized", isOn: $viewModel.config.earlyRetirementAuthorized)
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
                
                Section {
                    VStack(spacing: 0) {
                        // Multiplier Settings
                        HStack {
                            Text("Multiplier (%)")
                            Spacer()
                            TextField("2.5", value: $viewModel.config.multiplier, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
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
                            TextField("3", value: $viewModel.config.colaNumber, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Text("COLA Spacing (years)")
                            Spacer()
                            TextField("5", value: $viewModel.config.colaSpacing, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Text("COLA Percent (%)")
                            Spacer()
                            TextField("8", value: $viewModel.config.colaPercent, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
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
                
                Section(header: Text("Retirement Eligibility")) {
                    HStack {
                        Text("Years Until Vestment")
                        Spacer()
                        TextField("5", value: $viewModel.config.yearsUntilVestment, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("Retirement Age (Age Triggered After Vestment Attained)")
                        Spacer()
                        TextField("60", value: $viewModel.config.retirementAge, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("Years of Service (To Retire/Draw Immediately)")
                        Spacer()
                        TextField("25", value: $viewModel.config.careerYearsService, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("Min Age for Years of Service Retirement")
                        Spacer()
                        TextField("50", value: $viewModel.config.minAgeForYearsService, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                }
                
                Section(header: Text("System-Wide Wage Assumptions")) {
                    HStack {
                        Text("System-Wide Avg Retiree Base Wage")
                        Spacer()
                        TextField("85000", value: $viewModel.config.systemWideBaseWage, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("System-Wide Avg Retiree FAC Wage")
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
                        Spacer()
                        TextField("98000", value: $viewModel.config.systemWideFacWage, format: .number.precision(.fractionLength(0)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("System-Wide Average Wage (budgetary payroll including all wage, bonus an OT for the system divided by # of active employees for most accurate math)  this only determines the percent of payroll that the of employer contributions are.  you can leave it default. ")
                        Spacer()
                        TextField("70000", value: $viewModel.config.systemWideAverageWage, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                }
                
                Section(header: Text("Economic Assumptions")) {
                    HStack {
                        Text("Inflation Rate (%) 2.63 is the historical average")
                        Spacer()
                        TextField("2.63", value: $viewModel.config.expectedFutureInflationRate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("Expected Return (%) - system actuarial assumption, often between 7 and 7.5")
                        Spacer()
                        TextField("7.25", value: $viewModel.config.expectedSystemFutureRateReturn, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("Employee Contribution (%)")
                        Spacer()
                        TextField("5.0", value: $viewModel.config.employeeContributionPercent, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("Worker Life Expectancy (years)")
                        Spacer()
                        TextField("73", value: $viewModel.config.lifeExpectancy, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("Spouse Life Expectancy (years)")
                        Spacer()
                        TextField("79", value: $viewModel.config.lifeExpectancySpouse, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                }
                
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
        .onChange(of: viewModel.config.colaSpacing) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.colaPercent) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.yearsUntilVestment) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.retirementAge) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.careerYearsService) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.minAgeForYearsService) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.expectedFutureInflationRate) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.expectedSystemFutureRateReturn) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.employeeContributionPercent) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.lifeExpectancy) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.lifeExpectancySpouse) { _ in handleConfigChange() }
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
        .onChange(of: viewModel.config.earlyRetirementAuthorized) { _ in handleConfigChange() }
    }
    
    private func handleConfigChange() {
        viewModel.saveConfiguration()
        viewModel.markConfigChanged()
    }
}
