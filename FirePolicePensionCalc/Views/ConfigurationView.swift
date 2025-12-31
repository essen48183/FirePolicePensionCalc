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
    @State private var showPensionOptionDescription = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Wage Settings")) {
                    HStack {
                        Text("Externally Calculated Fixed or Base Wage")
                        Spacer()
                        TextField("87000", value: $viewModel.config.baseWage, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
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
                            Text("Calculate FAC")
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
                }
                
                Section(header: Text("Multiplier Settings")) {
                    HStack {
                        Text("Multiplier (%)")
                        Spacer()
                        TextField("2.5", value: $viewModel.config.multiplier, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    Toggle("Multiplier Based on FAC (otherwise on Base Wage)", isOn: $viewModel.config.multiplierBasedOnFAC)
                }
                
                Section(header: Text("COLA Settings")) {
                    Toggle("COLA Compounding", isOn: $viewModel.config.isColaCompounding)
                    HStack {
                        Text("Number of COLAs")
                        Spacer()
                        TextField("3", value: $viewModel.config.colaNumber, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("COLA Spacing (years)")
                        Spacer()
                        TextField("5", value: $viewModel.config.colaSpacing, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("COLA Percent (%)")
                        Spacer()
                        TextField("8", value: $viewModel.config.colaPercent, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                }
                
                Section(header: Text("Retirement Eligibility")) {
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
                }
                
                Section(header: Text("Individual Calc (or Fictional New Hire")) {
                    HStack {
                        Text("Hire Age")
                        Spacer()
                        TextField("30", value: $viewModel.config.fictionalNewHireAge, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("Spouse Age Diff")
                        Spacer()
                        TextField("-2", value: $viewModel.config.fictionalSpouseAgeDiff, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
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
                }
                
                Section(header: Text("Calculations")) {
                    Button(action: {
                        viewModel.saveConfiguration()
                        viewModel.calculateAll()
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
                
                Section(header: Text("Data Management")) {
                    Button(action: {
                        viewModel.saveConfiguration()
                    }) {
                        HStack {
                            Spacer()
                            Text("Save Configuration")
                            Spacer()
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        viewModel.loadDefaultConfiguration()
                    }) {
                        HStack {
                            Spacer()
                            Text("Load Default Configuration")
                            Spacer()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        .navigationTitle("Pension Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFACCalculator) {
            FACCalculatorView(viewModel: viewModel, facWage: $viewModel.config.facWage)
        }
        .sheet(isPresented: $showPensionOptionDescription) {
            PensionOptionDescriptionView()
        }
        .alert("FAC Wage", isPresented: $showFACTooltip) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Final Average Compensation is the contractually agreed upon number with which a pension is calculate upon")
        }
        .onChange(of: viewModel.config.baseWage) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.facWage) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.multiplier) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.multiplierBasedOnFAC) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.isColaCompounding) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.colaNumber) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.colaSpacing) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.colaPercent) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.retirementAge) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.careerYearsService) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.minAgeForYearsService) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.expectedFutureInflationRate) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.expectedSystemFutureRateReturn) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.employeeContributionPercent) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.fictionalNewHireAge) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.fictionalSpouseAgeDiff) { _ in handleConfigChange() }
        .onChange(of: viewModel.config.pensionOption) { _ in handleConfigChange() }
        }
    }
    
    private func handleConfigChange() {
        viewModel.saveConfiguration()
        viewModel.markConfigChanged()
    }
}
