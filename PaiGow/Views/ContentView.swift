import SwiftUI

// MARK: - Core Game Models
enum Suit: CaseIterable {
    case hearts, diamonds, clubs, spades
    
    var symbol: String {
        switch self {
        case .hearts: return "♥️"
        case .diamonds: return "♦️"
        case .clubs: return "♣️"
        case .spades: return "♠️"
        }
    }
    
    var color: Color {
        switch self {
        case .hearts, .diamonds: return .red
        case .clubs, .spades: return .black
        }
    }
}

enum Rank: Int, CaseIterable, Comparable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack = 11, queen, king, ace = 14, joker = 15
    
    static func < (lhs: Rank, rhs: Rank) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    var symbol: String {
        switch self {
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .ten: return "10"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        case .ace: return "A"
        case .joker: return "🃏"
        }
    }
}

struct Card: Identifiable, Equatable {
    let id = UUID()
    let rank: Rank
    let suit: Suit
    
    var description: String {
        if rank == .joker {
            return "🃏"
        }
        return "\(rank.symbol)\(suit.symbol)"
    }
}

enum HandRank: Int, Comparable, CaseIterable {
    case highCard = 1, pair, twoPair, threeOfAKind, straight, flush, fullHouse, fourOfAKind, straightFlush, fiveAces
    
    static func < (lhs: HandRank, rhs: HandRank) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    var description: String {
        switch self {
        case .highCard: return "High Card"
        case .pair: return "Pair"
        case .twoPair: return "Two Pair"
        case .threeOfAKind: return "Three of a Kind"
        case .straight: return "Straight"
        case .flush: return "Flush"
        case .fullHouse: return "Full House"
        case .fourOfAKind: return "Four of a Kind"
        case .straightFlush: return "Straight Flush"
        case .fiveAces: return "Five Aces"
        }
    }
}

struct Hand {
    let cards: [Card]
    let rank: HandRank
    let tiebreakers: [Int]
    
    init(cards: [Card]) {
        self.cards = cards.sorted { $0.rank < $1.rank }
        let (rank, tiebreakers) = Hand.evaluateHand(self.cards)
        self.rank = rank
        self.tiebreakers = tiebreakers
    }
    
    static func evaluateHand(_ cards: [Card]) -> (HandRank, [Int]) {
        // Don't try to evaluate hands with wrong number of cards
        if cards.count != 2 && cards.count != 5 {
            return (.highCard, cards.map { $0.rank.rawValue }.sorted(by: >))
        }
        
        var ranks = cards.map { $0.rank }
        let suits = cards.map { $0.suit }
        
        // Handle joker
        let hasJoker = ranks.contains(.joker)
        if hasJoker {
            ranks = ranks.filter { $0 != .joker }
        }
        
        let rankCounts = Dictionary(grouping: ranks, by: { $0 }).mapValues { $0.count }
        let sortedCounts = rankCounts.values.sorted(by: >)
        
        // For 2-card hands (low hands), only check for pairs and high card
        if cards.count == 2 {
            if sortedCounts.first == 2 || hasJoker {
                let pairRank = hasJoker ? ranks.max()?.rawValue ?? 14 : rankCounts.max(by: { $0.value < $1.value })?.key.rawValue ?? 14
                return (.pair, [pairRank])
            } else {
                return (.highCard, ranks.sorted(by: >).map { $0.rawValue })
            }
        }
        
        // For 5-card hands, do full evaluation
        // Check for five aces
        if hasJoker && rankCounts[.ace] == 4 {
            return (.fiveAces, [14])
        }
        
        // Check for straight flush
        let isFlush = Set(suits).count == 1
        let isStraight = checkStraight(ranks: ranks, hasJoker: hasJoker)
        
        if isFlush && isStraight {
            return (.straightFlush, [ranks.max()?.rawValue ?? 14])
        }
        
        // Four of a kind
        if sortedCounts.first == 4 || (hasJoker && sortedCounts.first == 3) {
            return (.fourOfAKind, [rankCounts.max(by: { $0.value < $1.value })?.key.rawValue ?? 14])
        }
        
        // Full house
        if sortedCounts == [3, 2] || (hasJoker && sortedCounts == [2, 2]) {
            return (.fullHouse, [rankCounts.max(by: { $0.value < $1.value })?.key.rawValue ?? 14])
        }
        
        // Flush
        if isFlush {
            return (.flush, ranks.sorted(by: >).map { $0.rawValue })
        }
        
        // Straight
        if isStraight {
            return (.straight, [ranks.max()?.rawValue ?? 14])
        }
        
        // Three of a kind
        if sortedCounts.first == 3 || (hasJoker && sortedCounts.first == 2) {
            return (.threeOfAKind, [rankCounts.max(by: { $0.value < $1.value })?.key.rawValue ?? 14])
        }
        
        // Two pair
        if sortedCounts == [2, 2, 1] {
            return (.twoPair, rankCounts.filter { $0.value == 2 }.keys.sorted(by: >).map { $0.rawValue })
        }
        
        // Pair
        if sortedCounts.first == 2 || hasJoker {
            let pairRank = hasJoker ? ranks.max()?.rawValue ?? 14 : rankCounts.max(by: { $0.value < $1.value })?.key.rawValue ?? 14
            return (.pair, [pairRank])
        }
        
        // High card
        return (.highCard, ranks.sorted(by: >).map { $0.rawValue })
    }
    
    private static func checkStraight(ranks: [Rank], hasJoker: Bool) -> Bool {
        // Only check straights for 5-card hands
        if ranks.count + (hasJoker ? 1 : 0) != 5 {
            return false
        }
        
        let rankValues = ranks.map { $0.rawValue }.sorted()
        
        if hasJoker {
            // Check if joker can complete a straight
            for i in 0..<rankValues.count - 1 {
                if rankValues[i+1] - rankValues[i] == 2 {
                    return true // Joker fills the gap
                }
            }
            // Check for A-2-3-4 with joker as 5
            if Set(rankValues).isSubset(of: Set([2, 3, 4, 14])) {
                return true
            }
        }
        
        // Regular straight check - need exactly 5 consecutive values
        if rankValues.count != 5 { return false }
        
        for i in 0..<rankValues.count - 1 {
            if rankValues[i+1] - rankValues[i] != 1 {
                return false
            }
        }
        return true
    }
}

// Extend Hand to be Comparable
extension Hand: Comparable {
    static func < (lhs: Hand, rhs: Hand) -> Bool {
        if lhs.rank != rhs.rank {
            return lhs.rank < rhs.rank
        }
        
        for (left, right) in zip(lhs.tiebreakers, rhs.tiebreakers) {
            if left != right {
                return left < right
            }
        }
        return false
    }
}

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

// MARK: - Card Position Tracking
struct CardPosition {
    let card: Card
    var position: HandPosition
}

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
    
    // Computed properties for current hand state
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
    
    init() {
        createDeck()
        startNewGame()
    }
    
    private func createDeck() {
        deck = []
        
        // Standard 52 cards
        for suit in Suit.allCases {
            for rank in Rank.allCases where rank != .joker {
                deck.append(Card(rank: rank, suit: suit))
            }
        }
        
        // Add joker
        deck.append(Card(rank: .joker, suit: .hearts))
    }
    
    func startNewGame() {
        deck.shuffle()
        let playerCardsArray = Array(deck.prefix(7))
        dealerCards = Array(deck.dropFirst(7).prefix(7))
        
        // Initialize with optimal hand setup using house way
        let optimalSetup = getOptimalPlayerSetup(playerCardsArray)
        
        cardPositions = []
        // Place first 2 cards in low hand
        for card in optimalSetup.lowHand.cards {
            cardPositions.append(CardPosition(card: card, position: .lowHand))
        }
        // Place remaining 5 cards in high hand
        for card in optimalSetup.highHand.cards {
            cardPositions.append(CardPosition(card: card, position: .highHand))
        }
        
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
    
    private func getOptimalPlayerSetup(_ cards: [Card]) -> PlayerHands {
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
    
    private func validateHandSetup() {
        let lowCount = lowHandCards.count
        let highCount = highHandCards.count
        let dealtCount = dealtCards.count
        
        // Valid if we have exactly 2 in low hand and 5 in high hand (0 dealt)
        let hasCorrectCounts = lowCount == 2 && highCount == 5 && dealtCount == 0
        
        // Valid if high hand beats low hand OR ties with low hand
        var hasValidRanking = true
        if let lowHand = currentLowHand, let highHand = currentHighHand {
            hasValidRanking = highHand > lowHand || highHand.rank == lowHand.rank
        }
        
        isHandSetValid = hasCorrectCounts && hasValidRanking
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
    
    private func setDealerHands() {
        let dealerHands = setDealerHandsUsingHouseWay()
        dealerHighHand = dealerHands.highHand
        dealerLowHand = dealerHands.lowHand
    }
    
    private func setDealerHandsUsingHouseWay() -> PlayerHands {
        // Simplified house way - try all combinations and pick the strongest valid one
        var bestOption: PlayerHands?
        
        // Generate all possible 2-card combinations for low hand
        for i in 0..<dealerCards.count {
            for j in (i+1)..<dealerCards.count {
                let lowCards = [dealerCards[i], dealerCards[j]]
                let highCards = dealerCards.filter { card in
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
        
        // Fallback if no valid combination found
        return bestOption ?? PlayerHands(
            highHand: Hand(cards: Array(dealerCards.prefix(5))),
            lowHand: Hand(cards: Array(dealerCards.suffix(2)))
        )
    }
    
    private func determineWinner(playerLow: Hand, playerHigh: Hand) {
        guard let dealerHigh = dealerHighHand,
              let dealerLow = dealerLowHand else { return }
        
        // Check for dealer Ace-high Pai Gow (automatic push)
        if isDealerAceHighPaiGow() {
            gameResult = .push
            return
        }
        
        let playerWinsHigh = playerHigh > dealerHigh
        let playerWinsLow = playerLow > dealerLow
        
        if playerWinsHigh && playerWinsLow {
            gameResult = .playerWins
        } else if !playerWinsHigh && !playerWinsLow {
            gameResult = .dealerWins
        } else {
            gameResult = .push
        }
    }
    
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

// MARK: - UI Components

// MARK: - Draggable Card View
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
            DragGesture(minimumDistance: 10) // Require minimum drag distance
                .onChanged { value in
                    dragOffset = value.translation
                    isDragging = true
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.3)) {
                        dragOffset = .zero
                        isDragging = false
                    }
                    
                    // Much more lenient drop zone detection
                    let dragDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    
                    // Only process if dragged far enough
                    if dragDistance > 30 {
                        let dragY = value.translation.height
                        let dragX = value.translation.width
                        
                        // Simplified zone detection - less strict
                        if abs(dragY) > abs(dragX) {
                            // Vertical drag
                            if dragY < -30 {
                                onMove(.lowHand)
                            } else if dragY > 30 {
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
        // Add tap gesture as backup
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

// MARK: - Hand Layout View
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
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isValid ? Color.green : Color.red, lineWidth: 1)
                            )
                            .frame(width: 45, height: 60)
                        
                        // Card if present
                        if let card = cardForSlot {
                            DraggableCardView(card: card, position: targetPosition) { newPosition in
                                onCardMove(card, newPosition)
                            }
                        } else {
                            // Empty slot indicator
                            VStack {
                                Image(systemName: "rectangle.dashed")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("\(slotIndex + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
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

// MARK: - Dealer Hand Layout View
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
            
            // Individual card slots - same layout as player but no interaction
            HStack(spacing: 8) {
                ForEach(0..<slots, id: \.self) { slotIndex in
                    let cardForSlot = slotIndex < cards.count ? cards[slotIndex] : nil
                    
                    ZStack {
                        // Slot background - same style as player
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.green, lineWidth: 1)
                            )
                            .frame(width: 45, height: 60)
                        
                        // Card if present - same style as player but no dragging
                        if let cardForSlot = cardForSlot {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                                
                                VStack(spacing: 2) {
                                    if cardForSlot.rank == .joker {
                                        Text("🃏")
                                            .font(.system(size: 20))
                                    } else {
                                        Text(cardForSlot.rank.symbol)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(cardForSlot.suit.color)
                                        
                                        Text(cardForSlot.suit.symbol)
                                            .font(.system(size: 16))
                                    }
                                }
                            }
                            .frame(width: 45, height: 60)
                        } else {
                            // Empty slot indicator - same as player
                            VStack {
                                Image(systemName: "rectangle.dashed")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("\(slotIndex + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
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

// MARK: - Results View
struct ResultsView: View {
    let gameResult: GameResult?
    let fortuneBonus: FortuneBonus?
    let aceHighSideBet: AceHighSideBet?
    let onNewGame: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🎉 Game Results")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Main Game:")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(gameResult?.description ?? "Unknown")
                        .foregroundColor(resultColor)
                }
                
                HStack {
                    Text("💰 Fortune Bonus:")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(fortuneBonus?.handName ?? "No qualifying hand")
                }
                
                if let fortune = fortuneBonus {
                    HStack {
                        Text("Payout:")
                            .font(.caption)
                        Spacer()
                        Text(fortune.payout)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                HStack {
                    Text("🎯 Ace High Side Bet:")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(aceHighSideBet?.scenario ?? "No win")
                }
                
                if let aceHigh = aceHighSideBet {
                    HStack {
                        Text("Payout:")
                            .font(.caption)
                        Spacer()
                        Text(aceHigh.payout)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            Button("New Game") {
                onNewGame()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
    
    private var resultColor: Color {
        switch gameResult {
        case .playerWins: return .green
        case .dealerWins: return .red
        case .push: return .orange
        case .none: return .primary
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var viewModel = PaiGowViewModel()
    
    var body: some View {
        ZStack {
            // Green casino background
            Color.green.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Title
                Text("🃏 Face-Up Pai Gow Poker")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 8)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Dealer Section
                        VStack(spacing: 8) {
                            Text("Dealer Cards (Face Up)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                                ForEach(viewModel.dealerCards) { card in
                                    DraggableCardView(card: card, position: .dealt) { _ in }
                                }
                            }
                            
                            // Dealer Hands Display
                            if let dealerHigh = viewModel.dealerHighHand,
                               let dealerLow = viewModel.dealerLowHand {
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
                        
                        Divider()
                        
                        // Side Bet Results (only show if applicable)
                        VStack(alignment: .leading, spacing: 4) {
                            // Only show Ace High if dealer actually has it
                            if let aceHigh = viewModel.aceHighSideBet {
                                Text("🎯 Ace High Side Bet: \(aceHigh.scenario)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        
                        Divider()
                        
                        // Player Hand Setup Area
                        VStack(spacing: 12) {
                            Text("Set Your Hands")
                                .font(.headline)
                            
                            Text("Drag cards to swap positions, or double-tap to move between hands.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            // Low Hand Layout (2 slots)
                            HandLayoutView(
                                title: "Low Hand (2 cards)",
                                cards: viewModel.lowHandCards,
                                hand: viewModel.currentLowHand,
                                isValid: viewModel.lowHandCards.count == 2,
                                slots: 2,
                                targetPosition: .lowHand,
                                onCardMove: { card, position in
                                    viewModel.moveCard(card, to: position)
                                }
                            )
                            
                            // High Hand Layout (5 slots)
                            HandLayoutView(
                                title: "High Hand (5 cards)",
                                cards: viewModel.highHandCards,
                                hand: viewModel.currentHighHand,
                                isValid: viewModel.highHandCards.count == 5 && 
                                        (viewModel.currentHighHand != nil && viewModel.currentLowHand != nil ? 
                                         viewModel.currentHighHand! > viewModel.currentLowHand! : true),
                                slots: 5,
                                targetPosition: .highHand,
                                onCardMove: { card, position in
                                    viewModel.moveCard(card, to: position)
                                }
                            )
                        }
                        .padding(.horizontal)
                        
                        // Validation Status
                        HStack {
                            Image(systemName: viewModel.isHandSetValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(viewModel.isHandSetValid ? .green : .red)
                            
                            Text(viewModel.isHandSetValid ? "Hand setup is valid!" : "Invalid setup")
                                .font(.caption)
                                .foregroundColor(viewModel.isHandSetValid ? .green : .red)
                                .fontWeight(.semibold)
                            
                            if !viewModel.isHandSetValid {
                                Text("- Check hand counts and rankings")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action Buttons
                        HStack(spacing: 20) {
                            Button("New Game") {
                                viewModel.startNewGame()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Play Hands") {
                                viewModel.playHands()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!viewModel.isHandSetValid)
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingResults) {
            ResultsView(
                gameResult: viewModel.gameResult,
                fortuneBonus: viewModel.fortuneBonus,
                aceHighSideBet: viewModel.aceHighSideBet,
                onNewGame: {
                    viewModel.startNewGame()
                }
            )
        }
    }
}
