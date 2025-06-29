import SwiftUI

// MARK: - Card UI Components

struct DraggableCardView: View {
    let card: Card
    let position: HandPosition
    let onMove: (HandPosition) -> Void
    
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isDragging ? Color.blue : Color.gray, lineWidth: isDragging ? 2 : 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
            
            VStack(spacing: 2) {
                if card.rank == .joker {
                    Text("🃏")
                        .font(.system(size: 20))
                } else {
                    Text(card.rank.symbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(card.suit.color)
                    
                    Text(card.suit.symbol)
                        .font(.system(size: 16))
                }
            }
        }
        .frame(width: 45, height: 60)
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .offset(dragOffset)
        .animation(.spring(response: 0.3), value: isDragging)
        .animation(.spring(response: 0.3), value: dragOffset)
        .gesture(
            DragGesture(minimumDistance: 15) // Slightly higher minimum for easier touch
                .onChanged { value in
                    dragOffset = value.translation
                    isDragging = true
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.3)) {
                        dragOffset = .zero
                        isDragging = false
                    }
                    
                    // Process drag to determine new position
                    let dragDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    
                    // More generous drag distance threshold
                    if dragDistance > 40 {
                        let dragY = value.translation.height
                        let dragX = value.translation.width
                        
                        // Simplified zone detection with larger zones
                        if abs(dragY) > abs(dragX) {
                            // Vertical drag
                            if dragY < -40 {
                                onMove(.lowHand)
                            } else if dragY > 40 {
                                onMove(.highHand)
                            }
                        } else {
                            // Horizontal drag - move to opposite hand
                            if position == .lowHand {
                                onMove(.highHand)
                            } else {
                                onMove(.lowHand)
                            }
                        }
                    }
                }
        )
        .onTapGesture(count: 2) {
            // Double tap to move between hands
            if position == .lowHand {
                onMove(.highHand)
            } else {
                onMove(.lowHand)
            }
        }
    }
}

struct StaticCardView: View {
    let card: Card
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
            
            VStack(spacing: 2) {
                if card.rank == .joker {
                    Text("🃏")
                        .font(.system(size: 20))
                } else {
                    Text(card.rank.symbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(card.suit.color)
                    
                    Text(card.suit.symbol)
                        .font(.system(size: 16))
                }
            }
        }
        .frame(width: 45, height: 60)
    }
}

struct CardSlotView: View {
    let slotNumber: Int
    let card: Card?
    let isValid: Bool
    
    var body: some View {
        ZStack {
            // Larger invisible drop zone for easier targeting
            Rectangle()
                .fill(Color.clear)
                .frame(width: 55, height: 70) // Larger than visible card
            
            // Visible slot
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isValid ? Color.green : Color.red, lineWidth: 1)
                    )
                    .frame(width: 45, height: 60)
                
                // Card if present
                if let card = card {
                    StaticCardView(card: card)
                } else {
                    // Empty slot indicator
                    VStack {
                        Image(systemName: "rectangle.dashed")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(slotNumber)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}