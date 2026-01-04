//
//  ComparisonData.swift
//  FirePolicePensionCalc
//
//  Model for storing comparison basis data
//

import Foundation

struct ComparisonData: Codable {
    let systemResult: SystemCalculationResult
    let config: PensionConfiguration
    let timestamp: Date
    let employeeCount: Int
    
    init(systemResult: SystemCalculationResult, config: PensionConfiguration, employeeCount: Int) {
        self.systemResult = systemResult
        self.config = config
        self.timestamp = Date()
        self.employeeCount = employeeCount
    }
}

// Helper to encode/decode SystemCalculationResult and EmployeeCalculationResult
extension SystemCalculationResult: Codable {
    enum CodingKeys: String, CodingKey {
        case totalDisbursements
        case totalCityContributions
        case totalEmployeeContributions
        case annualCityPayments
        case cityAnnualPercentOfPayroll
        case employeeResults
        case verificationResult
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalDisbursements = try container.decode(Double.self, forKey: .totalDisbursements)
        totalCityContributions = try container.decode(Double.self, forKey: .totalCityContributions)
        totalEmployeeContributions = try container.decode(Double.self, forKey: .totalEmployeeContributions)
        annualCityPayments = try container.decode(Double.self, forKey: .annualCityPayments)
        cityAnnualPercentOfPayroll = try container.decode(Double.self, forKey: .cityAnnualPercentOfPayroll)
        employeeResults = try container.decode([EmployeeCalculationResult].self, forKey: .employeeResults)
        verificationResult = try container.decodeIfPresent(ContributionVerificationResult.self, forKey: .verificationResult)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(totalDisbursements, forKey: .totalDisbursements)
        try container.encode(totalCityContributions, forKey: .totalCityContributions)
        try container.encode(totalEmployeeContributions, forKey: .totalEmployeeContributions)
        try container.encode(annualCityPayments, forKey: .annualCityPayments)
        try container.encode(cityAnnualPercentOfPayroll, forKey: .cityAnnualPercentOfPayroll)
        try container.encode(employeeResults, forKey: .employeeResults)
        try container.encodeIfPresent(verificationResult, forKey: .verificationResult)
    }
}

extension EmployeeCalculationResult: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case employee
        case totalDisbursements
        case initialAnnualPension
        case cityContributions
        case employeeContributions
        case yearsToRetire
        case retirementAge
        case spouseInitialAnnualPension
        case yearsReceivingSpousePension
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        employee = try container.decode(Employee.self, forKey: .employee)
        totalDisbursements = try container.decode(Double.self, forKey: .totalDisbursements)
        initialAnnualPension = try container.decode(Double.self, forKey: .initialAnnualPension)
        cityContributions = try container.decode(Double.self, forKey: .cityContributions)
        employeeContributions = try container.decode(Double.self, forKey: .employeeContributions)
        yearsToRetire = try container.decode(Int.self, forKey: .yearsToRetire)
        retirementAge = try container.decode(Int.self, forKey: .retirementAge)
        // Provide defaults for backward compatibility with existing saved data
        spouseInitialAnnualPension = try container.decodeIfPresent(Double.self, forKey: .spouseInitialAnnualPension) ?? 0
        yearsReceivingSpousePension = try container.decodeIfPresent(Int.self, forKey: .yearsReceivingSpousePension) ?? 0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(employee, forKey: .employee)
        try container.encode(totalDisbursements, forKey: .totalDisbursements)
        try container.encode(initialAnnualPension, forKey: .initialAnnualPension)
        try container.encode(cityContributions, forKey: .cityContributions)
        try container.encode(employeeContributions, forKey: .employeeContributions)
        try container.encode(yearsToRetire, forKey: .yearsToRetire)
        try container.encode(retirementAge, forKey: .retirementAge)
        try container.encode(spouseInitialAnnualPension, forKey: .spouseInitialAnnualPension)
        try container.encode(yearsReceivingSpousePension, forKey: .yearsReceivingSpousePension)
    }
}

extension ContributionVerificationResult: Codable {
    enum CodingKeys: String, CodingKey {
        case totalAvailableAtRetirement
        case totalNeededAtRetirement
        case surplus
        case isSufficient
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalAvailableAtRetirement = try container.decode(Double.self, forKey: .totalAvailableAtRetirement)
        totalNeededAtRetirement = try container.decode(Double.self, forKey: .totalNeededAtRetirement)
        surplus = try container.decode(Double.self, forKey: .surplus)
        isSufficient = try container.decode(Bool.self, forKey: .isSufficient)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(totalAvailableAtRetirement, forKey: .totalAvailableAtRetirement)
        try container.encode(totalNeededAtRetirement, forKey: .totalNeededAtRetirement)
        try container.encode(surplus, forKey: .surplus)
        try container.encode(isSufficient, forKey: .isSufficient)
    }
}

