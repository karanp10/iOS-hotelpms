import SwiftUI

struct OnboardingFormContainer<Content: View>: View {
    let content: () -> Content
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                HStack {
                    Spacer()
                    
                    VStack(spacing: AdaptiveLayout.verticalSpacing(horizontalSizeClass: horizontalSizeClass)) {
                        Spacer()
                            .frame(minHeight: AdaptiveLayout.topPadding(horizontalSizeClass: horizontalSizeClass))
                        
                        content()
                        
                        Spacer()
                            .frame(minHeight: AdaptiveLayout.formPadding(horizontalSizeClass: horizontalSizeClass))
                    }
                    .frame(width: AdaptiveLayout.contentWidth(geometry: geometry, horizontalSizeClass: horizontalSizeClass))
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .navigationBarHidden(true)
    }
}