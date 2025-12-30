//
//  PensionCalculatorPaymentsInto.swift
//  FirePolicePensionCalc
//
//  Ported from Java
//

import Foundation

class PensionCalculatorPaymentsInto {
    
    /// Calculates the present value of payments needed to fund a retirement benefit
    /// - Parameters:
    ///   - verbose: Whether to print detailed output
    ///   - sumDesiredAtRetirement: Total benefit payout needed (in today's dollars)
    ///   - initialBalance: Starting balance in the fund
    ///   - totalEmployeeContribution: Total employee contributions over career
    ///   - facWage: Final average compensation wage
    ///   - expectedInterestRate: Expected annual investment return (as percentage)
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
        
        // Calculate present value needed
        // PV = FV / (1 + r)^n
        // Where FV is the amount needed minus employee contributions and initial balance
        let futureValueNeeded = sumDesiredAtRetirement - initialBalance - totalEmployeeContribution
        let presentValueOfRetirementInput = presentValue(
            futureValue: futureValueNeeded,
            interestRate: realRateOfReturn * 100.0, // Convert back to percentage for presentValue function
            years: yearsInvesting
        )
        
        if verbose {
            let annualPayment = presentValueOfRetirementInput / Double(yearsInvesting)
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
    
    /// Calculate present value of an annuity with inflation-adjusted payments
    /// This calculates how much is needed at retirement to fund payments that decrease by inflation each year
    static func presentValueOfAnnuityWithInflation(
        initialAnnualPayment: Double,
        interestRate: Double,
        inflationRate: Double,
        years: Int
    ) -> Double {
        let r = interestRate / 100.0
        let inf = inflationRate / 100.0
        var pv = 0.0
        var currentPayment = initialAnnualPayment
        
        for year in 1...years {
            // Payment in year 'year' (adjusted for inflation from retirement date)
            currentPayment = currentPayment * (1 - inf)
            // Discount back to retirement date using investment return rate
            pv += currentPayment / pow(1 + r, Double(year))
        }
        
        return pv
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
        
        // Calculate annual city contribution (present value / years)
        let annualCityContribution = cityContributionPresentValue / Double(yearsInvesting)
        
        // Calculate future value of city contributions (annuity)
        let cityContributionsFV = futureValueOfAnnuity(
            annualPayment: annualCityContribution,
            interestRate: expectedInterestRate,
            years: yearsInvesting
        )
        
        // Total available at retirement
        let totalAvailableAtRetirement = employeeContributionsFV + cityContributionsFV
        
        // Calculate the present value of the annuity at retirement
        // This is the amount needed at retirement to fund all future payments
        let totalNeededAtRetirement = presentValueOfAnnuityWithInflation(
            initialAnnualPayment: initialAnnualPension,
            interestRate: expectedInterestRate,
            inflationRate: expectedInflationRate,
            years: yearsRetired
        )
        
        let shortfall = totalNeededAtRetirement - totalAvailableAtRetirement
        let isSufficient = shortfall <= 0
        
        return (isSufficient, totalAvailableAtRetirement, totalNeededAtRetirement, shortfall)
    }
}

