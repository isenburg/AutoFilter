import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AutoQSO Help & Information")
                            .font(.title)
                            .bold()
                        Text("Copyright (c) Georg Isenbürger - DJ6GI")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("v\(APP_VERSION) (b\(APP_BUILD_NUMBER))")
                        .font(.callout)
                        .monospaced()
                        .padding(6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }
                
                Divider()
                
                // Section 1: Overview & WSJT-X
                Group {
                    Text("1. System Overview & WSJT-X Integration")
                        .font(.title2)
                        .bold()
                    Text("AutoQSO monitors incoming WSJT-X decodes via UDP (default 224.0.0.1:2237 or 127.0.0.1:2237). When Auto Mode is enabled, it automatically initiates calls to new unworked stations.")
                        .font(.body)
                }
                
                // Section 2: Triggers
                Group {
                    Text("2. Auto QSO Trigger Messages")
                        .font(.title2)
                        .bold()
                    Text("AutoQSO automatically evaluates the following decode types:\n• CQ Calls (CQ, CQ DX, CQ POTA, etc.)\n• 73 Messages (e.g. DL1ABC G4XYZ 73)\n• RR73 & RRR Messages (e.g. K1ABC W1AW RR73)\n\nStations already worked on the current band are dimmed in gray and will not re-trigger.")
                        .font(.body)
                }
                
                // Section 3: Disclaimer
                Group {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Legal & Safety Disclaimer")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        Text("Operator Responsibility & Regulatory Compliance:\n1. Control of Station: The licensed amateur radio operator remains solely responsible for all transmissions originating from their station under national telecommunications laws (e.g. BNetzA, FCC).\n2. Duty of Supervision: Always supervise station operation while Auto Mode is active.\n3. Disclaimer of Warranty: Software provided 'AS IS' without warranty of any kind. Copyright (c) Georg Isenbürger - DJ6GI.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Divider()
                
                // Section 4: Changelog
                Group {
                    Text("4. Changelog")
                        .font(.title2)
                        .bold()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Version \(APP_VERSION) (Build \(APP_BUILD_NUMBER)):")
                            .font(.headline)
                        Text("• Added 73, RR73, and RRR decode triggers in addition to CQ.\n• Fixed ARRL LoTW pre-2014 history query parameters (qso_qsos=1, qso_startdate=1900-01-01).\n• Fixed QRZ.com pre-2014 logbook sync (MODSINCE:1900-01-01).\n• Added build & release automation with DMG packaging.\n• Built-in SQLite logbook engine.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: 550, minHeight: 500)
    }
}
