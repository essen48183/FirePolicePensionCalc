//
//  PensionCalculatorViewModel.swift
//  FirePolicePensionCalc
//
//  View model for pension calculations
//

import Foundation
import SwiftUI

class PensionCalculatorViewModel: ObservableObject {
    @Published var config = PensionConfiguration()
    @Published var systemResult: SystemCalculationResult?
    @Published var individualResult: (disbursement: PensionCalculatorDisbursements.DisbursementResult, cityContribution: Double)?
    @Published var employees: [Employee] = []
    @Published var isLoading = false
    @Published var hasUnsavedChanges = false
    
    private let calculatorService = PensionCalculatorService()
    private var lastCalculatedConfig: PensionConfiguration?
    
    init() {
        loadEmployees()
        loadSavedConfiguration()
    }
    
    func loadEmployees() {
        employees = EmployeeDataLoader.loadEmployees()
        config.totalNumberEmployees = employees.count
    }
    
    func loadSavedConfiguration() {
        if let savedConfig = ConfigurationPersistence.load() {
            config = savedConfig
            // Ensure employee count matches loaded employees
            config.totalNumberEmployees = employees.count
        }
    }
    
    func saveConfiguration() {
        ConfigurationPersistence.save(config)
    }
    
    func clearSavedConfiguration() {
        ConfigurationPersistence.clear()
    }
    
    func loadDefaultConfiguration() {
        config = PensionConfiguration()
        // Don't update employee count here - it will be updated when employees are loaded/cleared
        saveConfiguration()
    }
    
    func clearAllEmployees() {
        employees.removeAll()
        do {
            try EmployeeDataLoader.saveEmployees([])
            config.totalNumberEmployees = 0
        } catch {
            print("Error clearing employees: \(error)")
        }
    }
    
    func calculateSystemCosts() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let result = self.calculatorService.calculateSystemCosts(
                config: self.config,
                employees: self.employees
            )
            DispatchQueue.main.async {
                self.systemResult = result
                self.lastCalculatedConfig = self.config
                self.hasUnsavedChanges = false
                self.isLoading = false
            }
        }
    }
    
    func calculateIndividualPension() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let result = self.calculatorService.calculateIndividualPension(config: self.config)
            DispatchQueue.main.async {
                self.individualResult = result
                self.lastCalculatedConfig = self.config
                self.hasUnsavedChanges = false
                self.isLoading = false
            }
        }
    }
    
    func calculateAll() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let systemResult = self.calculatorService.calculateSystemCosts(
                config: self.config,
                employees: self.employees
            )
            let individualResult = self.calculatorService.calculateIndividualPension(config: self.config)
            DispatchQueue.main.async {
                self.systemResult = systemResult
                self.individualResult = individualResult
                self.lastCalculatedConfig = self.config
                self.hasUnsavedChanges = false
                self.isLoading = false
            }
        }
    }
    
    func markConfigChanged() {
        // Check if config has actually changed from last calculation
        if let lastConfig = lastCalculatedConfig {
            hasUnsavedChanges = !configsAreEqual(config, lastConfig)
        } else {
            // If no calculation has been done yet, don't mark as changed
            hasUnsavedChanges = false
        }
    }
    
    private func configsAreEqual(_ a: PensionConfiguration, _ b: PensionConfiguration) -> Bool {
        return a.baseWage == b.baseWage &&
               a.facWage == b.facWage &&
               a.multiplier == b.multiplier &&
               a.multiplierBasedOnFAC == b.multiplierBasedOnFAC &&
               a.employeeContributionPercent == b.employeeContributionPercent &&
               a.isColaCompounding == b.isColaCompounding &&
               a.colaNumber == b.colaNumber &&
               a.colaSpacing == b.colaSpacing &&
               a.colaPercent == b.colaPercent &&
               a.retirementAge == b.retirementAge &&
               a.careerYearsService == b.careerYearsService &&
               a.minAgeForYearsService == b.minAgeForYearsService &&
               a.expectedFutureInflationRate == b.expectedFutureInflationRate &&
               a.expectedSystemFutureRateReturn == b.expectedSystemFutureRateReturn &&
               a.fictionalNewHireAge == b.fictionalNewHireAge &&
               a.fictionalSpouseAgeDiff == b.fictionalSpouseAgeDiff &&
               a.spouseReductionPercent == b.spouseReductionPercent &&
               a.facBaseWageYear1 == b.facBaseWageYear1 &&
               a.facOvertimeYear1 == b.facOvertimeYear1 &&
               a.facRollInsYear1 == b.facRollInsYear1 &&
               a.facBaseWageYear2 == b.facBaseWageYear2 &&
               a.facOvertimeYear2 == b.facOvertimeYear2 &&
               a.facBaseWageYear3 == b.facBaseWageYear3 &&
               a.facOvertimeYear3 == b.facOvertimeYear3 &&
               a.pensionOption == b.pensionOption
    }
    
    func addEmployee(_ employee: Employee) {
        employees.append(employee)
        saveEmployees()
        config.totalNumberEmployees = employees.count
    }
    
    func getNextAvailableEmployeeId() -> Int {
        let maxId = employees.map { $0.id }.max() ?? 0
        return maxId + 1
    }
    
    func updateEmployee(_ employee: Employee) {
        if let index = employees.firstIndex(where: { $0.id == employee.id }) {
            employees[index] = employee
            saveEmployees()
        }
    }
    
    func deleteEmployees(at offsets: IndexSet) {
        employees.remove(atOffsets: offsets)
        saveEmployees()
        config.totalNumberEmployees = employees.count
    }
    
    private func saveEmployees() {
        do {
            try EmployeeDataLoader.saveEmployees(employees)
        } catch {
            print("Error saving employees: \(error)")
        }
    }
}

