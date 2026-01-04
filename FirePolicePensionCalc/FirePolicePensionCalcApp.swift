//
//  FirePolicePensionCalcApp.swift
//  FirePolicePensionCalc
//
//  Main app entry point
//

import SwiftUI

@main
struct FirePolicePensionCalcApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Show disclosure sheet on app launch
                    // The sheet will be presented automatically via ContentView
                }
        }
    }
}

