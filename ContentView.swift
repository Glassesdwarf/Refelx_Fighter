import SwiftUI
import AVFoundation

// MARK: - GAME STATE

class GameState: ObservableObject {
    
    // HP
    @Published var playerHP = 100
    @Published var enemyHP = 1000
    
    // Enemy attack direction
    @Published var currentAttack = "⬆️"
    
    // Feint attack
    @Published var isFeint = false
    
    // Message
    @Published var message = "Get Ready!"
    
    // Combo
    @Published var combo = 0
    
    // Attack phase
    @Published var inAttackPhase = false
    
    // Attack timer
    @Published var attackTimeLeft = 5
    
    // Dodge timer
    @Published var dodgeTimeLeft = 1.0
    
    // Game over
    @Published var gameOver = false
    
    // Shake animation
    @Published var enemyShake = false
    @Published var playerShake = false
    
    // Timers
    var attackTimer: Timer?
    var dodgeTimer: Timer?
    
    // Audio
    var slashPlayer: AVAudioPlayer?
    var enemyAttackPlayer: AVAudioPlayer?
    
    // Directions
    let directions = ["⬆️","⬇️","⬅️","➡️"]
    
    // MARK: - OPPOSITE DIRECTION
    
    func oppositeDirection(of direction: String) -> String {
        
        switch direction {
        case "⬆️":
            return "⬇️"
        case "⬇️":
            return "⬆️"
        case "⬅️":
            return "➡️"
        case "➡️":
            return "⬅️"
        default:
            return direction
        }
    }
    
    // MARK: - FEINT SYMBOLS
    
    func displayAttackSymbol() -> String {
        
        if !isFeint {
            return currentAttack
        }
        
        switch currentAttack {
        case "⬆️":
            return "🔺"
        case "⬇️":
            return "🔻"
        case "⬅️":
            return "◀️"
        case "➡️":
            return "▶️"
        default:
            return currentAttack
        }
    }
    
    // MARK: - SOUND
    
    func playSound(name: String) {
        
        if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
            
            do {
                
                let player = try AVAudioPlayer(contentsOf: url)
                
                player.volume = 0.7
                
                player.play()
                
                if name == "slash_sound" {
                    slashPlayer = player
                } else {
                    enemyAttackPlayer = player
                }
                
            } catch {
                print("Sound error")
            }
        }
    }
    
    // MARK: - Start Enemy Attack
    
    func startNewAttack() {
        
        currentAttack = directions.randomElement()!
        
        // 25% chance feint
        isFeint = Bool.random() && Bool.random()
        
        if isFeint {
            message = "FEINT ATTACK!"
        } else {
            message = "Enemy attacks \(currentAttack)"
        }
        
        playSound(name: "enemy_attack_sound")
        
        dodgeTimeLeft = 1.0
        
        // Remove old timer
        dodgeTimer?.invalidate()
        
        // Start dodge timer
        dodgeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            
            self.dodgeTimeLeft -= 0.1
            
            // Too slow
            if self.dodgeTimeLeft <= 0 {
                
                timer.invalidate()
                
                self.playerHP -= 10
                
                self.combo = 0
                
                self.message = "TOO SLOW! -10 HP"
                
                // Shake player
                self.playerShake.toggle()
                
                // Lose condition
                if self.playerHP <= 0 {
                    
                    self.playerHP = 0
                    
                    self.gameOver = true
                    
                    self.message = "💀 GAME OVER"
                    
                } else {
                    
                    self.startNewAttack()
                }
            }
        }
    }
    
    // MARK: - Dodge
    
    func dodge(input: String) {
        
        guard !inAttackPhase else { return }
        guard !gameOver else { return }
        
        dodgeTimer?.invalidate()
        
        // Determine correct answer
        let correctDirection =
            isFeint
            ? oppositeDirection(of: currentAttack)
            : currentAttack
        
        // Correct input
        if input == correctDirection {
            
            combo += 1
            
            if isFeint {
                message = "FEINT READ!"
            } else {
                message = "Perfect Dodge!"
            }
            
            // Start attack phase
            if combo >= 3 {
                
                startAttackPhase()
                
            } else {
                
                startNewAttack()
            }
            
        } else {
            
            // Wrong dodge
            playerHP -= 10
            
            combo = 0
            
            message = "Wrong Dodge! -10 HP"
            
            // Shake player
            playerShake.toggle()
            
            // Lose condition
            if playerHP <= 0 {
                
                playerHP = 0
                
                gameOver = true
                
                message = "💀 GAME OVER"
                
            } else {
                
                startNewAttack()
            }
        }
    }
    
    // MARK: - Attack Phase
    
    func startAttackPhase() {
        
        inAttackPhase = true
        
        attackTimeLeft = 5
        
        message = "⚔️ ATTACK FAST!"
        
        attackTimer?.invalidate()
        
        attackTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            
            self.attackTimeLeft -= 1
            
            if self.attackTimeLeft <= 0 {
                
                timer.invalidate()
                
                self.endAttackPhase()
            }
        }
    }
    
    // MARK: - Attack
    
    func attack() {
        
        guard inAttackPhase else { return }
        guard !gameOver else { return }
        
        playSound(name: "slash_sound")
        
        enemyHP -= 5
        
        message = "⚔️ HIT!"
        
        // Shake enemy
        enemyShake.toggle()
        
        // Win condition
        if enemyHP <= 0 {
            
            enemyHP = 0
            
            gameOver = true
            
            message = "🏆 YOU WIN!"
            
            attackTimer?.invalidate()
        }
    }
    
    // MARK: - End Attack Phase
    
    func endAttackPhase() {
        
        inAttackPhase = false
        
        combo = 0
        
        if !gameOver {
            
            message = "Enemy Turn!"
            
            startNewAttack()
        }
    }
    
    // MARK: - Restart
    
    func restartGame() {
        
        playerHP = 100
        enemyHP = 1000
        
        combo = 0
        
        inAttackPhase = false
        
        attackTimeLeft = 5
        
        dodgeTimeLeft = 1.0
        
        gameOver = false
        
        isFeint = false
        
        message = "Get Ready!"
        
        attackTimer?.invalidate()
        dodgeTimer?.invalidate()
        
        startNewAttack()
    }
}

// MARK: - MAIN VIEW

struct ContentView: View {
    
    @StateObject var game = GameState()
    
    var body: some View {
        
        ZStack {
            
            // Background
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                
                // Title
                Text("Reflex Fighter")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                
                // HP Display
                HStack(spacing: 40) {
                    
                    VStack {
                        
                        Text("❤️ Player")
                            .foregroundColor(.white)
                        
                        Text("\(game.playerHP)")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                    
                    VStack {
                        
                        Text("👾 Enemy")
                            .foregroundColor(.white)
                        
                        Text("\(game.enemyHP)")
                            .font(.title)
                            .foregroundColor(.red)
                    }
                }
                
                // Message
                Text(game.message)
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Combo
                if !game.inAttackPhase {
                    
                    Text("Combo: \(game.combo)/3")
                        .foregroundColor(.yellow)
                }
                
                Spacer()
                
                // MARK: - DODGE PHASE
                
                if !game.inAttackPhase && !game.gameOver {
                    
                    VStack(spacing: 25) {
                        
                        Text("Incoming Attack")
                            .foregroundColor(.white)
                            .font(.title2)
                        
                        // Enemy Sprite
                        Image("enemy")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .offset(x: game.enemyShake ? 10 : -10)
                            .animation(.easeInOut(duration: 0.1), value: game.enemyShake)
                        
                        // Attack Symbol
                        Text(game.displayAttackSymbol())
                            .font(.system(size: 80))
                            .foregroundColor(game.isFeint ? .purple : .white)
                        
                        // Feint Text
                        if game.isFeint {
                            Text("FEINT! Press opposite direction!")
                                .foregroundColor(.purple)
                                .bold()
                        }
                        
                        Text("Tap matching direction!")
                            .foregroundColor(.gray)
                        
                        // Dodge Timer
                        Text(String(format: "Time Left: %.1f", game.dodgeTimeLeft))
                            .foregroundColor(.red)
                            .font(.title2)
                        
                        // Controls
                        VStack(spacing: 15) {
                            
                            Button(action: {
                                game.dodge(input: "⬆️")
                            }) {
                                Text("⬆️")
                                    .font(.largeTitle)
                            }
                            
                            HStack(spacing: 25) {
                                
                                Button(action: {
                                    game.dodge(input: "⬅️")
                                }) {
                                    Text("⬅️")
                                        .font(.largeTitle)
                                }
                                
                                Button(action: {
                                    game.dodge(input: "⬇️")
                                }) {
                                    Text("⬇️")
                                        .font(.largeTitle)
                                }
                                
                                Button(action: {
                                    game.dodge(input: "➡️")
                                }) {
                                    Text("➡️")
                                        .font(.largeTitle)
                                }
                            }
                        }
                    }
                }
                
                // MARK: - ATTACK PHASE
                
                if game.inAttackPhase && !game.gameOver {
                    
                    VStack(spacing: 25) {
                        
                        Text("⚔️ ATTACK PHASE ⚔️")
                            .font(.title)
                            .bold()
                            .foregroundColor(.orange)
                        
                        // Player Sprite
                        Image("player")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                            .offset(x: game.playerShake ? 10 : -10)
                            .animation(.easeInOut(duration: 0.1), value: game.playerShake)
                        
                        Text("Time Left: \(game.attackTimeLeft)")
                            .foregroundColor(.white)
                            .font(.title2)
                        
                        // Attack Button
                        Button(action: {
                            game.attack()
                        }) {
                            
                            VStack {
                                
                                Image("slash")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                
                                Text("TAP TO ATTACK!")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                
                // MARK: - GAME OVER
                
                if game.gameOver {
                    
                    Button(action: {
                        game.restartGame()
                    }) {
                        
                        Text("Restart Game")
                            .font(.title2)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            game.startNewAttack()
        }
    }
}