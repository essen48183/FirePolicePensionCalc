//
//  EmployeeEntryCard.swift
//  FirePolicePensionCalc
//
//  Reusable card component for displaying/editing a single employee
//

import SwiftUI

struct EmployeeEntryCard: View {
    @Binding var employee: EditableEmployee
    var onDelete: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(employee.name.isEmpty ? "New Employee" : employee.name)
                    .font(.headline)
                Spacer()
                if onDelete != nil {
                    Button(action: {
                        onDelete?()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Employee Name", text: $employee.name)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    Text("Hired Year")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Year", value: $employee.hiredYear, format: .number.grouping(.never))
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    Text("Date of Birth")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Year", value: $employee.dateOfBirth, format: .number.grouping(.never))
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    HStack(spacing: 4) {
                        Text("Spouse DOB")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Image(systemName: "info.circle")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    .frame(width: 100, alignment: .leading)
                    TextField("0 for no spouse", value: $employee.spouseDateOfBirth, format: .number.grouping(.never))
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    EmployeeEntryCard(
        employee: .constant(EditableEmployee(
            id: 1,
            name: "John Doe",
            hiredYear: 2020,
            dateOfBirth: 1990,
            spouseDateOfBirth: 1992
        ))
    )
    .padding()
}

