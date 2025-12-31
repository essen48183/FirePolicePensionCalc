//
//  SystemInformationView.swift
//  FirePolicePensionCalc
//
//  Information view explaining the open/closed pension system
//

import SwiftUI

struct SystemInformationView: View {
    @ObservedObject var viewModel: PensionCalculatorViewModel
    @State private var showResetConfirmation = false
    @State private var showEmployeeEntry = false
    @State private var showDocumentPicker = false
    @State private var showExportSuccess = false
    @State private var showRestoreSuccess = false
    @State private var showRestoreError = false
    @State private var restoreErrorMessage = ""
    @State private var newEmployee = EditableEmployee(
        id: 1,
        name: "",
        hiredYear: Calendar.current.component(.year, from: Date()),
        dateOfBirth: Calendar.current.component(.year, from: Date()) - 30,
        spouseDateOfBirth: 0
    )
    
    init(viewModel: PensionCalculatorViewModel? = nil) {
        // Allow optional viewModel for preview
        if let vm = viewModel {
            _viewModel = ObservedObject(wrappedValue: vm)
        } else {
            // Create a dummy viewModel for preview
            _viewModel = ObservedObject(wrappedValue: PensionCalculatorViewModel())
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pension System Information")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Understanding Open/Closed Pension Systems")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                    
                    // Main Explanation
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How Pension Systems Work")
                            .font(.title3)
                            .bold()
                        
                        Text("Pension systems are typically **open and closed**, meaning they have both:")
                            .font(.body)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Active Employees")
                                        .font(.headline)
                                    Text("Currently working and contributing to the system")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "person.fill.checkmark")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Retired Employees")
                                        .font(.headline)
                                    Text("Already retired and receiving pension payments from funds accumulated during their working years")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.leading, 8)
                    }
                    
                    Divider()
                    
                    // What This Calculator Does
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What This Calculator Covers")
                            .font(.title3)
                            .bold()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("System-Wide Results")
                                        .font(.headline)
                                    Text("Calculations based on the **editable employee list** shown in the System Results tab. Each employee's actual hire date, current age, and spouse age difference are used for individual calculations that are then aggregated.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "person.circle")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Individual Calculation (Fictional Employee)")
                                        .font(.headline)
                                    Text("A separate calculation for a fictional new hire with configurable parameters. This is **NOT** used for system-wide results. It's only for individual planning and 'what-if' scenarios.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.leading, 8)
                    }
                    
                    Divider()
                    
                    // Important Note about Data Sources
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Important: System Results Data Source")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                Text("The **System Results** calculations come from the employee list that appears below the system-wide totals. You can edit this list using the 'Edit' button in the System Results tab.")
                                    .font(.body)
                                
                                Text("The fictional employee used in the **Individual Calculation** tab (with its own age, hire date, and spouse age) is **separate** and does not affect system-wide results.")
                                    .font(.body)
                                    .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Divider()
                    
                    // Important Disclaimer
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Important: Past Retirees Not Included")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                
                                Text("This calculator **does not include** employees who have already retired. Past retirees are already receiving pension payments from funds that were accumulated and invested during their working years.")
                                    .font(.body)
                                
                                Text("Any surplus or shortfall from past retirees (due to investment performance, changes in assumptions, or other factors) would be **in addition to** the annual system-wide contribution requirements calculated here.")
                                    .font(.body)
                                    .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Divider()
                    
                    // System Funding
                    VStack(alignment: .leading, spacing: 16) {
                        Text("System Funding")
                            .font(.title3)
                            .bold()
                        
                        Text("The annual city contribution calculated by this system represents the amount needed to fund:")
                            .font(.body)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Current active employees' future retirement benefits")
                            Text("• Future employees' retirement benefits (based on assumptions)")
                            Text("• 100% funding at retirement time for all active and future employees")
                        }
                        .font(.body)
                        .padding(.leading, 8)
                        
                        Text("**Note:** Any existing surplus or shortfall from past retirees must be accounted for separately in the overall pension system budget.")
                            .font(.body)
                            .padding(.top, 8)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Backup/Restore Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Backup & Restore Employees")
                            .font(.title3)
                            .bold()
                        
                        Text("Save a backup of your employee list or restore from a previously saved backup file.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
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
                        }
                    }
                    
                    Divider()
                    
                    // Reset Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reset to Defaults")
                            .font(.title3)
                            .bold()
                        
                        Text("Reset all configuration values to defaults and clear all employees. You will be prompted to add one employee with minimum required information.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showResetConfirmation = true
                        }) {
                            HStack {
                                Spacer()
                                Text("Reset All Values to Defaults")
                                    .font(.system(.body, design: .default).weight(.semibold))
                                Spacer()
                            }
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("System Information")
            .navigationBarTitleDisplayMode(.large)
            .alert("Reset All Values?", isPresented: $showResetConfirmation) {
                Button("Reset", role: .destructive) {
                    resetToDefaults()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will reset all configuration to defaults and clear all employees. You will then be asked to add one employee. restoring a backup will overrite this single employee")
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
                        importEmployees(from: url)
                        url.stopAccessingSecurityScopedResource()
                    }
                case .failure(let error):
                    restoreErrorMessage = "Error selecting file: \(error.localizedDescription)"
                    showRestoreError = true
                }
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
            .sheet(isPresented: $showEmployeeEntry) {
                NavigationView {
                    VStack(spacing: 20) {
                        Text("Add Initial Employee")
                            .font(.title2)
                            .bold()
                            .padding(.top)
                        
                        Text("Please enter the minimum required information for the first employee:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        EmployeeEntryCard(employee: $newEmployee)
                            .padding()
                        
                        Spacer()
                        
                        Button(action: {
                            saveInitialEmployee()
                        }) {
                            HStack {
                                Spacer()
                                Text("Save Employee")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding()
                            .background(newEmployee.name.isEmpty || newEmployee.hiredYear <= 0 || newEmployee.dateOfBirth <= 0 ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(newEmployee.name.isEmpty || newEmployee.hiredYear <= 0 || newEmployee.dateOfBirth <= 0)
                        .padding()
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Cancel") {
                                // If cancelled, add a default employee so system doesn't break
                                addDefaultEmployee()
                                showEmployeeEntry = false
                            }
                        }
                    }
                }
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
    
    private func resetToDefaults() {
        // Reset configuration to defaults
        viewModel.loadDefaultConfiguration()
        
        // Clear all employees
        viewModel.clearAllEmployees()
        
        // Reset new employee form
        let currentYear = Calendar.current.component(.year, from: Date())
        newEmployee = EditableEmployee(
            id: 1,
            name: "",
            hiredYear: currentYear,
            dateOfBirth: currentYear - 30,
            spouseDateOfBirth: 0
        )
        
        // Show employee entry form
        showEmployeeEntry = true
    }
    
    private func saveInitialEmployee() {
        // Validate required fields
        guard !newEmployee.name.trimmingCharacters(in: .whitespaces).isEmpty,
              newEmployee.hiredYear > 0,
              newEmployee.dateOfBirth > 0 else {
            return
        }
        
        let employee = newEmployee.toEmployee()
        viewModel.addEmployee(employee)
        showEmployeeEntry = false
    }
    
    private func addDefaultEmployee() {
        // Add a default employee if user cancels
        let currentYear = Calendar.current.component(.year, from: Date())
        let defaultEmployee = Employee(
            id: 1,
            name: "Employee 1",
            hiredYear: currentYear,
            dateOfBirth: currentYear - 30,
            spouseDateOfBirth: 0
        )
        viewModel.addEmployee(defaultEmployee)
    }
}

#Preview {
    SystemInformationView()
}

