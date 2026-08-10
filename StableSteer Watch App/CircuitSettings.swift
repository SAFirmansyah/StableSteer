//
//  CircuitSettings.swift
//  StableSteer
//
//  Created by Satria Adi Firmansyah on 10/08/26.
//


import Foundation
import Combine

/// Holds the currently selected circuit, persisted in UserDefaults.
/// Every new recording is tagged with whatever circuit is selected here.
final class CircuitSettings: ObservableObject {
    static let shared = CircuitSettings()

    @Published var selectedCircuit: Circuit {
        didSet {
            UserDefaults.standard.set(selectedCircuit.rawValue, forKey: Self.storageKey)
        }
    }

    private static let storageKey = "selectedCircuit"

    private init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let circuit = Circuit(rawValue: raw) {
            selectedCircuit = circuit
        } else {
            selectedCircuit = .monza
        }
    }
}