import SwiftUI

enum LoopColors {
    // Warm backgrounds
    static let background   = Color("LoopBackground")    // #FBF7EF light / #1A1614 dark
    static let surface      = Color("LoopSurface")       // #FFFFFF light / #24201D dark (cards)
    static let surfaceBorder = Color("LoopSurfaceBorder") // warm stroke for cards

    // Text
    static let textPrimary   = Color("LoopTextPrimary")   // #1A1614 light / #FBF7EF dark
    static let textSecondary = Color("LoopTextSecondary") // #6B6158 light / #A89E93 dark

    // Accents
    static let accent   = Color("LoopAccent")   // #D96B3F burnt orange
    static let verified = Color("LoopVerified") // #2C4A3E forest green
    static let warning  = Color("LoopWarning")  // #E8B33E mustard
    static let success  = Color("LoopAccent")   // inherit from accent
}

enum LoopFonts {
    static func serifTitle(_ size: CGFloat) -> Font {
        .custom("Fraunces-Bold", size: size)
    }
    static func serifSemibold(_ size: CGFloat) -> Font {
        .custom("Fraunces-SemiBold", size: size)
    }
    static func sansBody(_ size: CGFloat = 16) -> Font {
        .custom("Inter-Regular", size: size)
    }
    static func sansMedium(_ size: CGFloat = 14) -> Font {
        .custom("Inter-Medium", size: size)
    }
    static func sansSemibold(_ size: CGFloat = 14) -> Font {
        .custom("Inter-SemiBold", size: size)
    }
}

enum LoopRadius {
    static let card: CGFloat   = 20
    static let button: CGFloat = 14
    static let chip: CGFloat   = 20
}

enum LoopSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}
