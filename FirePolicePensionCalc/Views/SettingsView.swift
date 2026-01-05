//
//  SettingsView.swift
//  FirePolicePensionCalc
//
//  Settings view for the application
//

import SwiftUI
import UIKit
import ObjectiveC

struct SettingsView: View {
    @ObservedObject var viewModel: PensionCalculatorViewModel
    @State private var showClearEmployeesConfirmation = false
    @State private var showResetConfigConfirmation = false
    @State private var showDocumentPicker = false
    @State private var showExportSuccess = false
    @State private var showRestoreSuccess = false
    @State private var showRestoreError = false
    @State private var restoreErrorMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                // Backup Section
                Section(header: Text("Backup Employees")) {
                    Text("Save a backup of your employee list to a file.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        exportEmployees()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Backup Employees")
                                .font(.system(.body, design: .default).weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                }
                
                // Restore Section
                Section(header: Text("Restore Employees")) {
                    Text("Restore your employee list from a previously saved backup file.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showDocumentPicker = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Restore Employees")
                                .font(.system(.body, design: .default).weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                }
                
                // Clear Employees Section
                Section(header: Text("Clear Employees")) {
                    Text("Remove all employees from the list. This will not affect your configuration settings.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showClearEmployeesConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Clear All Employees")
                                .font(.system(.body, design: .default).weight(.semibold))
                            Spacer()
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                }
                
                // Reset Configuration Section
                Section(header: Text("Reset Configuration")) {
                    Text("Reset all configuration values to their default settings. This will not affect your employee list.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showResetConfigConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Reset Configuration to Defaults")
                                .font(.system(.body, design: .default).weight(.semibold))
                            Spacer()
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("Clear All Employees?", isPresented: $showClearEmployeesConfirmation) {
            Button("Clear", role: .destructive) {
                clearAllEmployees()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove all employees from the list. Your configuration settings will not be affected.")
        }
        .alert("Reset Configuration to Defaults?", isPresented: $showResetConfigConfirmation) {
            Button("Reset", role: .destructive) {
                resetConfigurationToDefaults()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset all configuration values to their default settings. Your employee list will not be affected.")
        }
        .alert("Backup Successful", isPresented: $showExportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Employee list has been exported. Use the share sheet to save it to your desired location.")
        }
        .alert("Restore Successful", isPresented: $showRestoreSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Employee list has been restored from backup.")
        }
        .alert("Restore Error", isPresented: $showRestoreError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreErrorMessage)
        }
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.commaSeparatedText, .json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    // Access the file
                    _ = url.startAccessingSecurityScopedResource()
                    defer {
                        url.stopAccessingSecurityScopedResource()
                    }
                    importEmployees(from: url)
                }
            case .failure(let error):
                restoreErrorMessage = "Error selecting file: \(error.localizedDescription)"
                showRestoreError = true
            }
        }
    }
    
    private func exportEmployees() {
        // Check if there are employees to export
        guard !viewModel.employees.isEmpty else {
            restoreErrorMessage = "No employees to export. Please add employees first."
            showRestoreError = true
            return
        }
        
        do {
            // Generate CSV content
            var csv = "id,name,hiredYear,dateOfBirth,spouseDateOfBirth,sex,spouseSex\n"
            
            for employee in viewModel.employees {
                let id = String(employee.id)
                let name = escapeCSVField(employee.name)
                let hiredYear = String(employee.hiredYear)
                let dateOfBirth = String(employee.dateOfBirth)
                let spouseDateOfBirth = String(employee.spouseDateOfBirth)
                let sex = employee.sex.rawValue
                let spouseSex = employee.spouseSex?.rawValue ?? ""
                
                csv += "\(id),\(name),\(hiredYear),\(dateOfBirth),\(spouseDateOfBirth),\(sex),\(spouseSex)\n"
            }
            
            // Create a temporary file with a readable name
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
            let fileName = "employees_backup_\(dateFormatter.string(from: Date())).csv"
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(fileName)
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            
            // Verify file was created and is accessible
            guard FileManager.default.fileExists(atPath: tempURL.path) else {
                restoreErrorMessage = "Error: File was not created successfully."
                showRestoreError = true
                return
            }
            
            // Present share sheet directly using UIKit
            presentShareSheet(with: tempURL)
        } catch {
            print("Error exporting employees: \(error)")
            restoreErrorMessage = "Error exporting employees: \(error.localizedDescription)"
            showRestoreError = true
        }
    }
    
    private func presentShareSheet(with url: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            restoreErrorMessage = "Error: Could not find view controller to present share sheet."
            showRestoreError = true
            return
        }
        
        // Find the topmost view controller
        var topViewController = rootViewController
        while let presented = topViewController.presentedViewController {
            topViewController = presented
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        // Configure for iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = topViewController.view
            popover.sourceRect = CGRect(x: topViewController.view.bounds.midX,
                                      y: topViewController.view.bounds.midY,
                                      width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Set completion handler
        activityViewController.completionWithItemsHandler = { _, completed, _, error in
            // Clean up temporary file after sharing
            try? FileManager.default.removeItem(at: url)
            if completed {
                DispatchQueue.main.async {
                    self.showExportSuccess = true
                }
            }
        }
        
        // Present the share sheet
        topViewController.present(activityViewController, animated: true)
    }
    
    private func importEmployees(from url: URL) {
        // Determine file type based on extension
        let fileExtension = url.pathExtension.lowercased()
        let isCSV = fileExtension == "csv" || fileExtension == "txt"
        let isJSON = fileExtension == "json"
        
        var csvError: Error?
        
        do {
            if isCSV || (!isJSON && !isCSV) {
                // Try CSV first (or if extension is unknown, try CSV first)
                let csvString = try String(contentsOf: url, encoding: .utf8)
                let importedEmployees = try parseCSV(csvString)
                
                // Validate employees
                guard !importedEmployees.isEmpty else {
                    restoreErrorMessage = "The CSV file is empty or contains no valid employee data."
                    showRestoreError = true
                    return
                }
                
                // Replace current employees with imported ones
                viewModel.employees = importedEmployees
                viewModel.config.totalNumberEmployees = importedEmployees.count
                
                // Save to persistent storage
                try EmployeeDataLoader.saveEmployees(importedEmployees)
                
                showRestoreSuccess = true
                return
            }
        } catch {
            csvError = error
            // If CSV parsing failed and file is explicitly CSV, show error
            if isCSV {
                restoreErrorMessage = "Error parsing CSV file: \(error.localizedDescription)\n\nPlease ensure the file is a valid CSV file with the correct format."
                showRestoreError = true
                return
            }
            // Otherwise, try JSON as fallback
        }
        
        // Try JSON (either explicitly JSON or as fallback)
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let importedEmployees = try decoder.decode([Employee].self, from: data)
            
            guard !importedEmployees.isEmpty else {
                restoreErrorMessage = "The JSON file is empty or contains no valid employee data."
                showRestoreError = true
                return
            }
            
            viewModel.employees = importedEmployees
            viewModel.config.totalNumberEmployees = importedEmployees.count
            try EmployeeDataLoader.saveEmployees(importedEmployees)
            showRestoreSuccess = true
        } catch let jsonError {
            if isJSON {
                restoreErrorMessage = "Error parsing JSON file: \(jsonError.localizedDescription)\n\nPlease ensure the file is a valid JSON file."
            } else {
                let csvErrorMsg = csvError?.localizedDescription ?? "Unknown error"
                restoreErrorMessage = "Error importing file: Could not parse as CSV or JSON.\n\nCSV error: \(csvErrorMsg)\nJSON error: \(jsonError.localizedDescription)"
            }
            showRestoreError = true
        }
    }
    
    // MARK: - CSV Helper Methods
    
    private func parseCSV(_ csvString: String) throws -> [Employee] {
        let lines = csvString.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw NSError(domain: "SettingsView", code: 1, userInfo: [NSLocalizedDescriptionKey: "CSV file is empty"])
        }
        
        // Parse header
        let header = parseCSVLine(lines[0])
        guard header.count >= 6 else {
            throw NSError(domain: "SettingsView", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid CSV header: Expected at least 6 columns, found \(header.count)"])
        }
        
        // Find column indices (case-insensitive)
        let headerLower = header.map { $0.lowercased() }
        let idIndex = headerLower.firstIndex(of: "id") ?? 0
        let nameIndex = headerLower.firstIndex(of: "name") ?? 1
        let hiredYearIndex = headerLower.firstIndex(of: "hiredyear") ?? 2
        let dateOfBirthIndex = headerLower.firstIndex(of: "dateofbirth") ?? 3
        let spouseDateOfBirthIndex = headerLower.firstIndex(of: "spousedateofbirth") ?? 4
        let sexIndex = headerLower.firstIndex(of: "sex") ?? 5
        let spouseSexIndex = headerLower.firstIndex(of: "spousesex")
        
        var employees: [Employee] = []
        var nextId = 1
        var rowNumber = 0
        
        // Parse data rows
        for (index, line) in lines.enumerated() {
            if index == 0 { continue } // Skip header
            
            rowNumber = index
            let columns = parseCSVLine(line)
            
            // Skip rows that don't have enough columns
            guard columns.count >= 6 else {
                print("Warning: Row \(rowNumber) has only \(columns.count) columns, skipping")
                continue
            }
            
            // Parse ID
            let id: Int
            if let parsedId = Int(columns[idIndex].trimmingCharacters(in: .whitespacesAndNewlines)) {
                id = parsedId
                nextId = max(nextId, id + 1)
            } else {
                id = nextId
                nextId += 1
            }
            
            // Parse name (required)
            let name = columns[nameIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else {
                print("Warning: Row \(rowNumber) has empty name, skipping")
                continue
            }
            
            // Parse numeric fields
            let hiredYear = Int(columns[hiredYearIndex].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            let dateOfBirth = Int(columns[dateOfBirthIndex].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            let spouseDateOfBirth = Int(columns[spouseDateOfBirthIndex].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            
            // Parse sex (case-insensitive, handles M/MALE/Male and F/FEMALE/Female)
            let sexString = columns[sexIndex].trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let sex: Sex = (sexString == "F" || sexString == "FEMALE") ? .female : .male
            
            // Parse spouse sex (optional)
            var spouseSex: Sex? = nil
            if let spouseSexIndex = spouseSexIndex, spouseSexIndex < columns.count {
                let spouseSexString = columns[spouseSexIndex].trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                if !spouseSexString.isEmpty && spouseDateOfBirth > 0 {
                    spouseSex = (spouseSexString == "M" || spouseSexString == "MALE") ? .male : .female
                }
            }
            
            let employee = Employee(
                id: id,
                name: name,
                hiredYear: hiredYear,
                dateOfBirth: dateOfBirth,
                spouseDateOfBirth: spouseDateOfBirth,
                sex: sex,
                spouseSex: spouseSex
            )
            employees.append(employee)
        }
        
        guard !employees.isEmpty else {
            throw NSError(domain: "SettingsView", code: 3, userInfo: [NSLocalizedDescriptionKey: "No valid employee data found in CSV file"])
        }
        
        return employees
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current) // Add last field
        
        return result.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
    }
    
    private func escapeCSVField(_ field: String) -> String {
        // If field contains comma, quote, or newline, wrap in quotes and escape quotes
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
    
    private func clearAllEmployees() {
        // Clear all employees
        viewModel.clearAllEmployees()
    }
    
    private func resetConfigurationToDefaults() {
        // Reset configuration to defaults only
        viewModel.loadDefaultConfiguration()
    }
}

