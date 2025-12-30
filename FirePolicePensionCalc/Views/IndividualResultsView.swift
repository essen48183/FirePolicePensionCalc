//
//  IndividualResultsView.swift
//  FirePolicePensionCalc
//
//  View for displaying individual pension calculation results
//

import SwiftUI

struct IndividualResultsView: View {
    @ObservedObject var viewModel: PensionCalculatorViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView("Calculating...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if let result = viewModel.individualResult {
                        Group {
                            Text("Individual Pension Calculation")
                                .font(.largeTitle)
                                .bold()
                            
                            Text("*All costs projected and adjusted to today's buying power using your specified economic assumptions of expected fund performance and inflation rate")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.bottom)
                            
                            Text("Individual Calc or Fictional New Hire")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            // Retiree Benefits Section
                            ResultCard(title: "Initial Annual Pension", value: result.disbursement.initialAnnualPension, format: .currency)
                            Text("This is \(String(format: "%.1f", calculateRetireePercentOfOption1(result: result)))% of Option 1 annual value.  Final Annual Pension dollar amount won't reduce (may increase with COLA) but will have the reduced today's value buying power of \(formatCurrency(result.disbursement.finalAnnualPension)) at life expectancy date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Show COLA increases in dollar amount
                            if let colaInfo = calculateCOLAInfo(result: result) {
                                Text(colaInfo)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            ResultCard(title: "Total Lifetime Payout", value: result.disbursement.totalPayout, format: .currency)
                            
                            // Survivor Benefits Section
                            if result.disbursement.yearsReceivingSpousePension > 0 {
                                let survivorPercentOfInitial = (result.disbursement.spouseInitialAnnualPension / result.disbursement.initialAnnualPension) * 100.0
                                ResultCard(title: "Survivor's Initial Annual Pension", value: survivorPercentOfInitial, format: .percent)
                                
                                if viewModel.config.pensionOption == .option3 {
                                    // Option 3: Dollar amount is 100% of initial pension plus COLAs from retiree's years, but buying power decreases
                                    // On day 1 of survivor pension (after retiree's years), dollar amount includes COLAs, but buying power is reduced by inflation
                                    Text("This survivor receives \(String(format: "%.1f", survivorPercentOfInitial))% of the initial annual pension (dollar amount of \(formatCurrency(result.disbursement.spouseInitialAnnualPension)), which includes any COLA increases from the \(result.disbursement.yearsReceivingPension) years the retiree received the pension) for \(result.disbursement.yearsReceivingSpousePension) years. The dollar amount stays at this level (or increases with additional COLA adjustments during survivor years), but the buying power decreases with inflation each year. On the day it starts (after \(result.disbursement.yearsReceivingPension) years of the retiree receiving the pension), the dollar amount paid is \(formatCurrency(result.disbursement.spouseInitialAnnualPension)) which has today's value buying power of \(formatCurrency(result.disbursement.spouseInitialBuyingPower)), and by the final life expectancy year, the final buying power will be \(formatCurrency(result.disbursement.spouseFinalAnnualPension)).")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("This survivor receives \(String(format: "%.1f", survivorPercentOfInitial))% of the initial annual pension for \(result.disbursement.yearsReceivingSpousePension) years, which will have today's value buying power on the day it starts of \(formatCurrency(result.disbursement.spouseInitialAnnualPension)) and final life expectancy year buying power of \(formatCurrency(result.disbursement.spouseFinalAnnualPension))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Costs Section
                            ResultCard(title: "City Contributions Required", value: result.cityContribution, format: .currency)
                            ResultCard(title: "Employee Contributions Required", value: calculateEmployeeContribution(), format: .currency)
                            
                            Divider()
                            
                            Text("Retirement Option Details")
                                .font(.title2)
                                .bold()
                            
                            Text("Retiree receives \(String(format: "%.1f", calculateRetireePercentOfOption1(result: result)))% of Option 1 annual value for \(result.disbursement.yearsReceivingPension) years")
                            
                            if result.disbursement.yearsReceivingSpousePension > 0 {
                                Text("Survivor receives \(String(format: "%.1f", calculateSurvivorPercentOfOption1(result: result)))% of Option 1 annual value for \(result.disbursement.yearsReceivingSpousePension) years")
                            }
                            
                            Divider()
                            
                            Text("Configuration Used")
                                .font(.title2)
                                .bold()
                            
                            Text("Hire Age: \(viewModel.config.fictionalNewHireAge)")
                            Text("Base Wage: \(formatCurrency(viewModel.config.baseWage))")
                            Text("FAC Wage: \(formatCurrency(viewModel.config.facWage))")
                            Text("Multiplier: \(viewModel.config.multiplier)%")
                            Text("COLA: \(viewModel.config.colaNumber) adjustments of \(viewModel.config.colaPercent)% every \(viewModel.config.colaSpacing) years")
                        }
                        .padding()
                    } else {
                        Text("Configure settings and tap 'Calculate Pension' to see results")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
            .navigationTitle("Individual Results")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
    
    private func calculateEmployeeContribution() -> Double {
        // Calculate years needed to retire for fictional new hire (same logic as service)
        let yearsToRetire: Int
        if (viewModel.config.fictionalNewHireAge + viewModel.config.careerYearsService) < viewModel.config.minAgeForYearsService {
            yearsToRetire = viewModel.config.minAgeForYearsService - viewModel.config.fictionalNewHireAge
        } else if viewModel.config.retirementAge <= (viewModel.config.careerYearsService + viewModel.config.fictionalNewHireAge) {
            yearsToRetire = viewModel.config.retirementAge - viewModel.config.fictionalNewHireAge
        } else {
            yearsToRetire = viewModel.config.careerYearsService
        }
        
        // Employee contribution is percentage of base wage over career
        return viewModel.config.baseWage * (viewModel.config.employeeContributionPercent / 100.0) * Double(yearsToRetire)
    }
    
    private func calculateOption1Pension() -> Double {
        // Calculate years needed to retire for fictional new hire (same logic as service)
        let yearsToRetire: Int
        if (viewModel.config.fictionalNewHireAge + viewModel.config.careerYearsService) < viewModel.config.minAgeForYearsService {
            yearsToRetire = viewModel.config.minAgeForYearsService - viewModel.config.fictionalNewHireAge
        } else if viewModel.config.retirementAge <= (viewModel.config.careerYearsService + viewModel.config.fictionalNewHireAge) {
            yearsToRetire = viewModel.config.retirementAge - viewModel.config.fictionalNewHireAge
        } else {
            yearsToRetire = viewModel.config.careerYearsService
        }
        
        // Calculate Option 1 (maximum) pension amount
        let earningsBasedOn = viewModel.config.multiplierBasedOnFAC ? viewModel.config.facWage : viewModel.config.baseWage
        let annualMulti = viewModel.config.multiplier / 100.0
        return earningsBasedOn * annualMulti * Double(yearsToRetire)
    }
    
    private func calculateRetireePercentOfOption1(result: (disbursement: PensionCalculatorDisbursements.DisbursementResult, cityContribution: Double)) -> Double {
        let option1Pension = calculateOption1Pension()
        return (result.disbursement.initialAnnualPension / option1Pension) * 100.0
    }
    
    private func calculateSurvivorPercentOfOption1(result: (disbursement: PensionCalculatorDisbursements.DisbursementResult, cityContribution: Double)) -> Double {
        let option1Pension = calculateOption1Pension()
        return (result.disbursement.spouseInitialAnnualPension / option1Pension) * 100.0
    }
    
    private func calculateCOLAInfo(result: (disbursement: PensionCalculatorDisbursements.DisbursementResult, cityContribution: Double)) -> String? {
        // Only show if there are COLAs configured
        guard viewModel.config.colaNumber > 0 else {
            return nil
        }
        
        let initialPension = result.disbursement.initialAnnualPension
        let colaPercent = viewModel.config.colaPercent / 100.0
        let isCompounding = viewModel.config.isColaCompounding
        let numberColas = viewModel.config.colaNumber
        let yearsReceivingPension = result.disbursement.yearsReceivingPension
        
        // Calculate the maximum dollar amount after all COLAs (not adjusted for inflation)
        var maxDollarAmount = initialPension
        let straightCola = initialPension * colaPercent
        
        for colaIndex in 0..<numberColas {
            let colaYear = (colaIndex + 1) * viewModel.config.colaSpacing
            if colaYear <= yearsReceivingPension {
                if isCompounding {
                    maxDollarAmount += maxDollarAmount * colaPercent
                } else {
                    maxDollarAmount += straightCola
                }
            }
        }
        
        let increase = maxDollarAmount - initialPension
        let increasePercent = (increase / initialPension) * 100.0
        
        if increase > 0 {
            return "Expected COLA increases: The dollar amount will increase from \(formatCurrency(initialPension)) to \(formatCurrency(maxDollarAmount)) (an increase of \(formatCurrency(increase)) or \(String(format: "%.1f", increasePercent))%) after all \(numberColas) COLA adjustment(s), not adjusted for inflation."
        } else {
            return nil
        }
    }
}

