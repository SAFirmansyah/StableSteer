//
//  Circuits.swift
//  StableSteer
//
//  Created by Satria Adi Firmansyah on 10/08/26.
//

import Foundation

/// The list of circuits selectable on the watch before recording a session.
/// Add new tracks here — both apps pick this up automatically.
enum Circuit: String, CaseIterable, Codable, Identifiable {
    case spaFrancorchamps = "Spa-Francorchamps"
    case daytona = "Daytona"
    case monza = "Monza"

    var id: String { rawValue }
}
