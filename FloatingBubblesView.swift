import SwiftUI

struct FloatingBubblesView: View {
    @State private var bubbles: [Bubble] = []
    let bubbleCount = 20

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    for bubble in bubbles {
                        let frame = CGRect(x: bubble.x, y: bubble.y, width: bubble.size, height: bubble.size)
                        context.fill(Circle().path(in: frame), with: .color(bubble.color.opacity(bubble.opacity)))
                    }
                }
                .onAppear {
                    self.bubbles = (0..<bubbleCount).map { _ in createBubble(geometry: geometry) }
                }
                .onChange(of: timeline.date) { _ in
                    for i in 0..<bubbles.count {
                        bubbles[i].y -= bubbles[i].speed
                        if bubbles[i].y < -bubbles[i].size {
                            bubbles[i] = createBubble(geometry: geometry, isInitial: false)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    private func createBubble(geometry: GeometryProxy, isInitial: Bool = true) -> Bubble {
        let size = CGFloat.random(in: 10...60)
        let x = CGFloat.random(in: 0...geometry.size.width)
        let y = isInitial ? CGFloat.random(in: 0...geometry.size.height) : geometry.size.height + size
        let speed = CGFloat.random(in: 0.5...2.0)
        let opacity = Double.random(in: 0.1...0.5)
        let color = [Color.white, Color(red: 0.8, green: 0.9, blue: 1.0)].randomElement()!

        return Bubble(x: x, y: y, size: size, speed: speed, opacity: opacity, color: color)
    }

    private struct Bubble {
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var speed: CGFloat
        var opacity: Double
        var color: Color
    }
}
