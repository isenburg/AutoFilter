import SwiftUI
import AppKit

@main
struct AutoQSOInstallerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            InstallerContentView()
                .frame(width: 540, height: 480)
                .fixedSize()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

enum InstallTarget: Int, CaseIterable, Identifiable {
    case systemApplications = 1
    case userApplications = 2
    case customFolder = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .systemApplications:
            return "/Applications"
        case .userApplications:
            return "~/Applications"
        case .customFolder:
            return "Benutzerdefinierter Ordner..."
        }
    }

    var subtitle: String {
        switch self {
        case .systemApplications:
            return "Systemweiter Programme-Ordner (Empfohlen)"
        case .userApplications:
            return "Programme im persönlichen Benutzerordner"
        case .customFolder:
            return "Ordner frei über den Finder auswählen"
        }
    }

    var icon: String {
        switch self {
        case .systemApplications:
            return "folder.badge.gearshape"
        case .userApplications:
            return "person.crop.square"
        case .customFolder:
            return "folder"
        }
    }
}

enum InstallState {
    case ready
    case installing(step: Int, message: String)
    case success(destinationPath: String)
    case failed(message: String)
}

struct InstallerContentView: View {
    @State private var selectedTarget: InstallTarget = .systemApplications
    @State private var customFolderPath: String = ""
    @State private var installState: InstallState = .ready
    @State private var launchAfterInstall: Bool = true
    @State private var sourceAppURL: URL? = nil
    @State private var showOverwriteAlert: Bool = false
    @State private var pendingTargetURL: URL? = nil

    private var targetDirectoryURL: URL {
        switch selectedTarget {
        case .systemApplications:
            return URL(fileURLWithPath: "/Applications")
        case .userApplications:
            let home = FileManager.default.homeDirectoryForCurrentUser
            return home.appendingPathComponent("Applications")
        case .customFolder:
            if !customFolderPath.isEmpty {
                return URL(fileURLWithPath: customFolderPath)
            }
            return URL(fileURLWithPath: "/Applications")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Main Content Area
            VStack(alignment: .leading, spacing: 16) {
                switch installState {
                case .ready:
                    readyView
                case .installing(let step, let message):
                    installingView(step: step, message: message)
                case .success(let path):
                    successView(path: path)
                case .failed(let message):
                    failedView(message: message)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Divider()

            // Footer / Actions
            footerView
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            locateSourceApp()
        }
        .alert("Bestehende Version überschreiben?", isPresented: $showOverwriteAlert) {
            Button("Überschreiben", role: .destructive) {
                if let target = pendingTargetURL {
                    executeInstallation(destinationDir: target, overwrite: true)
                }
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("In '\(targetDirectoryURL.path)' existiert bereits eine Version von AutoQSO. Möchtest du diese durch die neue Version ersetzen?")
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack(spacing: 16) {
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
            } else {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                    .frame(width: 56, height: 56)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("AutoQSO macOS Installer")
                    .font(.title2)
                    .bold()
                Text("1-Klick Installation & Gatekeeper Quarantäne-Fix")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }

    private var readyView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Wohin möchtest du AutoQSO installieren?")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(InstallTarget.allCases) { target in
                    Button(action: {
                        selectedTarget = target
                        if target == .customFolder && customFolderPath.isEmpty {
                            selectCustomFolder()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: selectedTarget == target ? "largecircle.fill.circle" : "circle")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(selectedTarget == target ? .accentColor : .secondary)

                            Image(systemName: target.icon)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .frame(width: 22)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(target.title)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(target == .customFolder && !customFolderPath.isEmpty ? customFolderPath : target.subtitle)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            if target == .customFolder {
                                Button("Auswählen...") {
                                    selectCustomFolder()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding(10)
                        .background(selectedTarget == target ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedTarget == target ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.green)
                    Text("Automatischer macOS Gatekeeper Fix")
                        .font(.system(size: 11, weight: .bold))
                }
                Text("Der Installer entfernt automatisch Quarantäne-Sperren (xattr -cr) und frischt die ad-hoc Code-Signatur auf, damit AutoQSO direkt ohne Warnungen startet.")
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(Color.green.opacity(0.08))
            .cornerRadius(8)
        }
    }

    private func installingView(step: Int, message: String) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Installation wird durchgeführt...")
                .font(.headline)

            VStack(alignment: .leading, spacing: 14) {
                installStepRow(stepNumber: 1, currentStep: step, title: "AutoQSO.app in Zielordner kopieren")
                installStepRow(stepNumber: 2, currentStep: step, title: "macOS Gatekeeper Quarantäne entfernen (xattr -cr)")
                installStepRow(stepNumber: 3, currentStep: step, title: "Ad-hoc Code-Signatur auffrischen (codesign)")
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func installStepRow(stepNumber: Int, currentStep: Int, title: String) -> some View {
        HStack(spacing: 10) {
            if currentStep > stepNumber {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 14))
            } else if currentStep == stepNumber {
                ProgressView()
                    .controlSize(.mini)
                    .frame(width: 14, height: 14)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.secondary.opacity(0.5))
                    .font(.system(size: 14))
            }

            Text(title)
                .font(.system(size: 12, weight: currentStep == stepNumber ? .semibold : .regular))
                .foregroundColor(currentStep >= stepNumber ? .primary : .secondary)

            Spacer()
        }
    }

    private func successView(path: String) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundColor(.green)

            VStack(spacing: 6) {
                Text("Installation erfolgreich!")
                    .font(.title2)
                    .bold()

                Text("AutoQSO wurde erfolgreich installiert und für den sicheren Start auf deinem Mac vorbereitet.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text("Zielort: \(path)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }

            Toggle("AutoQSO jetzt sofort starten", isOn: $launchAfterInstall)
                .font(.system(size: 12, weight: .medium))
                .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func failedView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)

            VStack(spacing: 6) {
                Text("Installation fehlgeschlagen")
                    .font(.title2)
                    .bold()

                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            Button("Erneut versuchen") {
                installState = .ready
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var footerView: some View {
        HStack {
            Button("Beenden") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.cancelAction)

            Spacer()

            switch installState {
            case .ready:
                Button(action: startInstallation) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("AutoQSO Installieren")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)

            case .installing:
                Button("Wird installiert...") { }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(true)

            case .success(let destPath):
                Button("Fertigstellen") {
                    if launchAfterInstall {
                        let destURL = URL(fileURLWithPath: destPath)
                        NSWorkspace.shared.open(destURL)
                    }
                    NSApp.terminate(nil)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)

            case .failed:
                EmptyView()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Logic

    private func locateSourceApp() {
        let fm = FileManager.default
        let mainBundleURL = Bundle.main.bundleURL
        let dir = mainBundleURL.deletingLastPathComponent()

        // 1. Next to installer bundle
        let candidate1 = dir.appendingPathComponent("AutoQSO.app")
        if fm.fileExists(atPath: candidate1.path) {
            sourceAppURL = candidate1
            return
        }

        // 2. Parent directory
        let candidate2 = dir.deletingLastPathComponent().appendingPathComponent("AutoQSO.app")
        if fm.fileExists(atPath: candidate2.path) {
            sourceAppURL = candidate2
            return
        }

        // 3. Search /Volumes
        if let volumes = try? fm.contentsOfDirectory(at: URL(fileURLWithPath: "/Volumes"), includingPropertiesForKeys: nil) {
            for vol in volumes {
                let candidate = vol.appendingPathComponent("AutoQSO.app")
                if fm.fileExists(atPath: candidate.path) {
                    sourceAppURL = candidate
                    return
                }
            }
        }
    }

    private func selectCustomFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Zielordner wählen"
        panel.title = "Zielordner für AutoQSO auswählen"

        if panel.runModal() == .OK, let url = panel.url {
            customFolderPath = url.path
            selectedTarget = .customFolder
        }
    }

    private func startInstallation() {
        guard sourceAppURL != nil else {
            installState = .failed(message: "Die Quelldatei 'AutoQSO.app' wurde im DMG oder Verzeichnis nicht gefunden.")
            return
        }

        let targetDir = targetDirectoryURL
        let destAppURL = targetDir.appendingPathComponent("AutoQSO.app")

        if FileManager.default.fileExists(atPath: destAppURL.path) {
            pendingTargetURL = targetDir
            showOverwriteAlert = true
            return
        }

        executeInstallation(destinationDir: targetDir, overwrite: false)
    }

    private func executeInstallation(destinationDir: URL, overwrite: Bool) {
        guard let source = sourceAppURL else { return }
        let destAppURL = destinationDir.appendingPathComponent("AutoQSO.app")

        installState = .installing(step: 1, message: "Kopiere AutoQSO nach '\(destinationDir.path)'...")

        DispatchQueue.global(qos: .userInitiated).async {
            let fm = FileManager.default

            do {
                // Ensure target directory exists
                try fm.createDirectory(at: destinationDir, withIntermediateDirectories: true, attributes: nil)

                // Remove existing if overwrite
                if fm.fileExists(atPath: destAppURL.path) {
                    try fm.removeItem(at: destAppURL)
                }

                // Step 1: Copy
                try fm.copyItem(at: source, to: destAppURL)

                DispatchQueue.main.async {
                    self.installState = .installing(step: 2, message: "Entferne macOS Gatekeeper Quarantäne (xattr -cr)...")
                }

                // Step 2: xattr -cr
                let xattrProcess = Process()
                xattrProcess.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
                xattrProcess.arguments = ["-cr", destAppURL.path]
                try? xattrProcess.run()
                xattrProcess.waitUntilExit()

                DispatchQueue.main.async {
                    self.installState = .installing(step: 3, message: "Aktualisiere ad-hoc Code-Signatur (codesign)...")
                }

                // Step 3: codesign
                let codesignProcess = Process()
                codesignProcess.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
                codesignProcess.arguments = ["--force", "--deep", "--sign", "-", destAppURL.path]
                try? codesignProcess.run()
                codesignProcess.waitUntilExit()

                DispatchQueue.main.async {
                    self.installState = .success(destinationPath: destAppURL.path)
                }
            } catch {
                DispatchQueue.main.async {
                    self.installState = .failed(message: "Fehler während der Installation: \(error.localizedDescription)")
                }
            }
        }
    }
}
