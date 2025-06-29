import SwiftUI

// MARK: - Game View Model

@MainActor
class PaiGowViewModel: ObservableObject {
    @Published var dealerCards: [Card] = []
    @Published var cardPositions: [CardPosition] = []
    @Published var gameResult: GameResult?
    @Published var fortuneBonus: FortuneBonus?
    @Published var aceHighSideBet: AceHighSideBet?
    @Published var dealerHighHand: Hand?
    @Published var dealerLowHand: Hand?
    @Published var showingResults = false
    @Published var isHandSetValid = false
    
    private var deck: [Card] = []
    
    // MARK: - Computed Properties
    
    var playerCards: [Card] {
        cardPositions.map { $0.card }
    }
    
    var lowHandCards: [Card] {
        cardPositions.filter { $0.position == .lowHand }.map { $0.card }
    }
    
    var highHandCards: [Card] {
        cardPositions.filter { $0.position == .highHand }.map { $0.card }
    }
    
    var dealtCards: [Card] {
        cardPositions.filter { $0.position == .dealt }.map { $0.card }
    }
    
    var currentLowHand: Hand? {
        guard lowHandCards.count == 2 else { return nil }
        return Hand(cards: lowHandCards)
    }
    
    var currentHighHand: Hand? {
        guard highHandCards.count == 5 else { return nil }
        return Hand(cards: highHandCards)
    }
    
    // MARK: - Initialization
    
    init() {
        deck = GameLogic.createDeck()
        startNewGame()
    }
    
    // MARK: - Game Management
    
    func startNewGame() {
        deck.shuffle()
        let playerCardsArray = Array(deck.prefix(7))
        dealerCards = Array(deck.dropFirst(7).prefix(7))
        
        // Initialize with optimal hand setup using house way
        let optimalSetup = GameLogic.getOptimalPlayerSetup(playerCardsArray)
        
        cardPositions = []
        // Place cards in optimal positions
        for card in optimalSetup.lowHand.cards {
            cardPositions.append(CardPosition(card: card, position: .lowHand))
        }
        for card in optimalSetup.highHand.cards {
            cardPositions.append(CardPosition(card: card, position: .highHand))
        }
        
        // Reset game state
        gameResult = nil
        fortuneBonus = nil
        aceHighSideBet = nil
        dealerHighHand = nil
        dealerLowHand = nil
        showingResults = false
        isHandSetValid = true // Start with valid setup
        
        // Set dealer hands immediately (face up)
        setDealerHands()
    }
    
    func moveCard(_ card: Card, to newPosition: HandPosition) {
        guard let currentIndex = cardPositions.firstIndex(where: { $0.card.id == card.id }) else { return }
        
        let currentPosition = cardPositions[currentIndex].position
        
        // If moving to same position, do nothing
        if currentPosition == newPosition { return }
        
        // Check if target position has space or we're swapping
        let targetCards = cardPositions.filter { $0.position == newPosition }
        
        switch newPosition {
        case .lowHand:
            if targetCards.count >= 2 && currentPosition != .lowHand {
                // Swap with first card in low hand
                if let swapIndex = cardPositions.firstIndex(where: { $0.position == .lowHand }) {
                    cardPositions[swapIndex].position = currentPosition
                }
            }
        case .highHand:
            if targetCards.count >= 5 && currentPosition != .highHand {
                // Swap with first card in high hand
                if let swapIndex = cardPositions.firstIndex(where: { $0.position == .highHand }) {
                    cardPositions[swapIndex].position = currentPosition
                }
            }
        case .dealt:
            break // Can always move to dealt
        }
        
        cardPositions[currentIndex].position = newPosition
        validateHandSetup()
    }
    
    func playHands() {
        guard isHandSetValid,
              let lowHand = currentLowHand,
              let highHand = currentHighHand else { return }
        
        // Determine winner
        determineWinner(playerLow: lowHand, playerHigh: highHand)
        
        // Evaluate side bets
        evaluateFortuneBonus()
        evaluateAceHighSideBet()
        
        showingResults = true
    }
    
    // MARK: - Private Game Logic
    
    private func validateHandSetup() {
        isHandSetValid = GameLogic.validateHandSetup(
            lowCards: lowHandCards,
            highCards: highHandCards,
            dealtCards: dealtCards
        )
    }
    
    private func setDealerHands() {
        let dealerHands = GameLogic.getOptimalPlayerSetup(dealerCards)
        dealerHighHand = dealerHands.highHand
        dealerLowHand = dealerHands.lowHand
    }
    
    private func determineWinner(playerLow: Hand, playerHigh: Hand) {
        guard let dealerHigh = dealerHighHand,
              let dealerLow = dealerLowHand else { return }
        
        // Check for dealer Ace-high Pai Gow (automatic push)
        if isDealerAceHighPaiGow() {
            gameResult = .push
            return
        }
        
        gameResult = GameLogic.determineWinner(
            playerLow: playerLow,
            playerHigh: playerHigh,
            dealerLow: dealerLow,
            dealerHigh: dealerHigh
        )
    }
    
    // MARK: - Side Bet Evaluation
    
    private func evaluateFortuneBonus() {
        let bestHand = findBestPossibleFortuneHand(playerCards)
        
        switch bestHand.rank {
        case .fiveAces:
            fortuneBonus = FortuneBonus(handName: "Five Aces", payout: "400 to 1", multiplier: 400)
        case .straightFlush:
            if isRoyalStraightFlush(bestHand) {
                fortuneBonus = FortuneBonus(handName: "Royal Straight Flush", payout: "150 to 1", multiplier: 150)
            } else {
                fortuneBonus = FortuneBonus(handName: "Straight Flush", payout: "50 to 1", multiplier: 50)
            }
        case .fourOfAKind:
            fortuneBonus = FortuneBonus(handName: "Four of a Kind", payout: "25 to 1", multiplier: 25)
        case .fullHouse:
            fortuneBonus = FortuneBonus(handName: "Full House", payout: "5 to 1", multiplier: 5)
        case .flush:
            fortuneBonus = FortuneBonus(handName: "Flush", payout: "4 to 1", multiplier: 4)
        case .straight:
            fortuneBonus = FortuneBonus(handName: "Straight", payout: "3 to 1", multiplier: 3)
        case .threeOfAKind:
            fortuneBonus = FortuneBonus(handName: "Three of a Kind", payout: "3 to 1", multiplier: 3)
        default:
            fortuneBonus = nil
        }
    }
    
    private func evaluateAceHighSideBet() {
        let dealerAceHigh = isDealerAceHighPaiGow()
        let dealerUsesJoker = dealerCards.contains { $0.rank == .joker }
        let playerAceHigh = isPlayerAceHighPaiGow()
        
        if dealerAceHigh && playerAceHigh {
            aceHighSideBet = AceHighSideBet(
                scenario: "Both Player and Dealer Ace High Pai Gow",
                payout: "40 to 1",
                multiplier: 40
            )
        } else if dealerAceHigh && dealerUsesJoker {
            aceHighSideBet = AceHighSideBet(
                scenario: "Dealer Ace High Pai Gow (with Joker)",
                payout: "15 to 1",
                multiplier: 15
            )
        } else if dealerAceHigh {
            aceHighSideBet = AceHighSideBet(
                scenario: "Dealer Ace High Pai Gow (no Joker)",
                payout: "5 to 1",
                multiplier: 5
            )
        } else {
            aceHighSideBet = nil
        }
    }
    
    // MARK: - Helper Methods
    
    private func findBestPossibleFortuneHand(_ cards: [Card]) -> Hand {
        let combinations = generateFiveCardCombinations(cards)
        return combinations.max { lhs, rhs in
            if lhs.rank != rhs.rank {
                return lhs.rank < rhs.rank
            }
            for (left, right) in zip(lhs.tiebreakers, rhs.tiebreakers) {
                if left != right {
                    return left < right
                }
            }
            return false
        } ?? Hand(cards: Array(cards.prefix(5)))
    }
    
    private func generateFiveCardCombinations(_ cards: [Card]) -> [Hand] {
        var combinations: [Hand] = []
        let cardArray = Array(cards)
        
        for i in 0..<cardArray.count {
            for j in (i+1)..<cardArray.count {
                for k in (j+1)..<cardArray.count {
                    for l in (k+1)..<cardArray.count {
                        for m in (l+1)..<cardArray.count {
                            let fiveCards = [cardArray[i], cardArray[j], cardArray[k], cardArray[l], cardArray[m]]
                            combinations.append(Hand(cards: fiveCards))
                        }
                    }
                }
            }
        }
        
        return combinations
    }
    
    private func isRoyalStraightFlush(_ hand: Hand) -> Bool {
        if hand.rank != .straightFlush { return false }
        let ranks = hand.cards.map { $0.rank.rawValue }.sorted()
        return ranks == [10, 11, 12, 13, 14]
    }
    
    private func isDealerAceHighPaiGow() -> Bool {
        guard let dealerHigh = dealerHighHand,
              let dealerLow = dealerLowHand else { return false }
        
        let bothHighCard = dealerHigh.rank == .highCard && dealerLow.rank == .highCard
        let hasAceOrJoker = dealerCards.contains { $0.rank == .ace || $0.rank == .joker }
        
        return bothHighCard && hasAceOrJoker
    }
    
    private func isPlayerAceHighPaiGow() -> Bool {
        guard let playerHigh = currentHighHand,
              let playerLow = currentLowHand else { return false }
        
        let bothHighCard = playerHigh.rank == .highCard && playerLow.rank == .highCard
        let hasAceOrJoker = playerCards.contains { $0.rank == .ace || $0.rank == .joker }
        
        return bothHighCard && hasAceOrJoker
    }
}
