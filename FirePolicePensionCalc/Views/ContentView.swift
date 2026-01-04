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
    @State private var showDisclosure = false
    @State private var hasShownDisclosureThisSession = false
    
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
                    Label("Systemwide", systemImage: "chart.bar")
                }
                .tag(2)
            
            ComparisonView(viewModel: viewModel)
                .tabItem {
                    Label("Comparison", systemImage: "chart.bar.doc.horizontal")
                }
                .tag(3)
            
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(4)
            
            SystemInformationView(viewModel: viewModel)
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
                .tag(5)
        }
        .onChange(of: selectedTab) { newTab in
            // If switching away from Configuration tab (0) and there are unsaved changes
            if previousTab == 0 && newTab != 0 && viewModel.hasUnsavedChanges {
                // Allow the change but show reminder alert
                pendingTabChange = newTab
                showRecalculateAlert = true
                // Update previous tab to allow navigation
                previousTab = newTab
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
            Button("Calculate Now") {
                viewModel.saveConfiguration()
                viewModel.calculateAll()
                pendingTabChange = nil
            }
            Button("Dismiss", role: .cancel) {
                // Just acknowledge and continue - don't force calculation
                pendingTabChange = nil
            }
        } message: {
            Text("You have unsaved configuration changes. Remember to press 'Calculate All' to update the results with your new settings.")
        }
        .sheet(isPresented: $showDisclosure) {
            FinancialDisclosureView()
        }
        .onAppear {
            // Show disclosure once per app launch session
            if !hasShownDisclosureThisSession {
                showDisclosure = true
                hasShownDisclosureThisSession = true
            }
        }
    }
}

