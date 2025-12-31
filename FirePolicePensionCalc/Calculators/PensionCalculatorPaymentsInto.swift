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
        let interestRate = expectedInterestRate / 100.0
        let inflationRate = expectedInflationRate / 100.0
        
        // Calculate real rate of return (after inflation)
        let realRateOfReturn = ((1 + interestRate) / (1 + inflationRate)) - 1
        
        // sumDesiredAtRetirement is the amount needed at retirement (100% of lifetime benefits in nominal dollars)
        // ACTUARIAL RULE: During retirement, investment returns won't outpace inflation, so we need the full sum
        // This represents the total of all pension payments (annual payment × years retired)
        
        // totalEmployeeContribution is the nominal sum of contributions over career
        // But we need the future value of those contributions at retirement (they earn interest over time)
        // Calculate annual employee contribution and its future value at retirement
        let annualEmployeeContribution = totalEmployeeContribution / Double(yearsInvesting)
        let employeeContributionsFV = futureValueOfAnnuity(
            annualPayment: annualEmployeeContribution,
            interestRate: expectedInterestRate,
            years: yearsInvesting
        )
        
        // Calculate present value needed
        // Amount needed at retirement (nominal) minus employee contributions FV (nominal) minus initial balance
        // This gives us what the city needs to provide at retirement (nominal)
        // Then discount back to today using NOMINAL interest rate (not real rate)
        // The real rate would be used if we were working in today's dollars, but sumDesiredAtRetirement
        // is already in retirement-date dollars (nominal), so we use nominal rate to discount
        let futureValueNeeded = sumDesiredAtRetirement - initialBalance - employeeContributionsFV
        let presentValueOfRetirementInput = presentValue(
            futureValue: futureValueNeeded,
            interestRate: expectedInterestRate, // Use nominal rate, not real rate
            years: yearsInvesting
        )
        
        if verbose {
            // Calculate annual payment using annuity formula: PMT = PV * (r / (1 - (1 + r)^-n))
            let annualPayment: Double
            if yearsInvesting > 0 && interestRate > 0 {
                let discountFactor = pow(1 + interestRate, Double(-yearsInvesting))
                let annuityFactor = interestRate / (1 - discountFactor)
                annualPayment = presentValueOfRetirementInput * annuityFactor
            } else {
                annualPayment = presentValueOfRetirementInput / Double(yearsInvesting)
            }
            print("Annual input to retirement system required to fund (per year) for this employee assuming \(String(format: "%.2f", expectedInterestRate))% expected interest rate and \(String(format: "%.2f", expectedInflationRate))% expected inflation: $\(Int(annualPayment)).")
        }
        
        return presentValueOfRetirementInput
    }
    
    /// Calculate present value from future value
    private static func presentValue(futureValue: Double, interestRate: Double, years: Int) -> Double {
        // PV = FV / (1 + r)^n
        // interestRate is already in percentage form (e.g., 5.0 for 5%)
        return futureValue / pow(1 + (interestRate / 100.0), Double(years))
    }
    
    /// Calculate future value from present value
    static func futureValue(presentValue: Double, interestRate: Double, years: Int) -> Double {
        // FV = PV * (1 + r)^n
        return presentValue * pow(1 + (interestRate / 100.0), Double(years))
    }
    
    /// Calculate future value of an annuity (annual payments)
    /// Formula: FV = PMT * (((1 + r)^n - 1) / r)
    /// Where PMT is the annual payment, r is the interest rate, n is the number of years
    static func futureValueOfAnnuity(annualPayment: Double, interestRate: Double, years: Int) -> Double {
        let r = interestRate / 100.0
        if r == 0 {
            return annualPayment * Double(years)
        }
        return annualPayment * ((pow(1 + r, Double(years)) - 1) / r)
    }
    
    /// Calculate amount needed at retirement to fund pension payments
    /// ACTUARIAL RULE: We need 100% of expected lifetime benefits at retirement time.
    /// Once retired, we cannot expect investment returns to outpace inflation.
    /// Therefore, we calculate the sum of all payments in nominal dollars (no discounting).
    /// Formula: Amount Needed = PMT * n
    /// Where PMT is the annual payment, n is the number of years
    static func presentValueOfAnnuityWithInflation(
        initialAnnualPayment: Double,
        interestRate: Double,
        inflationRate: Double,
        years: Int
    ) -> Double {
        // ACTUARIAL RULE: During retirement, investment returns won't outpace inflation
        // Therefore, we need the full sum of all payments at retirement (no discounting)
        // This is a conservative assumption that ensures 100% funding
        return initialAnnualPayment * Double(years)
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
        
        let interestRate = expectedInterestRate / 100.0
        let inflationRate = expectedInflationRate / 100.0
        
        // Calculate annual employee contribution
        let annualEmployeeContribution = facWage * (employeeContributionPercent / 100.0)
        
        // Calculate future value of employee contributions (annuity)
        let employeeContributionsFV = futureValueOfAnnuity(
            annualPayment: annualEmployeeContribution,
            interestRate: expectedInterestRate,
            years: yearsInvesting
        )
        
        // Calculate annual city contribution using annuity formula: PMT = PV * (r / (1 - (1 + r)^-n))
        let annualCityContribution: Double
        if yearsInvesting > 0 && interestRate > 0 {
            let discountFactor = pow(1 + interestRate, Double(-yearsInvesting))
            let annuityFactor = interestRate / (1 - discountFactor)
            annualCityContribution = cityContributionPresentValue * annuityFactor
        } else {
            annualCityContribution = cityContributionPresentValue / Double(yearsInvesting)
        }
        
        // Calculate future value of city contributions (annuity)
        let cityContributionsFV = futureValueOfAnnuity(
            annualPayment: annualCityContribution,
            interestRate: expectedInterestRate,
            years: yearsInvesting
        )
        
        // Total available at retirement
        let totalAvailableAtRetirement = employeeContributionsFV + cityContributionsFV
        
        // Calculate the amount needed at retirement
        // ACTUARIAL RULE: 100% of expected lifetime benefits needed (no discounting during retirement)
        let totalNeededAtRetirement = presentValueOfAnnuityWithInflation(
            initialAnnualPayment: initialAnnualPension,
            interestRate: expectedInterestRate, // Used during accumulation phase only
            inflationRate: expectedInflationRate,
            years: yearsRetired
        )
        
        let shortfall = totalNeededAtRetirement - totalAvailableAtRetirement
        let isSufficient = shortfall <= 0
        
        return (isSufficient, totalAvailableAtRetirement, totalNeededAtRetirement, shortfall)
    }
}

