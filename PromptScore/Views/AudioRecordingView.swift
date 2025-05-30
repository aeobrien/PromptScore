//
//  AudioRecordingView.swift
//  PromptScore
//
//  Created by Aidan O'Brien on 30/05/2025.
//

import SwiftUI
import AVFoundation // Needed for AudioManager

struct AudioRecordingView: View {
    @StateObject private var audioManager = AudioManager()
    @ObservedObject var viewModel: ScriptViewModel
    let sentenceId: UUID
    @Environment(\.dismiss) var dismiss
    
    // @State private var recordingURL: URL?
    // @State private var permissionRequested = false
    @State private var isAwaitingPermissionResponse = false // We might need this again with the permission request

    var body: some View {
        let _ = print("AudioRecordingView: body evaluated (permissionRequest ON). AudioManager: \\(audioManager.isRecording), HasPerm: \\(audioManager.hasPermission), Denied: \\(audioManager.permissionDenied), Awaiting: \\(isAwaitingPermissionResponse)")

        VStack(spacing: 20) {
            Text("DEBUG: ARV (Permission Request ON)")
                .font(.largeTitle)
                .padding()
                .background(Color.orange.opacity(0.3)) // New color: Orange
                .border(Color.orange)

            Text("Passed Sentence ID: \\(sentenceId.uuidString)").font(.body).padding()
            Text("Script paragraphs: \\(viewModel.script?.paragraphs.count ?? 0)").font(.caption)
            Text("Mic Permission: \\(audioManager.hasPermission.description)").font(.caption)
            Text("Permission Denied: \\(audioManager.permissionDenied.description)").font(.caption)
            Text("Awaiting Perm Response (View State): \\(isAwaitingPermissionResponse.description)").font(.caption)
            Text("Awaiting Perm Response (AudioMgr): \\(audioManager.waitingForPermission.description)").font(.caption)


            if isAwaitingPermissionResponse || audioManager.waitingForPermission {
                ProgressView("Awaiting Microphone Permission...")
            } else if audioManager.permissionDenied {
                Text("Microphone permission was denied.")
                    .foregroundColor(.red)
            } else if audioManager.hasPermission {
                Text("Microphone permission granted!")
                    .foregroundColor(.green)
            } else {
                Text("Microphone permission status: Undetermined or other.")
            }

            Button("Test Dismiss") { dismiss() }.padding()
        }
        .frame(width: 500, height: 400)
        .onAppear {
            print("AudioRecordingView: .onAppear called (permissionRequest ON). AudioManager init: \\(audioManager != nil)")
            requestMicrophonePermissionIfNeeded() // Re-enable this call
        }
    }
    
    // Make sure this function is available (uncommented if it was fully commented)
    private func requestMicrophonePermissionIfNeeded() {
        #if os(macOS)
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        print("AudioRecordingView: requestMicrophonePermissionIfNeeded - current mic status: \\(currentStatus)")

        if currentStatus == .notDetermined {
            print("AudioRecordingView: requestMicrophonePermissionIfNeeded - status is .notDetermined. Setting isAwaitingPermissionResponse = true and calling audioManager.requestMicrophonePermission.")
            isAwaitingPermissionResponse = true // For UI reaction
            audioManager.requestMicrophonePermission { [self] granted in // Ensure [self] is used if accessing self
                print("AudioRecordingView: requestMicrophonePermissionIfNeeded - audioManager.requestMicrophonePermission completion. Granted: \\(granted). Setting isAwaitingPermissionResponse = false.")
                // AudioManager's published properties (permissionDenied, hasPermission via status check) will drive main UI updates.
                // isAwaitingPermissionResponse is mostly for the ProgressView in this local view.
                isAwaitingPermissionResponse = false
            }
        } else {
            print("AudioRecordingView: requestMicrophonePermissionIfNeeded - status is already \\(currentStatus). Setting isAwaitingPermissionResponse = false.")
            isAwaitingPermissionResponse = false // Ensure UI is not stuck in awaiting state
            // If permission was already denied/granted, AudioManager's state should reflect this.
            // We might need to explicitly update audioManager.permissionDenied if status is .denied here and audioManager doesn't know yet.
            if currentStatus == .denied || currentStatus == .restricted {
                audioManager.permissionDenied = true
            }
        }
        #else
        print("AudioRecordingView: requestMicrophonePermissionIfNeeded - not macOS, skipping.")
        #endif
    }
}

#Preview {
    AudioRecordingView(viewModel: ScriptViewModel(), sentenceId: UUID())
}

extension Animation {
    static func pulse(duration: Double) -> Animation {
        Animation.easeInOut(duration: duration)
    }
}