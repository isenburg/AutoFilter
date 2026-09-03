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
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.2.square")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Text(isDe ? "Filter-Profile verwalten" : "Manage Filter Profiles")
                        .font(.title2)
                        .bold()
                }
                Spacer()
                Button(isDe ? "Fertig" : "Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            HSplitView {
                // Left: Profiles List
                VStack(spacing: 0) {
                    List(selection: $selectedProfileId) {
                        Section(header: Text(isDe ? "System-Vorlagen" : "System Presets")) {
                            ForEach(viewModel.filterProfiles.filter { $0.isSystem }) { profile in
                                profileRow(profile)
                                    .tag(profile.id)
                            }
                        }
                        
                        Section(header: Text(isDe ? "Benutzerdefinierte Profile" : "Custom Profiles")) {
                            ForEach(viewModel.filterProfiles.filter { !$0.isSystem }) { profile in
                                profileRow(profile)
                                    .tag(profile.id)
                            }
                        }
                    }
                    .listStyle(.sidebar)
                    
                    Divider()
                    
                    // Bottom Actions
                    HStack(spacing: 8) {
                        Button {
                            importProfile()
                        } label: {
                            Label(isDe ? "Importieren..." : "Import...", systemImage: "square.and.arrow.down")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Spacer()
                        
                        Button {
                            duplicateSelected()
                        } label: {
                            Label(isDe ? "Duplizieren" : "Duplicate", systemImage: "plus.square.on.square")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(selectedProfile == nil)
                    }
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                }
                .frame(minWidth: 220, idealWidth: 250, maxWidth: 300)
                
                // Right: Detail & Editor
                if let profile = selectedProfile {
                    profileDetailEditor(profile)
                        .frame(minWidth: 350, maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 40))
                            .foregroundStyle(.tertiary)
                        Text(isDe ? "Wähle ein Profil aus der Liste" : "Select a profile from the list")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(width: 650, height: 480)
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
        HStack(spacing: 8) {
            Image(systemName: profile.iconName)
                .foregroundStyle(profile.id == viewModel.activeFilterProfileId ? Color.blue : Color.secondary)
                .frame(width: 18)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(profile.name)
                        .font(.system(size: 12, weight: profile.id == viewModel.activeFilterProfileId ? .bold : .regular))
                    if profile.id == viewModel.activeFilterProfileId {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                    }
                }
                
                if let auto = profile.autoBand, !auto.isEmpty {
                    Text("Auto: \(auto)")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if profile.isSystem {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    private func profileDetailEditor(_ profile: FilterProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Title & Status
            HStack {
                Image(systemName: profile.iconName)
                    .font(.title)
                    .foregroundStyle(profile.isSystem ? Color.secondary : Color.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.headline)
                    Text(profile.isSystem ? (isDe ? "Schreibgeschützte System-Vorlage" : "Read-only system preset") : (isDe ? "Benutzerdefiniertes Profil" : "Custom User Profile"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if profile.id != viewModel.activeFilterProfileId {
                    Button(isDe ? "Aktivieren" : "Activate") {
                        viewModel.applyFilterProfile(profile)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                } else {
                    Label(isDe ? "Aktiv" : "Active", systemImage: "checkmark.circle.fill")
                        .font(.caption).bold()
                        .foregroundStyle(.green)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(.rect(cornerRadius: 8))
            
            if !profile.isSystem {
                // Name & Icon Editor
                VStack(alignment: .leading, spacing: 8) {
                    Text(isDe ? "PROFIL-EIGENSCHAFTEN" : "PROFILE PROPERTIES")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Text(isDe ? "Name:" : "Name:")
                            .font(.caption)
                            .frame(width: 50, alignment: .leading)
                        TextField("Name", text: Binding(
                            get: { profile.name },
                            set: { updateProfile(profile, name: $0) }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text(isDe ? "Symbol:" : "Icon:")
                            .font(.caption)
                            .frame(width: 50, alignment: .leading)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    Button {
                                        updateProfile(profile, iconName: icon)
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.system(size: 14))
                                            .padding(6)
                                            .background(profile.iconName == icon ? Color.blue.opacity(0.2) : Color.clear)
                                            .foregroundStyle(profile.iconName == icon ? Color.blue : Color.primary)
                                            .clipShape(.rect(cornerRadius: 6))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    // Smart Recall
                    HStack {
                        Text(isDe ? "Auto-Band:" : "Auto-Band:")
                            .font(.caption)
                            .frame(width: 70, alignment: .leading)
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
                        
                        Text(isDe ? "Auto-Mode:" : "Auto-Mode:")
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
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(.rect(cornerRadius: 8))
            }
            
            // Summary Info
            VStack(alignment: .leading, spacing: 6) {
                Text(isDe ? "ENTHALTENE FILTER-REGELN" : "CONTAINED FILTER RULES")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• \(isDe ? "Erlaubte Grids" : "Allowed Grids"): \(profile.allowedGrids.count)")
                        Text("• \(isDe ? "Erlaubte Calls" : "Allowed Calls"): \(profile.allowedDXCallsigns.count)")
                        Text("• \(isDe ? "Erlaubte Länder" : "Allowed Countries"): \(profile.allowedCountries.count)")
                        Text("• \(isDe ? "Nachrichten-Filter" : "Message Filter"): \(profile.isMessageFilterEnabled ? (profile.messageFilterQuery.isEmpty ? "Aktiv" : profile.messageFilterQuery) : "Aus")")
                    }
                    .font(.caption)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• \(isDe ? "Gesperrte Länder" : "Blocked Countries"): \(profile.blockedCountries.count)")
                        Text("• \(isDe ? "Gesperrte Kontinente" : "Blocked Continents"): \(profile.disabledContinents.count)")
                        Text("• Most Wanted Only: \(profile.isOnlyMostWantedFilterEnabled ? "Top \(profile.maxMostWantedRank)" : "Aus")")
                        Text("• Worked Before: \(profile.isWorkedBeforeFilterEnabled ? "\(profile.workedBeforeDuration) \(profile.workedBeforeUnit)" : "Aus")")
                    }
                    .font(.caption)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.06))
            .clipShape(.rect(cornerRadius: 8))
            
            Spacer()
            
            // Bottom Action Bar
            HStack {
                Button {
                    exportProfile(profile)
                } label: {
                    Label(isDe ? "Als Datei exportieren..." : "Export to File...", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                if !profile.isSystem {
                    Button(role: .destructive) {
                        profileToDelete = profile
                        isShowingDeleteAlert = true
                    } label: {
                        Label(isDe ? "Löschen" : "Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding()
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
        panel.nameFieldStringValue = "\(profile.name).autoqso-filter.json"
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
                // Ensure unique ID
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
