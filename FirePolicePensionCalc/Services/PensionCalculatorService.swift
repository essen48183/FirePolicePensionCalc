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
    
    init(employee: Employee, totalDisbursements: Double, initialAnnualPension: Double, cityContributions: Double, employeeContributions: Double, yearsToRetire: Int, retirementAge: Int) {
        self.id = employee.id
        self.employee = employee
        self.totalDisbursements = totalDisbursements
        self.initialAnnualPension = initialAnnualPension
        self.cityContributions = cityContributions
        self.employeeContributions = employeeContributions
        self.yearsToRetire = yearsToRetire
        self.retirementAge = retirementAge
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
    
    private let lifeExpectancy = 73
    
    func calculateSystemCosts(config: PensionConfiguration, employees: [Employee]) -> SystemCalculationResult {
        var totalDisbursements: Double = 0
        var totalCityContributions: Double = 0
        var totalEmployeeContributions: Double = 0
        var totalYearsOfService: Int = 0
        var employeeResults: [EmployeeCalculationResult] = []
        
        let currentYear = Calendar.current.component(.year, from: Date())
        
        for employee in employees {
            // Calculate years needed to retire
            let yearsToRetire = calculateYearsToRetire(
                employee: employee,
                config: config
            )
            
            let retirementAge = employee.hiredAge + yearsToRetire
            let employeeEarliestEligibleRetirementAge = (employee.hiredYear + yearsToRetire) - currentYear + employee.currentAge
            
            // Calculate disbursements
            let disbursementResult = PensionCalculatorDisbursements.calculateDisbursements(
                verbose: false,
                baseWage: config.baseWage,
                facWage: config.facWage,
                annualMultiplier: config.multiplier,
                useFacWage: config.multiplierBasedOnFAC,
                isColaCompounding: config.isColaCompounding,
                numberColas: config.colaNumber,
                colaSpacing: config.colaSpacing,
                colaPercent: config.colaPercent,
                inflateRate: config.expectedFutureInflationRate,
                retirementAge: employeeEarliestEligibleRetirementAge,
                totalYearsService: yearsToRetire,
                lifeExpDiff: config.deltaExtraLife,
                spouseAgeDiff: employee.spouseAgeDiff,
                currentAge: employee.currentAge,
                pensionOption: config.pensionOption
            )
            
            // Calculate employee contribution (percentage of base wage over career)
            let employeeContribution = config.baseWage * (config.employeeContributionPercent / 100.0) * Double(yearsToRetire)
            
            // Calculate amount needed at retirement to fund the annuity
            // ACTUARIAL RULE: We need 100% of expected lifetime benefits at retirement.
            // Once retired, investment returns won't outpace inflation, so we need the full sum.
            let yearsRetired = lifeExpectancy - employeeEarliestEligibleRetirementAge
            let amountNeededAtRetirement = PensionCalculatorPaymentsInto.presentValueOfAnnuityWithInflation(
                initialAnnualPayment: disbursementResult.initialAnnualPension,
                interestRate: config.expectedSystemFutureRateReturn, // Used during accumulation phase only
                inflationRate: config.expectedFutureInflationRate,
                years: yearsRetired
            )
            
            // Calculate city contributions needed
            let cityContribution = PensionCalculatorPaymentsInto.calculateDiscountPayment(
                verbose: false,
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
            
            totalDisbursements += disbursementResult.totalPayout
            totalCityContributions += cityContribution
            totalEmployeeContributions += employeeContribution
            totalYearsOfService += yearsToRetire
            
            employeeResults.append(EmployeeCalculationResult(
                employee: employee,
                totalDisbursements: disbursementResult.totalPayout,
                initialAnnualPension: disbursementResult.initialAnnualPension,
                cityContributions: cityContribution,
                employeeContributions: employeeContribution,
                yearsToRetire: yearsToRetire,
                retirementAge: retirementAge
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
            var yearsRetired = lifeExpectancy + config.deltaExtraLife - employeeEarliestEligibleRetirementAge
            if yearsRetired < 0 {
                yearsRetired = 0
            }
            
            // Calculate future value of employee contributions
            let annualEmployeeContribution = config.baseWage * (config.employeeContributionPercent / 100.0)
            let employeeContributionsFV = PensionCalculatorPaymentsInto.futureValueOfAnnuity(
                annualPayment: annualEmployeeContribution,
                interestRate: config.expectedSystemFutureRateReturn,
                years: yearsToRetire
            )
            
            // Calculate future value of city contributions
            // First calculate the annual payment using annuity formula, then calculate FV
            let interestRate = config.expectedSystemFutureRateReturn / 100.0
            let annualCityContribution: Double
            if yearsToRetire > 0 && interestRate > 0 {
                let discountFactor = pow(1 + interestRate, Double(-yearsToRetire))
                let annuityFactor = interestRate / (1 - discountFactor)
                annualCityContribution = employeeResult.cityContributions * annuityFactor
            } else {
                annualCityContribution = employeeResult.cityContributions / Double(yearsToRetire)
            }
            let cityContributionsFV = PensionCalculatorPaymentsInto.futureValueOfAnnuity(
                annualPayment: annualCityContribution,
                interestRate: config.expectedSystemFutureRateReturn,
                years: yearsToRetire
            )
            
            totalAvailableAtRetirement += employeeContributionsFV + cityContributionsFV
            
            // Calculate amount needed at retirement
            // ACTUARIAL RULE: 100% of expected lifetime benefits needed (no discounting during retirement)
            let neededAtRetirement = PensionCalculatorPaymentsInto.presentValueOfAnnuityWithInflation(
                initialAnnualPayment: employeeResult.initialAnnualPension,
                interestRate: config.expectedSystemFutureRateReturn, // Used during accumulation phase only
                inflationRate: config.expectedFutureInflationRate,
                years: yearsRetired
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
                retirementAge: result.retirementAge
            )
        }
        
        // Recalculate total available with adjusted contributions
        var adjustedTotalAvailableAtRetirement: Double = 0
        for employeeResult in adjustedEmployeeResults {
            let employee = employeeResult.employee
            let yearsToRetire = employeeResult.yearsToRetire
            let employeeEarliestEligibleRetirementAge = (employee.hiredYear + yearsToRetire) - currentYear + employee.currentAge
            var yearsRetired = lifeExpectancy + config.deltaExtraLife - employeeEarliestEligibleRetirementAge
            if yearsRetired < 0 {
                yearsRetired = 0
            }
            
            let annualEmployeeContribution = config.baseWage * (config.employeeContributionPercent / 100.0)
            let employeeContributionsFV = PensionCalculatorPaymentsInto.futureValueOfAnnuity(
                annualPayment: annualEmployeeContribution,
                interestRate: config.expectedSystemFutureRateReturn,
                years: yearsToRetire
            )
            
            // Calculate annual payment using annuity formula, then calculate FV
            let interestRate = config.expectedSystemFutureRateReturn / 100.0
            let annualCityContribution: Double
            if yearsToRetire > 0 && interestRate > 0 {
                let discountFactor = pow(1 + interestRate, Double(-yearsToRetire))
                let annuityFactor = interestRate / (1 - discountFactor)
                annualCityContribution = employeeResult.cityContributions * annuityFactor
            } else {
                annualCityContribution = employeeResult.cityContributions / Double(yearsToRetire)
            }
            let cityContributionsFV = PensionCalculatorPaymentsInto.futureValueOfAnnuity(
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
        
        // Calculate annual city payments (using adjusted contributions)
        // For each employee, calculate the annual payment needed to reach the present value target
        // Using annuity formula: PMT = PV * (r / (1 - (1 + r)^-n))
        // This calculates the annual payment during accumulation phase (before retirement)
        var annualCityPayments: Double = 0
        let interestRate = config.expectedSystemFutureRateReturn / 100.0
        
        for employeeResult in employeeResults {
            let yearsToRetire = employeeResult.yearsToRetire
            let presentValue = employeeResult.cityContributions
            
            if yearsToRetire > 0 && interestRate > 0 {
                // Calculate annual payment using annuity formula
                let discountFactor = pow(1 + interestRate, Double(-yearsToRetire))
                let annuityFactor = interestRate / (1 - discountFactor)
                let annualPaymentPerEmployee = presentValue * annuityFactor
                annualCityPayments += annualPaymentPerEmployee
            } else if yearsToRetire > 0 {
                // If interest rate is 0, just divide by years
                annualCityPayments += presentValue / Double(yearsToRetire)
            }
        }
        
        // Calculate percentage of payroll
        // Payroll is base wages + insurance, not including pension payments
        // Calculate dynamically based on actual number of employees
        let numberOfEmployees = employees.count
        let perEmployeeWage = config.baseWage
        let perEmployeeInsurance = config.eachEmployeeInsuranceAnnualCostToCity
        let totalPayroll = (perEmployeeWage + perEmployeeInsurance) * Double(numberOfEmployees)
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
        // Calculate years needed to retire for fictional new hire
        let yearsToRetire: Int
        if (config.fictionalNewHireAge + config.careerYearsService) < config.minAgeForYearsService {
            yearsToRetire = config.minAgeForYearsService - config.fictionalNewHireAge
        } else if config.retirementAge <= (config.careerYearsService + config.fictionalNewHireAge) {
            yearsToRetire = config.retirementAge - config.fictionalNewHireAge
        } else {
            yearsToRetire = config.careerYearsService
        }
        
        let retirementAge = config.fictionalNewHireAge + yearsToRetire
        
        // Calculate disbursements
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
            lifeExpDiff: config.deltaExtraLife,
            spouseAgeDiff: config.fictionalSpouseAgeDiff,
            currentAge: config.fictionalNewHireAge,
            pensionOption: config.pensionOption
        )
        
        // Calculate employee contribution (percentage of base wage over career)
        let employeeContribution = config.baseWage * (config.employeeContributionPercent / 100.0) * Double(yearsToRetire)
        
        // Calculate amount needed at retirement to fund the annuity
        // ACTUARIAL RULE: 100% of expected lifetime benefits needed (no discounting during retirement)
        let yearsRetired = lifeExpectancy - retirementAge
        let amountNeededAtRetirement = PensionCalculatorPaymentsInto.presentValueOfAnnuityWithInflation(
            initialAnnualPayment: disbursementResult.initialAnnualPension,
            interestRate: config.expectedSystemFutureRateReturn, // Used during accumulation phase only
            inflationRate: config.expectedFutureInflationRate,
            years: yearsRetired
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
        if config.retirementAge <= (config.careerYearsService + employee.hiredAge) {
            return config.retirementAge - employee.hiredAge
        } else if (employee.hiredAge + config.careerYearsService) < config.minAgeForYearsService {
            return config.minAgeForYearsService - employee.hiredAge
        } else {
            return config.careerYearsService
        }
    }
}

