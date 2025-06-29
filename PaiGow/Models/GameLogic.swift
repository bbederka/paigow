import Foundation

// MARK: - Game Logic Models

struct FortuneBonus {
    let handName: String
    let payout: String
    let multiplier: Int
}

struct AceHighSideBet {
    let scenario: String
    let payout: String
    let multiplier: Int
}

enum GameResult {
    case playerWins, dealerWins, push
    
    var description: String {
        switch self {
        case .playerWins: return "Player Wins!"
        case .dealerWins: return "Dealer Wins"
        case .push: return "Push (Tie)"
        }
    }
}

struct PlayerHands {
    let highHand: Hand
    let lowHand: Hand
}

enum HandPosition {
    case dealt, lowHand, highHand
}

struct CardPosition {
    let card: Card
    var position: HandPosition
}

// MARK: - Game Utilities

struct GameLogic {
    
    static func createDeck() -> [Card] {
        var deck: [Card] = []
        
        // Standard 52 cards
        for suit in Suit.allCases {
            for rank in Rank.allCases where rank != .joker {
                deck.append(Card(rank: rank, suit: suit))
            }
        }
        
        // Add joker
        deck.append(Card(rank: .joker, suit: .hearts))
        
        return deck
    }
    
    static func getOptimalPlayerSetup(_ cards: [Card]) -> PlayerHands {
        // Use simplified house way to get a valid starting setup
        var bestOption: PlayerHands?
        
        // Generate all possible 2-card combinations for low hand
        for i in 0..<cards.count {
            for j in (i+1)..<cards.count {
                let lowCards = [cards[i], cards[j]]
                let highCards = cards.filter { card in
                    !lowCards.contains { $0.id == card.id }
                }
                
                let lowHand = Hand(cards: lowCards)
                let highHand = Hand(cards: highCards)
                
                // Valid if high hand beats low hand
                if highHand > lowHand {
                    let option = PlayerHands(highHand: highHand, lowHand: lowHand)
                    
                    if bestOption == nil || 
                       highHand > bestOption!.highHand ||
                       (highHand.rank == bestOption!.highHand.rank && lowHand > bestOption!.lowHand) {
                        bestOption = option
                    }
                }
            }
        }
        
        // Fallback if no valid combination found (shouldn't happen)
        return bestOption ?? PlayerHands(
            highHand: Hand(cards: Array(cards.prefix(5))),
            lowHand: Hand(cards: Array(cards.suffix(2)))
        )
    }
    
    static func validateHandSetup(lowCards: [Card], highCards: [Card], dealtCards: [Card]) -> Bool {
        let lowCount = lowCards.count
        let highCount = highCards.count
        let dealtCount = dealtCards.count
        
        // Valid if we have exactly 2 in low hand and 5 in high hand (0 dealt)
        let hasCorrectCounts = lowCount == 2 && highCount == 5 && dealtCount == 0
        
        // Valid if high hand beats low hand OR ties with low hand
        var hasValidRanking = true
        if lowCount == 2 && highCount == 5 {
            let lowHand = Hand(cards: lowCards)
            let highHand = Hand(cards: highCards)
            hasValidRanking = highHand > lowHand || highHand.rank == lowHand.rank
        }
        
        return hasCorrectCounts && hasValidRanking
    }
    
    static func determineWinner(playerLow: Hand, playerHigh: Hand, dealerLow: Hand, dealerHigh: Hand) -> GameResult {
        let playerWinsHigh = playerHigh > dealerHigh
        let playerWinsLow = playerLow > dealerLow
        
        if playerWinsHigh && playerWinsLow {
            return .playerWins
        } else if !playerWinsHigh && !playerWinsLow {
            return .dealerWins
        } else {
            return .push
        }
    }
}
