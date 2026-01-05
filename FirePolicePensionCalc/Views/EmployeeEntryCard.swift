//
//  EmployeeEntryCard.swift
//  FirePolicePensionCalc
//
//  Reusable card component for displaying/editing a single employee
//

import SwiftUI

struct EmployeeEntryCard: View {
    @Binding var employee: EditableEmployee
    var originalEmployee: EditableEmployee?
    var onDelete: (() -> Void)?
    var onSave: (() -> Void)?
    
    private var hasChanges: Bool {
        guard let original = originalEmployee else { return true } // New employees always have changes
        return employee.name != original.name ||
               employee.hiredYear != original.hiredYear ||
               employee.dateOfBirth != original.dateOfBirth ||
               employee.spouseDateOfBirth != original.spouseDateOfBirth ||
               employee.sex != original.sex ||
               employee.spouseSex != original.spouseSex
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(employee.name.isEmpty ? "New Employee" : employee.name)
                    .font(.headline)
                Spacer()
                HStack(spacing: 12) {
                    if hasChanges && onSave != nil {
                        Button(action: {
                            onSave?()
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    if onDelete != nil {
                        Button(action: {
                            onDelete?()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
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
                    Text("Sex")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    Picker("", selection: $employee.sex) {
                        Text("M").tag(Sex.male)
                        Text("F").tag(Sex.female)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
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
                        .onChange(of: employee.spouseDateOfBirth) { newValue in
                            // If spouse DOB is set to 0, clear spouse sex; otherwise default to female if nil
                            if newValue == 0 {
                                employee.spouseSex = nil
                            } else if employee.spouseSex == nil {
                                employee.spouseSex = .female
                            }
                        }
                }
                
                if employee.spouseDateOfBirth > 0 {
                    HStack {
                        Text("Spouse Sex")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: Binding(
                            get: { employee.spouseSex ?? .female },
                            set: { employee.spouseSex = $0 }
                        )) {
                            Text("M").tag(Sex.male)
                            Text("F").tag(Sex.female)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
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
            spouseDateOfBirth: 1992,
            sex: .male,
            spouseSex: .female
        )),
        originalEmployee: EditableEmployee(
            id: 1,
            name: "John Doe",
            hiredYear: 2020,
            dateOfBirth: 1990,
            spouseDateOfBirth: 1992,
            sex: .male,
            spouseSex: .female
        )
    )
    .padding()
}

