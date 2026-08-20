import SwiftUI

struct ClusterSendDialog: View {
    @ObservedObject var viewModel: DecodeViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var text1 = ""
    @State private var text2 = ""
    @State private var text3 = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Text an DX-Cluster senden")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                // Cluster 1
                VStack(alignment: .leading, spacing: 4) {
                    Text("DX Cluster 1:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("Befehl eingeben...", text: $text1)
                            .textFieldStyle(.roundedBorder)
                        Button("Senden") {
                            viewModel.sendToCluster(index: 1, text: text1)
                            text1 = ""
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .disabled(text1.isEmpty)
                    }
                }
                
                // Cluster 2
                VStack(alignment: .leading, spacing: 4) {
                    Text("DX Cluster 2:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("Befehl eingeben...", text: $text2)
                            .textFieldStyle(.roundedBorder)
                        Button("Senden") {
                            viewModel.sendToCluster(index: 2, text: text2)
                            text2 = ""
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .disabled(text2.isEmpty)
                    }
                }
                
                // Cluster 3
                VStack(alignment: .leading, spacing: 4) {
                    Text("DX Cluster 3:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("Befehl eingeben...", text: $text3)
                            .textFieldStyle(.roundedBorder)
                        Button("Senden") {
                            viewModel.sendToCluster(index: 3, text: text3)
                            text3 = ""
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .disabled(text3.isEmpty)
                    }
                }
            }
            .frame(width: 400)
            
            Divider()
            
            HStack {
                Spacer()
                Button(L("common.close")) {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
