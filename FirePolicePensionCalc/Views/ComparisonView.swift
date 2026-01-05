//
//  ComparisonView.swift
//  FirePolicePensionCalc
//
//  View for comparing current results with saved comparison basis
//

import SwiftUI

struct ComparisonView: View {
    @ObservedObject var viewModel: PensionCalculatorViewModel
    @State private var comparisonData: ComparisonData?
    @State private var showSaveAlert = false
    @State private var showClearAlert = false
    @State private var showAllEmployees = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Control Buttons Section
                    VStack(spacing: 12) {
                        Button(action: {
                            if let systemResult = viewModel.systemResult {
                                let comparison = ComparisonData(
                                    systemResult: systemResult,
                                    config: viewModel.config,
                                    employeeCount: viewModel.employees.count
                                )
                                ComparisonPersistence.save(comparison)
                                comparisonData = comparison
                                showSaveAlert = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "bookmark.fill")
                                Text("Save Current as Comparison Basis")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(viewModel.systemResult == nil || viewModel.isLoading)
                        
                        if comparisonData != nil {
                            Button(action: {
                                showClearAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Clear Comparison Basis")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Comparison Content
                    if let comparison = comparisonData, let currentResult = viewModel.systemResult {
                        ComparisonContentView(
                            currentResult: currentResult,
                            currentConfig: viewModel.config,
                            currentEmployeeCount: viewModel.employees.count,
                            comparisonResult: comparison.systemResult,
                            comparisonConfig: comparison.config,
                            comparisonEmployeeCount: comparison.employeeCount,
                            comparisonDate: comparison.timestamp,
                            showAllEmployees: $showAllEmployees
                        )
                        .padding(.horizontal)
                    } else if comparisonData == nil {
                        // No comparison saved - show instructions
                        VStack(spacing: 20) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            VStack(spacing: 12) {
                                Text("Save a Calculation for Comparison")
                                    .font(.title2)
                                    .bold()
                                
                                Text("To compare different calculations:")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    InstructionStep(number: "1", text: "Go to the Configuration tab and set up your calculation parameters")
                                    InstructionStep(number: "2", text: "Calculate system costs to generate results")
                                    InstructionStep(number: "3", text: "Return to this tab and tap 'Save Current as Comparison Basis'")
                                    InstructionStep(number: "4", text: "Make changes to your configuration and recalculate")
                                    InstructionStep(number: "5", text: "View the comparison here to see how changes affect the results")
                                }
                                .padding(.top, 8)
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.vertical, 60)
                    } else {
                        // Comparison exists but no current results
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No Current Results")
                                .font(.title2)
                                .bold()
                            Text("Calculate system costs to compare with the saved comparison basis.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 60)
                    }
                }
            }
            .navigationTitle("Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                comparisonData = ComparisonPersistence.load()
            }
            .alert("Comparison Saved", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Current calculation has been saved as the comparison basis.")
            }
            .alert("Clear Comparison?", isPresented: $showClearAlert) {
                Button("Clear", role: .destructive) {
                    ComparisonPersistence.clear()
                    comparisonData = nil
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove the saved comparison basis. You can save a new one at any time.")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ComparisonContentView: View {
    let currentResult: SystemCalculationResult
    let currentConfig: PensionConfiguration
    let currentEmployeeCount: Int
    let comparisonResult: SystemCalculationResult
    let comparisonConfig: PensionConfiguration
    let comparisonEmployeeCount: Int
    let comparisonDate: Date
    @Binding var showAllEmployees: Bool
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Comparison Report")
                    .font(.largeTitle)
                    .bold()
                Text("Generated: \(dateFormatter.string(from: Date()))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Comparison Basis Saved: \(dateFormatter.string(from: comparisonDate))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)
            
            Divider()
            
            // Summary Results Comparison
            VStack(alignment: .leading, spacing: 16) {
                Text("Summary Results")
                    .font(.title2)
                    .bold()
                
                ComparisonRow(
                    title: "Total System-wide Lifetime Benefits",
                    current: currentResult.totalDisbursements,
                    comparison: comparisonResult.totalDisbursements,
                    format: .currency
                )
                
                ComparisonRow(
                    title: "Total Employer Contributions",
                    current: currentResult.totalCityContributions,
                    comparison: comparisonResult.totalCityContributions,
                    format: .currency
                )
                
                ComparisonRow(
                    title: "Total Employee Contributions",
                    current: currentResult.totalEmployeeContributions,
                    comparison: comparisonResult.totalEmployeeContributions,
                    format: .currency
                )
                
                ComparisonRow(
                    title: "Annual Employer Payments",
                    current: currentResult.annualCityPayments,
                    comparison: comparisonResult.annualCityPayments,
                    format: .currency
                )
                
                ComparisonRow(
                    title: "% of Payroll",
                    current: currentResult.cityAnnualPercentOfPayroll,
                    comparison: comparisonResult.cityAnnualPercentOfPayroll,
                    format: .percent
                )
            }
            
            Divider()
            
            // Verification Comparison
            if let currentVerification = currentResult.verificationResult,
               let comparisonVerification = comparisonResult.verificationResult {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Contribution Verification")
                        .font(.title2)
                        .bold()
                    
                    ComparisonRow(
                        title: "Total Available at Retirement",
                        current: currentVerification.totalAvailableAtRetirement,
                        comparison: comparisonVerification.totalAvailableAtRetirement,
                        format: .currency
                    )
                    
                    ComparisonRow(
                        title: "Total Needed at Retirement",
                        current: currentVerification.totalNeededAtRetirement,
                        comparison: comparisonVerification.totalNeededAtRetirement,
                        format: .currency
                    )
                    
                    ComparisonRow(
                        title: currentVerification.isSufficient ? "Surplus" : "Deficit",
                        current: abs(currentVerification.surplus),
                        comparison: abs(comparisonVerification.surplus),
                        format: .currency
                    )
                }
                
                Divider()
            }
            
            // Assumptions Comparison
            VStack(alignment: .leading, spacing: 16) {
                Text("Assumptions")
                    .font(.title2)
                    .bold()
                
                AssumptionComparisonRow(
                    title: "Number of Employees",
                    current: "\(currentEmployeeCount)",
                    comparison: "\(comparisonEmployeeCount)"
                )
                
                AssumptionComparisonRow(
                    title: "Pension Based On",
                    current: currentConfig.multiplierBasedOnFAC ? "FAC Wage" : "Fixed/Base Wage",
                    comparison: comparisonConfig.multiplierBasedOnFAC ? "FAC Wage" : "Fixed/Base Wage"
                )
                
                AssumptionComparisonRow(
                    title: "Average Wage Used",
                    current: formatCurrency(currentConfig.multiplierBasedOnFAC ? currentConfig.systemWideFacWage : currentConfig.systemWideBaseWage),
                    comparison: formatCurrency(comparisonConfig.multiplierBasedOnFAC ? comparisonConfig.systemWideFacWage : comparisonConfig.systemWideBaseWage)
                )
                
                AssumptionComparisonRow(
                    title: "Multiplier",
                    current: "\(formatPercent(currentConfig.multiplier))%",
                    comparison: "\(formatPercent(comparisonConfig.multiplier))%"
                )
                
                AssumptionComparisonRow(
                    title: "COLA Settings",
                    current: "\(currentConfig.colaNumber) adjustments, \(formatPercent(currentConfig.colaPercent))% every \(currentConfig.colaSpacing) years",
                    comparison: "\(comparisonConfig.colaNumber) adjustments, \(formatPercent(comparisonConfig.colaPercent))% every \(comparisonConfig.colaSpacing) years"
                )
                
                AssumptionComparisonRow(
                    title: "COLA Type",
                    current: currentConfig.isColaCompounding ? "Compounding" : "Straight",
                    comparison: comparisonConfig.isColaCompounding ? "Compounding" : "Straight"
                )
                
                AssumptionComparisonRow(
                    title: "Age-Triggered Retirement",
                    current: "\(currentConfig.retirementAge) years old",
                    comparison: "\(comparisonConfig.retirementAge) years old"
                )
                
                AssumptionComparisonRow(
                    title: "Years of Service Retirement",
                    current: "\(currentConfig.careerYearsService) years of service",
                    comparison: "\(comparisonConfig.careerYearsService) years of service"
                )
                
                AssumptionComparisonRow(
                    title: "Minimum Age for Years of Service",
                    current: "\(currentConfig.minAgeForYearsService) years old",
                    comparison: "\(comparisonConfig.minAgeForYearsService) years old"
                )
                
                AssumptionComparisonRow(
                    title: "Years Until Vestment",
                    current: "\(currentConfig.yearsUntilVestment)",
                    comparison: "\(comparisonConfig.yearsUntilVestment)"
                )
                
                AssumptionComparisonRow(
                    title: "Inflation Rate",
                    current: "\(formatPercent(currentConfig.expectedFutureInflationRate))%",
                    comparison: "\(formatPercent(comparisonConfig.expectedFutureInflationRate))%"
                )
                
                AssumptionComparisonRow(
                    title: "Expected Fund Return Rate",
                    current: "\(formatPercent(currentConfig.expectedSystemFutureRateReturn))%",
                    comparison: "\(formatPercent(comparisonConfig.expectedSystemFutureRateReturn))%"
                )
                
                AssumptionComparisonRow(
                    title: "Employee Contribution %",
                    current: "\(formatPercent(currentConfig.employeeContributionPercent))%",
                    comparison: "\(formatPercent(comparisonConfig.employeeContributionPercent))%"
                )
                
                AssumptionComparisonRow(
                    title: "Male Life Expectancy",
                    current: "\(currentConfig.lifeExpectancyMale) years",
                    comparison: "\(comparisonConfig.lifeExpectancyMale) years"
                )
                
                AssumptionComparisonRow(
                    title: "Female Life Expectancy",
                    current: "\(currentConfig.lifeExpectancyFemale) years",
                    comparison: "\(comparisonConfig.lifeExpectancyFemale) years"
                )
            }
            
            Divider()
            
            // Employee Details Comparison - Side by Side
            VStack(alignment: .leading, spacing: 16) {
                Text("Employee Details")
                    .font(.title2)
                    .bold()
                
                // Create a dictionary for quick lookup
                let comparisonEmployeeDict = Dictionary(uniqueKeysWithValues: comparisonResult.employeeResults.map { ($0.employee.id, $0) })
                let currentEmployeeIds = Set(currentResult.employeeResults.map { $0.employee.id })
                
                // Get all employees (current + comparison only)
                let allCurrentEmployees = currentResult.employeeResults
                let comparisonOnlyEmployees = comparisonResult.employeeResults.filter { !currentEmployeeIds.contains($0.employee.id) }
                let allEmployeesList = allCurrentEmployees + comparisonOnlyEmployees
                
                // Determine which employees to display
                let employeesToShow = showAllEmployees ? allEmployeesList : Array(allEmployeesList.prefix(10))
                
                ForEach(employeesToShow) { employeeResult in
                    if let comparisonEmployeeResult = comparisonEmployeeDict[employeeResult.employee.id] {
                        // Employee exists in both
                        EmployeeSideBySideComparisonRow(
                            currentResult: employeeResult,
                            comparisonResult: comparisonEmployeeResult,
                            currentConfig: currentConfig,
                            comparisonConfig: comparisonConfig
                        )
                    } else if currentEmployeeIds.contains(employeeResult.employee.id) {
                        // Employee exists in current but not in comparison
                        EmployeeSideBySideComparisonRow(
                            currentResult: employeeResult,
                            comparisonResult: nil,
                            currentConfig: currentConfig,
                            comparisonConfig: nil
                        )
                    } else {
                        // Employee exists in comparison but not in current
                        EmployeeSideBySideComparisonRow(
                            currentResult: nil,
                            comparisonResult: employeeResult,
                            currentConfig: nil,
                            comparisonConfig: comparisonConfig
                        )
                    }
                }
                
                // Show All / Show Less button - always show if there are employees
                if allEmployeesList.count > 0 {
                    Button(action: {
                        showAllEmployees.toggle()
                    }) {
                        HStack {
                            Spacer()
                            if showAllEmployees && allEmployeesList.count > 10 {
                                Text("Show Less")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Image(systemName: "chevron.up")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            } else if allEmployeesList.count > 10 {
                                Text("Show All \(allEmployeesList.count) Employees")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            } else {
                                Text("All \(allEmployeesList.count) Employees Shown")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(allEmployeesList.count > 10 ? Color.blue : Color(.systemGray5))
                        .cornerRadius(10)
                    }
                    .padding(.top, 12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
    
    private func formatPercent(_ value: Double) -> String {
        return String(format: "%.2f", value)
    }
}

struct ComparisonRow: View {
    let title: String
    let current: Double
    let comparison: Double
    let format: ValueFormat
    
    enum ValueFormat {
        case currency
        case percent
    }
    
    private var difference: Double {
        current - comparison
    }
    
    private var percentChange: Double {
        guard comparison != 0 else { return 0 }
        return (difference / comparison) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saved Comparison")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatValue(comparison))
                        .font(.body)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Newly Calculated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatValue(current))
                        .font(.body)
                        .bold()
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Difference")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatValue(difference))
                        .font(.body)
                        .bold()
                        .foregroundColor(difference > 0 ? .green : (difference < 0 ? .red : .primary))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Text("(\(formatPercentChange(percentChange)))")
                        .font(.caption)
                        .foregroundColor(percentChange > 0 ? .green : (percentChange < 0 ? .red : .primary))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        
        switch format {
        case .currency:
            formatter.numberStyle = .currency
            formatter.currencySymbol = "$"
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
        case .percent:
            return String(format: "%.1f%%", value)
        }
    }
    
    private func formatPercentChange(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }
}

struct InstructionStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct AssumptionComparisonRow: View {
    let title: String
    let current: String
    let comparison: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saved Comparison")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(comparison)
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Newly Calculated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(current)
                        .font(.body)
                }
                
                Spacer()
                
                if current != comparison {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct EmployeeSideBySideComparisonRow: View {
    let currentResult: EmployeeCalculationResult?
    let comparisonResult: EmployeeCalculationResult?
    let currentConfig: PensionConfiguration?
    let comparisonConfig: PensionConfiguration?
    
    var employeeName: String {
        currentResult?.employee.name ?? comparisonResult?.employee.name ?? "Unknown"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(employeeName)
                .font(.headline)
                .padding(.bottom, 4)
            
            HStack(alignment: .top, spacing: 20) {
                // Saved Comparison Column
                VStack(alignment: .leading, spacing: 8) {
                    Text("Saved Comparison")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .bold()
                    
                    if let comparison = comparisonResult, let config = comparisonConfig {
                        VStack(alignment: .leading, spacing: 4) {
                            // Determine which eligibility rule applies
                            let eligibilityRule = determineEligibilityRule(
                                retirementAge: comparison.retirementAge,
                                yearsToRetire: comparison.yearsToRetire,
                                employeeHiredAge: comparison.employee.hiredAge,
                                config: config
                            )
                            
                            Text("Retirement Age: \(comparison.retirementAge)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Eligible via: \(eligibilityRule)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("Initial Annual Benefit:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatCurrency(comparison.initialAnnualPension))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            
                            if let finalAnnual = calculateFinalAnnualWithCOLA(
                                initialPension: comparison.initialAnnualPension,
                                config: config,
                                retirementAge: comparison.retirementAge,
                                employeeSex: comparison.employee.sex
                            ) {
                                HStack {
                                    Text("Annual Benefit at Life Expectancy:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatCurrency(finalAnnual))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                }
                            }
                            
                            HStack {
                                Text("Lifetime Benefit:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatCurrency(comparison.totalDisbursements))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                        }
                    } else {
                        Text("N/A")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Newly Calculated Column
                VStack(alignment: .leading, spacing: 8) {
                    Text("Newly Calculated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .bold()
                    
                    if let current = currentResult, let config = currentConfig {
                        VStack(alignment: .leading, spacing: 4) {
                            // Determine which eligibility rule applies
                            let eligibilityRule = determineEligibilityRule(
                                retirementAge: current.retirementAge,
                                yearsToRetire: current.yearsToRetire,
                                employeeHiredAge: current.employee.hiredAge,
                                config: config
                            )
                            
                            // Compare retirement ages if comparison exists
                            if let comparison = comparisonResult {
                                let ageDifference = current.retirementAge - comparison.retirementAge
                                if ageDifference != 0 {
                                    HStack {
                                        Text("Retirement Age: \(current.retirementAge)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("(\(ageDifference > 0 ? "+" : "")\(ageDifference) years)")
                                            .font(.caption2)
                                            .foregroundColor(ageDifference < 0 ? .green : .red)
                                            .fontWeight(.semibold)
                                    }
                                } else {
                                    Text("Retirement Age: \(current.retirementAge)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Retirement Age: \(current.retirementAge)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Eligible via: \(eligibilityRule)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("Initial Annual Benefit:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatCurrency(current.initialAnnualPension))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            
                            if let finalAnnual = calculateFinalAnnualWithCOLA(
                                initialPension: current.initialAnnualPension,
                                config: config,
                                retirementAge: current.retirementAge,
                                employeeSex: current.employee.sex
                            ) {
                                HStack {
                                    Text("Annual Benefit at Life Expectancy:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatCurrency(finalAnnual))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                }
                            }
                            
                            HStack {
                                Text("Lifetime Benefit:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatCurrency(current.totalDisbursements))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            
                            // Total Lifetime Difference
                            if let comparison = comparisonResult {
                                Divider()
                                    .padding(.vertical, 4)
                                
                                let difference = current.totalDisbursements - comparison.totalDisbursements
                                
                                HStack {
                                    Text("Total Lifetime Difference:")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatCurrency(difference))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(difference > 0 ? .green : (difference < 0 ? .red : .primary))
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                }
                            }
                        }
                    } else {
                        Text("N/A")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func calculateFinalAnnualWithCOLA(
        initialPension: Double,
        config: PensionConfiguration,
        retirementAge: Int,
        employeeSex: Sex
    ) -> Double? {
        // Calculate years receiving pension
        let lifeExpectancy = employeeSex == .male ? config.lifeExpectancyMale : config.lifeExpectancyFemale
        let yearsReceivingPension = lifeExpectancy + config.deltaExtraLife - retirementAge
        
        guard yearsReceivingPension > 0, config.colaNumber > 0 else {
            return nil
        }
        
        // Calculate final annual pension with all COLAs applied
        var finalPension = initialPension
        let colaPercent = config.colaPercent / 100.0
        let straightCola = initialPension * colaPercent
        var colaCounter = 0
        
        for year in 1...yearsReceivingPension {
            if year % config.colaSpacing == 0 && colaCounter < config.colaNumber {
                colaCounter += 1
                finalPension = PensionMathCalculations.applyCOLA(
                    currentPension: finalPension,
                    colaPercent: colaPercent,
                    isCompounding: config.isColaCompounding,
                    straightColaAmount: straightCola
                )
            }
        }
        
        return finalPension
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
    
    private func determineEligibilityRule(
        retirementAge: Int,
        yearsToRetire: Int,
        employeeHiredAge: Int,
        config: PensionConfiguration
    ) -> String {
        // Calculate what each rule would produce
        let ageTriggeredRetirementAge = config.retirementAge
        let yearsOfServiceRetirementAge = employeeHiredAge + config.careerYearsService
        let minAgeForService = config.minAgeForYearsService
        
        // Determine which rule applies based on which produces the earliest retirement age
        if retirementAge == ageTriggeredRetirementAge {
            return "Age-triggered (\(config.retirementAge) years old)"
        } else if retirementAge >= minAgeForService && yearsToRetire == config.careerYearsService {
            if yearsOfServiceRetirementAge < minAgeForService {
                return "Years of service (\(config.careerYearsService) years) with min age constraint (\(minAgeForService) years old)"
            } else {
                return "Years of service (\(config.careerYearsService) years)"
            }
        } else if retirementAge == minAgeForService {
            return "Min age for years of service (\(minAgeForService) years old)"
        } else {
            // Fallback - show the actual values
            return "Age \(retirementAge) with \(yearsToRetire) years service"
        }
    }
}

