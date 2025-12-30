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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView("Calculating...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if let result = viewModel.systemResult {
                        Group {
                            Text("System-Wide Results")
                                .font(.largeTitle)
                                .bold()
                            
                            Text("*All costs projected and adjusted to today's buying power using your specified economic assumptions of expected fund performance and inflation rate")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.bottom)
                            
                            ResultCard(title: "Total Lifetime Benefits", value: result.totalDisbursements, format: .currency)
                            ResultCard(title: "Total City Contributions", value: result.totalCityContributions, format: .currency)
                            ResultCard(title: "Total Employee Contributions", value: result.totalEmployeeContributions, format: .currency)
                            ResultCard(title: "Annual City Payments", value: result.annualCityPayments, format: .currency)
                            ResultCard(title: "% of Payroll", value: result.cityAnnualPercentOfPayroll, format: .percent)
                            
                            if let verification = result.verificationResult {
                                Divider()
                                
                                Text("Contribution Verification")
                                    .font(.title2)
                                    .bold()
                                
                                ResultCard(title: "Total Available at Retirement", value: verification.totalAvailableAtRetirement, format: .currency)
                                ResultCard(title: "Total Needed at Retirement", value: verification.totalNeededAtRetirement, format: .currency)
                                
                                if verification.isSufficient {
                                    ResultCard(title: "Surplus", value: verification.surplus, format: .currency)
                                } else {
                                    ResultCard(title: "Deficit", value: abs(verification.surplus), format: .currency)
                                }
                            }
                            
                            Divider()
                            
                            Text("Configuration")
                                .font(.title2)
                                .bold()
                            
                            Text("Employees: \(viewModel.employees.count)")
                            Text("Multiplier: \(viewModel.config.multiplier)%")
                            Text("COLA: \(viewModel.config.colaNumber) adjustments, \(viewModel.config.colaPercent)% every \(viewModel.config.colaSpacing) years")
                            Text("Retirement Age: \(viewModel.config.retirementAge) or \(viewModel.config.careerYearsService) years service")
                            
                            Divider()
                            
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
                            .padding(.vertical, 4)
                            
                            ForEach(getDisplayedEmployees(from: result.employeeResults)) { employeeResult in
                                EmployeeResultRow(result: employeeResult)
                            }
                            
                            if result.employeeResults.count > 10 && !showAllEmployees {
                                Button(action: {
                                    showAllEmployees = true
                                }) {
                                    HStack {
                                        Text("... and \(result.employeeResults.count - 10) more employees")
                                            .foregroundColor(.blue)
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding()
                    } else {
                        Text("Configure settings and tap 'Calculate System Costs' to see results")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
            .navigationTitle("System Results")
            .navigationBarTitleDisplayMode(.inline)
        }
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

