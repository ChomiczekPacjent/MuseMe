import SwiftUI

struct SegmentedProgressBar: View {
    var currentStep: Int
    var totalSteps: Int   

    var body: some View {
        GeometryReader { geometry in
            let gap: CGFloat = 4
            let segmentWidth = (geometry.size.width - gap * CGFloat(totalSteps - 1)) / CGFloat(totalSteps)
            
            HStack(spacing: gap) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Rectangle()
                        .foregroundColor(index < currentStep ? .purple : Color.gray.opacity(0.3))
                        .frame(width: segmentWidth, height: 4)
                }
            }
        }
        .frame(height: 4)
    }
}
