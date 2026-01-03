//
//  FACExplanationView.swift
//  FirePolicePensionCalc
//
//  View explaining Final Average Compensation (FAC) calculation
//

import SwiftUI

struct FACExplanationView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Final Average Compensation (FAC)")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Understanding How FAC is Calculated")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                    
                    // What is FAC
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What is FAC?")
                            .font(.title3)
                            .bold()
                        
                        Text("Final Average Compensation (FAC) is the average of an employee's compensation over their final years of service. This average is used as the basis for calculating pension benefits instead of using just the base wage.")
                            .font(.body)
                        
                        Text("FAC typically includes:")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.body)
                                Text("Base wage or salary")
                                    .font(.body)
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.body)
                                Text("Overtime pay")
                                    .font(.body)
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.body)
                                Text("Roll-ins (other compensation items that roll into the pension calculation)")
                                    .font(.body)
                            }
                        }
                        .padding(.leading, 8)
                    }
                    
                    Divider()
                    
                    // Calculation Method
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How FAC is Calculated")
                            .font(.title3)
                            .bold()
                        
                        Text("This calculator uses a **3-year average** method:")
                            .font(.body)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Step 1: Calculate Total Compensation for Each Year")
                                    .font(.headline)
                                
                                Text("For each of the final 3 years before retirement:")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Year 1 Total = Base Wage + Overtime + Roll-ins")
                                    Text("Year 2 Total = Base Wage + Overtime")
                                    Text("Year 3 Total = Base Wage + Overtime")
                                }
                                .font(.body)
                                .padding(.leading, 8)
                                .padding(.top, 4)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Step 2: Calculate the Average")
                                    .font(.headline)
                                
                                Text("FAC = (Year 1 Total + Year 2 Total + Year 3 Total) ÷ 3")
                                    .font(.body)
                                    .padding(.leading, 8)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.leading, 8)
                    }
                    
                    Divider()
                    
                    // Example
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Example Calculation")
                            .font(.title3)
                            .bold()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Year 1:")
                                    .font(.headline)
                                Text("Base Wage: $85,000")
                                Text("Overtime: $5,000")
                                Text("Roll-ins: $6,000")
                                Text("Total: $96,000")
                                    .font(.headline)
                                    .padding(.top, 4)
                            }
                            .font(.body)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Year 2:")
                                    .font(.headline)
                                Text("Base Wage: $87,000")
                                Text("Overtime: $5,500")
                                Text("Total: $92,500")
                                    .font(.headline)
                                    .padding(.top, 4)
                            }
                            .font(.body)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Year 3:")
                                    .font(.headline)
                                Text("Base Wage: $89,000")
                                Text("Overtime: $6,000")
                                Text("Total: $95,000")
                                    .font(.headline)
                                    .padding(.top, 4)
                            }
                            .font(.body)
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("FAC Calculation:")
                                    .font(.headline)
                                Text("FAC = ($96,000 + $92,500 + $95,000) ÷ 3")
                                Text("FAC = $283,500 ÷ 3")
                                Text("FAC = $94,500")
                                    .font(.headline)
                                    .padding(.top, 4)
                            }
                            .font(.body)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Divider()
                    
                    // Usage in Pension Calculation
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How FAC is Used in Pension Calculations")
                            .font(.title3)
                            .bold()
                        
                        Text("When the multiplier is based on FAC (which is the default), the annual pension is calculated as:")
                            .font(.body)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Annual Pension = FAC × Multiplier × Years of Service")
                                .font(.body)
                                .bold()
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            Text("Example:")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("FAC: $94,500")
                                Text("Multiplier: 2.5%")
                                Text("Years of Service: 25")
                                Text("")
                                Text("Annual Pension = $94,500 × 0.025 × 25")
                                Text("Annual Pension = $59,063")
                                    .font(.headline)
                                    .padding(.top, 4)
                            }
                            .font(.body)
                            .padding(.leading, 8)
                        }
                    }
                    
                    Divider()
                    
                    // Important Notes
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Important Notes")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("• Roll-ins are only included in Year 1 of the 3-year average")
                                    Text("• Base wage and overtime are included in all 3 years")
                                    Text("• The FAC calculator in the Configuration tab allows you to input values for all 3 years and automatically calculates the average")
                                    Text("• You can choose to base the multiplier on FAC or on base wage in the configuration settings")
                                }
                                .font(.body)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("FAC Calculation")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    FACExplanationView()
}

