//
//  ContentView.swift
//  PumpWater-iOS
//
//  Created by 이명진 on 8/19/24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var frequency: Double = 0.0 // 기본 주파수 (440Hz)
    @State private var isPlaying = false
    @State private var timeRemaining = 600
    @State private var maxTime = 600
    @State private var timer: Timer?
    
    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var format: AVAudioFormat
    
    init() {
        let sampleRate = 40100.0
        let channelCount = 1
        self.format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: AVAudioChannelCount(channelCount))!
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("💦 Time Remaining:\n \(timeRemaining) seconds")
                .font(.largeTitle)
                .padding()
                .lineLimit(2)
            
            Slider(value: Binding(
                get: { Double(self.timeRemaining) },
                set: { newValue in
                    self.timeRemaining = Int(newValue)
                    self.maxTime = self.timeRemaining
                }
            ), in: 0...600, step: 1)
            .padding()
            .accentColor(.blue)
            
            Button(action: {
                if isPlaying {
                    stopTone()
                } else {
                    startTimer()
                    playTone(frequency: frequency)
                }
                isPlaying.toggle()
            }) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
            }
            
            Slider(value: $frequency, in: 20...2600, step: 1)
                .padding()
                .accentColor(.blue)
                .onChange(of: frequency) { newValue in
                    if isPlaying {
                        updateTone(frequency: newValue)
                    }
                }
            
            Text("⚡️ Frequency: \(Int(frequency)) Hz")
                .foregroundColor(Color.black)
                .padding()
            
            Text("❗️If you cannot hear sound, \n please turn off silent mode.")
                .foregroundColor(Color.black)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()
            
            // 앱 버전 추가
            if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                HStack {
                    Spacer()
                    Text("🌟 version: \(appVersion) v")
                        .foregroundColor(.black)
                        .padding()
                        .padding(.bottom, 70)
                        .padding(.trailing, 10)
                }
            }
        }
        .onDisappear {
            stopTone()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
    }
    
    private func playTone(frequency: Double) {
        let sampleRate = self.format.sampleRate
        let samplesPerCycle = sampleRate / frequency
        var currentSample = 0.0
        
        let bufferCapacity = AVAudioFrameCount(format.sampleRate / 10 + 1.1) // 샘플 버퍼
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferCapacity)!
        buffer.frameLength = bufferCapacity
        
        let bufferPointer = buffer.floatChannelData![0]
        
        for i in 0..<Int(bufferCapacity) {
            bufferPointer[i] = Float(sin(2.0 * .pi * (currentSample / samplesPerCycle)))
            currentSample += 1
        }
        
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        
        playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        
        do {
            try audioEngine.start()
            playerNode.play()
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
    }
    
    private func updateTone(frequency: Double) {
        if playerNode.isPlaying {
            playerNode.stop()
            playTone(frequency: frequency)
        }
    }
    
    private func stopTone() {
        playerNode.stop()
        audioEngine.stop()
        audioEngine.reset()
        
        timer?.invalidate()
        timer = nil
    }
    
    private func startTimer() {
        timer?.invalidate()  // 기존 타이머가 있으면 종료
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.stopTone()
                isPlaying = false
                timeRemaining = 120
            }
        }
    }
}

#Preview {
    ContentView()
}
