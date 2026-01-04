//
//  ComparisonPersistence.swift
//  FirePolicePensionCalc
//
//  Handles persistence of comparison basis data
//

import Foundation

class ComparisonPersistence {
    private static let comparisonDataKey = "comparisonBasisData"
    
    static func save(_ comparisonData: ComparisonData) {
        if let encoded = try? JSONEncoder().encode(comparisonData) {
            UserDefaults.standard.set(encoded, forKey: comparisonDataKey)
        }
    }
    
    static func load() -> ComparisonData? {
        guard let data = UserDefaults.standard.data(forKey: comparisonDataKey),
              let comparisonData = try? JSONDecoder().decode(ComparisonData.self, from: data) else {
            return nil
        }
        return comparisonData
    }
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: comparisonDataKey)
    }
    
    static func hasComparisonData() -> Bool {
        return UserDefaults.standard.data(forKey: comparisonDataKey) != nil
    }
}

