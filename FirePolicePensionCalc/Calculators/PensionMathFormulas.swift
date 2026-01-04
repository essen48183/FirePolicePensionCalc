//
//  PensionMathFormulas.swift
//  FirePolicePensionCalc
//
//  Core financial formulas used in pension calculations
//  This file contains pure math logic with no business logic dependencies
//

import Foundation

/// Core financial formulas for pension calculations
/// All formulas are pure functions with no side effects
struct PensionMathFormulas {
    
    // MARK: - Basic Financial Formulas
    
    /// Calculate present value from future value
    /// Formula: PV = FV / (1 + r)^n
    /// - Parameters:
    ///   - futureValue: Future value amount
    ///   - interestRate: Annual interest rate as percentage (e.g., 7.25 for 7.25%)
    ///   - years: Number of years
    /// - Returns: Present value
    static func presentValue(futureValue: Double, interestRate: Double, years: Int) -> Double {
        let r = interestRate / 100.0
        return futureValue / pow(1 + r, Double(years))
    }
    
    /// Calculate future value from present value
    /// Formula: FV = PV * (1 + r)^n
    /// - Parameters:
    ///   - presentValue: Present value amount
    ///   - interestRate: Annual interest rate as percentage (e.g., 7.25 for 7.25%)
    ///   - years: Number of years
    /// - Returns: Future value
    static func futureValue(presentValue: Double, interestRate: Double, years: Int) -> Double {
        let r = interestRate / 100.0
        return presentValue * pow(1 + r, Double(years))
    }
    
    // MARK: - Annuity Formulas
    
    /// Calculate future value of an ordinary annuity (payments at end of period)
    /// Formula: FV = PMT * (((1 + r)^n - 1) / r)
    /// - Parameters:
    ///   - annualPayment: Annual payment amount
    ///   - interestRate: Annual interest rate as percentage (e.g., 7.25 for 7.25%)
    ///   - years: Number of years
    /// - Returns: Future value of annuity
    static func futureValueOfAnnuity(annualPayment: Double, interestRate: Double, years: Int) -> Double {
        let r = interestRate / 100.0
        if r == 0 {
            return annualPayment * Double(years)
        }
        return annualPayment * ((pow(1 + r, Double(years)) - 1) / r)
    }
    
    /// Calculate annual payment (PMT) from present value
    /// Formula: PMT = PV * (r / (1 - (1 + r)^-n))
    /// - Parameters:
    ///   - presentValue: Present value amount
    ///   - interestRate: Annual interest rate as percentage (e.g., 7.25 for 7.25%)
    ///   - years: Number of years
    /// - Returns: Annual payment amount
    static func annualPaymentFromPresentValue(presentValue: Double, interestRate: Double, years: Int) -> Double {
        let r = interestRate / 100.0
        if years > 0 && r > 0 {
            let discountFactor = pow(1 + r, Double(-years))
            let annuityFactor = r / (1 - discountFactor)
            return presentValue * annuityFactor
        } else if years > 0 {
            return presentValue / Double(years)
        } else {
            return 0
        }
    }
    
    /// Calculate amount needed at retirement to fund pension payments
    /// ACTUARIAL RULE: We need 100% of expected lifetime benefits at retirement time.
    /// Once retired, we cannot expect investment returns to outpace inflation.
    /// Therefore, we calculate the sum of all payments in nominal dollars (no discounting).
    /// Formula: Amount Needed = PMT * n
    /// - Parameters:
    ///   - initialAnnualPayment: Initial annual pension payment
    ///   - years: Number of years receiving pension
    /// - Returns: Total amount needed at retirement (full sum, no discounting)
    static func amountNeededAtRetirement(initialAnnualPayment: Double, years: Int) -> Double {
        // ACTUARIAL RULE: During retirement, investment returns won't outpace inflation
        // Therefore, we need the full sum of all payments at retirement (no discounting)
        // This is a conservative assumption that ensures 100% funding
        return initialAnnualPayment * Double(years)
    }
    
    /// Calculate amount needed at retirement accounting for COLA increases
    /// This calculates the sum of all nominal payments (with COLA, without inflation)
    /// Includes both retiree and survivor benefits
    /// - Parameters:
    ///   - initialAnnualPayment: Initial annual pension payment (retiree)
    ///   - yearsRetired: Number of years retiree receives pension
    ///   - spouseInitialAnnualPension: Initial annual pension payment for survivor (at retiree's death)
    ///   - yearsReceivingSpousePension: Number of years survivor receives pension
    ///   - colaPercent: COLA percentage as decimal (e.g., 0.05 for 5%)
    ///   - isColaCompounding: Whether COLA is compounding
    ///   - numberColas: Number of COLA adjustments
    ///   - colaSpacing: Years between COLA adjustments
    /// - Returns: Total amount needed at retirement (sum of all nominal payments)
    static func amountNeededAtRetirementWithCOLA(
        initialAnnualPayment: Double,
        yearsRetired: Int,
        spouseInitialAnnualPension: Double,
        yearsReceivingSpousePension: Int,
        colaPercent: Double,
        isColaCompounding: Bool,
        numberColas: Int,
        colaSpacing: Int
    ) -> Double {
        var totalNominal: Double = 0
        var currentPension = initialAnnualPayment
        var colaCounter = 0
        let straightCola = initialAnnualPayment * colaPercent
        
        // Calculate retiree's nominal payments (with COLA, without inflation)
        for year in 1...yearsRetired {
            // Apply COLA if it's a COLA year
            if numberColas > 0 && year % colaSpacing == 0 && colaCounter < numberColas {
                colaCounter += 1
                if isColaCompounding {
                    currentPension += currentPension * colaPercent
                } else {
                    currentPension += straightCola
                }
            }
            
            // Add nominal payment (no inflation adjustment)
            totalNominal += currentPension
        }
        
        // Calculate survivor's nominal payments (with COLA, without inflation)
        if yearsReceivingSpousePension > 0 && spouseInitialAnnualPension > 0 {
            var spousePension = spouseInitialAnnualPension
            var spouseColaCounter = 0
            let spouseStraightCola = spouseInitialAnnualPension * colaPercent
            
            // Note: spouseInitialAnnualPension already includes COLAs from retiree's years for Option 3
            // For other options, it's the fixed amount at retiree's death
            
            for year in 1...yearsReceivingSpousePension {
                // Apply COLA if it's a COLA year (during survivor's years)
                if numberColas > 0 && year % colaSpacing == 0 && spouseColaCounter < numberColas {
                    spouseColaCounter += 1
                    if isColaCompounding {
                        spousePension += spousePension * colaPercent
                    } else {
                        spousePension += spouseStraightCola
                    }
                }
                
                // Add nominal payment (no inflation adjustment)
                totalNominal += spousePension
            }
        }
        
        return totalNominal
    }
    
    // MARK: - Real Rate of Return
    
    /// Calculate real rate of return (after inflation)
    /// Formula: Real Rate = ((1 + nominalRate) / (1 + inflationRate)) - 1
    /// - Parameters:
    ///   - nominalRate: Nominal interest rate as percentage
    ///   - inflationRate: Inflation rate as percentage
    /// - Returns: Real rate of return as percentage
    static func realRateOfReturn(nominalRate: Double, inflationRate: Double) -> Double {
        let nominal = nominalRate / 100.0
        let inflation = inflationRate / 100.0
        let real = ((1 + nominal) / (1 + inflation)) - 1
        return real * 100.0
    }
}

