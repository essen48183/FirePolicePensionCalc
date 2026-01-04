//
//  IndividualResultsView.swift
//  FirePolicePensionCalc
//
//  View for displaying individual pension calculation results
//

import SwiftUI

struct IndividualResultsView: View {
    @ObservedObject var viewModel: PensionCalculatorViewModel
    @State private var showPensionOptionDescription = false
    
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
                                Text("Individual Calculation")
                                    .font(.title2)
                                    .bold()
                                
                                Text("*All costs projected and adjusted to today's buying power using your specified economic assumptions of expected fund performance and inflation rate")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("(These are NOT part of the system-wide results)  sytem wide results use the same assumptions you set that show this single, but the personnel file ages hire dates and spouse info.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                                
                                // Show eligibility warning if not met
                                if let warning = calculateEligibilityWarning() {
                                    Text(warning)
                                        .foregroundColor(.red)
                                        .font(.headline)
                                        .padding(.top, 8)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                        
                        // Retiree Benefits Section
                        Section {
                            ResultCard(title: "Initial Annual Pension", value: result.disbursement.initialAnnualPension, format: .currency)
                            
                            Text("This is \(String(format: "%.1f", calculateRetireePercentOfOption1(result: result)))% of Option 1 annual value. Final Annual Pension dollar amount won't reduce (may increase with COLA).")
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
                        // Show for Options 2, 3, and 4 (always show for 3 and 4, even if years is 0)
                        if result.disbursement.yearsReceivingSpousePension > 0 || 
                           (viewModel.config.pensionOption == .option3 || viewModel.config.pensionOption == .option4) {
                            Section {
                                ResultCard(
                                    title: viewModel.config.pensionOption == .option2 ? "Designated Beneficiary's Initial Annual Pension" : "Survivor's Initial Annual Pension",
                                    value: calculateSurvivorPercentOfInitial(result: result),
                                    format: .percent
                                )
                                
                                if viewModel.config.pensionOption == .option2 {
                                    Text("This designated beneficiary receives 100% of the pension amount the retiree was receiving at death (the same dollar amount: \(formatCurrency(result.disbursement.spouseInitialAnnualPension))) for a maximum of \(result.disbursement.yearsReceivingSpousePension) years. Even though Option 2 has a lower initial pension than Option 1, the designated beneficiary receives the same dollar amount the retiree was receiving, but only for a maximum of \(result.disbursement.yearsReceivingSpousePension) years.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                } else if viewModel.config.pensionOption == .option3 {
                                    if result.disbursement.yearsReceivingSpousePension > 0 {
                                        Text("This survivor receives \(String(format: "%.1f", calculateSurvivorPercentOfInitial(result: result)))% of the initial annual pension (estimated dollar amount of \(formatCurrency(result.disbursement.spouseInitialAnnualPension)), which includes any COLA increases from the \(result.disbursement.yearsReceivingPension) years the retiree received the pension). Once the survivor pension begins, it is paid for the rest of the survivor's life. The number of years expected (\(result.disbursement.yearsReceivingSpousePension) years) is an estimate based on life expectancy—the actual duration depends on how long the survivor lives. On the day survivorship starts (after \(result.disbursement.yearsReceivingPension) years of the retiree receiving the pension), the dollar amount paid is \(formatCurrency(result.disbursement.spouseInitialAnnualPension)).")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    } else {
                                        Text("If this survivor outlives the retiree, they would receive \(String(format: "%.1f", calculateSurvivorPercentOfInitial(result: result)))% of the initial annual pension (estimated dollar amount of \(formatCurrency(result.disbursement.spouseInitialAnnualPension)), which includes any COLA increases from the \(result.disbursement.yearsReceivingPension) years the retiree received the pension). Once the survivor pension begins, it is paid for the rest of the survivor's life. Life expectancy suggests the survivor may die first, but if they outlive the retiree, the pension would continue for their lifetime.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    }
                                } else if viewModel.config.pensionOption == .option4 {
                                    if result.disbursement.yearsReceivingSpousePension > 0 {
                                        Text("This survivor receives \(String(format: "%.1f", calculateSurvivorPercentOfInitial(result: result)))% of the initial annual pension at retirement. Once the survivor pension begins, it is paid for the rest of the survivor's life. The number of years expected (\(result.disbursement.yearsReceivingSpousePension)) is an estimate based on life expectancy—the actual duration depends on how long the survivor lives. The dollar amount is \(formatCurrency(result.disbursement.spouseInitialAnnualPension)) (66.67% of the initial annual pension) on the day survivorship starts (after \(result.disbursement.yearsReceivingPension) years of the retiree receiving the pension).")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    } else {
                                        Text("If this survivor outlives the retiree, they would receive \(String(format: "%.1f", calculateSurvivorPercentOfInitial(result: result)))% of the initial annual pension at retirement. Once the survivor pension begins, it is paid for the rest of the survivor's life. Life expectancy suggests the survivor may die first, but if they outlive the retiree, the pension would continue for their lifetime. The dollar amount is \(formatCurrency(result.disbursement.spouseInitialAnnualPension)) (66.67% of the initial annual pension).")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    }
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
                        Section(header: HStack {
                            Text("Retirement Option Details")
                                .font(.title2)
                                .bold()
                            Spacer()
                            Button(action: {
                                showPensionOptionDescription = true
                            }) {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                            }
                        }) {
                            Text("Retiree receives \(String(format: "%.1f", calculateRetireePercentOfOption1(result: result)))% of Option 1 annual value for \(result.disbursement.yearsReceivingPension) years")
                            
                            if viewModel.config.pensionOption == .option2 {
                                if result.disbursement.yearsReceivingSpousePension > 0 {
                                    Text("Designated beneficiary receives \(String(format: "%.1f", calculateSurvivorPercentOfOption1(result: result)))% of Option 1 annual value for a maximum of \(result.disbursement.yearsReceivingSpousePension) years")
                                }
                            } else if viewModel.config.pensionOption == .option3 || viewModel.config.pensionOption == .option4 {
                                if result.disbursement.yearsReceivingSpousePension > 0 {
                                    Text("Survivor receives \(String(format: "%.1f", calculateSurvivorPercentOfOption1(result: result)))% of Option 1 annual value for the rest of their life (estimated  \(result.disbursement.yearsReceivingSpousePension) years based on life expectancy)")
                                } else {
                                    // Life expectancy suggests survivor dies first, but show what they would get if they outlive retiree
                                    Text("Survivor would receive \(String(format: "%.1f", calculateSurvivorPercentOfOption1(result: result)))% of Option 1 annual value for the rest of their life if they outlive the retiree (life expectancy suggests they may pass away first, nonetheless the pension would continue for their lifetime if they did outsurvive)")
                                }
                            }
                        }
                        
                        // Configuration Section
                        Section(header: Text("Configuration Used").font(.title2).bold()) {
                            Text("Hire Age: \(calculateHireAge()) (Year Hired: \(formatYear(viewModel.config.fictionalHiredYear)) - Year Born: \(formatYear(viewModel.config.fictionalBirthYear)))")
                            Text("Retire Age: \(calculateRetireAge())")
                            Text("Years of Work: \(viewModel.config.fictionalYearsOfWork)")
                            Text("Retirement Eligibility:")
                                .font(.headline)
                                .padding(.top, 4)
                            Text("• Age-triggered: \(viewModel.config.retirementAge) years old")
                            Text("• Years of service: \(viewModel.config.careerYearsService) years of service")
                            Text("• Minimum age for years of service: \(viewModel.config.minAgeForYearsService) years old")
                            
                            // Show eligibility warning if not met
                            if let warning = calculateEligibilityWarning() {
                                Text(warning)
                                    .foregroundColor(.red)
                                    .font(.headline)
                                    .padding(.top, 8)
                            }
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
        .sheet(isPresented: $showPensionOptionDescription) {
            PensionOptionDescriptionView()
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
    
    private func formatYear(_ value: Int) -> String {
        // Format year without commas
        return String(value)
    }
    
    private func formatPercent(_ value: Double) -> String {
        // Format percent with 2 decimal places
        return String(format: "%.2f", value)
    }
    
    private func calculateEmployeeContribution() -> Double {
        // Always use the chosen years of work directly
        let yearsToRetire = viewModel.config.fictionalYearsOfWork
        
        // Employee contribution is percentage of base wage over career
        return viewModel.config.baseWage * (viewModel.config.employeeContributionPercent / 100.0) * Double(yearsToRetire)
    }
    
    private func calculateOption1Pension() -> Double {
        // Always use the chosen years of work directly
        let yearsToRetire = viewModel.config.fictionalYearsOfWork
        
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
        // Always use the chosen years of work directly
        let hireAge = calculateHireAge()
        let yearsToRetire = viewModel.config.fictionalYearsOfWork
        return hireAge + yearsToRetire
    }
    
    private func calculateEligibilityWarning() -> String? {
        let config = viewModel.config
        let hireAge = calculateHireAge()
        let yearsOfWork = config.fictionalYearsOfWork
        let retirementAgeAtWorkEnd = hireAge + yearsOfWork
        
        // Check if they meet normal retirement age
        let meetsNormalRetirement = retirementAgeAtWorkEnd >= config.retirementAge
        
        // Check if they meet early retirement (min age + years of service)
        let meetsEarlyRetirement = retirementAgeAtWorkEnd >= config.minAgeForYearsService && yearsOfWork >= config.careerYearsService
        
        // If they meet either requirement, no warning needed
        if meetsNormalRetirement || meetsEarlyRetirement {
            return nil
        }
        
        // Calculate what's needed
        var yearsShort: Int = 0
        var ageWhenBenefitsStart: Int = 0
        var warningMessage = ""
        
        // Calculate when they would meet early retirement requirements
        let yearsToEarlyRetirementService = max(0, config.careerYearsService - yearsOfWork)
        let yearsToEarlyRetirementAge = max(0, config.minAgeForYearsService - retirementAgeAtWorkEnd)
        
        // Age when they would have enough years of service
        let ageWithEnoughYears = hireAge + config.careerYearsService
        
        // Age when they would meet the minimum age requirement
        let ageForMinAge = config.minAgeForYearsService
        
        // Determine which constraint is limiting (age or years of service)
        if yearsToEarlyRetirementService > 0 && yearsToEarlyRetirementAge > 0 {
            // Need both more years of service AND need to be older
            // Benefits start when BOTH conditions are met
            ageWhenBenefitsStart = max(ageWithEnoughYears, ageForMinAge)
            yearsShort = max(yearsToEarlyRetirementService, yearsToEarlyRetirementAge)
            
            if ageWithEnoughYears >= ageForMinAge {
                // Years of service is the limiting factor
                warningMessage = "⚠️ Retirement eligibility not met. The benefit amounts shown are calculated with \(yearsOfWork) years of service (inadequate for full eligibility). Benefits will not start until age \(ageWhenBenefitsStart) (minimum age \(config.minAgeForYearsService) with \(config.careerYearsService) years of service). Need \(yearsToEarlyRetirementService) more year\(yearsToEarlyRetirementService == 1 ? "" : "s") of service."
            } else {
                // Age is the limiting factor
                warningMessage = "⚠️ Retirement eligibility not met. The benefit amounts shown are calculated with \(yearsOfWork) years of service (inadequate for full eligibility). Benefits will not start until age \(ageWhenBenefitsStart) (minimum age \(config.minAgeForYearsService) with \(config.careerYearsService) years of service). Need to be age \(ageForMinAge) (in \(yearsToEarlyRetirementAge) year\(yearsToEarlyRetirementAge == 1 ? "" : "s"))."
            }
        } else if yearsToEarlyRetirementService > 0 {
            // Only need more years of service
            ageWhenBenefitsStart = ageWithEnoughYears
            yearsShort = yearsToEarlyRetirementService
            warningMessage = "⚠️ Retirement eligibility not met. The benefit amounts shown are calculated with \(yearsOfWork) years of service (inadequate for full eligibility). Benefits will not start until age \(ageWhenBenefitsStart) (minimum age \(config.minAgeForYearsService) with \(config.careerYearsService) years of service). Need \(yearsShort) more year\(yearsShort == 1 ? "" : "s") of service."
        } else if yearsToEarlyRetirementAge > 0 {
            // Only need to be older
            ageWhenBenefitsStart = ageForMinAge
            yearsShort = yearsToEarlyRetirementAge
            warningMessage = "⚠️ Retirement eligibility not met. The benefit amounts shown are calculated with \(yearsOfWork) years of service (inadequate for full eligibility). Benefits will not start until age \(ageWhenBenefitsStart) (minimum age \(config.minAgeForYearsService) with \(config.careerYearsService) years of service). Need to be age \(ageWhenBenefitsStart) (in \(yearsShort) year\(yearsShort == 1 ? "" : "s"))."
        }
        
        return warningMessage
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

