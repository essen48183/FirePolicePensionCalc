# Actuarial Rule: 100% Funding at Retirement

## Rule Statement

**We must plan to have 100% of the expected lifetime benefits at retirement time. Once a person is retired, we cannot expect investment returns to outpace inflation.**

## Implementation

### During Accumulation Phase (Before Retirement)
- **Expected Return Rate (7.25%)** is used for:
  - Future value of employee contributions (annuity formula)
  - Future value of city contributions (annuity formula)
  - Discounting city contributions back to today

### During Payout Phase (After Retirement)
- **No discounting is applied** - we need the full sum of all payments
- **Formula:** `Amount Needed = Annual Payment × Years Retired`
- **Reason:** Investment returns won't outpace inflation during retirement

## Calculation Impact

### Previous Approach (PV of Annuity)
```
Amount Needed = PMT × ((1 - (1 + r)^-n) / r)
```
This assumed the fund would earn interest (7.25%) while paying out, so less was needed.

**Example:**
- Annual pension: $54,375
- Years retired: 23
- Interest rate: 7.25%
- **Amount needed: $600,057** (PV of annuity)

### New Approach (100% Funding)
```
Amount Needed = PMT × n
```
This assumes no investment growth during retirement, so we need the full sum.

**Example:**
- Annual pension: $54,375
- Years retired: 23
- **Amount needed: $1,250,625** (full sum)

## Why This Rule?

1. **Conservative Assumption:** Ensures adequate funding even if investment returns are poor during retirement
2. **Inflation Protection:** Accounts for the fact that returns may not outpace inflation
3. **Risk Management:** Reduces the risk of underfunding the pension system

## Impact on Contributions

This rule significantly increases the amount needed at retirement, which means:
- **Higher city contributions required** (to reach the larger amount needed)
- **More conservative funding** (ensures 100% funding even in worst-case scenarios)
- **Better protection** for retirees and the pension system

## Code Location

**Function:** `PensionCalculatorPaymentsInto.presentValueOfAnnuityWithInflation()`

**Previous Implementation:**
```swift
// Standard annuity formula: PV = PMT * ((1 - (1 + r)^-n) / r)
let discountFactor = pow(1 + r, Double(-years))
let annuityFactor = (1 - discountFactor) / r
return initialAnnualPayment * annuityFactor
```

**New Implementation:**
```swift
// ACTUARIAL RULE: During retirement, investment returns won't outpace inflation
// Therefore, we need the full sum of all payments at retirement (no discounting)
return initialAnnualPayment * Double(years)
```

## Verification

The verification calculations in `PensionCalculatorService` use the same rule:
- `totalNeededAtRetirement` = sum of all payments (no discounting)
- `totalAvailableAtRetirement` = employee FV + city FV (using expected return during accumulation)
- System ensures: `totalAvailableAtRetirement >= totalNeededAtRetirement`

This ensures 100% funding at retirement time.

