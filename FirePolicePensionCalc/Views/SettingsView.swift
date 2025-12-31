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
            allowedContentTypes: [.json],
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
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(viewModel.employees)
            
            // Create a temporary file with a readable name
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
            let fileName = "employees_backup_\(dateFormatter.string(from: Date())).json"
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(fileName)
            try data.write(to: tempURL)
            
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
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let importedEmployees = try decoder.decode([Employee].self, from: data)
            
            // Validate employees
            guard !importedEmployees.isEmpty else {
                restoreErrorMessage = "The backup file is empty."
                showRestoreError = true
                return
            }
            
            // Replace current employees with imported ones
            viewModel.employees = importedEmployees
            viewModel.config.totalNumberEmployees = importedEmployees.count
            
            // Save to persistent storage
            try EmployeeDataLoader.saveEmployees(importedEmployees)
            
            showRestoreSuccess = true
        } catch {
            restoreErrorMessage = "Error importing employees: \(error.localizedDescription)"
            showRestoreError = true
        }
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

