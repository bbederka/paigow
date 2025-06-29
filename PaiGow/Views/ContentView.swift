import SwiftUI

// MARK: - Main Game Screen

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
                            DealerCardsGridView(dealerCards: viewModel.dealerCards)
                            
                            DealerHandsSummaryView(
                                dealerHighHand: viewModel.dealerHighHand,
                                dealerLowHand: viewModel.dealerLowHand
                            )
                        }
                        
                        Divider()
                        
                        // Side Bet Status
                        SideBetStatusView(aceHighSideBet: viewModel.aceHighSideBet)
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
                        HandValidationView(isValid: viewModel.isHandSetValid)
                            .padding(.horizontal)
                        
                        // Action Buttons
                        GameActionButtonsView(
                            isHandSetValid: viewModel.isHandSetValid,
                            onNewGame: {
                                viewModel.startNewGame()
                            },
                            onPlayHands: {
                                viewModel.playHands()
                            }
                        )
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
