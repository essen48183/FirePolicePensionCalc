//
//  ActuarialFormulasView.swift
//  FirePolicePensionCalc
//
//  View showing all math formulas and actuarial best practices
//

import SwiftUI

struct ActuarialFormulasView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Actuarial Formulas & Best Practices")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Mathematical Foundation of Pension Calculations")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                    
                    // Actuarial Rule
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("100% Funding Actuarial Rule")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                
                                Text("We must plan to have 100% of the expected lifetime benefits at retirement time. Once a person is retired, we cannot expect investment returns to outpace inflation.")
                                    .font(.body)
                                
                                Text("This conservative assumption ensures adequate funding even if investment returns are poor during retirement.")
                                    .font(.body)
                                    .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Divider()
                    
                    // Basic Financial Formulas
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Financial Formulas")
                            .font(.title3)
                            .bold()
                        
                        FormulaCard(
                            title: "Present Value from Future Value",
                            formula: "PV = FV / (1 + r)ⁿ",
                            description: "Discounts a future value back to today using the interest rate r over n periods.",
                            usage: "Used to calculate today's value of contributions needed at retirement."
                        )
                        
                        FormulaCard(
                            title: "Future Value from Present Value",
                            formula: "FV = PV × (1 + r)ⁿ",
                            description: "Calculates the future value of a present amount with compound interest.",
                            usage: "Used to calculate the value of contributions at retirement."
                        )
                    }
                    
                    Divider()
                    
                    // Annuity Formulas
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Annuity Formulas")
                            .font(.title3)
                            .bold()
                        
                        FormulaCard(
                            title: "Future Value of Annuity",
                            formula: "FV = PMT × (((1 + r)ⁿ - 1) / r)",
                            description: "Calculates the future value of a series of equal payments (annuity) made at the end of each period.",
                            usage: "Used to calculate the future value of employee and city contributions over a career."
                        )
                        
                        FormulaCard(
                            title: "Payment from Present Value",
                            formula: "PMT = PV × (r / (1 - (1 + r)⁻ⁿ))",
                            description: "Calculates the annual payment needed to reach a present value target over n periods.",
                            usage: "Used to calculate annual city contributions needed to fund future retirement benefits."
                        )
                    }
                    
                    Divider()
                    
                    // Actuarial Rule Formula
                    VStack(alignment: .leading, spacing: 16) {
                        Text("100% Funding Rule Formula")
                            .font(.title3)
                            .bold()
                        
                        FormulaCard(
                            title: "Amount Needed at Retirement",
                            formula: "Amount = PMT × n",
                            description: "The full sum of all expected pension payments. No discounting is applied because investment returns won't outpace inflation during retirement.",
                            usage: "Used to determine the total amount needed at retirement to fund all expected lifetime benefits."
                        )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Why This Formula?")
                                .font(.headline)
                            
                            Text("During the accumulation phase (before retirement), we use the expected return rate (7.25%) to grow contributions. However, during the payout phase (after retirement), we assume investment returns will not outpace inflation. Therefore, we need the full sum of all payments at retirement time.")
                                .font(.body)
                                .padding(.top, 4)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Divider()
                    
                    // Pension Benefit Calculation
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Pension Benefit Calculation")
                            .font(.title3)
                            .bold()
                        
                        FormulaCard(
                            title: "Annual Pension",
                            formula: "Annual Pension = Earnings × Multiplier × Years of Service",
                            description: "Earnings can be either base wage or FAC (Final Average Compensation), depending on configuration.",
                            usage: "Used to calculate the initial annual pension benefit at retirement."
                        )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Example:")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("FAC: $94,500")
                                Text("Multiplier: 2.5%")
                                Text("Years of Service: 25")
                                Text("")
                                Text("Annual Pension = $94,500 × 0.025 × 25 = $59,063")
                                    .font(.headline)
                            }
                            .font(.body)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Divider()
                    
                    // Actuarial Equivalence
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Actuarial Equivalence")
                            .font(.title3)
                            .bold()
                        
                        Text("All pension options (1-4) are actuarially equivalent, meaning they have the same total lifetime value in today's buying power. The calculator uses a binary search algorithm to find the reduced pension amount for Options 2, 3, and 4 that makes their total lifetime benefit equal to Option 1.")
                            .font(.body)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Process:")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("1. Calculate Option 1's total lifetime benefit")
                                Text("2. For Options 2, 3, and 4, iteratively find the reduced pension amount")
                                Text("3. Verify that total lifetime benefit equals Option 1")
                                Text("4. Precision: within $0.01")
                            }
                            .font(.body)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Divider()
                    
                    // COLA and Inflation
                    VStack(alignment: .leading, spacing: 16) {
                        Text("COLA and Inflation Adjustments")
                            .font(.title3)
                            .bold()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("COLA (Cost of Living Adjustment)")
                                    .font(.headline)
                                
                                Text("COLAs increase the dollar amount of pension payments. They can be:")
                                    .font(.body)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• Compounding: Each COLA is applied to the current (increased) amount")
                                    Text("• Non-compounding: Each COLA adds a fixed dollar amount")
                                }
                                .font(.body)
                                .padding(.leading, 8)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Inflation")
                                    .font(.headline)
                                
                                Text("Inflation reduces the buying power of pension payments over time. The calculator adjusts all costs to today's buying power using the expected inflation rate.")
                                    .font(.body)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Divider()
                    
                    // Best Practices
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Actuarial Best Practices")
                            .font(.title3)
                            .bold()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            PracticeItem(
                                icon: "checkmark.circle.fill",
                                title: "Conservative Assumptions",
                                description: "Using 100% funding rule ensures adequate funding even in worst-case scenarios."
                            )
                            
                            PracticeItem(
                                icon: "checkmark.circle.fill",
                                title: "Actuarial Equivalence",
                                description: "All pension options maintain actuarial equivalence, ensuring fairness across choices."
                            )
                            
                            PracticeItem(
                                icon: "checkmark.circle.fill",
                                title: "Standard Formulas",
                                description: "All calculations use standard actuarial and financial formulas recognized by the profession."
                            )
                            
                            PracticeItem(
                                icon: "checkmark.circle.fill",
                                title: "Verification",
                                description: "System automatically verifies that contributions meet 80-120% funding targets."
                            )
                            
                            PracticeItem(
                                icon: "checkmark.circle.fill",
                                title: "Transparency",
                                description: "All formulas and assumptions are documented and verifiable."
                            )
                        }
                    }
                    
                    Divider()
                    
                    // References
                    VStack(alignment: .leading, spacing: 16) {
                        Text("References")
                            .font(.title3)
                            .bold()
                        
                        Text("All formulas used in this calculator follow standard actuarial mathematics as documented in:")
                            .font(.body)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Actuarial Mathematics for Life Contingent Risks")
                            Text("• Fundamentals of Pension Mathematics")
                            Text("• Standard annuity and present value formulas")
                        }
                        .font(.body)
                        .padding(.leading, 8)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Formulas & Practices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FormulaCard: View {
    let title: String
    let formula: String
    let description: String
    let usage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            Text(formula)
                .font(.system(.body, design: .monospaced))
                .bold()
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
            
            Text("Usage: \(usage)")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PracticeItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ActuarialFormulasView()
}

