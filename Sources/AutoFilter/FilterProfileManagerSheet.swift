import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct FilterProfileManagerSheet: View {
    @Bindable var viewModel: DecodeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProfileId: String = ""
    @State private var isShowingDeleteAlert = false
    @State private var profileToDelete: FilterProfile? = nil
    
    private var isDe: Bool { LanguageManager.shared.isGerman }
    
    private let availableIcons = [
        "bookmark.fill",
        "bolt.fill",
        "trophy.fill",
        "map.fill",
        "mic.fill",
        "globe.europe.africa.fill",
        "antenna.radiowaves.left.and.right",
        "star.fill",
        "tag.fill",
        "flag.fill",
        "target",
        "sparkles"
    ]
    
    private let availableBands = ["--", "160m", "80m", "60m", "40m", "30m", "20m", "17m", "15m", "12m", "10m", "6m", "2m", "70cm"]
    private let availableModes = ["--", "FT8", "FT4", "SSB", "CW", "RTTY"]

    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 12) {
                Image(systemName: "slider.horizontal.2.square")
                    .font(.system(size: 20))
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(isDe ? "Filter-Profile verwalten" : "Manage Filter Profiles")
                        .font(.headline)
                    Text(isDe ? "Konfiguriere, sichere und organisiere deine Filter-Presets" : "Configure, save, and organize your filter presets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(isDe ? "Fertig" : "Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.regular)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Two-pane Master-Detail
            HSplitView {
                // Left Pane: Profiles List
                VStack(spacing: 0) {
                    List(selection: $selectedProfileId) {
                        Section(header: Text(isDe ? "System-Vorlagen" : "System Presets").font(.caption2).bold()) {
                            ForEach(viewModel.filterProfiles.filter { $0.isSystem }) { profile in
                                profileRow(profile)
                                    .tag(profile.id)
                            }
                        }
                        
                        Section(header: Text(isDe ? "Benutzerdefinierte Profile" : "Custom Profiles").font(.caption2).bold()) {
                            ForEach(viewModel.filterProfiles.filter { !$0.isSystem }) { profile in
                                profileRow(profile)
                                    .tag(profile.id)
                            }
                        }
                    }
                    .listStyle(.sidebar)
                    
                    Divider()
                    
                    // Left Bottom Actions
                    HStack(spacing: 10) {
                        Button {
                            importProfile()
                        } label: {
                            Label(isDe ? "Importieren..." : "Import...", systemImage: "square.and.arrow.down")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Spacer()
                        
                        Button {
                            duplicateSelected()
                        } label: {
                            Label(isDe ? "Duplizieren" : "Duplicate", systemImage: "plus.square.on.square")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(selectedProfile == nil)
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                }
                .frame(minWidth: 260, idealWidth: 280, maxWidth: 320)
                
                // Right Pane: Detail & Editor
                ScrollView(.vertical) {
                    if let profile = selectedProfile {
                        profileDetailEditor(profile)
                            .padding(24)
                    } else {
                        VStack(spacing: 14) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 44))
                                .foregroundStyle(.tertiary)
                            Text(isDe ? "Wähle ein Profil aus der linken Liste" : "Select a profile from the left list")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 350)
                    }
                }
                .frame(minWidth: 480, maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .frame(minWidth: 780, idealWidth: 840, maxWidth: 960, minHeight: 560, idealHeight: 620, maxHeight: 750)
        .onAppear {
            if selectedProfileId.isEmpty {
                selectedProfileId = viewModel.activeFilterProfileId
            }
        }
        .alert(isDe ? "Profil löschen?" : "Delete Profile?", isPresented: $isShowingDeleteAlert) {
            Button(isDe ? "Abbrechen" : "Cancel", role: .cancel) {}
            Button(isDe ? "Löschen" : "Delete", role: .destructive) {
                if let toDel = profileToDelete {
                    viewModel.deleteFilterProfile(id: toDel.id)
                    selectedProfileId = viewModel.activeFilterProfileId
                }
            }
        } message: {
            Text(isDe ? "Möchtest du das Profil '\(profileToDelete?.name ?? "")' wirklich unwiderruflich löschen?" : "Are you sure you want to permanently delete '\(profileToDelete?.name ?? "")'?")
        }
    }
    
    private var selectedProfile: FilterProfile? {
        viewModel.filterProfiles.first(where: { $0.id == selectedProfileId })
    }
    
    @ViewBuilder
    private func profileRow(_ profile: FilterProfile) -> some View {
        let isActive = profile.id == viewModel.activeFilterProfileId
        let isDirty = isActive && viewModel.isFilterProfileModified
        
        HStack(spacing: 10) {
            Image(systemName: profile.iconName)
                .font(.system(size: 13))
                .foregroundStyle(isDirty ? Color.orange : (isActive ? Color.blue : Color.secondary))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(profile.name)
                        .font(.system(size: 12, weight: isActive ? .bold : .regular))
                        .foregroundStyle(isDirty ? Color.orange : Color.primary)
                    
                    if isDirty {
                        Text("*")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.orange)
                    }
                }
                
                if let auto = profile.autoBand, !auto.isEmpty {
                    Text("Auto: \(auto)")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if isDirty {
                Text(isDe ? "geändert" : "modified")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.orange.opacity(0.15))
                    .foregroundStyle(Color.orange)
                    .clipShape(Capsule())
            } else if isActive {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 6, height: 6)
            }
            
            if profile.isSystem {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func profileDetailEditor(_ profile: FilterProfile) -> some View {
        let isActive = profile.id == viewModel.activeFilterProfileId
        let isDirty = isActive && viewModel.isFilterProfileModified
        
        VStack(alignment: .leading, spacing: 18) {
            // 1. Status & Header Card
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    Image(systemName: profile.iconName)
                        .font(.system(size: 28))
                        .foregroundStyle(isDirty ? Color.orange : (profile.isSystem ? Color.secondary : Color.blue))
                        .frame(width: 36)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(profile.name)
                                .font(.title3)
                                .bold()
                            if isDirty {
                                Text("*")
                                    .font(.title3).bold()
                                    .foregroundStyle(Color.orange)
                            }
                        }
                        
                        Text(profile.isSystem ? (isDe ? "Schreibgeschützte System-Vorlage" : "Read-only system preset") : (isDe ? "Benutzerdefiniertes Profil" : "Custom User Profile"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if !isActive {
                        Button(isDe ? "Profil aktivieren" : "Activate Profile") {
                            viewModel.applyFilterProfile(profile)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    } else {
                        Label(isDe ? "Aktives Profil" : "Active Profile", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isDirty ? Color.orange : Color.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(isDirty ? Color.orange.opacity(0.12) : Color.green.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                
                // Dirty Notice Banner
                if isDirty {
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.orange)
                            .font(.system(size: 14))
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(isDe ? "Ungespeicherte Änderungen aktiv" : "Unsaved Changes Active")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.orange)
                            Text(isDe ? "Die aktuellen Filtereinstellungen weichen von diesem gespeicherten Profil ab." : "Current filter settings differ from this saved profile.")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(isDe ? "Übernehmen" : "Save Changes") {
                            viewModel.saveCurrentSettingsToActiveProfile()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.orange)
                        .controlSize(.small)
                        
                        Button(isDe ? "Zurücksetzen" : "Reset") {
                            viewModel.resetActiveProfileToOriginal()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.08))
                    .clipShape(.rect(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(.rect(cornerRadius: 10))
            
            // 2. Profile Properties Editor
            if !profile.isSystem {
                VStack(alignment: .leading, spacing: 12) {
                    Text(isDe ? "PROFIL-EIGENSCHAFTEN" : "PROFILE PROPERTIES")
                        .font(.caption2)
                        .bold()
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        Text(isDe ? "Name:" : "Name:")
                            .font(.caption)
                            .frame(width: 70, alignment: .leading)
                        TextField("Name", text: Binding(
                            get: { profile.name },
                            set: { updateProfile(profile, name: $0) }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack(spacing: 12) {
                        Text(isDe ? "Symbol:" : "Icon:")
                            .font(.caption)
                            .frame(width: 70, alignment: .leading)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    Button {
                                        updateProfile(profile, iconName: icon)
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.system(size: 14))
                                            .padding(7)
                                            .background(profile.iconName == icon ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.08))
                                            .foregroundStyle(profile.iconName == icon ? Color.blue : Color.primary)
                                            .clipShape(.rect(cornerRadius: 6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(profile.iconName == icon ? Color.blue : Color.clear, lineWidth: 1.5)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    
                    Divider().padding(.vertical, 2)
                    
                    // Smart Recall Triggers
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "Smart Recall (Automatische Aktivierung)" : "Smart Recall (Automatic Activation)")
                            .font(.caption)
                            .bold()
                        Text(isDe ? "Aktiviert dieses Profil automatisch beim Band- oder Moduswechsel in WSJT-X:" : "Automatically activates this profile when tuning to a band or mode in WSJT-X:")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 16) {
                            HStack {
                                Text("Band:")
                                    .font(.caption)
                                Picker("", selection: Binding(
                                    get: { profile.autoBand ?? "--" },
                                    set: { updateProfile(profile, autoBand: $0 == "--" ? nil : $0) }
                                )) {
                                    ForEach(availableBands, id: \.self) { b in
                                        Text(b).tag(b)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 100)
                            }
                            
                            HStack {
                                Text("Mode:")
                                    .font(.caption)
                                Picker("", selection: Binding(
                                    get: { profile.autoMode ?? "--" },
                                    set: { updateProfile(profile, autoMode: $0 == "--" ? nil : $0) }
                                )) {
                                    ForEach(availableModes, id: \.self) { m in
                                        Text(m).tag(m)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 100)
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(.rect(cornerRadius: 10))
            }
            
            // 3. Contained Rules Overview
            VStack(alignment: .leading, spacing: 10) {
                Text(isDe ? "GESPEICHERTE FILTER-REGELN IN DIESEM PROFIL" : "FILTER RULES STORED IN THIS PROFILE")
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("• \(isDe ? "Erlaubte Grids" : "Allowed Grids"): **\(profile.allowedGrids.count)**")
                        Text("• \(isDe ? "Erlaubte Rufzeichen" : "Allowed Calls"): **\(profile.allowedDXCallsigns.count)**")
                        Text("• \(isDe ? "Erlaubte Länder" : "Allowed Countries"): **\(profile.allowedCountries.count)**")
                        Text("• \(isDe ? "Nachrichten-Filter" : "Message Filter"): **\(profile.isMessageFilterEnabled ? (profile.messageFilterQuery.isEmpty ? "Aktiv" : profile.messageFilterQuery) : "Aus")**")
                    }
                    .font(.system(size: 11))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("• \(isDe ? "Gesperrte Länder" : "Blocked Countries"): **\(profile.blockedCountries.count)**")
                        Text("• \(isDe ? "Gesperrte Kontinente" : "Blocked Continents"): **\(profile.disabledContinents.count)**")
                        Text("• Most Wanted Only: **\(profile.isOnlyMostWantedFilterEnabled ? "Top \(profile.maxMostWantedRank)" : "Aus")**")
                        Text("• Worked Before: **\(profile.isWorkedBeforeFilterEnabled ? "\(profile.workedBeforeDuration) \(profile.workedBeforeUnit)" : "Aus")**")
                    }
                    .font(.system(size: 11))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.06))
            .clipShape(.rect(cornerRadius: 10))
            
            // 4. Action Buttons
            HStack(spacing: 12) {
                Button {
                    exportProfile(profile)
                } label: {
                    Label(isDe ? "Als Datei exportieren..." : "Export to File...", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                
                Spacer()
                
                if !profile.isSystem {
                    Button(role: .destructive) {
                        profileToDelete = profile
                        isShowingDeleteAlert = true
                    } label: {
                        Label(isDe ? "Profil löschen" : "Delete Profile", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
            }
            .padding(.top, 4)
        }
    }
    
    private func updateProfile(_ profile: FilterProfile, name: String? = nil, iconName: String? = nil, autoBand: String? = nil, autoMode: String? = nil) {
        guard var p = viewModel.filterProfiles.first(where: { $0.id == profile.id }), !p.isSystem else { return }
        if let n = name { p.name = n }
        if let i = iconName { p.iconName = i }
        if let b = autoBand { p.autoBand = b }
        if let m = autoMode { p.autoMode = m }
        p.updatedAt = Date()
        
        DatabaseManager.shared.saveFilterProfile(p)
        if let idx = viewModel.filterProfiles.firstIndex(where: { $0.id == p.id }) {
            viewModel.filterProfiles[idx] = p
        }
    }
    
    private func duplicateSelected() {
        guard let current = selectedProfile else { return }
        let newName = "\(current.name) \(isDe ? "(Kopie)" : "(Copy)")"
        viewModel.saveCurrentSettingsAsNewProfile(
            name: newName,
            iconName: current.iconName,
            autoBand: current.autoBand,
            autoMode: current.autoMode
        )
        selectedProfileId = viewModel.activeFilterProfileId
    }
    
    private func exportProfile(_ profile: FilterProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.json]
        panel.nameFieldStringValue = "\(profile.name).autofilter-filter.json"
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }
    
    private func importProfile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.json]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            if let data = try? Data(contentsOf: url),
               var profile = try? JSONDecoder().decode(FilterProfile.self, from: data) {
                profile = FilterProfile(
                    id: UUID().uuidString,
                    name: "\(profile.name) (Import)",
                    isSystem: false,
                    iconName: profile.iconName,
                    autoBand: profile.autoBand,
                    autoMode: profile.autoMode,
                    updatedAt: Date(),
                    allowedDXCallsigns: profile.allowedDXCallsigns,
                    allowedGrids: profile.allowedGrids,
                    allowedCountries: profile.allowedCountries,
                    allowedSpotterCountries: profile.allowedSpotterCountries,
                    allowedSpotterCallsigns: profile.allowedSpotterCallsigns,
                    isMessageFilterEnabled: profile.isMessageFilterEnabled,
                    messageFilterQuery: profile.messageFilterQuery,
                    blockedCountries: profile.blockedCountries,
                    disabledContinents: profile.disabledContinents,
                    blockedCQZones: profile.blockedCQZones,
                    blockedITUZones: profile.blockedITUZones,
                    isOnlyMostWantedFilterEnabled: profile.isOnlyMostWantedFilterEnabled,
                    maxMostWantedRank: profile.maxMostWantedRank,
                    isWorkedBeforeFilterEnabled: profile.isWorkedBeforeFilterEnabled,
                    workedBeforeDuration: profile.workedBeforeDuration,
                    workedBeforeUnit: profile.workedBeforeUnit,
                    isNew4CharGridOnlyFilterEnabled: profile.isNew4CharGridOnlyFilterEnabled,
                    isNew6CharGridOnlyFilterEnabled: profile.isNew6CharGridOnlyFilterEnabled,
                    isWsjtSpecialFilterEnabled: profile.isWsjtSpecialFilterEnabled,
                    isDuplicateFilterEnabled: profile.isDuplicateFilterEnabled,
                    duplicateSpotWindowMinutes: profile.duplicateSpotWindowMinutes,
                    duplicateSpotFrequencyTolerance: profile.duplicateSpotFrequencyTolerance,
                    filterOrder: profile.filterOrder
                )
                DatabaseManager.shared.saveFilterProfile(profile)
                viewModel.filterProfiles.append(profile)
                viewModel.applyFilterProfile(profile)
                selectedProfileId = profile.id
            }
        }
    }
}

// MARK: - Save New Profile Sheet Modal
struct SaveNewProfileSheet: View {
    @Bindable var viewModel: DecodeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var profileName: String = ""
    @State private var selectedIcon: String = "bookmark.fill"
    
    private var isDe: Bool { LanguageManager.shared.isGerman }
    
    private let icons = ["bookmark.fill", "bolt.fill", "trophy.fill", "map.fill", "mic.fill", "globe.europe.africa.fill", "star.fill", "tag.fill"]
    
    var body: some View {
        VStack(spacing: 16) {
            Text(isDe ? "Neues Filter-Profil speichern" : "Save New Filter Profile")
                .font(.headline)
            
            Text(isDe ? "Speichert alle aktuellen Filter-Einstellungen und die Pipeline-Reihenfolge als eigenes Profil ab." : "Saves all current filter settings and pipeline ordering as a custom profile.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            TextField(isDe ? "Profil-Name" : "Profile Name", text: $profileName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 280)
            
            HStack(spacing: 8) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        Image(systemName: icon)
                            .padding(6)
                            .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                            .foregroundStyle(selectedIcon == icon ? Color.blue : Color.primary)
                            .clipShape(.rect(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            HStack(spacing: 12) {
                Button(isDe ? "Abbrechen" : "Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button(isDe ? "Speichern" : "Save") {
                    let name = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty {
                        viewModel.saveCurrentSettingsAsNewProfile(name: name, iconName: selectedIcon)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 340)
        .onAppear {
            let base = viewModel.activeFilterProfile?.name ?? (isDe ? "Profil" : "Profile")
            profileName = base + (isDe ? " (Kopie)" : " (Copy)")
        }
    }
}
