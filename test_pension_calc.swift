#!/usr/bin/env swift

// Unit test for pension calculations
// 25 year old, 25 years service, retires at 50
// 2.5% multiplier based on base pay
// Employee contributes 5% of base wage

import Foundation

// Test parameters
let baseWage = 87000.0
let facWage = 97000.0
let multiplier = 2.5 // percentage
let employeeContributionPercent = 5.0 // percentage
let yearsOfService = 25
let hireAge = 25
let retirementAge = 50
let yearsRetired = 73 - retirementAge // 23 years
let expectedReturn = 7.25 // percentage
let inflationRate = 2.63 // percentage
let numberOfEmployees = 61

// Calculate pension
let earningsBasedOn = baseWage // Using base wage (not FAC)
let annualPension = earningsBasedOn * (multiplier / 100.0) * Double(yearsOfService)
print("=== Pension Calculation Test ===")
print("Base Wage: $\(Int(baseWage))")
print("FAC Wage: $\(Int(facWage))")
print("Multiplier: \(multiplier)%")
print("Years of Service: \(yearsOfService)")
print("Annual Pension: $\(Int(annualPension))")
print("")

// Calculate total payout (in today's dollars, adjusted for inflation)
var totalPayout = 0.0
var currentPension = annualPension
for year in 1...yearsRetired {
    // Apply inflation (reduces buying power)
    currentPension = currentPension * (1 - (inflationRate / 100.0))
    totalPayout += currentPension
}
print("Total Lifetime Payout (today's dollars): $\(Int(totalPayout))")
print("")

// Calculate employee contributions
let annualEmployeeContribution = baseWage * (employeeContributionPercent / 100.0)
let totalEmployeeContributionNominal = annualEmployeeContribution * Double(yearsOfService)
print("Employee Contributions:")
print("  Annual: $\(Int(annualEmployeeContribution))")
print("  Total Nominal: $\(Int(totalEmployeeContributionNominal))")

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
print("  Future Value at Retirement: $\(Int(employeeContributionsFV))")
print("")

// Calculate amount needed at retirement
// ACTUARIAL RULE: 100% of expected lifetime benefits needed at retirement
// Once retired, investment returns won't outpace inflation, so we need the full sum
func presentValueOfAnnuityWithInflation(
    initialAnnualPayment: Double,
    interestRate: Double,
    inflationRate: Double,
    years: Int
) -> Double {
    // ACTUARIAL RULE: During retirement, investment returns won't outpace inflation
    // Therefore, we need the full sum of all payments at retirement (no discounting)
    return initialAnnualPayment * Double(years)
}

let amountNeededAtRetirement = presentValueOfAnnuityWithInflation(
    initialAnnualPayment: annualPension,
    interestRate: expectedReturn, // Used during accumulation phase only
    inflationRate: inflationRate,
    years: yearsRetired
)
print("Amount Needed at Retirement (100% of lifetime benefits): $\(Int(amountNeededAtRetirement))")
print("")

// Calculate what city needs to provide at retirement
let cityNeededAtRetirement = amountNeededAtRetirement - employeeContributionsFV
print("City Needs to Provide at Retirement: $\(Int(cityNeededAtRetirement))")
print("")

// Calculate present value of city contributions needed
func presentValue(futureValue: Double, interestRate: Double, years: Int) -> Double {
    return futureValue / pow(1 + (interestRate / 100.0), Double(years))
}

// Use NOMINAL rate to discount back (not real rate)
let cityContributionPV = presentValue(
    futureValue: cityNeededAtRetirement,
    interestRate: expectedReturn, // NOMINAL rate
    years: yearsOfService
)
print("City Contribution Present Value: $\(Int(cityContributionPV))")
print("")

// Calculate annual city contribution using annuity formula
let interestRate = expectedReturn / 100.0
let discountFactor = pow(1 + interestRate, Double(-yearsOfService))
let annuityFactor = interestRate / (1 - discountFactor)
let annualCityContribution = cityContributionPV * annuityFactor
print("Annual City Contribution (per employee): $\(Int(annualCityContribution))")
print("")

// Calculate totals for all employees
let totalEmployeeContributions = totalEmployeeContributionNominal * Double(numberOfEmployees)
let totalCityContributionsPV = cityContributionPV * Double(numberOfEmployees)
let totalAnnualCityContributions = annualCityContribution * Double(numberOfEmployees)

print("=== Totals for \(numberOfEmployees) Employees ===")
print("Total Employee Contributions (nominal): $\(Int(totalEmployeeContributions))")
print("Total City Contributions (present value): $\(Int(totalCityContributionsPV))")
print("Total Annual City Contributions: $\(Int(totalAnnualCityContributions))")
print("")

// Calculate ratio (comparing present values)
let employeeContributionPV = totalEmployeeContributions / pow(1 + (expectedReturn / 100.0), Double(yearsOfService))
let cityToEmployeeRatioPV = totalCityContributionsPV / employeeContributionPV
print("Employee Contribution PV: $\(Int(employeeContributionPV))")
print("City Contribution PV: $\(Int(totalCityContributionsPV))")
print("City to Employee Contribution Ratio (PV): \(String(format: "%.2f", cityToEmployeeRatioPV))x")
print("Note: Ratio is higher due to 100% funding actuarial rule (no discounting during retirement)")
print("")

// Calculate percent of payroll
let cityAnnualWageAndBonusPayments = 4949000.0
let cityAnnualInsurancePayments = 1033000.0
let totalPayroll = cityAnnualWageAndBonusPayments + cityAnnualInsurancePayments
let percentOfPayroll = (totalAnnualCityContributions / totalPayroll) * 100.0
print("Percent of Payroll: \(String(format: "%.2f", percentOfPayroll))%")
print("Note: Percent may vary based on employee demographics and 100% funding actuarial rule")

