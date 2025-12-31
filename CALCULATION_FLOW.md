# Pension Calculation Flow

This document explains the conceptual flow of pension calculations, confirming that we:
1. Calculate each person's lifetime benefit (entire career)
2. Determine the amount needed at retirement to fund that benefit
3. Work backwards to calculate required contributions

## Step 1: Calculate Lifetime Benefit

**Location:** `PensionCalculatorDisbursements.calculateDisbursements()`

For each employee, we calculate their **total lifetime benefit** in today's buying power:
- Annual pension = base wage (or FAC) × multiplier × years of service
- Apply COLA increases (dollar amount increases)
- Apply inflation (buying power decreases)
- Sum all payments over retirement years
- For options with survivor benefits, include survivor payments

**Result:** `disbursementResult.totalPayout` = total lifetime benefit in today's buying power

**Example:**
- Annual pension: $54,375
- Years retired: 23
- Total lifetime benefit: ~$922,560 (in today's buying power)

## Step 2: Determine Amount Needed at Retirement

**Location:** `PensionCalculatorService.calculateSystemCosts()` → `presentValueOfAnnuityWithInflation()`

**ACTUARIAL RULE:** We need 100% of expected lifetime benefits at retirement. Once retired, investment returns won't outpace inflation, so we need the full sum of all payments.

**Calculation:**
```
Amount Needed at Retirement = PMT × n
```

Where:
- PMT = annual pension payment (fixed in nominal dollars)
- n = years retired

**Why this works:**
- During retirement, investment returns won't outpace inflation
- Therefore, we need the full sum of all payments (no discounting)
- This is a conservative assumption that ensures 100% funding

**Example:**
- Annual pension: $54,375
- Years retired: 23
- **Amount needed at retirement: $1,250,625** (full sum of all payments)

## Step 3: Work Backwards to Calculate Contributions

**Location:** `PensionCalculatorPaymentsInto.calculateDiscountPayment()`

Now we work backwards from retirement to today:

### 3a. Calculate Employee Contributions Future Value
- Employee contributes annually: base wage × contribution percent
- Calculate FV of these contributions at retirement using annuity formula
- **Example:** $4,350/year for 25 years → $285,210 at retirement

### 3b. Calculate City Contribution Needed
- Amount needed at retirement: $1,250,625 (100% of lifetime benefits)
- Minus employee contributions FV: $285,210
- **City needs to provide at retirement: $965,415**

### 3c. Discount Back to Today
- Discount the city's needed amount back to today using nominal interest rate
- **City contribution PV: $167,890** (discounted 25 years at 7.25%)

### 3d. Calculate Annual City Payment
- Use annuity formula to calculate annual payment from present value
- **Annual city payment: $14,700/year** (for 25 years, grows to $965,415)

## Verification

**Location:** `PensionCalculatorService.calculateSystemCosts()` → verification section

We verify that:
1. Employee contributions FV + City contributions FV = Amount needed at retirement
2. This ensures 100% funding (within 80-120% range)

**Example:**
- Employee contributions FV: $285,210
- City contributions FV: $965,415
- **Total available: $1,250,625** ✓
- Amount needed: $1,250,625 ✓
- **Match!**

## Summary

✅ **Step 1:** Calculate lifetime benefit for each person (entire career)
✅ **Step 2:** Calculate amount needed at retirement (100% of lifetime benefits - full sum, no discounting)
✅ **Step 3:** Work backwards to calculate required contributions (employee + city)

**ACTUARIAL RULE:** We need 100% of expected lifetime benefits at retirement because investment returns won't outpace inflation during the payout phase. This conservative assumption ensures adequate funding.

