#!/usr/bin/env swift

// Verification script to confirm contributions are sufficient
// Test case: 27 year old employee, 25 years service, no spouse, normal life expectancy
// 7.25% investment return, no COLA, 2.62% inflation

import Foundation

// Copy the necessary functions and constants
let LIFE_EXPECTANCY = 73

// Test parameters
let hireAge = 27
let yearsOfService = 25
let retirementAge = hireAge + yearsOfService // 52
let yearsRetired = LIFE_EXPECTANCY - retirementAge // 21 years
let facWage = 100000.0 // Example FAC wage
let baseWage = 80000.0 // Example base wage
let multiplier = 2.5 // 2.5% multiplier
let useFacWage = true
let expectedReturn = 7.25
let inflationRate = 2.62
let noCola = true
let noSpouse = true

// Calculate pension (Option 1 - 100% retiree only)
let earningsBasedOn = useFacWage ? facWage : baseWage
let option1Pension = earningsBasedOn * (multiplier / 100.0) * Double(yearsOfService)
// Example: 100000 * 0.025 * 25 = 62,500 annual pension

// Calculate total payout (no COLA, but adjusted for inflation in today's dollars)
// Since no COLA, annual pension stays the same, but we need to account for inflation
// Total payout = sum of each year's payment adjusted for inflation (in today's dollars)
var totalPayout = 0.0
var currentPension = option1Pension
for year in 1...yearsRetired {
    // Apply inflation (reduces buying power) - this matches the disbursement calculation
    currentPension = currentPension * (1 - (inflationRate / 100.0))
    totalPayout += currentPension
}

// Calculate employee contribution (6% of FAC wage annually)
let annualEmployeeContribution = facWage * 0.06
let totalEmployeeContribution = annualEmployeeContribution * Double(yearsOfService)

// Calculate future value of employee contributions
func futureValueOfAnnuity(annualPayment: Double, interestRate: Double, years: Int) -> Double {
    let r = interestRate / 100.0
    if r == 0 {
        return annualPayment * Double(years)
    }
    return annualPayment * ((pow(1 + r, Double(years)) - 1) / r)
}

let employeeContributionsFV = futureValueOfAnnuity(
    annualPayment: annualEmployeeContribution,
    interestRate: expectedReturn,
    years: yearsOfService
)

// Calculate what city needs to contribute
// ACTUARIAL RULE: We need 100% of expected lifetime benefits at retirement
// Once retired, investment returns won't outpace inflation, so we need the full sum

// Amount needed at retirement (100% of lifetime benefits - full sum, no discounting)
// Payments are fixed in nominal dollars, so we need: annual payment × years retired
let amountNeededAtRetirement = option1Pension * Double(yearsRetired)

// Now calculate what city needs to contribute
// Amount needed at retirement (nominal) minus employee contributions FV (nominal)
let futureValueNeeded = amountNeededAtRetirement - employeeContributionsFV

// Discount back to today using NOMINAL interest rate (not real rate)
// The amount needed is in retirement-date dollars (nominal), so we use nominal rate to discount
let cityContributionPV = futureValueNeeded / pow(1 + (expectedReturn / 100.0), Double(yearsOfService))

// Calculate annual city contribution using annuity formula: PMT = PV * (r / (1 - (1 + r)^-n))
let interestRate = expectedReturn / 100.0
let discountFactor = pow(1 + interestRate, Double(-yearsOfService))
let annuityFactor = interestRate / (1 - discountFactor)
let annualCityContribution = cityContributionPV * annuityFactor

// Calculate future value of city contributions
let cityContributionsFV = futureValueOfAnnuity(
    annualPayment: annualCityContribution,
    interestRate: expectedReturn,
    years: yearsOfService
)

// Total available at retirement
let totalAvailableAtRetirement = employeeContributionsFV + cityContributionsFV

// Total needed at retirement (100% of lifetime benefits - full sum)
let totalNeededAtRetirement = amountNeededAtRetirement

// Results
print("=== Pension Contribution Verification ===")
print("Employee: Age \(hireAge) at hire, \(yearsOfService) years service, retires at \(retirementAge)")
print("Life expectancy: \(LIFE_EXPECTANCY), Years retired: \(yearsRetired)")
print("FAC Wage: $\(Int(facWage))")
print("Annual Pension (Option 1): $\(Int(option1Pension))")
print("Total Payout Needed (today's dollars): $\(Int(totalPayout))")
print("")
print("=== Contributions ===")
print("Employee Contribution: 6% of FAC wage = $\(Int(annualEmployeeContribution)) per year")
print("Total Employee Contributions (nominal): $\(Int(totalEmployeeContribution))")
print("Employee Contributions FV at retirement: $\(Int(employeeContributionsFV))")
print("")
print("City Contribution PV needed: $\(Int(cityContributionPV))")
print("City Contribution per year: $\(Int(annualCityContribution))")
print("City Contributions FV at retirement: $\(Int(cityContributionsFV))")
print("")
print("=== Verification ===")
print("Total Available at Retirement: $\(Int(totalAvailableAtRetirement))")
print("Total Needed at Retirement (nominal): $\(Int(totalNeededAtRetirement))")
print("Shortfall/Surplus: $\(Int(totalAvailableAtRetirement - totalNeededAtRetirement))")
print("")
if totalAvailableAtRetirement >= totalNeededAtRetirement {
    print("✓ SUFFICIENT: Contributions with \(expectedReturn)% return are sufficient")
} else {
    print("✗ INSUFFICIENT: Shortfall of $\(Int(totalNeededAtRetirement - totalAvailableAtRetirement))")
}

