import SwiftUI

struct AdaptiveLayout {
    static func contentWidth(geometry: GeometryProxy, horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        switch horizontalSizeClass {
        case .regular:
            // iPad - use much more space, better for forms
            return min(800, max(500, geometry.size.width * 0.75))
        default:
            // iPhone - current behavior
            return min(400, geometry.size.width * 0.8)
        }
    }
    
    static func formPadding(horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        switch horizontalSizeClass {
        case .regular:
            return 80 // Much more padding on iPad
        default:
            return 40 // Current iPhone padding
        }
    }
    
    static func verticalSpacing(horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        switch horizontalSizeClass {
        case .regular:
            return 60 // Much larger spacing on iPad
        default:
            return 32 // Current iPhone spacing
        }
    }
    
    static func sectionSpacing(horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        switch horizontalSizeClass {
        case .regular:
            return 32 // Much larger section spacing on iPad
        default:
            return 20 // Current iPhone spacing
        }
    }
    
    static func topPadding(horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        switch horizontalSizeClass {
        case .regular:
            return 100 // More top spacing on iPad to center content better
        default:
            return 40 // Current iPhone padding
        }
    }
}