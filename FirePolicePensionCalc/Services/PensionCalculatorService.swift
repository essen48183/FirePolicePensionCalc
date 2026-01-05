//
//  PensionCalculatorService.swift
//  FirePolicePensionCalc
//
//  Main service that orchestrates pension calculations
//

import Foundation

struct EmployeeCalculationResult: Identifiable {
    let id: Int
    let employee: Employee
    let totalDisbursements: Double
    let initialAnnualPension: Double
    let cityContributions: Double
    let employeeContributions: Double
    let yearsToRetire: Int
    let retirementAge: Int
    let spouseInitialAnnualPension: Double
    let yearsReceivingSpousePension: Int
    
    init(employee: Employee, totalDisbursements: Double, initialAnnualPension: Double, cityContributions: Double, employeeContributions: Double, yearsToRetire: Int, retirementAge: Int, spouseInitialAnnualPension: Double = 0, yearsReceivingSpousePension: Int = 0) {
        self.id = employee.id
        self.employee = employee
        self.totalDisbursements = totalDisbursements
        self.initialAnnualPension = initialAnnualPension
        self.cityContributions = cityContributions
        self.employeeContributions = employeeContributions
        self.yearsToRetire = yearsToRetire
        self.retirementAge = retirementAge
        self.spouseInitialAnnualPension = spouseInitialAnnualPension
        self.yearsReceivingSpousePension = yearsReceivingSpousePension
    }
}

struct SystemCalculationResult {
    let totalDisbursements: Double
    let totalCityContributions: Double
    let totalEmployeeContributions: Double
    let annualCityPayments: Double
    let cityAnnualPercentOfPayroll: Double
    let employeeResults: [EmployeeCalculationResult]
    let verificationResult: ContributionVerificationResult?
}

struct ContributionVerificationResult {
    let totalAvailableAtRetirement: Double
    let totalNeededAtRetirement: Double
    let surplus: Double
    let isSufficient: Bool
}

class PensionCalculatorService {
    
    func calculateSystemCosts(config: PensionConfiguration, employees: [Employee]) -> SystemCalculationResult {
        var totalDisbursements: Double = 0
        var totalCityContributions: Double = 0
        var totalEmployeeContributions: Double = 0
        var totalYearsOfService: Int = 0
        var employeeResults: [EmployeeCalculationResult] = []
        
        let currentYear = Calendar.current.component(.year, from: Date())
        
        for employee in employees {
            // Check if employee is vested (must work at least yearsUntilVestment)
            // Minimum vestment is 1 to prevent division by zero and ensure valid calculations
            let vestmentRequirement = max(config.yearsUntilVestment, 1)
            let yearsWorked = currentYear - employee.hiredYear
            let isVested = yearsWorked >= vestmentRequirement
            
            // If not vested, skip this employee (no benefits until vested)
            if !isVested {
                // Employee hasn't worked long enough to be vested - no benefits yet
                continue
            }
            
            // Calculate years needed to retire
            let yearsToRetire = calculateYearsToRetire(
                employee: employee,
                config: config
            )
            
            // Ensure yearsToRetire is at least the vestment period
            // This prevents negative or invalid calculations for older new hires
            // Minimum vestment is 1 to prevent division by zero and ensure valid calculations
            let minYearsToRetire = max(yearsToRetire, vestmentRequirement)
            
            let retirementAge = employee.hiredAge + minYearsToRetire
            let employeeEarliestEligibleRetirementAge = (employee.hiredYear + minYearsToRetire) - currentYear + employee.currentAge
            
            // Calculate disbursements using system-wide wages
            // SYSTEM-WIDE RULE: Always use Option 1 (no survivor) for system-wide calculations
            // Actuarial equivalence means all options have the same total lifetime benefit,
            // so we fund based on Option 1's amount
            let disbursementResult = PensionCalculatorDisbursements.calculateDisbursements(
                verbose: false,
                baseWage: config.systemWideBaseWage,
                facWage: config.systemWideFacWage,
                annualMultiplier: config.multiplier,
                useFacWage: config.multiplierBasedOnFAC,
                isColaCompounding: config.isColaCompounding,
                numberColas: config.colaNumber,
                colaSpacing: config.colaSpacing,
                colaPercent: config.colaPercent,
                inflateRate: config.expectedFutureInflationRate,
                retirementAge: employeeEarliestEligibleRetirementAge,
                totalYearsService: minYearsToRetire,
                employeeSex: employee.sex,
                spouseSex: employee.spouseSex,
                lifeExpectancyMale: config.lifeExpectancyMale,
                lifeExpectancyFemale: config.lifeExpectancyFemale,
                lifeExpDiff: config.deltaExtraLife,
                spouseAgeDiff: employee.spouseAgeDiff,
                currentAge: employee.currentAge,
                pensionOption: .option1  // Always Option 1 for system-wide
            )
            
            // Calculate employee contribution using PensionMathCalculations
            // Use average wage for system-wide calculations to better reflect actual contribution patterns
            let employeeContribution = PensionMathCalculations.calculateTotalEmployeeContribution(
                baseWage: config.systemWideAverageWage,
                contributionPercent: config.employeeContributionPercent,
                yearsOfService: minYearsToRetire
            )
            
            // Calculate amount needed at retirement to fund the annuity
            // ACTUARIAL RULE: We need 100% of expected lifetime benefits at retirement.
            // SYSTEM-WIDE RULE: Always use Option 1 (no survivor) - only retiree's payments
            //
            // UNITS: This calculates the sum in NOMINAL DOLLARS (retirement-date dollars)
            // - Includes COLA increases (dollar amounts increase)
            // - Does NOT include inflation adjustments (we need actual dollars, not buying power)
            // - This is different from totalPayout which is in today's buying power
            // - For funding, we need nominal dollars because that's what will actually be paid
            //
            // Only retiree's portion - no survivor benefits for system-wide calculations
            let employeeLifeExpectancy = employee.sex == .male ? config.lifeExpectancyMale : config.lifeExpectancyFemale
            var yearsRetired = employeeLifeExpectancy + config.deltaExtraLife - employeeEarliestEligibleRetirementAge
            
            // Ensure minimum 1 year of benefit - no matter the hire age, there should be at least 1 year
            // This prevents negative benefits for older new hires
            if yearsRetired < 1 {
                yearsRetired = 1
            }
            
            let colaPercent = config.colaPercent / 100.0
            let amountNeededAtRetirement = PensionMathFormulas.amountNeededAtRetirementWithCOLA(
                initialAnnualPayment: disbursementResult.initialAnnualPension,
                yearsRetired: yearsRetired,
                spouseInitialAnnualPension: 0,  // No survivor for system-wide (Option 1)
                yearsReceivingSpousePension: 0,  // No survivor for system-wide (Option 1)
                colaPercent: colaPercent,
                isColaCompounding: config.isColaCompounding,
                numberColas: config.colaNumber,
                colaSpacing: config.colaSpacing
            )
            
            // Calculate city contributions needed
            let cityContribution = PensionCalculatorPaymentsInto.calculateDiscountPayment(
                verbose: false,
                sumDesiredAtRetirement: amountNeededAtRetirement,
                initialBalance: 0,
                totalEmployeeContribution: employeeContribution,
                facWage: config.systemWideFacWage,
                expectedInterestRate: config.expectedSystemFutureRateReturn,
                expectedInflationRate: config.expectedFutureInflationRate,
                yearsInvesting: minYearsToRetire,
                yearsRetired: yearsRetired,
                compoundsPerYear: 1
            )
            
            // IMPORTANT: Units distinction
            // - disbursementResult.totalPayout: Sum in TODAY'S BUYING POWER (inflation-adjusted)
            //   Used for display/understanding of benefit value in current dollars
            // - amountNeededAtRetirement: Sum in NOMINAL DOLLARS (with COLA, without inflation)
            //   Used for funding calculations - actual dollars needed at retirement date
            // These are intentionally different units for different purposes
            totalDisbursements += disbursementResult.totalPayout
            totalCityContributions += cityContribution
            totalEmployeeContributions += employeeContribution
            totalYearsOfService += minYearsToRetire
            
            employeeResults.append(EmployeeCalculationResult(
                employee: employee,
                totalDisbursements: disbursementResult.totalPayout,
                initialAnnualPension: disbursementResult.initialAnnualPension,
                cityContributions: cityContribution,
                employeeContributions: employeeContribution,
                yearsToRetire: minYearsToRetire,
                retirementAge: retirementAge,
                spouseInitialAnnualPension: disbursementResult.spouseInitialAnnualPension,
                yearsReceivingSpousePension: disbursementResult.yearsReceivingSpousePension
            ))
        }
        
        // Calculate verification: aggregate future values across all employees
        var totalAvailableAtRetirement: Double = 0
        var totalNeededAtRetirement: Double = 0
        
        for employeeResult in employeeResults {
            let employee = employeeResult.employee
            let yearsToRetire = employeeResult.yearsToRetire
            // Use the same retirement age calculation as in disbursements
            let employeeEarliestEligibleRetirementAge = (employee.hiredYear + yearsToRetire) - currentYear + employee.currentAge
            // Use the same years retired calculation as in disbursements
            let employeeLifeExpectancy = employeeResult.employee.sex == .male ? config.lifeExpectancyMale : config.lifeExpectancyFemale
            var yearsRetired = employeeLifeExpectancy + config.deltaExtraLife - employeeEarliestEligibleRetirementAge
            
            // Ensure minimum 1 year of benefit - no matter the hire age, there should be at least 1 year
            // This prevents negative benefits for older new hires
            if yearsRetired < 1 {
                yearsRetired = 1
            }
            
            // Calculate future value of employee contributions using PensionMathCalculations
            // Use average wage for system-wide calculations to better reflect actual contribution patterns
            let annualEmployeeContribution = PensionMathCalculations.calculateAnnualEmployeeContribution(
                baseWage: config.systemWideAverageWage,
                contributionPercent: config.employeeContributionPercent
            )
            let employeeContributionsFV = PensionMathFormulas.futureValueOfAnnuity(
                annualPayment: annualEmployeeContribution,
                interestRate: config.expectedSystemFutureRateReturn,
                years: yearsToRetire
            )
            
            // Calculate future value of city contributions using PensionMathCalculations
            let annualCityContribution = PensionMathCalculations.calculateAnnualCityContribution(
                presentValue: employeeResult.cityContributions,
                interestRate: config.expectedSystemFutureRateReturn,
                yearsInvesting: yearsToRetire
            )
            let cityContributionsFV = PensionMathFormulas.futureValueOfAnnuity(
                annualPayment: annualCityContribution,
                interestRate: config.expectedSystemFutureRateReturn,
                years: yearsToRetire
            )
            
            totalAvailableAtRetirement += employeeContributionsFV + cityContributionsFV
            
            // Calculate amount needed at retirement
            // ACTUARIAL RULE: 100% of expected lifetime benefits needed (no discounting during retirement)
            // SYSTEM-WIDE RULE: Always use Option 1 (no survivor) - only retiree's payments
            // Calculate sum of all nominal payments (with COLA, without inflation)
            // Only retiree's portion - no survivor benefits for system-wide calculations
            let colaPercent = config.colaPercent / 100.0
            let neededAtRetirement = PensionMathFormulas.amountNeededAtRetirementWithCOLA(
                initialAnnualPayment: employeeResult.initialAnnualPension,
                yearsRetired: yearsRetired,
                spouseInitialAnnualPension: 0,  // No survivor for system-wide (Option 1)
                yearsReceivingSpousePension: 0,   // No survivor for system-wide (Option 1)
                colaPercent: colaPercent,
                isColaCompounding: config.isColaCompounding,
                numberColas: config.colaNumber,
                colaSpacing: config.colaSpacing
            )
            
            totalNeededAtRetirement += neededAtRetirement
        }
        
        // Calculate funding ratio and adjust city contributions to target 100% funding (constrained to 80-120%)
        let fundingRatio = totalAvailableAtRetirement / totalNeededAtRetirement
        let minFundingRatio = 0.80
        let maxFundingRatio = 1.20
        let targetFundingRatio = 1.0 // Target 100% funding (no shortfall or surplus)
        
        // Calculate adjustment factor to bring funding to target (constrained to 80-120% range)
        let constrainedTargetRatio = min(max(targetFundingRatio, minFundingRatio), maxFundingRatio)
        let adjustmentFactor = constrainedTargetRatio / fundingRatio
        
        // Adjust all city contributions proportionally to achieve target funding
        let adjustedTotalCityContributions = totalCityContributions * adjustmentFactor
        
        // Update employee results with adjusted city contributions
        let adjustedEmployeeResults = employeeResults.map { result in
            EmployeeCalculationResult(
                employee: result.employee,
                totalDisbursements: result.totalDisbursements,
                initialAnnualPension: result.initialAnnualPension,
                cityContributions: result.cityContributions * adjustmentFactor,
                employeeContributions: result.employeeContributions,
                yearsToRetire: result.yearsToRetire,
                retirementAge: result.retirementAge,
                spouseInitialAnnualPension: result.spouseInitialAnnualPension,
                yearsReceivingSpousePension: result.yearsReceivingSpousePension
            )
        }
        
        // Recalculate total available with adjusted contributions
        var adjustedTotalAvailableAtRetirement: Double = 0
        for employeeResult in adjustedEmployeeResults {
            let employee = employeeResult.employee
            let yearsToRetire = employeeResult.yearsToRetire
            let employeeEarliestEligibleRetirementAge = (employee.hiredYear + yearsToRetire) - currentYear + employee.currentAge
            let employeeLifeExpectancy = employee.sex == .male ? config.lifeExpectancyMale : config.lifeExpectancyFemale
            var yearsRetired = employeeLifeExpectancy + config.deltaExtraLife - employeeEarliestEligibleRetirementAge
            if yearsRetired < 0 {
                yearsRetired = 0
            }
            
            // Calculate future value of employee contributions using PensionMathCalculations
            // Use average wage for system-wide calculations to better reflect actual contribution patterns
            let annualEmployeeContribution = PensionMathCalculations.calculateAnnualEmployeeContribution(
                baseWage: config.systemWideAverageWage,
                contributionPercent: config.employeeContributionPercent
            )
            let employeeContributionsFV = PensionMathFormulas.futureValueOfAnnuity(
                annualPayment: annualEmployeeContribution,
                interestRate: config.expectedSystemFutureRateReturn,
                years: yearsToRetire
            )
            
            // Calculate future value of city contributions using PensionMathCalculations
            let annualCityContribution = PensionMathCalculations.calculateAnnualCityContribution(
                presentValue: employeeResult.cityContributions,
                interestRate: config.expectedSystemFutureRateReturn,
                yearsInvesting: yearsToRetire
            )
            let cityContributionsFV = PensionMathFormulas.futureValueOfAnnuity(
                annualPayment: annualCityContribution,
                interestRate: config.expectedSystemFutureRateReturn,
                years: yearsToRetire
            )
            
            adjustedTotalAvailableAtRetirement += employeeContributionsFV + cityContributionsFV
        }
        
        // Update totals with adjusted values
        totalCityContributions = adjustedTotalCityContributions
        employeeResults = adjustedEmployeeResults
        totalAvailableAtRetirement = adjustedTotalAvailableAtRetirement
        
        let surplus = totalAvailableAtRetirement - totalNeededAtRetirement
        let finalFundingRatio = totalAvailableAtRetirement / totalNeededAtRetirement
        let isSufficient = finalFundingRatio >= minFundingRatio && finalFundingRatio <= maxFundingRatio
        
        // Calculate annual city payments using PensionMathCalculations
        var annualCityPayments: Double = 0
        
        for employeeResult in employeeResults {
            let annualPaymentPerEmployee = PensionMathCalculations.calculateAnnualCityContribution(
                presentValue: employeeResult.cityContributions,
                interestRate: config.expectedSystemFutureRateReturn,
                yearsInvesting: employeeResult.yearsToRetire
            )
            annualCityPayments += annualPaymentPerEmployee
        }
        
        // Calculate percentage of payroll
        // Payroll is average wages + insurance, not including pension payments
        // Use system-wide average wage directly and number of employees in the list
        let numberOfEmployees = employees.count
        let averageWage = config.systemWideAverageWage
        let perEmployeeInsurance = config.eachEmployeeInsuranceAnnualCostToCity
        let totalPayroll = (averageWage + perEmployeeInsurance) * Double(numberOfEmployees)
        let cityAnnualPercentOfPayroll = numberOfEmployees > 0 ? (annualCityPayments / totalPayroll) * 100.0 : 0.0
        
        let verificationResult = ContributionVerificationResult(
            totalAvailableAtRetirement: totalAvailableAtRetirement,
            totalNeededAtRetirement: totalNeededAtRetirement,
            surplus: surplus,
            isSufficient: isSufficient
        )
        
        return SystemCalculationResult(
            totalDisbursements: totalDisbursements,
            totalCityContributions: totalCityContributions,
            totalEmployeeContributions: totalEmployeeContributions,
            annualCityPayments: annualCityPayments,
            cityAnnualPercentOfPayroll: cityAnnualPercentOfPayroll,
            employeeResults: employeeResults,
            verificationResult: verificationResult
        )
    }
    
    func calculateIndividualPension(config: PensionConfiguration) -> (disbursement: PensionCalculatorDisbursements.DisbursementResult, cityContribution: Double) {
        // Calculate hire age from blue box inputs (Year Hired - Year Born)
        let hireAge = config.fictionalHiredYear - config.fictionalBirthYear
        
        // Calculate years needed to retire using fictionalYearsOfWork from blue box
        // Always use the chosen years of work directly
        let yearsToRetire = config.fictionalYearsOfWork
        
        let retirementAge = hireAge + yearsToRetire
        
        // Calculate disbursements
        // Determine spouse sex: use config value if spouse exists (spouseBirthYear > 0), otherwise nil
        let spouseSex: Sex? = config.fictionalSpouseBirthYear > 0 ? config.fictionalSpouseSex : nil
        
        let disbursementResult = PensionCalculatorDisbursements.calculateDisbursements(
            verbose: true,
            baseWage: config.baseWage,
            facWage: config.facWage,
            annualMultiplier: config.multiplier,
            useFacWage: config.multiplierBasedOnFAC,
            isColaCompounding: config.isColaCompounding,
            numberColas: config.colaNumber,
            colaSpacing: config.colaSpacing,
            colaPercent: config.colaPercent,
            inflateRate: config.expectedFutureInflationRate,
            retirementAge: retirementAge,
            totalYearsService: yearsToRetire,
            employeeSex: config.fictionalEmployeeSex,
            spouseSex: spouseSex,
            lifeExpectancyMale: config.lifeExpectancyMale,
            lifeExpectancyFemale: config.lifeExpectancyFemale,
            lifeExpDiff: config.deltaExtraLife,
            spouseAgeDiff: config.fictionalSpouseAgeDiff,
            currentAge: hireAge,
            pensionOption: config.pensionOption
        )
        
        // Calculate employee contribution using PensionMathCalculations
        let employeeContribution = PensionMathCalculations.calculateTotalEmployeeContribution(
            baseWage: config.baseWage,
            contributionPercent: config.employeeContributionPercent,
            yearsOfService: yearsToRetire
        )
        
        // Calculate amount needed at retirement
        // ACTUARIAL RULE: 100% of expected lifetime benefits needed (no discounting during retirement)
        // Calculate sum of all nominal payments (with COLA, without inflation)
        // Includes both retiree and survivor benefits
        let employeeLifeExpectancy = config.fictionalEmployeeSex == .male ? config.lifeExpectancyMale : config.lifeExpectancyFemale
        var yearsRetired = employeeLifeExpectancy + config.deltaExtraLife - retirementAge
        
        // Ensure minimum 1 year of benefit - no matter the hire age, there should be at least 1 year
        // This prevents negative benefits for older new hires
        if yearsRetired < 1 {
            yearsRetired = 1
        }
        
        let colaPercent = config.colaPercent / 100.0
        let amountNeededAtRetirement = PensionMathFormulas.amountNeededAtRetirementWithCOLA(
            initialAnnualPayment: disbursementResult.initialAnnualPension,
            yearsRetired: yearsRetired,
            spouseInitialAnnualPension: disbursementResult.spouseInitialAnnualPension,
            yearsReceivingSpousePension: disbursementResult.yearsReceivingSpousePension,
            colaPercent: colaPercent,
            isColaCompounding: config.isColaCompounding,
            numberColas: config.colaNumber,
            colaSpacing: config.colaSpacing
        )
        
        // Calculate city contribution
        let cityContribution = PensionCalculatorPaymentsInto.calculateDiscountPayment(
            verbose: true,
            sumDesiredAtRetirement: amountNeededAtRetirement,
            initialBalance: 0,
            totalEmployeeContribution: employeeContribution,
            facWage: config.facWage,
            expectedInterestRate: config.expectedSystemFutureRateReturn,
            expectedInflationRate: config.expectedFutureInflationRate,
            yearsInvesting: yearsToRetire,
            yearsRetired: yearsRetired,
            compoundsPerYear: 1
        )
        
        return (disbursementResult, cityContribution)
    }
    
    private func calculateYearsToRetire(employee: Employee, config: PensionConfiguration) -> Int {
        // First, ensure the result is at least the vestment period
        // Employees must work at least yearsUntilVestment before being eligible
        // Minimum vestment is 1 to prevent division by zero and ensure valid calculations
        let minRequiredYears = max(config.yearsUntilVestment, 1)
        
        let calculatedYears: Int
        if config.retirementAge <= (config.careerYearsService + employee.hiredAge) {
            calculatedYears = config.retirementAge - employee.hiredAge
        } else if (employee.hiredAge + config.careerYearsService) < config.minAgeForYearsService {
            calculatedYears = config.minAgeForYearsService - employee.hiredAge
        } else {
            calculatedYears = config.careerYearsService
        }
        
        // Return the maximum of calculated years and vestment requirement
        // This ensures employees must work at least the vestment period
        return max(calculatedYears, minRequiredYears)
    }
}

