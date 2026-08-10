//
//  CircuitSettingsView.swift
//  StableSteer
//
//  Created by Satria Adi Firmansyah on 10/08/26.
//


import SwiftUI

struct CircuitSettingsView: View {
    @ObservedObject private var settings = CircuitSettings.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(Circuit.allCases) { circuit in
            Button {
                settings.selectedCircuit = circuit
                dismiss()
            } label: {
                HStack {
                    Text(circuit.rawValue)
                    Spacer()
                    if circuit == settings.selectedCircuit {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .navigationTitle("Circuit")
    }
}

#Preview {
    NavigationStack {
        CircuitSettingsView()
    }
}