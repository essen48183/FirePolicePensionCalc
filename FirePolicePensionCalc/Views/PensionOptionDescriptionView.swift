//
//  PensionOptionDescriptionView.swift
//  FirePolicePensionCalc
//
//  View for displaying pension option descriptions
//

import SwiftUI

struct PensionOptionDescriptionView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Pension Option Descriptions")
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        OptionDescription(
                            title: "Option 1: Maximum Monthly Benefit",
                            description: "The maximum monthly benefit payable to you for your lifetime. Upon your death, the monthly benefit will stop, and your beneficiary will receive only a refund of any contributions you paid which are in excess of the amount you received in benefits. This option does not provide a continuing benefit to your beneficiary. If you are married and select Option 1, your spouse must acknowledge your selection.\n\nThe Option 1 benefit provides the largest monthly amount for which you are eligible, but provides no continuing benefit upon your death. You may consider selecting Option 1 if you have no spouse or eligible joint annuitant dependent upon support from you; or if your spouse or joint annuitant is in ill health or otherwise expected to die before you; or if your spouse or joint annuitant has independent sources of income and is not in need of additional continuing support from you upon your death.\n\nYou might not want to choose Option 1 if you are in ill health and your future physical condition is uncertain."
                        )
                        
                        OptionDescription(
                            title: "Option 2: Ten Year Certain",
                            description: "A monthly benefit that is less than the Option 1 benefit, and the benefit is payable to you for your lifetime. In the event you die within ten years after your retirement date, including any period of DROP participation, the same monthly benefit will be paid to your designated beneficiary for the balance of the 10-year period. No further benefits are then payable. If you are married and select Option 2, your spouse must acknowledge your selection. The amount of reduction of the Option 2 benefit depends on your age only---the older you are, the larger the reduction.\n\nIf you have no spouse or eligible joint annuitant to be the recipient of a continuing benefit under Option 3 or 4 after your death, you may consider selecting Option 2 in order to provide a monthly payment to your beneficiary for the remainder of the 10-year period if you should die before you have been retired for 10 years. You may name contingent beneficiaries to receive any benefits that are to be paid after the death of your primary beneficiary. This option would be particularly appropriate if you are in ill health and your future physical condition is uncertain at the time of retirement since children, other heirs, charities, organizations, or your estate or trust can be designated as beneficiaries for Option 2."
                        )
                        
                        OptionDescription(
                            title: "Option 3: Joint and Survivor (100%)",
                            description: "A reduced monthly benefit payable for your lifetime. Upon your death, your joint annuitant, if living, will receive a lifetime monthly benefit payment in the same amount as you were receiving. [Exception: The benefit paid to a joint annuitant under age 25, who is not your spouse, will be your Option 1 benefit amount. The benefit will stop when your joint annuitant reaches age 25, unless disabled and incapable of self-support, in which case the benefit will continue for the duration of the disability.] No further benefits are payable after both you and your joint annuitant(s) are deceased. The amount of reduction of the Option 3 benefit depends on your age and the age of your joint annuitant(s).\n\nIf you wish to have the security of a lifetime benefit for yourself and to provide a continuing benefit of the same amount to your joint annuitant(s) after your death, you may consider selecting Option 3."
                        )
                        
                        OptionDescription(
                            title: "Option 4: Joint and Survivor (66.67%)",
                            description: "An adjusted monthly benefit payable to you while both you and your joint annuitant are living. Upon the death of either you or your joint annuitant, the monthly benefit payable to the survivor is reduced to two-thirds (66.67%) of the monthly benefit received when both are living. [Exception: The benefit paid to a joint annuitant under age 25, who is not your spouse, will be your Option 1 benefit amount. The benefit will stop when your joint annuitant reaches age 25, unless disabled and incapable of self-support, in which case the benefit will continue for the duration of the disability.] No further benefits are payable after both you and your joint annuitant are deceased. The amount of reduction of the Option 4 benefit depends on your age and the age of your joint annuitant.\n\nIf you anticipate the need for a larger benefit while both you and your joint annuitant are living and a smaller benefit when only one of you survives, you may consider selecting Option 4.",
                            isDisabled: true
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Pension Options")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct OptionDescription: View {
    let title: String
    let description: String
    var isDisabled: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(isDisabled ? .secondary : .primary)
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isDisabled ? Color(.systemGray5) : Color(.systemGray6))
        .cornerRadius(10)
    }
}

