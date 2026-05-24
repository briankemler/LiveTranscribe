import SwiftUI

/// Animated bar waveform. Mirrors the source `Waveform` and the smaller inline waves in `SpeakerHeader`.
struct Waveform: View {
    let color: Color
    var count: Int = 14
    var height: CGFloat = 18
    var barWidth: CGFloat = 3

    @State private var phase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(color.opacity(0.4 + Double(i % 3) * 0.25))
                    .frame(width: barWidth, height: barHeight(for: i))
                    .animation(
                        reduceMotion
                            ? .default
                            : .easeInOut(duration: 0.7 + Double(i % 3) * 0.2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.05),
                        value: phase
                    )
            }
        }
        .accessibilityHidden(true)
        .onAppear { phase = 1 }
    }

    private func barHeight(for i: Int) -> CGFloat {
        let base: CGFloat = 4 + abs(CGFloat(sin(Double(i) * 0.5))) * height
        return phase == 0 ? base * 0.6 : base
    }
}
