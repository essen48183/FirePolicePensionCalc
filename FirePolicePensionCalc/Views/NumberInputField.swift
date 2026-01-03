//
//  NumberInputField.swift
//  FirePolicePensionCalc
//
//  Custom number input field that shows a popup for easier editing
//

import SwiftUI

struct NumberInputField: View {
    let title: String
    @Binding var value: Double
    let defaultValue: Double
    let format: NumberFormat
    let keyboardType: UIKeyboardType
    
    enum NumberFormat {
        case number
        case integer
        case currency
    }
    
    @State private var showInputSheet = false
    @State private var inputText = ""
    
    var body: some View {
        Button(action: {
            inputText = ""
            showInputSheet = true
        }) {
            HStack {
                Spacer()
                Text(formatValue(value))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.trailing)
            }
            .frame(width: 120)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showInputSheet) {
            NumberInputSheet(
                title: title,
                currentValue: value,
                defaultValue: defaultValue,
                inputText: $inputText,
                format: format,
                keyboardType: keyboardType,
                onSave: { newValue in
                    value = newValue
                }
            )
        }
    }
    
    private func formatValue(_ val: Double) -> String {
        switch format {
        case .number:
            // Format without commas
            if val.truncatingRemainder(dividingBy: 1) == 0 {
                return String(Int(val))
            } else {
                // Format with up to 2 decimal places, remove trailing zeros
                let formatted = String(format: "%.2f", val)
                return formatted.replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
            }
        case .integer:
            return String(Int(val))
        case .currency:
            return "$\(Int(val))"
        }
    }
}

struct NumberInputSheet: View {
    let title: String
    let currentValue: Double
    let defaultValue: Double
    @Binding var inputText: String
    let format: NumberInputField.NumberFormat
    let keyboardType: UIKeyboardType
    let onSave: (Double) -> Void
    
    @Environment(\.dismiss) var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Enter new value:")
                            .font(.headline)
                        
                        TextField("", text: $inputText)
                            .keyboardType(keyboardType)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($isTextFieldFocused)
                            .font(.title2)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current value: \(formatValue(currentValue))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Default value: \(formatValue(defaultValue))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button(action: {
                        if let newValue = parseInput() {
                            onSave(newValue)
                            dismiss()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Save")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(inputText.isEmpty)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Text("Cancel")
                            Spacer()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
    
    private func parseInput() -> Double? {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil
        }
        // Remove any currency symbols or commas
        let cleaned = trimmed.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        return Double(cleaned)
    }
    
    private func formatValue(_ val: Double) -> String {
        switch format {
        case .number:
            // Format without commas
            if val.truncatingRemainder(dividingBy: 1) == 0 {
                return String(Int(val))
            } else {
                // Format with up to 2 decimal places, remove trailing zeros
                let formatted = String(format: "%.2f", val)
                return formatted.replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
            }
        case .integer:
            return String(Int(val))
        case .currency:
            return "$\(Int(val))"
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var value: Double = 85000
        
        var body: some View {
            Form {
                HStack {
                    Text("Base Wage")
                    Spacer()
                    NumberInputField(
                        title: "Base Wage",
                        value: $value,
                        defaultValue: 85000,
                        format: .number,
                        keyboardType: .decimalPad
                    )
                }
            }
        }
    }
    return PreviewWrapper()
}

