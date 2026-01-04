//
//  FinancialDisclosureView.swift
//  FirePolicePensionCalc
//
//  Financial disclosure that must be acknowledged
//

import SwiftUI

struct FinancialDisclosureView: View {
    @Environment(\.dismiss) var dismiss
    @State private var hasBeenAcknowledged: Bool
    
    init() {
        // Check if disclosure has been acknowledged before
        _hasBeenAcknowledged = State(initialValue: UserDefaults.standard.bool(forKey: "financialDisclosureAcknowledged"))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header icon and title
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("Financial Disclosure")
                                .font(.title)
                                .bold()
                        }
                        Spacer()
                    }
                    .padding(.bottom)
                    
                    DisclosureSection(
                        title: "Purpose of This Calculator",
                        content: "This pension calculator is designed to assist in estimating pension benefits and system-wide funding requirements. It is intended for informational and planning purposes only."
                    )
                    
                    DisclosureSection(
                        title: "Not Financial Advice",
                        content: "This calculator does not provide financial, investment, or legal advice. The calculations and projections are estimates based on the assumptions and data you provide and modeled after typical pension systems should not be used as the sole basis for financial decisions."
                    )
                    
                    DisclosureSection(
                        title: "Assumptions and Limitations",
                        content: "The calculations rely on various assumptions including, but not limited to:\n\n• Expected investment returns\n• Inflation rates\n• Life expectancy\n• Future salary growth\n• Retirement dates\n\nActual results may vary significantly from these estimates."
                    )
                    
                    DisclosureSection(
                        title: "No Guarantees",
                        content: "Pension benefits are subject to change based on plan amendments, legislative changes, and other factors beyond the control of this calculator. Past performance does not guarantee future results."
                    )
                    
                    DisclosureSection(
                        title: "Consult Professionals",
                        content: "You should consult with qualified financial advisors, actuaries, and legal professionals before making any decisions based on the information provided by this calculator."
                    )
                    
                    DisclosureSection(
                        title: "Accuracy Disclaimer",
                        content: "While every effort has been made to ensure the accuracy of the calculations, the developers make no warranties or representations regarding the accuracy, completeness, or suitability of the information provided. Use of this calculator is at your own risk."
                    )
                    
                    DisclosureSection(
                        title: "Data Privacy",
                        content: "All data entered into this calculator is stored locally on your device. No information is transmitted to external servers or third parties."
                    )
                    
                    // Action buttons
                    if !hasBeenAcknowledged {
                        VStack(spacing: 12) {
                            Button(action: {
                                // Accept - acknowledge and dismiss
                                UserDefaults.standard.set(true, forKey: "financialDisclosureAcknowledged")
                                hasBeenAcknowledged = true
                                dismiss()
                            }) {
                                HStack {
                                    Spacer()
                                    Text("I Acknowledge and Agree")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                // Decline - exit app
                                exit(0)
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Decline")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.top, 20)
                    }
                }
                .padding()
            }
            .navigationTitle("Financial Disclosure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if hasBeenAcknowledged {
                        // After first acknowledgment, show dismissible Done button
                        Button("I Understand") {
                            dismiss()
                        }
                    }
                }
            }
            .interactiveDismissDisabled(!hasBeenAcknowledged) // Prevent swipe down on first time
        }
    }
}

struct DisclosureSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    FinancialDisclosureView()
}

