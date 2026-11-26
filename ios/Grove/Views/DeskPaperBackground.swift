import SwiftUI

/// Warm linen desk surface with a soft lamp glow — direction A “书桌盆栽”.
struct DeskPaperBackground: View {
    var wilted: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: wilted
                    ? [Color(hex: "E4E0DA"), Color(hex: "D5D0C8")]
                    : [GroveTheme.paperTop, GroveTheme.paperBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft desk lamp wash
            RadialGradient(
                colors: [
                    wilted ? Color.clear : GroveTheme.warmGlow,
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 340
            )
            .offset(x: 40, y: -80)

            // Subtle fiber grain
            Canvas { context, size in
                for i in 0..<48 {
                    let x = CGFloat((i * 47) % Int(size.width))
                    let y = CGFloat((i * 89) % Int(size.height))
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x + 12, y: y + 1))
                    context.stroke(
                        path,
                        with: .color(.black.opacity(0.03)),
                        lineWidth: 0.6
                    )
                }
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.55), value: wilted)
    }
}
