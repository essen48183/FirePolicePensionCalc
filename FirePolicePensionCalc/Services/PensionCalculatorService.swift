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
            
            // Calculate disbursements using system-wide wages
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
                totalYearsService: yearsToRetire,
                employeeSex: employee.sex,
                spouseSex: employee.spouseSex,
                lifeExpectancyMale: config.lifeExpectancyMale,
                lifeExpectancyFemale: config.lifeExpectancyFemale,
                lifeExpDiff: config.deltaExtraLife,
                spouseAgeDiff: employee.spouseAgeDiff,
                currentAge: employee.currentAge,
                pensionOption: config.pensionOption
            )
            
            // Calculate employee contribution using PensionMathCalculations
            let employeeContribution = PensionMathCalculations.calculateTotalEmployeeContribution(
                baseWage: config.systemWideBaseWage,
                contributionPercent: config.employeeContributionPercent,
                yearsOfService: yearsToRetire
            )
            
            // Calculate amount needed at retirement to fund the annuity using PensionMathFormulas
            // ACTUARIAL RULE: We need 100% of expected lifetime benefits at retirement.
            let employeeLifeExpectancy = employee.sex == .male ? config.lifeExpectancyMale : config.lifeExpectancyFemale
            let yearsRetired = employeeLifeExpectancy + config.deltaExtraLife - employeeEarliestEligibleRetirementAge
            let amountNeededAtRetirement = PensionMathFormulas.amountNeededAtRetirement(
                initialAnnualPayment: disbursementResult.initialAnnualPension,
                years: yearsRetired
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
            let employeeLifeExpectancy = employeeResult.employee.sex == .male ? config.lifeExpectancyMale : config.lifeExpectancyFemale
            var yearsRetired = employeeLifeExpectancy + config.deltaExtraLife - employeeEarliestEligibleRetirementAge
            if yearsRetired < 0 {
                yearsRetired = 0
            }
            
            // Calculate future value of employee contributions using PensionMathCalculations
            let annualEmployeeContribution = PensionMathCalculations.calculateAnnualEmployeeContribution(
                baseWage: config.systemWideBaseWage,
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
            
            // Calculate amount needed at retirement using PensionMathFormulas
            // ACTUARIAL RULE: 100% of expected lifetime benefits needed (no discounting during retirement)
            let neededAtRetirement = PensionMathFormulas.amountNeededAtRetirement(
                initialAnnualPayment: employeeResult.initialAnnualPension,
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
            let employeeLifeExpectancy = employee.sex == .male ? config.lifeExpectancyMale : config.lifeExpectancyFemale
            var yearsRetired = employeeLifeExpectancy + config.deltaExtraLife - employeeEarliestEligibleRetirementAge
            if yearsRetired < 0 {
                yearsRetired = 0
            }
            
            // Calculate future value of employee contributions using PensionMathCalculations
            let annualEmployeeContribution = PensionMathCalculations.calculateAnnualEmployeeContribution(
                baseWage: config.systemWideBaseWage,
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
        // If early retirement is authorized, use years of work directly; otherwise respect constraints
        let yearsToRetire: Int
        if config.earlyRetirementAuthorized {
            // If early retirement is authorized, use years of work directly
            yearsToRetire = config.fictionalYearsOfWork
        } else if (hireAge + config.fictionalYearsOfWork) < config.minAgeForYearsService {
            // If years of work wouldn't reach min age, use min age constraint
            yearsToRetire = config.minAgeForYearsService - hireAge
        } else if config.retirementAge <= (config.fictionalYearsOfWork + hireAge) {
            // If retirement age would be reached before completing years of work, use retirement age
            yearsToRetire = config.retirementAge - hireAge
        } else {
            // Use the chosen years of work from blue box
            yearsToRetire = config.fictionalYearsOfWork
        }
        
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
        
        // Calculate amount needed at retirement using PensionMathFormulas
        // ACTUARIAL RULE: 100% of expected lifetime benefits needed (no discounting during retirement)
        let employeeLifeExpectancy = config.fictionalEmployeeSex == .male ? config.lifeExpectancyMale : config.lifeExpectancyFemale
        let yearsRetired = employeeLifeExpectancy + config.deltaExtraLife - retirementAge
        let amountNeededAtRetirement = PensionMathFormulas.amountNeededAtRetirement(
            initialAnnualPayment: disbursementResult.initialAnnualPension,
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

