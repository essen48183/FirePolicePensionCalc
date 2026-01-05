//
//  EmployeeListView.swift
//  FirePolicePensionCalc
//
//  View for displaying and editing employee data
//

import SwiftUI

struct EmployeeListView: View {
    @ObservedObject var viewModel: PensionCalculatorViewModel
    @State private var selectedEmployee: Employee?
    @State private var showingAddEmployee = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Employees (\(viewModel.employees.count))")) {
                    ForEach(viewModel.employees) { employee in
                        EmployeeRow(employee: employee)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedEmployee = employee
                            }
                    }
                    .onDelete(perform: deleteEmployees)
                }
            }
            .navigationTitle("Employees")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddEmployee = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEmployee) {
                EmployeeEditor(
                    employee: nil,
                    onSave: { newEmployee in
                        viewModel.addEmployee(newEmployee)
                    }
                )
            }
            .sheet(item: $selectedEmployee) { employee in
                EmployeeEditor(
                    employee: employee,
                    onSave: { updatedEmployee in
                        viewModel.updateEmployee(updatedEmployee)
                        selectedEmployee = nil
                    }
                )
            }
        }
    }
    
    private func deleteEmployees(at offsets: IndexSet) {
        viewModel.deleteEmployees(at: offsets)
    }
}

struct EmployeeRow: View {
    let employee: Employee
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(employee.name)
                .font(.headline)
            HStack {
                Text("Hired: \(employee.hiredYear)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Age: \(employee.currentAge)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if employee.hasSpouse {
                Text("Spouse: Age \(employee.spouseCurrentAge)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("No spouse")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmployeeEditor: View {
    let employee: Employee?
    let onSave: (Employee) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var hiredYear: String = ""
    @State private var dateOfBirth: String = ""
    @State private var spouseDateOfBirth: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Employee Information")) {
                    TextField("Name", text: $name)
                    TextField("Hired Year", text: $hiredYear)
                        .keyboardType(.numberPad)
                    TextField("Date of Birth (Year)", text: $dateOfBirth)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Spouse Information")) {
                    TextField("Spouse Date of Birth (Year, 0 for none)", text: $spouseDateOfBirth)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button("Save") {
                        saveEmployee()
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle(employee == nil ? "Add Employee" : "Edit Employee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadEmployeeData()
            }
        }
    }
    
    private func loadEmployeeData() {
        if let employee = employee {
            name = employee.name
            hiredYear = "\(employee.hiredYear)"
            dateOfBirth = "\(employee.dateOfBirth)"
            spouseDateOfBirth = employee.spouseDateOfBirth > 0 ? "\(employee.spouseDateOfBirth)" : "0"
        } else {
            // Default values for new employee
            let currentYear = Calendar.current.component(.year, from: Date())
            hiredYear = "\(currentYear)"
            dateOfBirth = "\(currentYear - 30)"
            spouseDateOfBirth = "0"
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty &&
        Int(hiredYear) != nil &&
        Int(dateOfBirth) != nil &&
        (spouseDateOfBirth.isEmpty || Int(spouseDateOfBirth) != nil)
    }
    
    private func saveEmployee() {
        guard let hired = Int(hiredYear),
              let dob = Int(dateOfBirth) else { return }
        
        let spouseDOB = Int(spouseDateOfBirth) ?? 0
        
        let newEmployee: Employee
        if let existing = employee {
            newEmployee = Employee(
                id: existing.id,
                name: name,
                hiredYear: hired,
                dateOfBirth: dob,
                spouseDateOfBirth: spouseDOB
            )
        } else {
            // Find next available ID
            let maxId = EmployeeDataLoader.loadEmployees().map { $0.id }.max() ?? 0
            newEmployee = Employee(
                id: maxId + 1,
                name: name,
                hiredYear: hired,
                dateOfBirth: dob,
                spouseDateOfBirth: spouseDOB
            )
        }
        
        onSave(newEmployee)
        dismiss()
    }
}

