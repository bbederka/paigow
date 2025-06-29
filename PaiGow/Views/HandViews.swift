import SwiftUI

// MARK: - Hand Layout Components

struct HandLayoutView: View {
    let title: String
    let cards: [Card]
    let hand: Hand?
    let isValid: Bool
    let slots: Int
    let targetPosition: HandPosition
    let onCardMove: (Card, HandPosition) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isValid ? .primary : .red)
                
                Spacer()
                
                if let hand = hand {
                    Text(hand.rank.description)
                        .font(.caption)
                        .foregroundColor(isValid ? .green : .red)
                        .fontWeight(.semibold)
                }
            }
            
            // Cards touching each other with larger drop zones
            HStack(spacing: 2) { // Minimal spacing - cards almost touching
                ForEach(0..<slots, id: \.self) { slotIndex in
                    let cardForSlot = slotIndex < cards.count ? cards[slotIndex] : nil
                    
                    ZStack {
                        // Larger invisible drop zone around each card position
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 55, height: 70) // Generous drop area
                        
                        // Card slot with tighter visual spacing
                        ZStack {
                            // Slot background - only show when empty
                            if cardForSlot == nil {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isValid ? Color.green.opacity(0.6) : Color.red.opacity(0.6), 
                                                   lineWidth: 1, 
                                                   lineCap: .round)
                                            .dashPattern([5, 3])
                                    )
                                    .frame(width: 45, height: 60)
                                
                                // Empty slot indicator
                                VStack {
                                    Image(systemName: "rectangle.dashed")
                                        .font(.caption)
                                        .foregroundColor(.gray.opacity(0.7))
                                    Text("\(slotIndex + 1)")
                                        .font(.caption2)
                                        .foregroundColor(.gray.opacity(0.7))
                                }
                            }
                            
                            // Card if present
                            if let card = cardForSlot {
                                DraggableCardView(card: card, position: targetPosition) { newPosition in
                                    onCardMove(card, newPosition)
                                }
                            }
                        }
                    }
                    .contentShape(Rectangle()) // Make entire area tappable for drop zone
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isValid ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 2)
                )
        )
    }
}

struct DealerHandLayoutView: View {
    let title: String
    let cards: [Card]
    let hand: Hand?
    let slots: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let hand = hand {
                    Text(hand.rank.description)
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
            }
            
            // Dealer cards also touching for consistency
            HStack(spacing: 2) { // Minimal spacing - cards touching
                ForEach(0..<slots, id: \.self) { slotIndex in
                    let cardForSlot = slotIndex < cards.count ? cards[slotIndex] : nil
                    
                    ZStack {
                        // Empty slot background for dealer (when not all cards shown)
                        if cardForSlot == nil {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.green.opacity(0.5), lineWidth: 1)
                                )
                                .frame(width: 45, height: 60)
                            
                            VStack {
                                Image(systemName: "rectangle.dashed")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("\(slotIndex + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        } else {
                            StaticCardView(card: cardForSlot!)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 2)
                )
        )
    }
}

struct DealerCardsGridView: View {
    let dealerCards: [Card]
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Dealer Cards (Face Up)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Tighter grid spacing for dealer's initial cards
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 6) {
                ForEach(dealerCards) { card in
                    StaticCardView(card: card)
                }
            }
        }
    }
}

struct DealerHandsSummaryView: View {
    let dealerHighHand: Hand?
    let dealerLowHand: Hand?
    
    var body: some View {
        if let dealerHigh = dealerHighHand,
           let dealerLow = dealerLowHand {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dealer High")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(dealerHigh.rank.description)
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Dealer Low")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(dealerLow.rank.description)
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct HandValidationView: View {
    let isValid: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isValid ? .green : .red)
            
            Text(isValid ? "Hand setup is valid!" : "Invalid setup")
                .font(.caption)
                .foregroundColor(isValid ? .green : .red)
                .fontWeight(.semibold)
            
            if !isValid {
                Text("- Check hand counts and rankings")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Extension to add dashed stroke
extension Shape {
    func dashPattern(_ pattern: [CGFloat]) -> some View {
        self.stroke(style: StrokeStyle(lineWidth: 1, dash: pattern))
    }
}