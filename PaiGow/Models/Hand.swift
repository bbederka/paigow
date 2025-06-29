import Foundation

// MARK: - Hand Evaluation

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
