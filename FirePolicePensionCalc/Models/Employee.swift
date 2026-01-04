//
//  Employee.swift
//  FirePolicePensionCalc
//
//  Created from Java port
//

import Foundation

enum Sex: String, Codable {
    case male = "M"
    case female = "F"
}

struct Employee: Codable, Identifiable {
    let id: Int
    let name: String
    let hiredYear: Int
    let dateOfBirth: Int
    let spouseDateOfBirth: Int
    let sex: Sex
    let spouseSex: Sex?
    
    enum CodingKeys: String, CodingKey {
        case id, name, hiredYear, dateOfBirth, spouseDateOfBirth, sex, spouseSex
    }
    
    init(id: Int, name: String, hiredYear: Int, dateOfBirth: Int, spouseDateOfBirth: Int, sex: Sex = .male, spouseSex: Sex? = nil) {
        self.id = id
        self.name = name
        self.hiredYear = hiredYear
        self.dateOfBirth = dateOfBirth
        self.spouseDateOfBirth = spouseDateOfBirth
        self.sex = sex
        // If spouseDateOfBirth is 0 (no spouse), spouseSex should be nil
        // Otherwise default to female if not specified
        self.spouseSex = spouseDateOfBirth > 0 ? (spouseSex ?? .female) : nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        hiredYear = try container.decode(Int.self, forKey: .hiredYear)
        dateOfBirth = try container.decode(Int.self, forKey: .dateOfBirth)
        spouseDateOfBirth = try container.decode(Int.self, forKey: .spouseDateOfBirth)
        // Default to male if sex field is missing (backward compatibility)
        sex = (try? container.decode(Sex.self, forKey: .sex)) ?? .male
        // Default to female if spouseSex is missing and there is a spouse, nil if no spouse
        if spouseDateOfBirth > 0 {
            spouseSex = (try? container.decode(Sex.self, forKey: .spouseSex)) ?? .female
        } else {
            spouseSex = nil
        }
    }
    
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
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(hiredYear, forKey: .hiredYear)
        try container.encode(dateOfBirth, forKey: .dateOfBirth)
        try container.encode(spouseDateOfBirth, forKey: .spouseDateOfBirth)
        try container.encode(sex, forKey: .sex)
        // Only encode spouseSex if there is a spouse
        if spouseDateOfBirth > 0, let spouseSex = spouseSex {
            try container.encode(spouseSex, forKey: .spouseSex)
        }
    }
}

