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
    
    // Economic assumptions
    var expectedFutureInflationRate: Double = 2.63 // percentage
    var expectedSystemFutureRateReturn: Double = 7.0 // percentage
    var employeeContributionPercent: Double = 5.0 // percentage of base wage
    
    // Life expectancy
    var lifeExpectancy: Int = 73
    var deltaExtraLife: Int = 0 // additional years beyond life expectancy
    
    // Fictional new hire (for individual calculations)
    var fictionalNewHireAge: Int = 25
    var fictionalSpouseAgeDiff: Int = -2
    var spouseReductionPercent: Double = 80.0 // percentage (deprecated - calculated based on pension option)
    var pensionOption: PensionOption = .option3 // Default to option 3
    
    // System-wide settings
    var totalNumberEmployees: Int = 61
    var eachEmployeeInsuranceAnnualCostToCity: Double = 12000
    var cityAnnualWageAndBonusPayments: Double = 4949000
    var cityAnnualInsurancePayments: Double = 1033000
    
    // FAC Calculator defaults (persisted)
    var facBaseWageYear1: Double = 0
    var facOvertimeYear1: Double = 5000
    var facRollInsYear1: Double = 6000
    var facBaseWageYear2: Double = 0
    var facOvertimeYear2: Double = 0
    var facBaseWageYear3: Double = 0
    var facOvertimeYear3: Double = 0
}

