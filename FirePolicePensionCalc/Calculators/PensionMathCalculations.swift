//
//  PensionMathCalculations.swift
//  FirePolicePensionCalc
//
//  Pension-specific calculation logic
//  This file contains business logic calculations that use PensionMathFormulas
//

import Foundation

/// Pension-specific calculation logic
/// Uses PensionMathFormulas for underlying financial calculations
struct PensionMathCalculations {
    
    // MARK: - Life Expectancy Constants
    
    private static let LIFE_EXPECTANCY_MALE = 73 // Average life expectancy of male
    private static let LIFE_EXPECTANCY_FEMALE = 79 // Average life expectancy of female
    
    // MARK: - Final Average Compensation (FAC)
    
    /// Calculate Final Average Compensation (FAC) from 3-year wage data
    /// Formula: FAC = (Year1Total + Year2Total + Year3Total) / 3
    /// - Parameters:
    ///   - baseWageYear1: Base wage for year 1
    ///   - overtimeYear1: Overtime for year 1
    ///   - rollInsYear1: Roll-ins for year 1 (only in year 1)
    ///   - baseWageYear2: Base wage for year 2
    ///   - overtimeYear2: Overtime for year 2
    ///   - baseWageYear3: Base wage for year 3
    ///   - overtimeYear3: Overtime for year 3
    /// - Returns: Final Average Compensation
    static func calculateFAC(
        baseWageYear1: Double,
        overtimeYear1: Double,
        rollInsYear1: Double,
        baseWageYear2: Double,
        overtimeYear2: Double,
        baseWageYear3: Double,
        overtimeYear3: Double
    ) -> Double {
        let totalYear1 = baseWageYear1 + overtimeYear1 + rollInsYear1
        let totalYear2 = baseWageYear2 + overtimeYear2
        let totalYear3 = baseWageYear3 + overtimeYear3
        
        return (totalYear1 + totalYear2 + totalYear3) / 3.0
    }
    
    // MARK: - Pension Amount Calculations
    
    /// Calculate initial annual pension amount
    /// Formula: Annual Pension = Earnings × Multiplier × Years of Service
    /// - Parameters:
    ///   - earnings: Base wage or FAC (depending on configuration)
    ///   - multiplier: Annual multiplier as percentage (e.g., 2.5 for 2.5%)
    ///   - yearsOfService: Total years of service
    /// - Returns: Initial annual pension amount
    static func calculateInitialAnnualPension(
        earnings: Double,
        multiplier: Double,
        yearsOfService: Int
    ) -> Double {
        let multiplierDecimal = multiplier / 100.0
        return earnings * multiplierDecimal * Double(yearsOfService)
    }
    
    // MARK: - Years Calculations
    
    /// Calculate years receiving pension based on life expectancy
    /// - Parameters:
    ///   - retirementAge: Age at retirement
    ///   - employeeSex: Sex of the employee (M or F)
    ///   - lifeExpectancyMale: Male life expectancy
    ///   - lifeExpectancyFemale: Female life expectancy
    ///   - lifeExpDiff: Difference from standard life expectancy
    /// - Returns: Years receiving pension (0 if negative)
    static func calculateYearsReceivingPension(
        retirementAge: Int,
        employeeSex: Sex,
        lifeExpectancyMale: Int,
        lifeExpectancyFemale: Int,
        lifeExpDiff: Int
    ) -> Int {
        let lifeExpectancy = employeeSex == .male ? lifeExpectancyMale : lifeExpectancyFemale
        let years = lifeExpectancy + lifeExpDiff - retirementAge
        return max(0, years)
    }
    
    /// Calculate years receiving spouse pension based on option
    /// - Parameters:
    ///   - pensionOption: Pension option (1, 2, 3, or 4)
    ///   - employeeSex: Sex of the employee (M or F)
    ///   - spouseSex: Sex of the spouse (M or F, nil if no spouse)
    ///   - spouseAgeDiff: Age difference between retiree and spouse
    ///   - lifeExpectancyMale: Male life expectancy
    ///   - lifeExpectancyFemale: Female life expectancy
    ///   - lifeExpDiff: Difference from standard life expectancy
    /// - Returns: Years receiving spouse pension
    static func calculateYearsReceivingSpousePension(
        pensionOption: PensionOption,
        employeeSex: Sex,
        spouseSex: Sex?,
        spouseAgeDiff: Int,
        lifeExpectancyMale: Int,
        lifeExpectancyFemale: Int,
        lifeExpDiff: Int
    ) -> Int {
        switch pensionOption {
        case .option1:
            return 0 // No survivor benefit
        case .option2:
            return 10 // Fixed 10-year survivor
        case .option3, .option4:
            // Use actual spouse sex to determine life expectancy
            guard let spouseSex = spouseSex else {
                return 0 // No spouse
            }
            let employeeLifeExpectancy = employeeSex == .male ? lifeExpectancyMale : lifeExpectancyFemale
            let spouseLifeExpectancy = spouseSex == .male ? lifeExpectancyMale : lifeExpectancyFemale
            let years = spouseLifeExpectancy - employeeLifeExpectancy - spouseAgeDiff
            return max(0, years)
        }
    }
    
    // MARK: - COLA and Inflation Calculations
    
    /// Apply COLA (Cost of Living Adjustment) to a pension amount
    /// - Parameters:
    ///   - currentPension: Current pension amount
    ///   - colaPercent: COLA percentage as decimal (e.g., 0.03 for 3%)
    ///   - isCompounding: Whether COLA is compounding or fixed dollar amount
    ///   - straightColaAmount: Fixed dollar amount for non-compounding COLA
    /// - Returns: New pension amount after COLA
    static func applyCOLA(
        currentPension: Double,
        colaPercent: Double,
        isCompounding: Bool,
        straightColaAmount: Double
    ) -> Double {
        if isCompounding {
            // Compounding: multiply by (1 + colaPercent)
            return currentPension + (currentPension * colaPercent)
        } else {
            // Non-compounding: add fixed dollar amount
            return currentPension + straightColaAmount
        }
    }
    
    /// Apply inflation adjustment to reduce buying power
    /// Formula: New Amount = Current Amount - (Current Amount × Inflation Rate)
    /// - Parameters:
    ///   - currentAmount: Current amount
    ///   - inflationRate: Inflation rate as decimal (e.g., 0.025 for 2.5%)
    /// - Returns: Amount after inflation adjustment (reduced buying power)
    static func applyInflation(
        currentAmount: Double,
        inflationRate: Double
    ) -> Double {
        return currentAmount - (currentAmount * inflationRate)
    }
    
    // MARK: - Contribution Calculations
    
    /// Calculate total employee contribution over career
    /// - Parameters:
    ///   - baseWage: Base wage amount
    ///   - contributionPercent: Employee contribution percentage (e.g., 6.0 for 6%)
    ///   - yearsOfService: Years of service
    /// - Returns: Total employee contribution (nominal sum)
    static func calculateTotalEmployeeContribution(
        baseWage: Double,
        contributionPercent: Double,
        yearsOfService: Int
    ) -> Double {
        let annualContribution = baseWage * (contributionPercent / 100.0)
        return annualContribution * Double(yearsOfService)
    }
    
    /// Calculate annual employee contribution
    /// - Parameters:
    ///   - baseWage: Base wage amount
    ///   - contributionPercent: Employee contribution percentage (e.g., 6.0 for 6%)
    /// - Returns: Annual employee contribution
    static func calculateAnnualEmployeeContribution(
        baseWage: Double,
        contributionPercent: Double
    ) -> Double {
        return baseWage * (contributionPercent / 100.0)
    }
    
    /// Calculate present value of city contributions needed
    /// This calculates what the city needs to contribute today to fund future retirement benefits
    /// - Parameters:
    ///   - amountNeededAtRetirement: Total amount needed at retirement (100% of lifetime benefits)
    ///   - initialBalance: Starting balance in the fund
    ///   - totalEmployeeContribution: Total employee contributions over career (nominal sum)
    ///   - expectedInterestRate: Expected annual investment return during accumulation (as percentage)
    ///   - yearsInvesting: Years of service before retirement
    /// - Returns: Present value of city contributions needed (in today's dollars)
    static func calculateCityContributionPresentValue(
        amountNeededAtRetirement: Double,
        initialBalance: Double,
        totalEmployeeContribution: Double,
        expectedInterestRate: Double,
        yearsInvesting: Int
    ) -> Double {
        // Calculate annual employee contribution and its future value at retirement
        let annualEmployeeContribution = totalEmployeeContribution / Double(yearsInvesting)
        let employeeContributionsFV = PensionMathFormulas.futureValueOfAnnuity(
            annualPayment: annualEmployeeContribution,
            interestRate: expectedInterestRate,
            years: yearsInvesting
        )
        
        // Calculate what the city needs to provide at retirement (nominal)
        let futureValueNeeded = amountNeededAtRetirement - initialBalance - employeeContributionsFV
        
        // Discount back to today using nominal interest rate
        let presentValue = PensionMathFormulas.presentValue(
            futureValue: futureValueNeeded,
            interestRate: expectedInterestRate,
            years: yearsInvesting
        )
        
        return presentValue
    }
    
    /// Calculate annual city contribution payment
    /// Uses annuity formula to calculate annual payment from present value
    /// - Parameters:
    ///   - presentValue: Present value of city contributions needed
    ///   - interestRate: Expected annual investment return (as percentage)
    ///   - yearsInvesting: Years of service before retirement
    /// - Returns: Annual city contribution payment
    static func calculateAnnualCityContribution(
        presentValue: Double,
        interestRate: Double,
        yearsInvesting: Int
    ) -> Double {
        return PensionMathFormulas.annualPaymentFromPresentValue(
            presentValue: presentValue,
            interestRate: interestRate,
            years: yearsInvesting
        )
    }
    
    // MARK: - Funding Verification
    
    /// Verify that contributions are sufficient to cover lifetime benefits
    /// - Parameters:
    ///   - initialAnnualPension: Initial annual pension amount
    ///   - yearsRetired: Years receiving pension
    ///   - annualEmployeeContribution: Annual employee contribution
    ///   - cityContributionPresentValue: Present value of city contributions
    ///   - expectedInterestRate: Expected annual investment return (as percentage)
    ///   - yearsInvesting: Years of service before retirement
    /// - Returns: Tuple with (isSufficient: Bool, totalAvailableAtRetirement: Double, totalNeededAtRetirement: Double, shortfall: Double)
    static func verifyContributionSufficiency(
        initialAnnualPension: Double,
        yearsRetired: Int,
        annualEmployeeContribution: Double,
        cityContributionPresentValue: Double,
        expectedInterestRate: Double,
        yearsInvesting: Int
    ) -> (isSufficient: Bool, totalAvailableAtRetirement: Double, totalNeededAtRetirement: Double, shortfall: Double) {
        
        // Calculate future value of employee contributions
        let employeeContributionsFV = PensionMathFormulas.futureValueOfAnnuity(
            annualPayment: annualEmployeeContribution,
            interestRate: expectedInterestRate,
            years: yearsInvesting
        )
        
        // Calculate annual city contribution and its future value
        let annualCityContribution = calculateAnnualCityContribution(
            presentValue: cityContributionPresentValue,
            interestRate: expectedInterestRate,
            yearsInvesting: yearsInvesting
        )
        
        let cityContributionsFV = PensionMathFormulas.futureValueOfAnnuity(
            annualPayment: annualCityContribution,
            interestRate: expectedInterestRate,
            years: yearsInvesting
        )
        
        // Total available at retirement
        let totalAvailableAtRetirement = employeeContributionsFV + cityContributionsFV
        
        // Amount needed at retirement (100% of lifetime benefits)
        let totalNeededAtRetirement = PensionMathFormulas.amountNeededAtRetirement(
            initialAnnualPayment: initialAnnualPension,
            years: yearsRetired
        )
        
        let shortfall = totalNeededAtRetirement - totalAvailableAtRetirement
        let isSufficient = shortfall <= 0
        
        return (isSufficient, totalAvailableAtRetirement, totalNeededAtRetirement, shortfall)
    }
}

