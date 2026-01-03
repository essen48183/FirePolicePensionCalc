//
//  IntegerInputField.swift
//  FirePolicePensionCalc
//
//  Custom integer input field that shows a popup for easier editing
//

import SwiftUI

struct IntegerInputField: View {
    let title: String
    @Binding var value: Int
    let defaultValue: Int
    let keyboardType: UIKeyboardType
    
    @State private var showInputSheet = false
    @State private var inputText = ""
    
    var body: some View {
        Button(action: {
            inputText = ""
            showInputSheet = true
        }) {
            HStack {
                Spacer()
                Text(String(value))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.trailing)
            }
            .frame(width: 120)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showInputSheet) {
            IntegerInputSheet(
                title: title,
                currentValue: value,
                defaultValue: defaultValue,
                inputText: $inputText,
                keyboardType: keyboardType,
                onSave: { newValue in
                    value = newValue
                }
            )
        }
    }
}

struct IntegerInputSheet: View {
    let title: String
    let currentValue: Int
    let defaultValue: Int
    @Binding var inputText: String
    let keyboardType: UIKeyboardType
    let onSave: (Int) -> Void
    
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
                            Text("Current value: \(formatInteger(currentValue))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Default value: \(formatInteger(defaultValue))")
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
    
    private func parseInput() -> Int? {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil
        }
        // Remove any commas
        let cleaned = trimmed.replacingOccurrences(of: ",", with: "")
        return Int(cleaned)
    }
    
    private func formatInteger(_ val: Int) -> String {
        // Format without commas - just convert to string directly
        return String(val)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var value: Int = 2025
        
        var body: some View {
            Form {
                HStack {
                    Text("Year Hired")
                    Spacer()
                    IntegerInputField(
                        title: "Year Hired",
                        value: $value,
                        defaultValue: 2025,
                        keyboardType: .numberPad
                    )
                }
            }
        }
    }
    return PreviewWrapper()
}

