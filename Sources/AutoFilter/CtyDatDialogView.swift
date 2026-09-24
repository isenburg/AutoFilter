import SwiftUI

/// Ein Dialog zur manuellen Aktualisierung und Statusanzeige der CTY.DAT (DXCC-Präfix-Datenbank)
struct CtyDatDialogView: View {
    @Bindable var viewModel: DecodeViewModel
    @Environment(\.dismiss) private var dismiss
    @Bindable private var langManager = LanguageManager.shared
    
    private var isDe: Bool { langManager.isGerman }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "globe.europe.africa.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(isDe ? "CTY.DAT (DXCC- & Präfix-Datenbank)" : "CTY.DAT (DXCC & Prefix Database)")
                        .font(.headline)
                    Text(isDe
                         ? "Quelle: country-files.com von Jim Reisert, AD1C"
                         : "Source: country-files.com by Jim Reisert, AD1C")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
            
            // Description
            Text(isDe
                 ? "Die Datei CTY.DAT enthält die weltweiten Zuordnungen von Amateurfunk-Rufzeichen und Präfixen zu Ländern (DXCC), CQ- und ITU-Zonen sowie geografischen Koordinaten."
                 : "The CTY.DAT file contains worldwide mappings of amateur radio callsigns and prefixes to countries (DXCC), CQ and ITU zones, and geographical coordinates.")
                .font(.callout)
                .foregroundStyle(.secondary)
            
            // Status Info Box
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(isDe ? "Status / Letztes Update:" : "Status / Last Update:")
                        .font(.subheadline)
                        .bold()
                    Spacer()
                    if let date = viewModel.ctyLastUpdateDate {
                        Text(date.formatted(date: .long, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    } else {
                        Text(isDe ? "Noch nicht heruntergeladen (Offline-Basisdaten aktiv)" : "Not downloaded yet (Offline base data active)")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
                
                if let date = viewModel.ctyLastUpdateDate {
                    let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
                    HStack {
                        Text(isDe ? "Alter der Daten:" : "Data Age:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(days == 0
                             ? (isDe ? "Heute aktualisiert" : "Updated today")
                             : (isDe ? "Vor \(days) Tag(en)" : "\(days) day(s) ago"))
                            .font(.caption)
                            .foregroundStyle(days > 14 ? .orange : .secondary)
                    }
                }
                
                Divider()
                
                HStack {
                    Text(isDe ? "Geladene Präfixe:" : "Loaded Prefixes:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(viewModel.matcher.prefixCount)")
                        .font(.caption)
                        .bold()
                }
                
                HStack {
                    Text(isDe ? "Erkannte DXCC-Länder:" : "Recognized DXCC Countries:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(viewModel.matcher.allCountries().count)")
                        .font(.caption)
                        .bold()
                }
                
                HStack {
                    Text(isDe ? "Automatisches Update:" : "Automatic Update:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(isDe ? "Alle 14 Tage beim App-Start" : "Every 14 days on app launch")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
            
            // Progress or Status Message
            if viewModel.isUpdatingCty {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text(viewModel.ctyUpdateMessage.isEmpty
                         ? (isDe ? "Aktualisiere CTY.DAT..." : "Updating CTY.DAT...")
                         : viewModel.ctyUpdateMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            } else if !viewModel.ctyUpdateMessage.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.ctyUpdateMessage.contains("Fehler") || viewModel.ctyUpdateMessage.contains("Error")
                          ? "exclamationmark.triangle.fill"
                          : "checkmark.circle.fill")
                        .foregroundStyle(viewModel.ctyUpdateMessage.contains("Fehler") || viewModel.ctyUpdateMessage.contains("Error")
                                         ? .red : .green)
                        .font(.caption)
                    Text(viewModel.ctyUpdateMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
            
            Spacer()
            
            // Bottom Buttons
            HStack {
                Button(isDe ? "Schließen" : "Close") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(action: {
                    viewModel.updateCtyData()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text(isDe ? "Jetzt aktualisieren" : "Update Now")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isUpdatingCty)
            }
        }
        .padding(20)
        .frame(width: 480, height: 380)
    }
}
