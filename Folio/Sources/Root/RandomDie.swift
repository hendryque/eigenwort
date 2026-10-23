import SwiftUI

/// The random article button: a die on the paragraph mark's grid, its square
/// pips the height of the mark's words and the middle one in the accent, as
/// one word is in the mark. Quiet parts take the bar's inactive style.
struct RandomDie: View {
    /// Points per grid unit, a third of a point like the mark's.
    var unit: CGFloat = 1.0 / 3

    @Environment(\.folioTheme) private var theme

    private static let side: CGFloat = 45, rim: CGFloat = 5, radius: CGFloat = 10, pip: CGFloat = 7
    // Bottom left to top right, the middle one in the accent.
    private static let pips: [CGPoint] = [CGPoint(x: 9, y: 29), CGPoint(x: 19, y: 19), CGPoint(x: 29, y: 9)]
    private static let accent = 1

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Self.radius * unit, style: .continuous)
                .strokeBorder(lineWidth: Self.rim * unit)
                .foregroundStyle(theme.palette.inactiveStyle)
            ForEach(Self.pips.indices, id: \.self) { index in
                Rectangle()
                    .fill(index == Self.accent ? AnyShapeStyle(theme.palette.accentColor) : theme.palette.inactiveStyle)
                    .frame(width: Self.pip * unit, height: Self.pip * unit)
                    .offset(x: Self.pips[index].x * unit, y: Self.pips[index].y * unit)
            }
        }
        .frame(width: Self.side * unit, height: Self.side * unit)
    }
}
