//
//  ContentView.swift
//  FirePolicePensionCalc
//
//  Main view with tab navigation
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PensionCalculatorViewModel()
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var pendingTabChange: Int?
    @State private var showRecalculateAlert = false
    @State private var shouldAutoSwitchToIndividual = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ConfigurationView(viewModel: viewModel)
                .tabItem {
                    Label("Configuration", systemImage: "slider.horizontal.3")
                }
                .tag(0)
            
            IndividualResultsView(viewModel: viewModel)
                .tabItem {
                    Label("Individual", systemImage: "person")
                }
                .tag(1)
            
            SystemResultsView(viewModel: viewModel)
                .tabItem {
                    Label("System Results", systemImage: "chart.bar")
                }
                .tag(2)
            
            SystemInformationView(viewModel: viewModel)
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
                .tag(3)
        }
        .onChange(of: selectedTab) { newTab in
            // If switching away from Configuration tab (0) and there are unsaved changes
            if previousTab == 0 && newTab != 0 && viewModel.hasUnsavedChanges {
                // Prevent the change and show alert
                pendingTabChange = newTab
                showRecalculateAlert = true
                // Revert the selection
                selectedTab = 0
            } else {
                // Update previous tab if change was allowed
                previousTab = newTab
            }
        }
        .onChange(of: viewModel.isLoading) { isLoading in
            // When calculation starts from Configuration tab, set flag to auto-switch
            if isLoading && selectedTab == 0 {
                shouldAutoSwitchToIndividual = true
            }
            // When calculation completes, switch to Individual Results tab
            if !isLoading && shouldAutoSwitchToIndividual && viewModel.individualResult != nil {
                selectedTab = 1
                previousTab = 1
                shouldAutoSwitchToIndividual = false
            }
        }
        .alert("Configuration Changed", isPresented: $showRecalculateAlert) {
            Button("Recalculate All") {
                viewModel.saveConfiguration()
                viewModel.calculateAll()
                if let newTab = pendingTabChange {
                    previousTab = newTab
                    selectedTab = newTab
                }
                pendingTabChange = nil
            }
            Button("Keep Old Values") {
                // Just navigate without recalculating
                if let newTab = pendingTabChange {
                    previousTab = newTab
                    selectedTab = newTab
                }
                pendingTabChange = nil
            }
            Button("Cancel", role: .cancel) {
                pendingTabChange = nil
            }
        } message: {
            Text("You have unsaved configuration changes. Would you like to recalculate before viewing results?")
        }
    }
}

