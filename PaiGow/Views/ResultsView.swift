import SwiftUI

// MARK: - Results and Side Bet Views

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

struct SideBetStatusView: View {
    let aceHighSideBet: AceHighSideBet?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let aceHigh = aceHighSideBet {
                Text("🎯 Ace High Side Bet: \(aceHigh.scenario)")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct GameActionButtonsView: View {
    let isHandSetValid: Bool
    let onNewGame: () -> Void
    let onPlayHands: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button("New Game") {
                onNewGame()
            }
            .buttonStyle(.bordered)
            
            Button("Play Hands") {
                onPlayHands()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isHandSetValid)
        }
    }
}
