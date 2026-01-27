import SwiftUI

struct WatchRunningView: View {
    @EnvironmentObject var runManager: WatchRunManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Timer
                Text(runManager.formattedDuration)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                // Stats Row
                HStack(spacing: 16) {
                    // Heart Rate
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("\(runManager.currentHR)")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    // Cadence
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text("\(runManager.currentCadence)")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                
                // Sprints Counter
                VStack(spacing: 2) {
                    Text("Sprints")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    HStack(spacing: 4) {
                        Text("\(runManager.sprintsCompleted)")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("/")
                            .foregroundColor(.gray)
                        Text("\(runManager.totalSprints)")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 4)
                
                // Recovery indicator
                if runManager.isInRecovery {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text("Recovery: \(Int(runManager.recoveryRemaining))s")
                    }
                    .font(.caption)
                    .foregroundColor(.cyan)
                }
                
                // Controls
                HStack(spacing: 20) {
                    Button {
                        runManager.pauseRun()
                    } label: {
                        Image(systemName: runManager.isPaused ? "play.fill" : "pause.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        runManager.endRun()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.red.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
                
                // MARK: - Debug Controls (scroll down to reveal)
                Divider()
                    .padding(.top, 20)
                
                VStack(spacing: 10) {
                    Text("DEBUG CONTROLS")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    Button {
                        runManager.debugTriggerSprint()
                    } label: {
                        Text("Trigger Sprint")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.3))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    HStack(spacing: 8) {
                        Button {
                            runManager.debugCompleteSprintSuccess()
                        } label: {
                            Text("Win")
                                .font(.caption2)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.3))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            runManager.debugCompleteSprintFail()
                        } label: {
                            Text("Fail")
                                .font(.caption2)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.3))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button {
                        runManager.debugTriggerPetCatch()
                    } label: {
                        Text("Catch Pet")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.purple.opacity(0.3))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        runManager.debugSkipRecovery()
                    } label: {
                        Text("Skip Recovery")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.cyan.opacity(0.3))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        runManager.debugTestAllHaptics()
                    } label: {
                        Text("Test All Haptics")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.yellow.opacity(0.3))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 20)
            }
            .padding()
        }
    }
}

#Preview {
    WatchRunningView()
        .environmentObject(WatchRunManager.shared)
}
