//
//  PensionConfiguration.swift
//  FirePolicePensionCalc
//
//  Created from Java port
//

import Foundation

enum PensionOption: Int, Codable, CaseIterable {
    case option1 = 1  // 100% retiree only, 0% survivor
    case option2 = 2  // Ten year certain survivor (fixed 10 years)
    case option3 = 3  // Joint and Survivor (100% - survivor receives 100% of initial annual pension)
    case option4 = 4  // Joint and Survivor (66.67% - survivor receives 66.67% of what retiree was receiving)
    
    var displayName: String {
        switch self {
        case .option1: return "Option 1: Maximum Monthly Benefit"
        case .option2: return "Option 2: Ten Year Certain"
        case .option3: return "Option 3: Joint and Survivor (100%)"
        case .option4: return "Option 4: Joint and Survivor (66.67%)"
        }
    }
}

struct PensionConfiguration: Codable {
    // Wage inputs
    var baseWage: Double = 85000
    var facWage: Double = 98000
    
    // Multiplier settings
    var multiplier: Double = 2.5 // percentage
    var multiplierBasedOnFAC: Bool = true
    
    // COLA settings
    var isColaCompounding: Bool = false
    var colaNumber: Int = 2
    var colaSpacing: Int = 5 // years apart
    var colaPercent: Double = 6 // percentage
    
    // Retirement eligibility
    var retirementAge: Int = 55
    var careerYearsService: Int = 20
    var minAgeForYearsService: Int = 50
    var yearsUntilVestment: Int = 5 // system-wide years until vestment
    
    // Economic assumptions
    var expectedFutureInflationRate: Double = 2.63 // percentage
    var expectedSystemFutureRateReturn: Double = 7.25 // percentage
    var employeeContributionPercent: Double = 5.0 // percentage of base wage
    
    // Life expectancy
    var lifeExpectancyMale: Int = 73 // system-wide male life expectancy
    var lifeExpectancyFemale: Int = 79 // system-wide female life expectancy
    var deltaExtraLife: Int = 0 // additional years beyond life expectancy
    
    // Fictional new hire (for individual calculations)
    var fictionalNewHireAge: Int = 25
    var fictionalSpouseAgeDiff: Int = -2
    var spouseReductionPercent: Double = 80.0 // percentage (deprecated - calculated based on pension option)
    var pensionOption: PensionOption = .option3 // Default to option 3
    
    // Real employee data for fictional new hire
    var fictionalHiredYear: Int = 2025
    var fictionalBirthYear: Int = 2000
    var fictionalEmployeeSex: Sex = .male // M or F
    var fictionalSpouseBirthYear: Int = 1998
    var fictionalSpouseSex: Sex = .female // M or F, defaults to F
    var fictionalYearsOfWork: Int = 25 // chosen number of years of work
    var earlyRetirementAuthorized: Bool = false // if checked, bypasses early retirement validation
    
    // System-wide settings
    var totalNumberEmployees: Int = 61
    var eachEmployeeInsuranceAnnualCostToCity: Double = 12000
    var cityAnnualWageAndBonusPayments: Double = 4949000
    var cityAnnualInsurancePayments: Double = 1033000
    
    // System-wide wage assumptions
    var systemWideBaseWage: Double = 85000 // system-wide base wage for calculations
    var systemWideFacWage: Double = 98000 // system-wide FAC wage for calculations
    var systemWideAverageWage: Double = 60000 // system-wide average wage for average payroll calculations
    
    // FAC Calculator defaults (persisted)
    var facBaseWageYear1: Double = 0
    var facOvertimeYear1: Double = 5000
    var facRollInsYear1: Double = 6000
    var facBaseWageYear2: Double = 0
    var facOvertimeYear2: Double = 0
    var facBaseWageYear3: Double = 0
    var facOvertimeYear3: Double = 0
}

