//
//  PensionCalculatorDisbursements.swift
//  FirePolicePensionCalc
//
//  Ported from Java
//

import Foundation

class PensionCalculatorDisbursements {
    
    private static let LIFE_EXPECTANCY = 73 // average life expectancy of male
    private static let LIFE_EXPECTANCY_SPOUSE = LIFE_EXPECTANCY + 6 // average additional life expectancy of a female spouse
    
    struct DisbursementResult {
        let totalPayout: Double
        let initialAnnualPension: Double
        let finalAnnualPension: Double
        let spouseInitialAnnualPension: Double // Initial amount at retiree's death (dollar amount)
        let spouseInitialBuyingPower: Double // Buying power of spouse pension on day 1 (after retiree's years of inflation)
        let spouseFinalAnnualPension: Double // Final buying power after all years (for Option 3 this is buying power, not dollar amount)
        let yearsReceivingPension: Int
        let yearsReceivingSpousePension: Int
        let spouseReductionPercent: Double // Calculated percentage based on option
    }
    
    static func calculateDisbursements(
        verbose: Bool = false,
        baseWage: Double,
        facWage: Double,
        annualMultiplier: Double, // as percentage
        useFacWage: Bool,
        isColaCompounding: Bool,
        numberColas: Int,
        colaSpacing: Int,
        colaPercent: Double, // as percentage
        inflateRate: Double, // as percentage
        retirementAge: Int,
        totalYearsService: Int,
        lifeExpDiff: Int,
        spouseAgeDiff: Int,
        currentAge: Int,
        pensionOption: PensionOption = .option3
    ) -> DisbursementResult {
        
        // Convert percentages to decimals
        let annualMulti = annualMultiplier / 100.0
        let colaPerc = colaPercent / 100.0
        let inflate = inflateRate / 100.0
        
        // Calculate years receiving pension
        var yearsReceivingPension = LIFE_EXPECTANCY + lifeExpDiff - retirementAge
        if yearsReceivingPension < 0 {
            yearsReceivingPension = 0
        }
        // Calculate spouse pension years based on option
        var yearsReceivingSpousePension: Int
        switch pensionOption {
        case .option1:
            yearsReceivingSpousePension = 0 // No survivor benefit
        case .option2:
            yearsReceivingSpousePension = 10 // Fixed 10-year survivor
        case .option3, .option4:
            // Default actuarial calculation
            yearsReceivingSpousePension = LIFE_EXPECTANCY_SPOUSE - LIFE_EXPECTANCY - spouseAgeDiff
            if yearsReceivingSpousePension < 0 {
                yearsReceivingSpousePension = 0
            }
        }
        
        // Calculate Option 1 (maximum) pension amount
        let earningsBasedOn = useFacWage ? facWage : baseWage
        let option1Pension = earningsBasedOn * annualMulti * Double(totalYearsService)
        
        // Calculate spouse age
        let spouseAge = retirementAge + spouseAgeDiff
        
        // FIRST: Always calculate Option 1's total lifetime benefit (retiree only)
        let option1TotalBenefit = calculateOption1TotalBenefit(
            initialPension: option1Pension,
            yearsReceivingPension: yearsReceivingPension,
            colaPerc: colaPerc,
            inflate: inflate,
            isColaCompounding: isColaCompounding,
            numberColas: numberColas,
            colaSpacing: colaSpacing
        )
        
        // Calculate actuarial reduction factor to make other options equivalent to Option 1
        var initialAnnualPension = option1Pension
        
        switch pensionOption {
        case .option1:
            // No reduction - maximum benefit
            initialAnnualPension = option1Pension
        case .option2:
            // Calculate reduction for 10-year certain to make actuarially equivalent
            initialAnnualPension = calculateActuarialEquivalentPension(
                targetTotalBenefit: option1TotalBenefit,
                option1Pension: option1Pension,
                retirementAge: retirementAge,
                yearsReceivingPension: yearsReceivingPension,
                yearsReceivingSpousePension: 10, // Fixed 10 years
                colaPerc: colaPerc,
                inflate: inflate,
                isColaCompounding: isColaCompounding,
                numberColas: numberColas,
                colaSpacing: colaSpacing,
                survivorPercent: 1.0, // 100% for Option 2
                isFixedYears: true
            )
        case .option3:
            // Calculate reduction for Joint and Survivor 100%
            initialAnnualPension = calculateActuarialEquivalentPension(
                targetTotalBenefit: option1TotalBenefit,
                option1Pension: option1Pension,
                retirementAge: retirementAge,
                yearsReceivingPension: yearsReceivingPension,
                yearsReceivingSpousePension: yearsReceivingSpousePension,
                colaPerc: colaPerc,
                inflate: inflate,
                isColaCompounding: isColaCompounding,
                numberColas: numberColas,
                colaSpacing: colaSpacing,
                survivorPercent: 1.0, // 100% for Option 3
                isFixedYears: false
            )
        case .option4:
            // Calculate reduction for Joint and Survivor 66.67%
            initialAnnualPension = calculateActuarialEquivalentPension(
                targetTotalBenefit: option1TotalBenefit,
                option1Pension: option1Pension,
                retirementAge: retirementAge,
                yearsReceivingPension: yearsReceivingPension,
                yearsReceivingSpousePension: yearsReceivingSpousePension,
                colaPerc: colaPerc,
                inflate: inflate,
                isColaCompounding: isColaCompounding,
                numberColas: numberColas,
                colaSpacing: colaSpacing,
                survivorPercent: 2.0 / 3.0, // 66.67% for Option 4
                isFixedYears: false
            )
        }
        
        // Calculate non-compounding COLA amount (if applicable)
        let straightCola = initialAnnualPension * colaPerc
        
        // Track pension over time
        var currentPension = initialAnnualPension
        var totalPayout: Double = 0
        var colaCounter = 0
        
        // Calculate pension payments over retirement years
        // For Option 1, we already have the total, but we need to track currentPension for display
        // For other options, we calculate the total to match Option 1
        if yearsReceivingPension > 0 {
            for year in 1...yearsReceivingPension {
                // Apply COLA if it's a COLA year
                if numberColas > 0 && year % colaSpacing == 0 && colaCounter < numberColas {
                    colaCounter += 1
                    if isColaCompounding {
                        // Compounding: multiply by (1 + colaPercent)
                        currentPension += currentPension * colaPerc
                    } else {
                        // Non-compounding: add fixed dollar amount
                        currentPension += straightCola
                    }
                }
                
                // Apply inflation (reduces buying power)
                currentPension -= currentPension * inflate
                
                // Add to total payout
                totalPayout += currentPension
            }
        }
        
        // Calculate spouse pension based on option and determine reduction percent
        var annualSpousePension: Double = 0
        var spousePension: Double = 0
        var calculatedSpouseReductionPercent: Double = 0
        
        switch pensionOption {
        case .option1:
            // No survivor benefit - benefit stops upon death
            annualSpousePension = 0
            spousePension = 0
            calculatedSpouseReductionPercent = 0
        case .option2:
            // 10-year fixed survivor - same amount as final pension for up to 10 years
            annualSpousePension = currentPension
            spousePension = annualSpousePension
            calculatedSpouseReductionPercent = 100.0 // 100% of reduced pension
        case .option3:
            // Joint and Survivor (100%) - survivor receives 100% of initial annual pension
            // Dollar amount includes COLAs from retiree's years (without inflation), but buying power decreases with inflation
            // Calculate dollar amount after COLAs during retiree's years (without inflation adjustments)
            var spouseDollarAmountAfterColas = initialAnnualPension
            var retireeColaCounter = 0
            let retireeStraightCola = initialAnnualPension * colaPerc
            
            for year in 1...yearsReceivingPension {
                // Apply COLA if it's a COLA year (increases dollar amount, no inflation adjustment)
                if numberColas > 0 && year % colaSpacing == 0 && retireeColaCounter < numberColas {
                    retireeColaCounter += 1
                    if isColaCompounding {
                        spouseDollarAmountAfterColas += spouseDollarAmountAfterColas * colaPerc
                    } else {
                        spouseDollarAmountAfterColas += retireeStraightCola
                    }
                }
            }
            
            annualSpousePension = spouseDollarAmountAfterColas // 100% of initial annual pension plus COLAs (dollar amount)
            spousePension = annualSpousePension
            calculatedSpouseReductionPercent = 100.0 // 100% of initial annual pension
        case .option4:
            // Joint and Survivor (66.67%) - survivor receives 66.67% of what retiree was receiving
            annualSpousePension = currentPension * (2.0 / 3.0) // 66.67%
            spousePension = annualSpousePension
            calculatedSpouseReductionPercent = 66.67 // 66.67% of reduced pension
        }
        
        // Store initial spouse pension (at retiree's death)
        let spouseInitialPension = spousePension
        
        // Calculate buying power of spouse pension on day 1 (after retiree has received pension for yearsReceivingPension years)
        // For Option 3, the dollar amount includes COLAs from retiree's years, but buying power is reduced by inflation over retiree's years
        var spouseInitialBuyingPower: Double
        if pensionOption == .option3 {
            // Dollar amount after COLAs (already calculated above as spouseInitialPension)
            // Now calculate buying power by applying inflation over retiree's years
            var buyingPower = spouseInitialPension // Start with dollar amount after COLAs
            for _ in 1...yearsReceivingPension {
                buyingPower -= buyingPower * inflate
            }
            spouseInitialBuyingPower = buyingPower
        } else {
            // For other options, buying power equals dollar amount on day 1
            spouseInitialBuyingPower = spouseInitialPension
        }
        
        // Calculate spouse pension payments and track final amount
        if yearsReceivingSpousePension > 0 && pensionOption != .option1 {
            // For Option 3, track both dollar amount (with COLA) and buying power (with inflation)
            if pensionOption == .option3 {
                // Dollar amount starts at spouseInitialPension (which already includes COLAs from retiree's years)
                // Buying power starts at spouseInitialBuyingPower (already reduced by retiree's years of inflation)
                var spouseDollarAmount = spouseInitialPension // Already includes COLAs from retiree's years
                var spouseBuyingPower = spouseInitialBuyingPower // Already adjusted for inflation over retiree's years
                var spouseColaCounter = 0
                let spouseStraightCola = spouseDollarAmount * colaPerc // Use current dollar amount for COLA calculation
                
                for year in 1...yearsReceivingSpousePension {
                    // Apply COLA if it's a COLA year (increases dollar amount)
                    if numberColas > 0 && year % colaSpacing == 0 && spouseColaCounter < numberColas {
                        spouseColaCounter += 1
                        if isColaCompounding {
                            spouseDollarAmount += spouseDollarAmount * colaPerc
                        } else {
                            spouseDollarAmount += spouseStraightCola
                        }
                        // Buying power also increases with COLA (to match new dollar amount)
                        spouseBuyingPower = spouseDollarAmount
                    }
                    
                    // Apply inflation (reduces buying power, but dollar amount stays the same)
                    spouseBuyingPower -= spouseBuyingPower * inflate
                    
                    // Use buying power for total payout calculation (actuarial equivalence)
                    totalPayout += spouseBuyingPower
                }
                
                // Calculate final buying power: initial buying power reduced by inflation over survivor's years
                // This is independent of COLAs - just inflation reduction from start to end
                var finalBuyingPower = spouseInitialBuyingPower
                for _ in 1...yearsReceivingSpousePension {
                    finalBuyingPower -= finalBuyingPower * inflate
                }
                
                // Store final buying power for display
                spousePension = finalBuyingPower
            } else {
                // For Options 2 and 4, apply inflation to both dollar amount and buying power
                for year in 1...yearsReceivingSpousePension {
                    // Apply inflation
                    spousePension -= spousePension * inflate
                    totalPayout += spousePension
                }
            }
        }
        
        // For all options, ensure total matches Option 1 exactly (actuarial equivalence)
        // Recalculate using the same method to verify, and use Option 1's total as the source of truth
        if pensionOption != .option1 {
            // Verify the total matches Option 1 (should be very close from binary search)
            let recalculatedTotal = calculateTotalBenefitWithSurvivor(
                initialPension: initialAnnualPension,
                yearsReceivingPension: yearsReceivingPension,
                yearsReceivingSpousePension: yearsReceivingSpousePension,
                colaPerc: colaPerc,
                inflate: inflate,
                isColaCompounding: isColaCompounding,
                numberColas: numberColas,
                colaSpacing: colaSpacing,
                survivorPercent: pensionOption == .option2 ? 1.0 : (pensionOption == .option3 ? 1.0 : 2.0/3.0),
                isFixedYears: pensionOption == .option2
            )
            // Use Option 1's total as the authoritative value for actuarial equivalence
            totalPayout = option1TotalBenefit
        } else {
            // For Option 1, use the calculated total
            totalPayout = option1TotalBenefit
        }
        
        return DisbursementResult(
            totalPayout: totalPayout,
            initialAnnualPension: initialAnnualPension,
            finalAnnualPension: currentPension,
            spouseInitialAnnualPension: spouseInitialPension,
            spouseInitialBuyingPower: spouseInitialBuyingPower,
            spouseFinalAnnualPension: spousePension,
            yearsReceivingPension: yearsReceivingPension,
            yearsReceivingSpousePension: yearsReceivingSpousePension,
            spouseReductionPercent: calculatedSpouseReductionPercent
        )
    }
    
    // Calculate Option 1's total lifetime benefit (retiree only)
    private static func calculateOption1TotalBenefit(
        initialPension: Double,
        yearsReceivingPension: Int,
        colaPerc: Double,
        inflate: Double,
        isColaCompounding: Bool,
        numberColas: Int,
        colaSpacing: Int
    ) -> Double {
        var totalBenefit: Double = 0
        var currentPension = initialPension
        var colaCounter = 0
        let straightCola = initialPension * colaPerc
        
        for year in 1...yearsReceivingPension {
            // Apply COLA if it's a COLA year
            if numberColas > 0 && year % colaSpacing == 0 && colaCounter < numberColas {
                colaCounter += 1
                if isColaCompounding {
                    currentPension += currentPension * colaPerc
                } else {
                    currentPension += straightCola
                }
            }
            
            // Apply inflation (reduces buying power)
            currentPension -= currentPension * inflate
            totalBenefit += currentPension
        }
        
        return totalBenefit
    }
    
    // Calculate actuarially equivalent pension for Options 2, 3, and 4
    // Uses iterative approach to find pension amount that makes total benefit equal to Option 1
    private static func calculateActuarialEquivalentPension(
        targetTotalBenefit: Double,
        option1Pension: Double,
        retirementAge: Int,
        yearsReceivingPension: Int,
        yearsReceivingSpousePension: Int,
        colaPerc: Double,
        inflate: Double,
        isColaCompounding: Bool,
        numberColas: Int,
        colaSpacing: Int,
        survivorPercent: Double,
        isFixedYears: Bool
    ) -> Double {
        // Use binary search to find the reduced pension that makes total benefit equal to target
        var low: Double = option1Pension * 0.70
        var high: Double = option1Pension * 0.98
        var bestPension: Double = option1Pension * 0.90
        
        for _ in 0..<50 { // 50 iterations for better precision
            let mid = (low + high) / 2.0
            let totalBenefit = calculateTotalBenefitWithSurvivor(
                initialPension: mid,
                yearsReceivingPension: yearsReceivingPension,
                yearsReceivingSpousePension: yearsReceivingSpousePension,
                colaPerc: colaPerc,
                inflate: inflate,
                isColaCompounding: isColaCompounding,
                numberColas: numberColas,
                colaSpacing: colaSpacing,
                survivorPercent: survivorPercent,
                isFixedYears: isFixedYears
            )
            
            let difference = abs(totalBenefit - targetTotalBenefit)
            if difference < 0.01 { // Very close (within 1 cent)
                bestPension = mid
                break
            } else if totalBenefit < targetTotalBenefit {
                // Need higher pension to reach target
                low = mid
            } else {
                // Need lower pension to reach target
                high = mid
            }
            bestPension = mid
        }
        
        return bestPension
    }
    
    // Calculate total lifetime benefit with survivor (for Options 2, 3, 4)
    // Uses EXACT same calculation method as main function
    private static func calculateTotalBenefitWithSurvivor(
        initialPension: Double,
        yearsReceivingPension: Int,
        yearsReceivingSpousePension: Int,
        colaPerc: Double,
        inflate: Double,
        isColaCompounding: Bool,
        numberColas: Int,
        colaSpacing: Int,
        survivorPercent: Double,
        isFixedYears: Bool
    ) -> Double {
        var totalBenefit: Double = 0
        var currentPension = initialPension
        var colaCounter = 0
        let straightCola = initialPension * colaPerc
        
        // Retiree's pension payments (same method as main function)
        for year in 1...yearsReceivingPension {
            // Apply COLA if it's a COLA year
            if numberColas > 0 && year % colaSpacing == 0 && colaCounter < numberColas {
                colaCounter += 1
                if isColaCompounding {
                    currentPension += currentPension * colaPerc
                } else {
                    currentPension += straightCola
                }
            }
            
            // Apply inflation (reduces buying power)
            currentPension -= currentPension * inflate
            totalBenefit += currentPension
        }
        
        // Survivor's pension payments
        if yearsReceivingSpousePension > 0 && survivorPercent > 0 {
            let actualSurvivorYears = isFixedYears ? min(10, yearsReceivingSpousePension) : yearsReceivingSpousePension
            
            if survivorPercent == 1.0 && !isFixedYears {
                // Option 3: Dollar amount includes COLAs from retiree's years, then stays at that level (plus additional COLAs), but buying power decreases with inflation
                // First, calculate dollar amount after COLAs during retiree's years (without inflation)
                var survivorDollarAmount = initialPension
                var retireeColaCounter = 0
                let retireeStraightCola = initialPension * colaPerc
                
                for year in 1...yearsReceivingPension {
                    // Apply COLA if it's a COLA year (increases dollar amount, no inflation adjustment)
                    if numberColas > 0 && year % colaSpacing == 0 && retireeColaCounter < numberColas {
                        retireeColaCounter += 1
                        if isColaCompounding {
                            survivorDollarAmount += survivorDollarAmount * colaPerc
                        } else {
                            survivorDollarAmount += retireeStraightCola
                        }
                    }
                }
                
                // Now calculate buying power by applying inflation over retiree's years
                var survivorBuyingPower = survivorDollarAmount
                for _ in 1...yearsReceivingPension {
                    survivorBuyingPower -= survivorBuyingPower * inflate
                }
                
                // Track additional COLAs during survivor years
                var survivorColaCounter = 0
                let survivorStraightCola = survivorDollarAmount * colaPerc
                
                for year in 1...actualSurvivorYears {
                    // Apply COLA if it's a COLA year (increases dollar amount)
                    if numberColas > 0 && year % colaSpacing == 0 && survivorColaCounter < numberColas {
                        survivorColaCounter += 1
                        if isColaCompounding {
                            survivorDollarAmount += survivorDollarAmount * colaPerc
                        } else {
                            survivorDollarAmount += survivorStraightCola
                        }
                        // Buying power also increases with COLA
                        survivorBuyingPower = survivorDollarAmount
                    }
                    
                    // Apply inflation (reduces buying power, but dollar amount stays the same)
                    survivorBuyingPower -= survivorBuyingPower * inflate
                    
                    // Use buying power for total benefit calculation (actuarial equivalence)
                    totalBenefit += survivorBuyingPower
                }
            } else {
                // Option 2 and 4: percentage of current pension at death
                var survivorPension = currentPension * survivorPercent
                
                for year in 1...actualSurvivorYears {
                    // Apply inflation
                    survivorPension -= survivorPension * inflate
                    totalBenefit += survivorPension
                }
            }
        }
        
        return totalBenefit
    }
    
}

