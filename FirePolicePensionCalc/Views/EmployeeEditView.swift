//
//  EmployeeEditView.swift
//  FirePolicePensionCalc
//
//  View for editing employee data
//

import SwiftUI

struct EditableEmployee: Identifiable, Equatable {
    var id: Int
    var name: String
    var hiredYear: Int
    var dateOfBirth: Int
    var spouseDateOfBirth: Int
    var sex: Sex
    var spouseSex: Sex?
    
    static func == (lhs: EditableEmployee, rhs: EditableEmployee) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.hiredYear == rhs.hiredYear &&
               lhs.dateOfBirth == rhs.dateOfBirth &&
               lhs.spouseDateOfBirth == rhs.spouseDateOfBirth &&
               lhs.sex == rhs.sex &&
               lhs.spouseSex == rhs.spouseSex
    }
    
    init(from employee: Employee) {
        self.id = employee.id
        self.name = employee.name
        self.hiredYear = employee.hiredYear
        self.dateOfBirth = employee.dateOfBirth
        self.spouseDateOfBirth = employee.spouseDateOfBirth
        self.sex = employee.sex
        self.spouseSex = employee.spouseSex
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
    
    func toEmployee() -> Employee {
        Employee(
            id: id,
            name: name,
            hiredYear: hiredYear,
            dateOfBirth: dateOfBirth,
            spouseDateOfBirth: spouseDateOfBirth,
            sex: sex,
            spouseSex: spouseSex
        )
    }
}

struct EmployeeEditView: View {
    @ObservedObject var viewModel: PensionCalculatorViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var editedEmployees: [EditableEmployee]
    @State private var originalEmployees: [EditableEmployee]
    @State private var showValidationError = false
    @State private var validationErrorMessage = ""
    @State private var showSaveChangesAlert = false
    
    init(viewModel: PensionCalculatorViewModel) {
        self.viewModel = viewModel
        let initialEmployees = viewModel.employees.map { EditableEmployee(from: $0) }
        _editedEmployees = State(initialValue: initialEmployees)
        _originalEmployees = State(initialValue: initialEmployees)
    }
    
    var body: some View {
        employeeList
            .navigationTitle("Edit Employees")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    leadingToolbarButtons
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    trailingToolbarButton
                }
            }
            .alert("Validation Error", isPresented: $showValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationErrorMessage)
            }
            .alert("Save Changes?", isPresented: $showSaveChangesAlert) {
                Button("Save") {
                    if validateEmployees() {
                        saveChanges()
                    } else {
                        // If validation fails, show validation error instead
                        showSaveChangesAlert = false
                    }
                }
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Would you like to save them before leaving?")
            }
    }
    
    private var employeeList: some View {
        List {
            ForEach($editedEmployees) { $employee in
                Section {
                    EmployeeEntryCard(employee: $employee, onDelete: {
                        if let index = editedEmployees.firstIndex(where: { $0.id == employee.id }) {
                            editedEmployees.remove(at: index)
                        }
                    })
                } header: {
                    Text(employee.name.isEmpty ? "New Employee" : employee.name)
                }
            }
            .onDelete { indexSet in
                editedEmployees.remove(atOffsets: indexSet)
            }
            .onChange(of: editedEmployees) { _ in
                // Track changes when employees are modified
            }
        }
    }
    
    private var leadingToolbarButtons: some View {
        HStack(spacing: 16) {
            Button(action: {
                if hasUnsavedChanges() {
                    showSaveChangesAlert = true
                } else {
                    dismiss()
                }
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            }
            Button(action: addNewEmployee) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add")
                }
            }
        }
    }
    
    private var trailingToolbarButton: some View {
        Button("Save") {
            if validateEmployees() {
                saveChanges()
            }
        }
    }
    
    private func addNewEmployee() {
        let newId = getNextAvailableId()
        let newEmployee = EditableEmployee(
            id: newId,
            name: "",
            hiredYear: Calendar.current.component(.year, from: Date()),
            dateOfBirth: 1990,
            spouseDateOfBirth: 0,
            sex: .male,
            spouseSex: nil
        )
        editedEmployees.insert(newEmployee, at: 0)
    }
    
    private func getNextAvailableId() -> Int {
        let allIds = Set(editedEmployees.map { $0.id })
        let existingIds = Set(viewModel.employees.map { $0.id })
        let maxId = (allIds.union(existingIds)).max() ?? 0
        return maxId + 1
    }
    
    private func hasUnsavedChanges() -> Bool {
        // Check if employees were added or removed
        if editedEmployees.count != originalEmployees.count {
            return true
        }
        
        // Check if any employee data was modified
        let originalMap = Dictionary(uniqueKeysWithValues: originalEmployees.map { ($0.id, $0) })
        
        for editedEmployee in editedEmployees {
            if let originalEmployee = originalMap[editedEmployee.id] {
            if editedEmployee.name != originalEmployee.name ||
               editedEmployee.hiredYear != originalEmployee.hiredYear ||
               editedEmployee.dateOfBirth != originalEmployee.dateOfBirth ||
               editedEmployee.spouseDateOfBirth != originalEmployee.spouseDateOfBirth ||
               editedEmployee.sex != originalEmployee.sex ||
               editedEmployee.spouseSex != originalEmployee.spouseSex {
                    return true
                }
            } else {
                // New employee (not in original list)
                return true
            }
        }
        
        // Check if any original employees were deleted
        let editedIds = Set(editedEmployees.map { $0.id })
        for originalEmployee in originalEmployees {
            if !editedIds.contains(originalEmployee.id) {
                return true
            }
        }
        
        return false
    }
    
    private func validateEmployees() -> Bool {
        for (index, employee) in editedEmployees.enumerated() {
            if employee.name.trimmingCharacters(in: .whitespaces).isEmpty {
                validationErrorMessage = "Employee at position \(index + 1) is missing a name."
                showValidationError = true
                return false
            }
            
            if employee.hiredYear <= 0 {
                validationErrorMessage = "Employee '\(employee.name)' is missing a valid hire year."
                showValidationError = true
                return false
            }
            
            if employee.dateOfBirth <= 0 {
                validationErrorMessage = "Employee '\(employee.name)' is missing a valid date of birth."
                showValidationError = true
                return false
            }
        }
        return true
    }
    
    private func saveChanges() {
        // Generate IDs for any new employees (those with ID 0 or negative)
        // We need to do this iteratively to avoid conflicts
        var nextId = getNextAvailableId()
        for i in 0..<editedEmployees.count {
            if editedEmployees[i].id <= 0 {
                editedEmployees[i].id = nextId
                nextId += 1
            }
        }
        
        // Convert editable employees back to Employee structs
        let updatedEmployees = editedEmployees.map { $0.toEmployee() }
        
        // Separate existing and new employees
        let existingIds = Set(viewModel.employees.map { $0.id })
        var newEmployees: [Employee] = []
        var employeesToUpdate: [Employee] = []
        
        for employee in updatedEmployees {
            if existingIds.contains(employee.id) {
                employeesToUpdate.append(employee)
            } else {
                newEmployees.append(employee)
            }
        }
        
        // Update existing employees
        for employee in employeesToUpdate {
            viewModel.updateEmployee(employee)
        }
        
        // Add new employees
        for employee in newEmployees {
            viewModel.addEmployee(employee)
        }
        
        // Remove any employees that were deleted
        let editedIds = Set(editedEmployees.map { $0.id })
        let toDelete = viewModel.employees.filter { !editedIds.contains($0.id) }
        for employee in toDelete {
            if let index = viewModel.employees.firstIndex(where: { $0.id == employee.id }) {
                viewModel.deleteEmployees(at: IndexSet([index]))
            }
        }
        
        // Reload employees to ensure sync
        viewModel.loadEmployees()
        
        // Update original employees to reflect saved state
        originalEmployees = editedEmployees
        
        dismiss()
    }
}


