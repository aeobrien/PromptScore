import SwiftUI

struct MinimalTestSheetView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Minimal Test Sheet")
                .font(.largeTitle)
                .padding()
                .background(Color.green.opacity(0.3))

            Text("If you see this, the sheet presentation mechanism is working to some extent.")
                .multilineTextAlignment(.center)
                .padding()

            Button("Dismiss") {
                dismiss()
            }
            .padding()
        }
        .onAppear {
            print("MinimalTestSheetView: .onAppear called.")
        }
        .frame(width: 400, height: 300)
    }
}

#Preview {
    MinimalTestSheetView()
} 