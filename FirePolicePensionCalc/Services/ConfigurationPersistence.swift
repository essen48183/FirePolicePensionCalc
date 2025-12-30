//
//  ConfigurationPersistence.swift
//  FirePolicePensionCalc
//
//  Handles saving and loading configuration from UserDefaults
//

import Foundation

class ConfigurationPersistence {
    private static let configurationKey = "savedPensionConfiguration"
    
    static func save(_ configuration: PensionConfiguration) {
        if let encoded = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(encoded, forKey: configurationKey)
        }
    }
    
    static func load() -> PensionConfiguration? {
        guard let data = UserDefaults.standard.data(forKey: configurationKey),
              let configuration = try? JSONDecoder().decode(PensionConfiguration.self, from: data) else {
            return nil
        }
        return configuration
    }
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: configurationKey)
    }
}

