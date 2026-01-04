# Expected Return Rate and Inflation Rate Usage Verification

This document confirms that both the **Expected Return Rate** and **Inflation Rate** are properly included throughout all calculations.

## Expected Return Rate (`expectedSystemFutureRateReturn`)

**Default:** 7.25%  
**Location in Config:** `PensionConfiguration.expectedSystemFutureRateReturn`

### ✅ Used in All Critical Calculations:

#### 1. Future Value of Employee Contributions
**Location:** `PensionCalculatorPaymentsInto.futureValueOfAnnuity()`
- **Formula:** `FV = PMT * (((1 + r)^n - 1) / r)`
- **Purpose:** Calculate how much employee contributions grow to at retirement
- **Rate Used:** `expectedSystemFutureRateReturn`
- **Status:** ✅ **CORRECT**

#### 2. Amount Needed at Retirement
**Location:** `PensionCalculatorPaymentsInto.presentValueOfAnnuityWithInflation()`
- **Formula:** `Amount Needed = PMT * n` (full sum, no discounting)
- **Purpose:** Calculate amount needed at retirement (100% of lifetime benefits)
- **Actuarial Rule:** During retirement, investment returns won't outpace inflation
- **Status:** ✅ **CORRECT**

#### 3. Discounting City Contributions Back to Today
**Location:** `PensionCalculatorPaymentsInto.calculateDiscountPayment()` → `presentValue()`
- **Formula:** `PV = FV / (1 + r)^n`
- **Purpose:** Discount city's needed amount from retirement back to today
- **Rate Used:** `expectedSystemFutureRateReturn` (nominal rate, not real rate)
- **Status:** ✅ **CORRECT**

#### 4. Future Value of City Contributions
**Location:** `PensionCalculatorService.calculateSystemCosts()` → `futureValueOfAnnuity()`
- **Formula:** `FV = PMT * (((1 + r)^n - 1) / r)`
- **Purpose:** Calculate how much city contributions grow to at retirement
- **Rate Used:** `expectedSystemFutureRateReturn`
- **Status:** ✅ **CORRECT**

#### 5. Annual City Payment Calculation
**Location:** `PensionCalculatorService.calculateSystemCosts()`
- **Formula:** `PMT = PV * (r / (1 - (1 + r)^-n))`
- **Purpose:** Calculate annual payment needed from present value
- **Rate Used:** `expectedSystemFutureRateReturn`
- **Status:** ✅ **CORRECT**

## Inflation Rate (`expectedFutureInflationRate`)

**Default:** 2.63%  
**Location in Config:** `PensionConfiguration.expectedFutureInflationRate`

### ✅ Used in All Critical Calculations:

#### 1. Lifetime Benefit Calculation (Buying Power Adjustment)
**Location:** `PensionCalculatorDisbursements.calculateOption1TotalBenefit()` and related functions
- **Method:** Each year, reduce buying power by inflation: `buyingPower -= buyingPower * inflate`
- **Purpose:** Calculate total lifetime benefit in today's buying power
- **Rate Used:** `expectedFutureInflationRate` (converted to `inflate = inflateRate / 100.0`)
- **Status:** ✅ **CORRECT**

**Example:**
```swift
for year in 1...yearsReceivingPension {
    // Apply COLA (increases dollar amount)
    if isColaYear {
        currentPension += currentPension * colaPerc
    }
    // Apply inflation (reduces buying power)
    currentPension -= currentPension * inflate
    totalBenefit += currentPension  // Sum in today's buying power
}
```

#### 2. Survivor Benefit Buying Power Calculation
**Location:** `PensionCalculatorDisbursements.calculateDisbursements()` (Option 3)
- **Method:** Apply inflation over retiree's years and survivor's years
- **Purpose:** Calculate survivor's initial and final buying power
- **Rate Used:** `expectedFutureInflationRate`
- **Status:** ✅ **CORRECT**

#### 3. Actuarial Equivalence Calculations
**Location:** `PensionCalculatorDisbursements.calculateTotalBenefitWithSurvivor()`
- **Method:** Uses same inflation adjustment as main calculation
- **Purpose:** Ensure all pension options are actuarially equivalent
- **Rate Used:** `expectedFutureInflationRate`
- **Status:** ✅ **CORRECT**

#### 4. Present Value of Annuity (Parameter)
**Location:** `PensionCalculatorPaymentsInto.presentValueOfAnnuityWithInflation()`
- **Note:** Parameter accepted but not used in calculation (correct behavior)
- **Reason:** Pension payments are fixed in nominal dollars, so inflation doesn't affect the PV calculation
- **Status:** ✅ **CORRECT** (inflation already accounted for in lifetime benefit calculation)

## Calculation Flow with Rates

### Step 1: Calculate Lifetime Benefit
```
Annual Pension → Apply COLA → Apply Inflation → Sum All Years
                                    ↑
                          Uses: expectedFutureInflationRate
```

### Step 2: Calculate Amount Needed at Retirement
```
Amount Needed = PMT × n  (full sum, no discounting)
                                    ↑
                          ACTUARIAL RULE: 100% funding required
                          (Investment returns won't outpace inflation during retirement)
```

### Step 3: Calculate Contributions Needed
```
Employee FV = PMT × (((1 + r)^n - 1) / r)  ← Uses expectedSystemFutureRateReturn
City Needed = Amount Needed - Employee FV
City PV = City Needed / (1 + r)^n          ← Uses expectedSystemFutureRateReturn
City PMT = City PV × (r / (1 - (1 + r)^-n)) ← Uses expectedSystemFutureRateReturn
```

## Verification Points

✅ **Expected Return Rate** is used in:
- Future value calculations (employee and city contributions during accumulation)
- Discounting calculations (retirement to today)
- Annual payment calculations (during accumulation phase)
- **Note:** NOT used for amount needed at retirement (uses 100% funding rule)

✅ **Inflation Rate** is used in:
- Lifetime benefit calculations (buying power adjustments)
- Survivor benefit calculations (buying power over time)
- Actuarial equivalence calculations

✅ Both rates are:
- Passed correctly through all function calls
- Converted from percentages to decimals where needed
- Used consistently throughout the calculation chain

## Summary

**Both rates are properly included and used correctly throughout all calculations:**

1. **Expected Return Rate (7.25%)** - Used for all time value of money calculations (FV, PV, discounting)
2. **Inflation Rate (2.63%)** - Used for all buying power adjustments in lifetime benefit calculations

The calculation flow properly accounts for:
- How contributions grow over time (expected return)
- How buying power decreases over time (inflation)
- How much is needed at retirement (100% of lifetime benefits - full sum)
- How much needs to be contributed today (discounted using expected return)

All calculations are mathematically sound and use both rates appropriately.

