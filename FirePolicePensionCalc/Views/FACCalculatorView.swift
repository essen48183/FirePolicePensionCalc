//
//  FACCalculatorView.swift
//  FirePolicePensionCalc
//
//  View for calculating Final Average Compensation
//

import SwiftUI

struct FACCalculatorView: View {
    @ObservedObject var viewModel: PensionCalculatorViewModel
    @Binding var facWage: Double
    @Environment(\.dismiss) var dismiss
    
    @State private var baseWageYear1: Double = 0
    @State private var overtimeYear1: Double = 0
    @State private var rollInsYear1: Double = 0
    @State private var baseWageYear2: Double = 0
    @State private var overtimeYear2: Double = 0
    @State private var baseWageYear3: Double = 0
    @State private var overtimeYear3: Double = 0
    @State private var calculatedFAC: Double = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Year 1")) {
                    HStack {
                        Text("Base Wage")
                        Spacer()
                        TextField("0", value: $baseWageYear1, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("Overtime")
                        Spacer()
                        TextField("0", value: $overtimeYear1, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("Roll-ins")
                        Spacer()
                        TextField("0", value: $rollInsYear1, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                }
                
                Section(header: Text("Year 2")) {
                    HStack {
                        Text("Base Wage")
                        Spacer()
                        TextField("0", value: $baseWageYear2, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("Overtime")
                        Spacer()
                        TextField("0", value: $overtimeYear2, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                }
                
                Section(header: Text("Year 3")) {
                    HStack {
                        Text("Base Wage")
                        Spacer()
                        TextField("0", value: $baseWageYear3, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("Overtime")
                        Spacer()
                        TextField("0", value: $overtimeYear3, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                }
                
                Section(header: Text("Calculation")) {
                    if calculatedFAC > 0 {
                        HStack {
                            Text("Calculated FAC:")
                                .font(.headline)
                            Spacer()
                            Text(formatCurrency(calculatedFAC))
                                .font(.title3)
                                .bold()
                        }
                        .padding(.vertical, 4)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack {
                                Spacer()
                                Text("Cancel")
                                Spacer()
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            if calculatedFAC > 0 {
                                saveAndReturn()
                            } else {
                                calculateFAC()
                            }
                        }) {
                            HStack {
                                Spacer()
                                Text(calculatedFAC > 0 ? "Save" : "Calculate")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("FAC Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadFACDefaults()
            }
        }
    }
    
    private func loadFACDefaults() {
        // Load persisted values
        baseWageYear1 = viewModel.config.facBaseWageYear1
        overtimeYear1 = viewModel.config.facOvertimeYear1
        rollInsYear1 = viewModel.config.facRollInsYear1
        baseWageYear2 = viewModel.config.facBaseWageYear2
        overtimeYear2 = viewModel.config.facOvertimeYear2
        baseWageYear3 = viewModel.config.facBaseWageYear3
        overtimeYear3 = viewModel.config.facOvertimeYear3
        
        // If first time (baseWageYear1 hasn't been set yet), initialize with defaults
        if baseWageYear1 == 0 {
            let defaultBaseWage = viewModel.config.baseWage
            let defaultOvertime = 5000.0
            let defaultRollIns = 6000.0
            
            // Set all years to same base wage and overtime
            baseWageYear1 = defaultBaseWage
            overtimeYear1 = defaultOvertime
            rollInsYear1 = defaultRollIns
            baseWageYear2 = defaultBaseWage
            overtimeYear2 = defaultOvertime
            baseWageYear3 = defaultBaseWage
            overtimeYear3 = defaultOvertime
        }
    }
    
    private func calculateFAC() {
        let totalYear1 = baseWageYear1 + overtimeYear1 + rollInsYear1
        let totalYear2 = baseWageYear2 + overtimeYear2
        let totalYear3 = baseWageYear3 + overtimeYear3
        
        calculatedFAC = (totalYear1 + totalYear2 + totalYear3) / 3.0
    }
    
    private func saveAndReturn() {
        // Save calculated FAC
        facWage = calculatedFAC
        viewModel.config.facWage = calculatedFAC
        
        // Save FAC calculator field values for persistence
        viewModel.config.facBaseWageYear1 = baseWageYear1
        viewModel.config.facOvertimeYear1 = overtimeYear1
        viewModel.config.facRollInsYear1 = rollInsYear1
        viewModel.config.facBaseWageYear2 = baseWageYear2
        viewModel.config.facOvertimeYear2 = overtimeYear2
        viewModel.config.facBaseWageYear3 = baseWageYear3
        viewModel.config.facOvertimeYear3 = overtimeYear3
        
        viewModel.saveConfiguration()
        dismiss()
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

