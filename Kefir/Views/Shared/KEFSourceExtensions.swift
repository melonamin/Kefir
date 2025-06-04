import SwiftUI
import SwiftKEF

// MARK: - KEF Source Extensions

extension KEFSource {
    var displayName: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .bluetooth: return "Bluetooth"
        case .tv: return "TV"
        case .optic: return "Optical"
        case .coaxial: return "Coaxial"
        case .analog: return "Analog"
        case .usb: return "USB"
        }
    }
}