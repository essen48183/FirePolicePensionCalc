//
//  SystemResultsView.swift
//  FirePolicePensionCalc
//
//  View for displaying system-wide calculation results
//

import SwiftUI

struct SystemResultsView: View {
    @ObservedObject var viewModel: PensionCalculatorViewModel
    @State private var showAllEmployees = false
    
    private func getDisplayedEmployees(from results: [EmployeeCalculationResult]) -> [EmployeeCalculationResult] {
        if showAllEmployees {
            return results
        } else {
            return Array(results.prefix(10))
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    List {
                        Section {
                            ProgressView("Calculating...")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowInsets(EdgeInsets())
                        }
                    }
                } else if let result = viewModel.systemResult {
                    List {
                        // Header Section
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("System-Wide Results for All Active Employees")
                                    .font(.title2)
                                    .bold()
                                
                                Text("*All costs projected and adjusted to today's buying power using your specified economic assumptions of expected fund performance and inflation rate")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                        
                        // Summary Cards Section
                        Section {
                            ResultCard(title: "Total System-wide Lifetime Benefits", value: result.totalDisbursements, format: .currency)
                            ResultCard(title: "Total Employer Contributions", value: result.totalCityContributions, format: .currency)
                            ResultCard(title: "Total Employee Contributions", value: result.totalEmployeeContributions, format: .currency)
                            ResultCard(title: "Annual Employer Payments (active employees)", value: result.annualCityPayments, format: .currency)
                            ResultCard(title: "% of Payroll (approximately)", value: result.cityAnnualPercentOfPayroll, format: .percent)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        
                        // Verification Section
                        if let verification = result.verificationResult {
                            Section(header: Text("Contribution Estimate for Active Employees Verification").font(.title2).bold()) {
                                ResultCard(title: "Total Available at Retirement", value: verification.totalAvailableAtRetirement, format: .currency)
                                ResultCard(title: "Total Needed at Retirement", value: verification.totalNeededAtRetirement, format: .currency)
                                
                                if verification.isSufficient {
                                    ResultCard(title: "Surplus", value: verification.surplus, format: .currency)
                                } else {
                                    ResultCard(title: "Deficit", value: abs(verification.surplus), format: .currency)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        }
                        
                        // Configuration Section
                        Section(header: Text("Configuration").font(.title2).bold()) {
                            Text("Employees: \(viewModel.employees.count)")
                            if viewModel.config.multiplierBasedOnFAC {
                                Text("Pension Based On: FAC Wage")
                                Text("Average FAC Wage Used: \(formatCurrency(viewModel.config.systemWideFacWage))")
                            } else {
                                Text("Pension Based On: Fixed/Base Wage")
                                Text("Average Fixed/Base Wage Used: \(formatCurrency(viewModel.config.systemWideBaseWage))")
                            }
                            Text("Multiplier: \(formatPercent(viewModel.config.multiplier))%")
                            Text("COLA: \(viewModel.config.colaNumber) adjustments, \(formatPercent(viewModel.config.colaPercent))% every \(viewModel.config.colaSpacing) years")
                            Text("Retirement Eligibility:")
                                .font(.headline)
                            Text("• Age-triggered: \(viewModel.config.retirementAge) years old")
                            Text("• Years of service: \(viewModel.config.careerYearsService) years of service")
                            Text("• Minimum age for years of service: \(viewModel.config.minAgeForYearsService) years old")
                        }
                        
                        // Employee Details Section
                        Section {
                            HStack {
                                Text("Employee Details")
                                    .font(.title2)
                                    .bold()
                                Spacer()
                                NavigationLink(destination: EmployeeEditView(viewModel: viewModel)) {
                                    HStack {
                                        Image(systemName: "pencil")
                                        Text("Edit")
                                    }
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            
                            ForEach(getDisplayedEmployees(from: result.employeeResults)) { employeeResult in
                                EmployeeResultRow(result: employeeResult)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            }
                        }
                        
                        // Show All / Show Less button section - always show if there are employees
                        let vestedEmployeesCount = result.employeeResults.count
                        let totalEmployeesInSystem = viewModel.employees.count
                        let displayedCount = getDisplayedEmployees(from: result.employeeResults).count
                        
                        if vestedEmployeesCount > 0 {
                            Section {
                                Button(action: {
                                    showAllEmployees.toggle()
                                }) {
                                    VStack(spacing: 4) {
                                        HStack {
                                            Spacer()
                                            if showAllEmployees && vestedEmployeesCount > 10 {
                                                Text("Show Less")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                Image(systemName: "chevron.up")
                                                    .foregroundColor(.white)
                                                    .font(.caption)
                                            } else if vestedEmployeesCount > 10 {
                                                Text("Show All \(vestedEmployeesCount) Vested Employees")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                Image(systemName: "chevron.down")
                                                    .foregroundColor(.white)
                                                    .font(.caption)
                                            } else {
                                                Text("All \(vestedEmployeesCount) Vested Employees Shown")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                        }
                                        if totalEmployeesInSystem > vestedEmployeesCount {
                                            VStack(spacing: 2) {
                                                Text("(\(totalEmployeesInSystem - vestedEmployeesCount) not yet vested)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Text("Note: For new system-wide inductions where all are immediately vested, temporarily reduce vestment to 1 year in Configuration")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .multilineTextAlignment(.center)
                                                    .padding(.horizontal, 8)
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(vestedEmployeesCount > 10 ? Color.blue : Color(.systemGray5))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        }
                    }
                } else {
                    List {
                        Section {
                            Text("Configure settings and tap 'Calculate System Costs' to see results")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowInsets(EdgeInsets())
                        }
                    }
                }
            }
            .navigationTitle("System Results")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func formatPercent(_ value: Double) -> String {
        // Format percent with 2 decimal places
        return String(format: "%.2f", value)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}

struct ResultCard: View {
        let title: String
        let value: Double
        let format: ValueFormat
        
        enum ValueFormat {
            case currency
            case percent
            case number
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(formattedValue)
                    .font(.title2)
                    .bold()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        
        private var formattedValue: String {
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
            case .number:
                formatter.maximumFractionDigits = 0
                return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
            }
        }
    }
    
    struct EmployeeResultRow: View {
        let result: EmployeeCalculationResult
        
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(result.employee.name)
                    .font(.headline)
                
                HStack {
                    Text("Retires at age \(result.retirementAge)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                HStack {
                    Text("Annual Benefit:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatCurrency(result.initialAnnualPension))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Lifetime Benefit:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatCurrency(result.totalDisbursements))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .padding(.vertical, 6)
        }
        
        private func formatCurrency(_ value: Double) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "$"
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
        }
    }

