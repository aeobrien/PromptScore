//
//  AudioManager.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import AVFoundation
import SwiftUI

@MainActor
class AudioManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingTime: TimeInterval = 0
    @Published var currentPlaybackTime: TimeInterval = 0
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var playbackTimer: Timer?
    
    override init() {
        super.init()
        print("AudioManager: init called.") // DEBUG
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        #if os(macOS)
        let initialStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        print("AudioManager: configureAudioSession - initial mic status: \\(initialStatus)") // DEBUG
        
        // We will NOT automatically request permission here if .notDetermined.
        // The request will be driven by the UI calling the public requestMicrophonePermission method.
        /* 
        if initialStatus == .notDetermined {
            print("AudioManager: configureAudioSession - status is .notDetermined, calling private requestMicrophonePermission() to trigger system prompt if needed.") // DEBUG
        }
        // Request microphone permission on macOS. This calls the private version.
        requestMicrophonePermission()
        */
        #else
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        #endif
    }
    
    #if os(macOS)
    private func requestMicrophonePermission() {
        // This is the private version previously called by init().
        // It is NO LONGER CALLED by configureAudioSession to avoid auto-requesting on init.
        // Keeping the method here for now in case it's needed later, but it's effectively unused.
        print("AudioManager (private request - currently unused): Attempting AVCaptureDevice.requestAccess.") // DEBUG
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                print("AudioManager (private request - currently unused): AVCaptureDevice.requestAccess completion. Granted: \\(granted)") // DEBUG
            }
        }
    }
    #endif
    
    @Published var permissionDenied = false
    @Published var waitingForPermission = false
    
    var hasPermission: Bool {
        #if os(macOS)
        let currentAuthStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        // print("AudioManager: hasPermission check. Status: \\(currentAuthStatus)") // DEBUG - Can be noisy
        return currentAuthStatus == .authorized
        #else
        return true
        #endif
    }
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        #if os(macOS)
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        print("AudioManager (public request): Called. Current microphone status: \\(status)") // DEBUG
        
        switch status {
        case .authorized:
            print("AudioManager (public request): Status .authorized.") // DEBUG
            self.permissionDenied = false
            self.waitingForPermission = false
            completion(true)
        case .notDetermined:
            print("AudioManager (public request): Status .notDetermined. Requesting system access.") // DEBUG
            self.waitingForPermission = true // UI can react to this
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    print("AudioManager (public request): System access request completed. Granted: \\(granted)") // DEBUG
                    self.waitingForPermission = false
                    self.permissionDenied = !granted
                    completion(granted)
                }
            }
        case .denied, .restricted:
            print("AudioManager (public request): Status .denied or .restricted.") // DEBUG
            self.permissionDenied = true
            self.waitingForPermission = false
            completion(false)
        @unknown default:
            print("AudioManager (public request): Status unknown (\(status.rawValue)). Defaulting to denied.") // DEBUG
            self.permissionDenied = true
            self.waitingForPermission = false
            completion(false)
        }
        #else
        completion(true)
        #endif
    }
    
    func startRecording() -> URL? {
        // Check microphone permission on macOS
        #if os(macOS)
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        print("Current microphone status: \(status)")
        
        if status != .authorized {
            print("Microphone not authorized. Status: \(status)")
            return nil
        }
        #endif
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            
            let success = audioRecorder?.record() ?? false
            print("Recording started successfully: \(success)")
            print("Recording to: \(audioFilename)")
            
            isRecording = true
            recordingTime = 0
            
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.recordingTime = self.audioRecorder?.currentTime ?? 0
            }
            
            return audioFilename
        } catch {
            print("Failed to start recording: \(error)")
            return nil
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        
        // Check if file was created and has content
        if let url = audioRecorder?.url {
            let fileExists = FileManager.default.fileExists(atPath: url.path)
            print("Recording stopped. File exists: \(fileExists)")
            
            if fileExists {
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                    let fileSize = attributes[.size] as? NSNumber
                    print("File size: \(fileSize?.intValue ?? 0) bytes")
                } catch {
                    print("Could not get file attributes: \(error)")
                }
            }
        }
    }
    
    func playAudio(from url: URL) {
        print("Attempting to play audio from: \(url)")
        print("File exists: \(FileManager.default.fileExists(atPath: url.path))")
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            
            // Enable the audio player's rate control
            audioPlayer?.enableRate = true
            
            let success = audioPlayer?.play() ?? false
            print("Audio player play() returned: \(success)")
            print("Audio duration: \(audioPlayer?.duration ?? 0)")
            print("Audio volume: \(audioPlayer?.volume ?? 0)")
            
            isPlaying = true
            currentPlaybackTime = 0
            
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.currentPlaybackTime = self.audioPlayer?.currentTime ?? 0
            }
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        playbackTimer?.invalidate()
        playbackTimer = nil
        isPlaying = false
        currentPlaybackTime = 0
    }
    
    func deleteAudio(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Failed to delete audio: \(error)")
        }
    }
}

extension AudioManager: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            isRecording = false
        }
    }
}

extension AudioManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            stopPlayback()
        }
    }
}