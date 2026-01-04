//
//  DocumentationView.swift
//  FirePolicePensionCalc
//
//  View for displaying documentation files
//

import SwiftUI

struct DocumentationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedDocument: DocumentationItem?
    
    struct DocumentationItem: Identifiable {
        let id: String
        let title: String
        let description: String
        let filename: String
    }
    
    let documents: [DocumentationItem] = [
        DocumentationItem(
            id: "assumptions",
            title: "Actuarial Assumptions",
            description: "Important disclosures about model limitations and assumptions",
            filename: "ACTUARIAL_ASSUMPTIONS.md"
        ),
        DocumentationItem(
            id: "calculation-flow",
            title: "Calculation Flow",
            description: "Step-by-step explanation of how calculations work",
            filename: "CALCULATION_FLOW.md"
        ),
        DocumentationItem(
            id: "actuarial-rule",
            title: "Actuarial Rule",
            description: "Explanation of the 100% funding actuarial rule",
            filename: "ACTUARIAL_RULE.md"
        ),
        DocumentationItem(
            id: "math-verification",
            title: "Math Verification",
            description: "Verification of all mathematical formulas",
            filename: "ACTUARIAL_MATH_VERIFICATION.md"
        ),
        DocumentationItem(
            id: "rate-usage",
            title: "Rate Usage",
            description: "How expected return and inflation rates are used",
            filename: "RATE_USAGE_VERIFICATION.md"
        ),
        DocumentationItem(
            id: "quick-start",
            title: "Quick Start",
            description: "Quick start guide for using the application",
            filename: "QUICK_START.md"
        )
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(documents) { document in
                    Button(action: {
                        selectedDocument = document
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(document.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(document.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Documentation")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $selectedDocument) { document in
            DocumentDetailView(document: document)
        }
    }
}

struct DocumentDetailView: View {
    @Environment(\.dismiss) var dismiss
    let document: DocumentationView.DocumentationItem
    @State private var content: String = ""
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        MarkdownTextView(text: content)
                            .padding()
                    }
                }
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadDocument()
        }
    }
    
    private func loadDocument() {
        // Try multiple locations to find the markdown file
        let filenameWithoutExt = document.filename.replacingOccurrences(of: ".md", with: "")
        
        // First try: Bundle resource
        if let url = Bundle.main.url(forResource: filenameWithoutExt, withExtension: "md") {
            do {
                content = try String(contentsOf: url, encoding: .utf8)
                isLoading = false
                return
            } catch {
                // Fall through to next attempt
            }
        }
        
        // Second try: Bundle path
        if let path = Bundle.main.path(forResource: filenameWithoutExt, ofType: "md") {
            if let loaded = try? String(contentsOfFile: path) {
                content = loaded
                isLoading = false
                return
            }
        }
        
        // Third try: Project root (for development/testing)
        if let projectRoot = getProjectRoot() {
            let filePath = (projectRoot as NSString).appendingPathComponent(document.filename)
            if FileManager.default.fileExists(atPath: filePath),
               let loaded = try? String(contentsOfFile: filePath) {
                content = loaded
                isLoading = false
                return
            }
        }
        
        // If all else fails, show error message
        content = """
        Document not found: \(document.filename)
        
        The documentation files need to be included in the app bundle. 
        Please ensure \(document.filename) is added to the project and included in the app target.
        """
        isLoading = false
    }
    
    private func getProjectRoot() -> String? {
        // Try to find project root by looking for common files
        let currentPath = FileManager.default.currentDirectoryPath
        var searchPath = currentPath
        
        // Look up to 5 levels up for project root indicators
        for _ in 0..<5 {
            let xcodeprojPath = (searchPath as NSString).appendingPathComponent("FirePolicePensionCalc.xcodeproj")
            if FileManager.default.fileExists(atPath: xcodeprojPath) {
                return searchPath
            }
            searchPath = (searchPath as NSString).deletingLastPathComponent
            if searchPath == "/" {
                break
            }
        }
        
        return nil
    }
}

struct MarkdownTextView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(parseMarkdown(text), id: \.id) { block in
                block.view
            }
        }
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = text.components(separatedBy: .newlines)
        var currentParagraph: [String] = []
        var inCodeBlock = false
        var codeBlockContent: [String] = []
        
        for line in lines {
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // End code block
                    blocks.append(.codeBlock(codeBlockContent.joined(separator: "\n")))
                    codeBlockContent = []
                    inCodeBlock = false
                } else {
                    // Start code block - save any current paragraph first
                    if !currentParagraph.isEmpty {
                        blocks.append(.paragraph(currentParagraph.joined(separator: " ")))
                        currentParagraph = []
                    }
                    inCodeBlock = true
                }
            } else if inCodeBlock {
                codeBlockContent.append(line)
            } else if line.isEmpty {
                if !currentParagraph.isEmpty {
                    blocks.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
            } else if line.hasPrefix("# ") {
                if !currentParagraph.isEmpty {
                    blocks.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                blocks.append(.heading1(String(line.dropFirst(2))))
            } else if line.hasPrefix("## ") {
                if !currentParagraph.isEmpty {
                    blocks.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                blocks.append(.heading2(String(line.dropFirst(3))))
            } else if line.hasPrefix("### ") {
                if !currentParagraph.isEmpty {
                    blocks.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                blocks.append(.heading3(String(line.dropFirst(4))))
            } else if line.hasPrefix("#### ") {
                if !currentParagraph.isEmpty {
                    blocks.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                blocks.append(.heading4(String(line.dropFirst(5))))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                if !currentParagraph.isEmpty {
                    blocks.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                blocks.append(.bullet(String(line.dropFirst(2))))
            } else {
                currentParagraph.append(line)
            }
        }
        
        if !currentParagraph.isEmpty {
            blocks.append(.paragraph(currentParagraph.joined(separator: " ")))
        }
        
        return blocks
    }
}

enum MarkdownBlock: Identifiable {
    case heading1(String)
    case heading2(String)
    case heading3(String)
    case heading4(String)
    case paragraph(String)
    case bullet(String)
    case codeBlock(String)
    
    var id: String {
        switch self {
        case .heading1(let text): return "h1-\(text)"
        case .heading2(let text): return "h2-\(text)"
        case .heading3(let text): return "h3-\(text)"
        case .heading4(let text): return "h4-\(text)"
        case .paragraph(let text): return "p-\(text.prefix(20))"
        case .bullet(let text): return "b-\(text.prefix(20))"
        case .codeBlock(let text): return "c-\(text.prefix(20))"
        }
    }
    
    @ViewBuilder
    var view: some View {
        switch self {
        case .heading1(let text):
            formatText(text)
                .font(.largeTitle)
                .bold()
                .padding(.top, 8)
        case .heading2(let text):
            formatText(text)
                .font(.title)
                .bold()
                .padding(.top, 8)
        case .heading3(let text):
            formatText(text)
                .font(.title2)
                .bold()
                .padding(.top, 8)
        case .heading4(let text):
            formatText(text)
                .font(.title3)
                .bold()
                .padding(.top, 4)
        case .paragraph(let text):
            formatText(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        case .bullet(let text):
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.body)
                formatText(text)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .codeBlock(let text):
            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
    
    private func formatText(_ text: String) -> Text {
        // Simple markdown formatting - handle bold and code
        var result = Text("")
        var remaining = text
        var isFirst = true
        
        // Handle bold (**text**)
        while let boldRange = remaining.range(of: "**") {
            let beforeBold = String(remaining[..<boldRange.lowerBound])
            if !beforeBold.isEmpty {
                if isFirst {
                    result = Text(beforeBold)
                    isFirst = false
                } else {
                    result = result + Text(beforeBold)
                }
            }
            
            remaining = String(remaining[boldRange.upperBound...])
            if let endBoldRange = remaining.range(of: "**") {
                let boldText = String(remaining[..<endBoldRange.lowerBound])
                if isFirst {
                    result = Text(boldText).bold()
                    isFirst = false
                } else {
                    result = result + Text(boldText).bold()
                }
                remaining = String(remaining[endBoldRange.upperBound...])
            }
        }
        
        if !remaining.isEmpty {
            if isFirst {
                result = Text(remaining)
            } else {
                result = result + Text(remaining)
            }
        }
        
        return result
    }
}

#Preview {
    DocumentationView()
}

