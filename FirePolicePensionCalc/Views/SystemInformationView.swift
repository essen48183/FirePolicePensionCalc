//
//  SystemInformationView.swift
//  FirePolicePensionCalc
//
//  Information view explaining the open/closed pension system
//

import SwiftUI

struct SystemInformationView: View {
    @ObservedObject var viewModel: PensionCalculatorViewModel
    @State private var showPensionOptions = false
    @State private var showFACExplanation = false
    @State private var showActuarialFormulas = false
    
    init(viewModel: PensionCalculatorViewModel? = nil) {
        // Allow optional viewModel for preview
        if let vm = viewModel {
            _viewModel = ObservedObject(wrappedValue: vm)
        } else {
            // Create a dummy viewModel for preview
            _viewModel = ObservedObject(wrappedValue: PensionCalculatorViewModel())
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pension System Information")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Understanding Open/Closed Pension Systems")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                    
                    // Main Explanation
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How Pension Systems Work")
                            .font(.title3)
                            .bold()
                        
                        Text("Pension systems are typically **open and closed**, meaning they have both:")
                            .font(.body)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Active Employees")
                                        .font(.headline)
                                    Text("Currently working and contributing to the system")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "person.fill.checkmark")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Retired Employees")
                                        .font(.headline)
                                    Text("Already retired and receiving pension payments from funds accumulated during their working years")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.leading, 8)
                    }
                    
                    Divider()
                    
                    // What This Calculator Does
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What This Calculator Covers")
                            .font(.title3)
                            .bold()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("System-Wide Results")
                                        .font(.headline)
                                    Text("Calculations based on the **editable employee list** shown in the System Results tab. Each employee's actual hire date, current age, and spouse age difference are used for individual calculations that are then aggregated.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "person.circle")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Individual Calculation of (Fictional Employee)")
                                        .font(.headline)
                                    Text("A separate calculation for a fictional employee with configurable parameters. This is **NOT** used for system-wide results. It's only for individual planning and 'what-if' scenarios.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.leading, 8)
                    }
                    
                    Divider()
                    
                    // Important Note about Data Sources
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Important: System Results Data Source")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                Text("The **System Results** calculations come from the employee list that appears below the system-wide totals. You can edit this list using the 'Edit' button in the System Results tab.")
                                    .font(.body)
                                
                                Text("The fictional employee used in the **Individual Calculation** tab (with its own age, hire date, and spouse age) is **separate** and does not affect system-wide results.")
                                    .font(.body)
                                    .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Divider()
                    
                    // Important Disclaimer
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Important: Past Retirees Not Included")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                
                                Text("This calculator **does not include** employees who have already retired. Past retirees are already receiving pension payments from funds that were accumulated and invested during their working years.")
                                    .font(.body)
                                
                                Text("Any surplus or shortfall from past retirees (due to investment performance, changes in assumptions, or other factors) would be **in addition to** the annual system-wide contribution requirements calculated here.")
                                    .font(.body)
                                    .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Divider()
                    
                    // System Funding
                    VStack(alignment: .leading, spacing: 16) {
                        Text("System Funding")
                            .font(.title3)
                            .bold()
                        
                        Text("The annual city contribution calculated by this system represents the amount needed to fund:")
                            .font(.body)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Current active employees' future retirement benefits")
                            Text("• Future employees' retirement benefits (based on assumptions)")
                            Text("• 100% funding at retirement time for all active and future employees")
                        }
                        .font(.body)
                        .padding(.leading, 8)
                        
                        Text("**Note:** Any existing surplus or shortfall from past retirees must be accounted for separately in the overall pension system budget.")
                            .font(.body)
                            .padding(.top, 8)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Additional Resources
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Additional Resources")
                            .font(.title3)
                            .bold()
                        
                        VStack(spacing: 12) {
                            Button(action: { showPensionOptions = true }) {
                                HStack {
                                    Image(systemName: "list.bullet.rectangle")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Pension Option Descriptions")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("Detailed descriptions of Options 1-4")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            Button(action: { showFACExplanation = true }) {
                                HStack {
                                    Image(systemName: "calculator")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("FAC Calculation Explanation")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("How Final Average Compensation is calculated")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            Button(action: { showActuarialFormulas = true }) {
                                HStack {
                                    Image(systemName: "function")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Actuarial Formulas & Best Practices")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("All math formulas and actuarial standards used")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("System Information")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showPensionOptions) {
            PensionOptionDescriptionView()
        }
        .sheet(isPresented: $showFACExplanation) {
            FACExplanationView()
        }
        .sheet(isPresented: $showActuarialFormulas) {
            ActuarialFormulasView()
        }
    }
}

#Preview {
    SystemInformationView()
}

