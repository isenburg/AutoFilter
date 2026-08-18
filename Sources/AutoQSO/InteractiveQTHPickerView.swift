import SwiftUI
import MapKit

struct InteractiveQTHPickerView: View {
    @Binding var myGridLocator: String
    @Environment(\.dismiss) private var dismiss

    @State private var cameraPosition: MapCameraPosition
    @State private var currentRegion: MKCoordinateRegion
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedGrid: String
    @State private var mapStyleOption: MapStyleOption = .hybrid

    init(myGridLocator: Binding<String>) {
        self._myGridLocator = myGridLocator
        let initialGrid = myGridLocator.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        let initialCoord: CLLocationCoordinate2D
        if let coords = Maidenhead.locatorToLatLon(initialGrid) {
            initialCoord = CLLocationCoordinate2D(latitude: coords.lat, longitude: coords.lon)
        } else {
            initialCoord = CLLocationCoordinate2D(latitude: 51.1657, longitude: 10.4515) // Standard Mittelpunkt
        }
        
        let initialRegion = MKCoordinateRegion(
            center: initialCoord,
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.25)
        )
        
        self._currentRegion = State(initialValue: initialRegion)
        self._cameraPosition = State(initialValue: .region(initialRegion))
        self._selectedCoordinate = State(initialValue: initialCoord)
        self._selectedGrid = State(initialValue: initialGrid.isEmpty ? "JO31" : initialGrid)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        Text("Interactive QTH Finder")
                            .font(.headline)
                            .bold()
                    }
                    Text("Zoomstufen: Das Maidenhead-Gitter passt sich beim Hineinzoomen automatisch von 2- bis 8-Stellen an.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selected Grid Indicator
                HStack(spacing: 6) {
                    Text("Ausgewählt:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(selectedGrid)
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.yellow, lineWidth: 1.5))
                }
                
                Button("Abbrechen") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Übernehmen & Schließen") {
                    myGridLocator = selectedGrid
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            
            Divider()
            
            // Interactive Map Section
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    // Google-style Red Pin Indicator
                    if let coord = selectedCoordinate {
                        Annotation(selectedGrid, coordinate: coord) {
                            VStack(spacing: 0) {
                                HStack(spacing: 4) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.red)
                                    Text(selectedGrid)
                                        .font(.system(size: 11, weight: .black, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(Color.red, in: Capsule())
                                .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                                
                                Image(systemName: "triangle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.red)
                                    .rotationEffect(.degrees(180))
                                    .offset(y: -2)
                            }
                        }
                    }
                }
                .mapStyle(mapStyleOption.mapStyle)
                .onMapCameraChange { context in
                    currentRegion = context.region
                }
                .overlay {
                    // Dynamic Maidenhead Grid Lines & Subsquare Labels
                    MaidenheadGridCanvasView(proxy: proxy, region: currentRegion)
                        .allowsHitTesting(false)
                }
                .onTapGesture { position in
                    if let coord = proxy.convert(position, from: .local) {
                        selectedCoordinate = coord
                        selectedGrid = Maidenhead.latLonToLocator(lat: coord.latitude, lon: coord.longitude, length: 8)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    Menu {
                        ForEach(MapStyleOption.allCases) { style in
                            Button(action: {
                                mapStyleOption = style
                            }) {
                                HStack {
                                    Text(style.rawValue)
                                    if mapStyleOption == style {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(mapStyleOption.rawValue)
                                .font(.system(size: 12, weight: .medium))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5.5)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .menuStyle(.borderlessButton)
                    .help("Kartenstil auswählen")
                    .padding(10)
                }
            }
        }
        .frame(minWidth: 820, minHeight: 580)
    }
}
