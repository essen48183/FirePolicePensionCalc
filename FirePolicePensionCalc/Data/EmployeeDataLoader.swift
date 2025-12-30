//
//  EmployeeDataLoader.swift
//  FirePolicePensionCalc
//
//  Loads employee data from JSON file
//

import Foundation

class EmployeeDataLoader {
    
    private static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private static var employeesFileURL: URL {
        documentsURL.appendingPathComponent("employees.json")
    }
    
    static func loadEmployees() -> [Employee] {
        // First try to load from Documents directory (user-edited version)
        if FileManager.default.fileExists(atPath: employeesFileURL.path) {
            do {
                let data = try Data(contentsOf: employeesFileURL)
                let decoder = JSONDecoder()
                let employees = try decoder.decode([Employee].self, from: data)
                return employees
            } catch {
                print("Error loading employees from Documents: \(error)")
            }
        }
        
        // Fall back to bundle (original file)
        guard let bundleURL = Bundle.main.url(forResource: "employees", withExtension: "json") else {
            print("Warning: employees.json not found in bundle, returning empty array")
            return []
        }
        
        do {
            let data = try Data(contentsOf: bundleURL)
            let decoder = JSONDecoder()
            let employees = try decoder.decode([Employee].self, from: data)
            // Copy to Documents directory for future edits
            try saveEmployees(employees)
            return employees
        } catch {
            print("Error loading employees: \(error)")
            return []
        }
    }
    
    static func saveEmployees(_ employees: [Employee]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(employees)
        try data.write(to: employeesFileURL, options: .atomic)
    }
}

