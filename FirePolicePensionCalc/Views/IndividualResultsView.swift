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
            Group {
                if viewModel.isLoading {
                    List {
                        Section {
                            ProgressView("Calculating...")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowInsets(EdgeInsets())
                        }
                    }
                } else if let result = viewModel.individualResult {
                    List {
                        // Header Section
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Individual Fictional Calc.")
                                    .font(.title2)
                                    .bold()
                                
                                Text("*All costs projected and adjusted to today's buying power using your specified economic assumptions of expected fund performance and inflation rate")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("(not part of the system-wide results)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                            .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                        
                        // Retiree Benefits Section
                        Section {
                            ResultCard(title: "Initial Annual Pension", value: result.disbursement.initialAnnualPension, format: .currency)
                            
                            Text("This is \(String(format: "%.1f", calculateRetireePercentOfOption1(result: result)))% of Option 1 annual value.  Final Annual Pension dollar amount won't reduce (may increase with COLA) but will have the reduced today's value buying power of \(formatCurrency(result.disbursement.finalAnnualPension)) at life expectancy date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            
                            // Show COLA increases in dollar amount
                            if let colaInfo = calculateCOLAInfo(result: result) {
                                Text(colaInfo)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            }
                            
                            ResultCard(title: "Total Lifetime Payout", value: result.disbursement.totalPayout, format: .currency)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        
                        // Survivor Benefits Section
                        if result.disbursement.yearsReceivingSpousePension > 0 {
                            Section {
                                ResultCard(
                                    title: "Survivor's Initial Annual Pension",
                                    value: calculateSurvivorPercentOfInitial(result: result),
                                    format: .percent
                                )
                                
                                if viewModel.config.pensionOption == .option3 {
                                    Text("This survivor receives \(String(format: "%.1f", calculateSurvivorPercentOfInitial(result: result)))% for \(result.disbursement.yearsReceivingSpousePension) years of the initial annual pension (estimated dollar amount of \(formatCurrency(result.disbursement.spouseInitialAnnualPension)), which includes any COLA increases from the \(result.disbursement.yearsReceivingPension) years the retiree and survivor received the pension). The dollar amount decreases to the option level and the buying power decreases with inflation each year even though the dollar amount doesn't. On the day survivorship starts (after \(result.disbursement.yearsReceivingPension) years of the retiree receiving the pension), the dollar amount paid is \(formatCurrency(result.disbursement.spouseInitialAnnualPension)) which will have an approximate today's-dollar-value buying power of \(formatCurrency(result.disbursement.spouseInitialBuyingPower)), and by the final life expectancy year, the final buying power in today's dollars will be closer to \(formatCurrency(result.disbursement.spouseFinalAnnualPension)).")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                } else if viewModel.config.pensionOption == .option4 {
                                    Text("This survivor receives \(String(format: "%.1f", calculateSurvivorPercentOfInitial(result: result)))% of the initial annual pension at retirement for \(result.disbursement.yearsReceivingSpousePension) years. The dollar amount is \(formatCurrency(result.disbursement.spouseInitialAnnualPension)) (66.67% of the initial annual pension), which will have today's value buying power on the day survivorship starts (after \(result.disbursement.yearsReceivingPension) years of the retiree receiving the pension) of \(formatCurrency(result.disbursement.spouseInitialBuyingPower)), and final life expectancy year buying power of \(formatCurrency(result.disbursement.spouseFinalAnnualPension))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                } else {
                                    Text("This survivor receives \(String(format: "%.1f", calculateSurvivorPercentOfInitial(result: result)))% of the initial annual pension for \(result.disbursement.yearsReceivingSpousePension) years, which will have today's value buying power on the day it starts of \(formatCurrency(result.disbursement.spouseInitialAnnualPension)) and final life expectancy year buying power of \(formatCurrency(result.disbursement.spouseFinalAnnualPension))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        }
                        
                        // Costs Section
                        Section {
                            ResultCard(title: "City Contributions Required", value: result.cityContribution, format: .currency)
                            ResultCard(title: "Employee Contributions Required", value: calculateEmployeeContribution(), format: .currency)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        
                        // Retirement Option Details Section
                        Section(header: Text("Retirement Option Details").font(.title2).bold()) {
                            Text("Retiree receives \(String(format: "%.1f", calculateRetireePercentOfOption1(result: result)))% of Option 1 annual value for \(result.disbursement.yearsReceivingPension) years")
                            
                            if result.disbursement.yearsReceivingSpousePension > 0 {
                                Text("Survivor receives \(String(format: "%.1f", calculateSurvivorPercentOfOption1(result: result)))% of Option 1 annual value for \(result.disbursement.yearsReceivingSpousePension) years")
                            }
                        }
                        
                        // Configuration Section
                        Section(header: Text("Configuration Used").font(.title2).bold()) {
                            Text("Hire Age: \(calculateHireAge()) (Year Hired: \(formatYear(viewModel.config.fictionalHiredYear)) - Year Born: \(formatYear(viewModel.config.fictionalBirthYear)))")
                            if viewModel.config.earlyRetirementAuthorized {
                                Text("Retire Age: \(calculateRetireAge()) (Note: Pension payments may start at minimum service years age (\(viewModel.config.minAgeForYearsService)) depending on system)")
                            } else {
                                Text("Retire Age: \(calculateRetireAge())")
                            }
                            Text("Years of Work: \(viewModel.config.fictionalYearsOfWork)")
                            if viewModel.config.multiplierBasedOnFAC {
                                Text("FAC Wage: \(formatCurrency(viewModel.config.facWage))")
                            } else {
                                Text("Fixed/Base Wage: \(formatCurrency(viewModel.config.baseWage))")
                            }
                            Text("Multiplier: \(formatPercent(viewModel.config.multiplier))%")
                            Text("COLA: \(viewModel.config.colaNumber) adjustments of \(formatPercent(viewModel.config.colaPercent))% every \(viewModel.config.colaSpacing) years")
                        }
                    }
                } else {
                    List {
                        Section {
                            Text("Configure settings and tap 'Calculate Pension' to see results")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowInsets(EdgeInsets())
                        }
                    }
                }
            }
            .navigationTitle("Individual Results")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
    
    private func formatYear(_ value: Int) -> String {
        // Format year without commas
        return String(value)
    }
    
    private func formatPercent(_ value: Double) -> String {
        // Format percent with 2 decimal places
        return String(format: "%.2f", value)
    }
    
    private func calculateEmployeeContribution() -> Double {
        // Calculate years needed to retire using fictionalYearsOfWork from blue box (same logic as service)
        let hireAge = calculateHireAge()
        let yearsToRetire: Int
        
        // If early retirement is authorized, use years of work directly
        if viewModel.config.earlyRetirementAuthorized {
            yearsToRetire = viewModel.config.fictionalYearsOfWork
        } else if (hireAge + viewModel.config.fictionalYearsOfWork) < viewModel.config.minAgeForYearsService {
            yearsToRetire = viewModel.config.minAgeForYearsService - hireAge
        } else if viewModel.config.retirementAge <= (viewModel.config.fictionalYearsOfWork + hireAge) {
            yearsToRetire = viewModel.config.retirementAge - hireAge
        } else {
            yearsToRetire = viewModel.config.fictionalYearsOfWork
        }
        
        // Employee contribution is percentage of base wage over career
        return viewModel.config.baseWage * (viewModel.config.employeeContributionPercent / 100.0) * Double(yearsToRetire)
    }
    
    private func calculateOption1Pension() -> Double {
        // Calculate years needed to retire using fictionalYearsOfWork from blue box (same logic as service)
        let hireAge = calculateHireAge()
        let yearsToRetire: Int
        
        // If early retirement is authorized, use years of work directly
        if viewModel.config.earlyRetirementAuthorized {
            yearsToRetire = viewModel.config.fictionalYearsOfWork
        } else if (hireAge + viewModel.config.fictionalYearsOfWork) < viewModel.config.minAgeForYearsService {
            yearsToRetire = viewModel.config.minAgeForYearsService - hireAge
        } else if viewModel.config.retirementAge <= (viewModel.config.fictionalYearsOfWork + hireAge) {
            yearsToRetire = viewModel.config.retirementAge - hireAge
        } else {
            yearsToRetire = viewModel.config.fictionalYearsOfWork
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
    
    private func calculateSurvivorPercentOfInitial(result: (disbursement: PensionCalculatorDisbursements.DisbursementResult, cityContribution: Double)) -> Double {
        // Use the stored spouseReductionPercent for Options 2 and 4, calculate for Option 3
        if viewModel.config.pensionOption == .option3 {
            // For Option 3, calculate as percentage of initial pension (includes COLAs)
            return (result.disbursement.spouseInitialAnnualPension / result.disbursement.initialAnnualPension) * 100.0
        } else {
            // For Options 2 and 4, use the stored percentage (100% for Option 2, 66.67% for Option 4)
            return result.disbursement.spouseReductionPercent
        }
    }
    
    private func calculateHireAge() -> Int {
        // Calculate hire age from blue box inputs (Year Hired - Year Born)
        return viewModel.config.fictionalHiredYear - viewModel.config.fictionalBirthYear
    }
    
    private func calculateRetireAge() -> Int {
        // Calculate years needed to retire using fictionalYearsOfWork from blue box (same logic as service)
        let hireAge = calculateHireAge()
        let yearsToRetire: Int
        
        // If early retirement is authorized, use years of work directly
        if viewModel.config.earlyRetirementAuthorized {
            yearsToRetire = viewModel.config.fictionalYearsOfWork
        } else if (hireAge + viewModel.config.fictionalYearsOfWork) < viewModel.config.minAgeForYearsService {
            // If years of work wouldn't reach min age, use min age constraint
            yearsToRetire = viewModel.config.minAgeForYearsService - hireAge
        } else if viewModel.config.retirementAge <= (viewModel.config.fictionalYearsOfWork + hireAge) {
            // If retirement age would be reached before completing years of work, use retirement age
            yearsToRetire = viewModel.config.retirementAge - hireAge
        } else {
            // Use the chosen years of work from blue box
            yearsToRetire = viewModel.config.fictionalYearsOfWork
        }
        return hireAge + yearsToRetire
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

