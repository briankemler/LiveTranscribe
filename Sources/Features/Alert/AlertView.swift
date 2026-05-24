import SwiftUI
import UIKit

struct AlertView: View {
    let detection: SoundDetection

    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme
    @Environment(\.tweaks) private var tweaks

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private var headerKicker: String {
        "URGENT · " + Self.timeFormatter.string(from: detection.detectedAt)
    }

    private var confidencePercent: Int {
        max(0, min(100, Int((detection.confidence * 100).rounded())))
    }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()
            // Radial alert glow
            RadialGradient(
                colors: [theme.alert.opacity(0.28), .clear],
                center: .init(x: 0.5, y: 0.3),
                startRadius: 0,
                endRadius: 360
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TopBar(
                    title: "At home",
                    left: { IconButton(systemName: "chevron.left", action: { state.path.removeLast() }, color: theme.inkSoft, accessibilityLabel: "Back") },
                    right: { PrivacyPill() }
                )
                heroCard
                contextStack
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        // Trap VoiceOver focus inside this screen so the urgent alert can't be missed by
        // tabbing past it accidentally.
        .accessibilityAddTraits(.isModal)
        .onAppear {
            // Fire a strong error haptic on first appearance — for an accessibility-focused
            // alert, the buzz is half the value of the feature. We use `.error` (the three-tap
            // strong pattern) rather than `.warning` so it grabs attention through a pocket.
            // Rev-2 captions: gated by `tweaks.vibrateOnAlerts`. The VoiceOver
            // announcement below is unconditional so a deaf-blind user always hears the
            // alert label regardless of haptic preference.
            if tweaks.vibrateOnAlerts {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            // Post a VoiceOver announcement so users hear the alert even if focus hasn't
            // landed on the hero card yet. SwiftUI's `.accessibilityLabel` alone wouldn't
            // fire until focus shifts.
            UIAccessibility.post(notification: .announcement, argument: "\(detection.sound.label) detected, \(confidencePercent) percent confidence")
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(.white.opacity(0.18)).frame(width: 64, height: 64)
                    Image(systemName: detection.sound.icon)
                        .font(.scaled(size: 28, weight: .heavy, relativeTo: .title1))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(headerKicker)
                        .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.85))
                    Text(detection.sound.label)
                        .font(.scaled(size: 38, weight: .semibold, design: .serif, relativeTo: .largeTitle))
                        .tracking(-1)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.bottom, 18)

            Text("Detected just now · ")
                .font(.scaled(size: 14, relativeTo: .subheadline))
                .foregroundStyle(.white.opacity(0.92))
            + Text("\(confidencePercent)% match")
                .font(.scaled(size: 14, weight: .bold, relativeTo: .subheadline))
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                Button { state.path.removeLast() } label: {
                    Text("Dismiss")
                        .font(.scaled(size: 14, weight: .semibold, relativeTo: .subheadline))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Capsule().fill(.white.opacity(0.18)))
                }
                .buttonStyle(.plain)

                Button { state.path.removeLast() } label: {
                    Text("I see it")
                        .font(.scaled(size: 14, weight: .bold, relativeTo: .subheadline))
                        .foregroundStyle(theme.alert)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Capsule().fill(.white))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 18)
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.alert)
                // Diagonal stripes
                Stripes()
                    .fill(.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        )
        .shadow(color: theme.alert.opacity(0.4), radius: 30, y: 24)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var contextStack: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHAT'S AROUND")
                .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                .tracking(1.5)
                .foregroundStyle(theme.inkMute)
                .padding(.top, 24)

            // Past line
            VStack(alignment: .leading, spacing: 4) {
                Text("SAM · 14:01")
                    .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                    .tracking(0.4)
                    .foregroundStyle(theme.spkB)
                Text("I'll grab the kettle, you want tea?")
                    .font(.scaled(size: 15, relativeTo: .subheadline))
                    .foregroundStyle(theme.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.surface)
            )
            .overlay(
                Rectangle().fill(theme.spkB).frame(width: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)),
                alignment: .leading
            )
            .opacity(0.75)

            // Current line
            VStack(alignment: .leading, spacing: 4) {
                Text("SAM · NOW")
                    .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                    .tracking(0.4)
                    .foregroundStyle(theme.spkB)
                Text("Wait — that's the kitchen, hold on…")
                    .font(.scaled(size: 22, weight: .medium, design: .serif, relativeTo: .title2))
                    .tracking(-0.3)
                    .foregroundStyle(theme.ink)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.surfaceHi)
            )
            .overlay(
                Rectangle().fill(theme.spkB).frame(width: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)),
                alignment: .leading
            )
        }
        .padding(.horizontal, 20)
    }
}

private struct Stripes: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let stripeWidth: CGFloat = 16
        let spacing: CGFloat = 32
        let diagonal = sqrt(rect.width * rect.width + rect.height * rect.height)
        var x: CGFloat = -diagonal
        while x < diagonal * 2 {
            path.addRect(CGRect(x: x, y: -diagonal, width: stripeWidth, height: diagonal * 2))
            x += spacing
        }
        return path.applying(CGAffineTransform(rotationAngle: .pi / 4)
            .concatenating(CGAffineTransform(translationX: rect.width / 2, y: rect.height / 2)))
    }
}
