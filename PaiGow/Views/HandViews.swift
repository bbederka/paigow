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
            
            // Individual card slots
            HStack(spacing: 8) {
                ForEach(0..<slots, id: \.self) { slotIndex in
                    let cardForSlot = slotIndex < cards.count ? cards[slotIndex] : nil
                    
                    ZStack {
                        // Slot background
                        CardSlotView(
                            slotNumber: slotIndex + 1,
                            card: nil,
                            isValid: isValid
                        )
                        
                        // Card if present
                        if let card = cardForSlot {
                            DraggableCardView(card: card, position: targetPosition) { newPosition in
                                onCardMove(card, newPosition)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
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
            
            // Individual card slots - no interaction
            HStack(spacing: 8) {
                ForEach(0..<slots, id: \.self) { slotIndex in
                    let cardForSlot = slotIndex < cards.count ? cards[slotIndex] : nil
                    
                    CardSlotView(
                        slotNumber: slotIndex + 1,
                        card: cardForSlot,
                        isValid: true
                    )
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct DealerCardsGridView: View {
    let dealerCards: [Card]
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Dealer Cards (Face Up)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
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
