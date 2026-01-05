//
//  PensionCalculatorPaymentsInto.swift
//  FirePolicePensionCalc
//
//  Ported from Java
//

import Foundation

class PensionCalculatorPaymentsInto {
    
    /// Calculates the present value of city contributions needed to fund a retirement benefit
    /// ACTUARIAL RULE: Amount needed at retirement is 100% of expected lifetime benefits (full sum, no discounting)
    /// - Parameters:
    ///   - verbose: Whether to print detailed output
    ///   - sumDesiredAtRetirement: Amount needed at retirement (100% of lifetime benefits in nominal dollars)
    ///   - initialBalance: Starting balance in the fund
    ///   - totalEmployeeContribution: Total employee contributions over career (nominal sum)
    ///   - facWage: Final average compensation wage
    ///   - expectedInterestRate: Expected annual investment return during accumulation (as percentage)
    ///   - expectedInflationRate: Expected annual inflation rate (as percentage)
    ///   - yearsInvesting: Years of service before retirement
    ///   - yearsRetired: Years receiving pension
    ///   - compoundsPerYear: Number of compounding periods per year
    /// - Returns: Present value of city contributions needed (in today's dollars)
    static func calculateDiscountPayment(
        verbose: Bool = false,
        sumDesiredAtRetirement: Double,
        initialBalance: Double,
        totalEmployeeContribution: Double,
        facWage: Double,
        expectedInterestRate: Double, // as percentage
        expectedInflationRate: Double, // as percentage
        yearsInvesting: Int,
        yearsRetired: Int,
        compoundsPerYear: Int
    ) -> Double {
        
        // Convert percentages to decimals
        let inflationRate = expectedInflationRate / 100.0
        
        // sumDesiredAtRetirement is the amount needed at retirement (100% of lifetime benefits in nominal dollars)
        // ACTUARIAL RULE: During retirement, investment returns won't outpace inflation, so we need the full sum
        // This represents the total of all pension payments (annual payment × years retired)
        
        // totalEmployeeContribution is the nominal sum of contributions over career
        // But we need the future value of those contributions at retirement (they earn interest over time)
        // Use PensionMathCalculations for city contribution calculation
        let presentValueOfRetirementInput = PensionMathCalculations.calculateCityContributionPresentValue(
            amountNeededAtRetirement: sumDesiredAtRetirement,
            initialBalance: initialBalance,
            totalEmployeeContribution: totalEmployeeContribution,
            expectedInterestRate: expectedInterestRate,
            yearsInvesting: yearsInvesting
        )
        
        if verbose {
            // Calculate annual payment using PensionMathCalculations
            let annualPayment = PensionMathCalculations.calculateAnnualCityContribution(
                presentValue: presentValueOfRetirementInput,
                interestRate: expectedInterestRate,
                yearsInvesting: yearsInvesting
            )
            print("Annual input to retirement system required to fund (per year) for this employee assuming \(String(format: "%.2f", expectedInterestRate))% expected interest rate and \(String(format: "%.2f", expectedInflationRate))% expected inflation: $\(Int(annualPayment)).")
        }
        
        return presentValueOfRetirementInput
    }
    
    /// Calculate present value from future value
    /// Uses PensionMathFormulas for the calculation
    static func presentValue(futureValue: Double, interestRate: Double, years: Int) -> Double {
        return PensionMathFormulas.presentValue(futureValue: futureValue, interestRate: interestRate, years: years)
    }
    
    /// Calculate future value from present value
    /// Uses PensionMathFormulas for the calculation
    static func futureValue(presentValue: Double, interestRate: Double, years: Int) -> Double {
        return PensionMathFormulas.futureValue(presentValue: presentValue, interestRate: interestRate, years: years)
    }
    
    /// Calculate future value of an annuity (annual payments)
    /// Uses PensionMathFormulas for the calculation
    static func futureValueOfAnnuity(annualPayment: Double, interestRate: Double, years: Int) -> Double {
        return PensionMathFormulas.futureValueOfAnnuity(annualPayment: annualPayment, interestRate: interestRate, years: years)
    }
    
    /// Calculate amount needed at retirement to fund pension payments
    /// ACTUARIAL RULE: We need 100% of expected lifetime benefits at retirement time.
    /// Uses PensionMathFormulas for the calculation
    static func presentValueOfAnnuityWithInflation(
        initialAnnualPayment: Double,
        interestRate: Double,
        inflationRate: Double,
        years: Int
    ) -> Double {
        // Note: interestRate and inflationRate parameters kept for API compatibility but not used
        // The actuarial rule requires full sum with no discounting
        return PensionMathFormulas.amountNeededAtRetirement(initialAnnualPayment: initialAnnualPayment, years: years)
    }
    
    /// Verify that employee and employer contributions with expected return rate are sufficient
    /// to cover the lifetime payout
    /// - Parameters:
    ///   - totalPayoutNeeded: Total lifetime payout needed (in today's dollars) - sum of all inflation-adjusted payments
    ///   - initialAnnualPension: Initial annual pension amount
    ///   - facWage: Final average compensation wage
    ///   - employeeContributionPercent: Employee contribution as percentage of FAC wage (default 6%)
    ///   - cityContributionPresentValue: Present value of city contributions needed
    ///   - expectedInterestRate: Expected annual investment return (as percentage)
    ///   - expectedInflationRate: Expected annual inflation rate (as percentage)
    ///   - yearsInvesting: Years of service before retirement
    ///   - yearsRetired: Years receiving pension
    /// - Returns: Tuple with (isSufficient: Bool, totalAvailableAtRetirement: Double, totalNeededAtRetirement: Double, shortfall: Double)
    static func verifyContributionSufficiency(
        totalPayoutNeeded: Double,
        initialAnnualPension: Double,
        facWage: Double,
        employeeContributionPercent: Double = 6.0,
        cityContributionPresentValue: Double,
        expectedInterestRate: Double,
        expectedInflationRate: Double,
        yearsInvesting: Int,
        yearsRetired: Int
    ) -> (isSufficient: Bool, totalAvailableAtRetirement: Double, totalNeededAtRetirement: Double, shortfall: Double) {
        
        // Use PensionMathCalculations for verification
        let annualEmployeeContribution = PensionMathCalculations.calculateAnnualEmployeeContribution(
            baseWage: facWage,
            contributionPercent: employeeContributionPercent
        )
        
        return PensionMathCalculations.verifyContributionSufficiency(
            initialAnnualPension: initialAnnualPension,
            yearsRetired: yearsRetired,
            annualEmployeeContribution: annualEmployeeContribution,
            cityContributionPresentValue: cityContributionPresentValue,
            expectedInterestRate: expectedInterestRate,
            yearsInvesting: yearsInvesting
        )
    }
}

