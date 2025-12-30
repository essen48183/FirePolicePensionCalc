//
//  Employee.swift
//  FirePolicePensionCalc
//
//  Created from Java port
//

import Foundation

struct Employee: Codable, Identifiable {
    let id: Int
    let name: String
    let hiredYear: Int
    let dateOfBirth: Int
    let spouseDateOfBirth: Int
    
    var currentAge: Int {
        Calendar.current.component(.year, from: Date()) - dateOfBirth
    }
    
    var spouseCurrentAge: Int {
        guard spouseDateOfBirth > 0 else { return 0 }
        return Calendar.current.component(.year, from: Date()) - spouseDateOfBirth
    }
    
    var spouseAgeDiff: Int {
        guard spouseDateOfBirth > 0 else { return 6 } // Return 6 so that yearsReceivingSpousePension = 0 when no spouse
        return spouseCurrentAge - currentAge
    }
    
    var hiredAge: Int {
        hiredYear - dateOfBirth
    }
    
    var hasSpouse: Bool {
        spouseDateOfBirth > 0
    }
}

