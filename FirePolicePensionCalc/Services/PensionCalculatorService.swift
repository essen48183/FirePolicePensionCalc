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
            
            // Calculate city contributions needed
            let cityContribution = PensionCalculatorPaymentsInto.calculateDiscountPayment(
                verbose: false,
                sumDesiredAtRetirement: disbursementResult.totalPayout,
                initialBalance: 0,
                totalEmployeeContribution: employeeContribution,
                facWage: config.facWage,
                expectedInterestRate: config.expectedSystemFutureRateReturn,
                expectedInflationRate: config.expectedFutureInflationRate,
                yearsInvesting: yearsToRetire,
                yearsRetired: lifeExpectancy - employeeEarliestEligibleRetirementAge,
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
        
        // Calculate annual city payments
        // Formula: (totalCityContributions / totalYearsOfService) * employees.count
        // This gives the average annual payment per employee, multiplied by number of employees
        let annualCityPayments = (totalCityContributions / Double(totalYearsOfService)) * Double(employees.count)
        
        // Calculate percentage of payroll
        let totalPayroll = annualCityPayments + config.cityAnnualWageAndBonusPayments + config.cityAnnualInsurancePayments
        let cityAnnualPercentOfPayroll = (annualCityPayments / totalPayroll) * 100.0
        
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
            let annualCityContribution = employeeResult.cityContributions / Double(yearsToRetire)
            let cityContributionsFV = PensionCalculatorPaymentsInto.futureValueOfAnnuity(
                annualPayment: annualCityContribution,
                interestRate: config.expectedSystemFutureRateReturn,
                years: yearsToRetire
            )
            
            totalAvailableAtRetirement += employeeContributionsFV + cityContributionsFV
            
            // Calculate present value of annuity needed at retirement
            let neededAtRetirement = PensionCalculatorPaymentsInto.presentValueOfAnnuityWithInflation(
                initialAnnualPayment: employeeResult.initialAnnualPension,
                interestRate: config.expectedSystemFutureRateReturn,
                inflationRate: config.expectedFutureInflationRate,
                years: yearsRetired
            )
            
            totalNeededAtRetirement += neededAtRetirement
        }
        
        let surplus = totalAvailableAtRetirement - totalNeededAtRetirement
        let isSufficient = surplus >= 0
        
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
        
        // Calculate city contribution
        let cityContribution = PensionCalculatorPaymentsInto.calculateDiscountPayment(
            verbose: true,
            sumDesiredAtRetirement: disbursementResult.totalPayout,
            initialBalance: 0,
            totalEmployeeContribution: employeeContribution,
            facWage: config.facWage,
            expectedInterestRate: config.expectedSystemFutureRateReturn,
            expectedInflationRate: config.expectedFutureInflationRate,
            yearsInvesting: yearsToRetire,
            yearsRetired: lifeExpectancy - retirementAge,
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

