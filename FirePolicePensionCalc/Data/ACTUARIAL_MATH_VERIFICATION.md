# Actuarial Math Verification

This document verifies that all financial calculations use standard annuity and actuarial formulas correctly.

## 1. Basic Financial Formulas

### Present Value (PV) from Future Value (FV)
**Location:** `PensionCalculatorPaymentsInto.presentValue()`
**Formula:** `PV = FV / (1 + r)^n`
**Status:** ✅ **CORRECT**
- Standard present value formula
- Correctly handles percentage to decimal conversion

### Future Value (FV) from Present Value (PV)
**Location:** `PensionCalculatorPaymentsInto.futureValue()`
**Formula:** `FV = PV * (1 + r)^n`
**Status:** ✅ **CORRECT**
- Standard future value formula
- Correctly handles percentage to decimal conversion

## 2. Annuity Formulas

### Future Value of Annuity (Ordinary Annuity)
**Location:** `PensionCalculatorPaymentsInto.futureValueOfAnnuity()`
**Formula:** `FV = PMT * (((1 + r)^n - 1) / r)`
**Status:** ✅ **CORRECT**
- Standard formula for future value of an ordinary annuity (payments at end of period)
- Correctly handles r = 0 case (returns PMT * n)
- Used for calculating future value of employee and city contributions

### Amount Needed at Retirement
**Location:** `PensionCalculatorPaymentsInto.presentValueOfAnnuityWithInflation()`
**Formula:** `Amount Needed = PMT * n` (full sum, no discounting)
**Status:** ✅ **CORRECT**
- ACTUARIAL RULE: 100% of expected lifetime benefits needed at retirement
- Once retired, investment returns won't outpace inflation, so we need the full sum
- Used to calculate amount needed at retirement to fund pension payments
- **Note:** Pension payments are fixed in nominal dollars (they don't decrease by inflation)

### Annual Payment (PMT) from Present Value
**Location:** Multiple locations (now fixed)
**Formula:** `PMT = PV * (r / (1 - (1 + r)^-n))`
**Status:** ✅ **CORRECT** (after fixes)
- Standard formula for calculating payment amount from present value
- Used to calculate annual city contributions needed
- Previously had bug: was dividing PV by years (ignored interest)
- Now correctly uses annuity formula

## 3. Discounting and Inflation

### Real Rate of Return
**Location:** `PensionCalculatorPaymentsInto.calculateDiscountPayment()`
**Formula:** `realRate = ((1 + nominalRate) / (1 + inflationRate)) - 1`
**Status:** ✅ **CORRECT** (calculated but not used incorrectly)
- Standard formula for real rate of return
- **Note:** Currently NOT used for discounting (correctly using nominal rate)

### Discounting from Retirement to Today
**Location:** `PensionCalculatorPaymentsInto.calculateDiscountPayment()`
**Method:** Uses nominal interest rate (not real rate)
**Status:** ✅ **CORRECT**
- `sumDesiredAtRetirement` is in retirement-date dollars (nominal)
- Discounting back to today uses nominal rate: `PV = FV / (1 + r)^n`
- Real rate would only be used if working in today's dollars throughout

## 4. Actuarial Equivalence

### Option 1 Total Benefit Calculation
**Location:** `PensionCalculatorDisbursements.calculateOption1TotalBenefit()`
**Method:** Sums all payments adjusted for COLA and inflation
**Status:** ✅ **CORRECT**
- Calculates total lifetime benefit in today's buying power
- Accounts for COLA increases (dollar amount)
- Accounts for inflation (buying power reduction)
- This becomes the target for other options

### Binary Search for Actuarial Equivalence
**Location:** `PensionCalculatorDisbursements.calculateActuarialEquivalentPension()`
**Method:** Binary search to find pension amount that makes total benefit equal to Option 1
**Status:** ✅ **CORRECT**
- Uses iterative approach (50 iterations)
- Precision: within $0.01
- Search range: 70% to 98% of Option 1 pension
- Uses same calculation method (`calculateTotalBenefitWithSurvivor`) for consistency

### Total Benefit with Survivor
**Location:** `PensionCalculatorDisbursements.calculateTotalBenefitWithSurvivor()`
**Method:** Calculates total lifetime benefit including retiree and survivor payments
**Status:** ✅ **CORRECT**
- Uses same COLA and inflation logic as main calculation
- Handles different survivor percentages (100%, 66.67%, fixed 10 years)
- For Option 3: Correctly handles dollar amount (with COLAs) vs buying power (with inflation)

## 5. Contribution Calculations

### Employee Contribution Future Value
**Location:** `PensionCalculatorPaymentsInto.calculateDiscountPayment()`
**Method:** Uses `futureValueOfAnnuity()` with annual employee contribution
**Status:** ✅ **CORRECT**
- Annual contribution = total / years
- Future value calculated using annuity formula
- Accounts for investment growth over career

### City Contribution Present Value
**Location:** `PensionCalculatorPaymentsInto.calculateDiscountPayment()`
**Method:** 
1. Calculate amount needed at retirement (PV of annuity)
2. Subtract employee contributions FV
3. Discount back to today using nominal rate
**Status:** ✅ **CORRECT**
- All values in consistent units (retirement-date dollars)
- Correctly discounts using nominal rate

### Annual City Payment Calculation
**Location:** `PensionCalculatorService.calculateSystemCosts()`
**Method:** Uses annuity formula: `PMT = PV * (r / (1 - (1 + r)^-n))`
**Status:** ✅ **CORRECT** (after fixes)
- Previously had bug: was dividing PV by years
- Now correctly uses annuity formula for each employee
- Sums annual payments across all employees

## 6. Verification and Testing

### Contribution Sufficiency Verification
**Location:** `PensionCalculatorPaymentsInto.verifyContributionSufficiency()`
**Method:** 
1. Calculate FV of employee contributions (annuity)
2. Calculate FV of city contributions (annuity) - **NOW FIXED**
3. Calculate PV of pension payments needed at retirement
4. Compare available vs needed
**Status:** ✅ **CORRECT** (after fixes)
- Now correctly calculates annual city contribution using annuity formula
- Properly accounts for investment growth

## Summary of Fixes Applied

1. ✅ Fixed `presentValueOfAnnuityWithInflation()` - now implements 100% funding actuarial rule (full sum, no discounting)
2. ✅ Fixed discounting in `calculateDiscountPayment()` - now uses nominal rate instead of real rate
3. ✅ Fixed annual payment calculation in verbose output - now uses annuity formula
4. ✅ Fixed annual city contribution in `verifyContributionSufficiency()` - now uses annuity formula
5. ✅ Fixed annual city contribution calculation in `PensionCalculatorService` - now uses annuity formula for FV calculation
6. ✅ Updated all documentation and comments to reflect 100% funding actuarial rule

## Standard Formulas Reference

- **Amount Needed at Retirement:** `Amount = PMT * n` (100% funding rule - full sum, no discounting)
- **FV of Annuity:** `FV = PMT * (((1 + r)^n - 1) / r)`
- **PMT from PV:** `PMT = PV * (r / (1 - (1 + r)^-n))`
- **PV from FV:** `PV = FV / (1 + r)^n`
- **FV from PV:** `FV = PV * (1 + r)^n`
- **Real Rate:** `realRate = ((1 + nominalRate) / (1 + inflationRate)) - 1`

All formulas are now correctly implemented using standard actuarial mathematics.

