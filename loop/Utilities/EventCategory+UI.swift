import SwiftUI

/// SwiftUI-specific additions to EventCategory.
/// Kept in Utilities (not Models) so the model layer stays free of UI imports.
extension EventCategory {

    var color: Color {
        switch self {
        case .fitness:  .green
        case .books:    .brown
        case .social:   .blue
        case .music:    .purple
        case .food:     .orange
        case .outdoors: .teal
        case .kids:     .pink
        case .other:    .gray
        }
    }
}
