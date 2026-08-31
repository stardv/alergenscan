import SwiftUI
import AllergenEngine

struct ScanView: View {
    @EnvironmentObject private var profile: AllergenProfile
    @StateObject private var camera = CameraController()
    @StateObject private var scanner = ScannerModel()

    @State private var showManualEntry = false
    @State private var typedBarcode = ""

    var body: some View {
        NavigationStack {
            ZStack {
                viewfinder
                overlay
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Enter barcode") { showManualEntry = true }
                }
            }
            .task { await camera.start() }
            .onDisappear { camera.stop() }
            .sheet(isPresented: $showManualEntry) { manualEntry }
            .sheet(isPresented: isShowingResult) {
                if case let .done(result, product) = scanner.state {
                    ResultView(result: result, product: product) { scanner.reset() }
                }
            }
        }
    }

    // MARK: - Viewfinder

    @ViewBuilder
    private var viewfinder: some View {
        switch camera.access {
        case .granted:
            CameraPreview(session: camera.session).ignoresSafeArea()
        case .denied:
            ContentUnavailableView(
                "Camera access needed",
                systemImage: "camera.fill",
                description: Text("Allow camera access in Settings so the app can read "
                                  + "ingredient labels and barcodes.")
            )
        case .unknown:
            Color.black.ignoresSafeArea()
        }
    }

    // MARK: - Overlay

    private var overlay: some View {
        VStack {
            instructions
            Spacer()
            if case let .working(message) = scanner.state {
                progress(message)
            } else if case let .failed(message) = scanner.state {
                failure(message)
            } else {
                scanButton
            }
        }
        .padding()
    }

    private var instructions: some View {
        Text(profile.isEmpty
             ? "Pick your allergens on the Allergens tab first."
             : "Point at the ingredients list, or the barcode.")
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.black.opacity(0.55), in: Capsule())
    }

    private var scanButton: some View {
        Button {
            Task { await scanner.scan(using: camera, profile: profile.selected) }
        } label: {
            Text("Scan")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .disabled(profile.isEmpty || camera.access != .granted)
    }

    private func progress(_ message: String) -> some View {
        HStack(spacing: 10) {
            ProgressView()
            Text(message)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func failure(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message).multilineTextAlignment(.center)
            Button("Try again") { scanner.reset() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Manual barcode entry

    private var manualEntry: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. 3017620422003", text: $typedBarcode)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Barcode")
                } footer: {
                    Text("Looks the product up in Open Food Facts. "
                         + "Nothing is read from the packet itself, so the answer "
                         + "is only as fresh as the database entry.")
                }
            }
            .navigationTitle("Enter barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showManualEntry = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Look up") {
                        let code = typedBarcode.trimmingCharacters(in: .whitespaces)
                        showManualEntry = false
                        typedBarcode = ""
                        Task { await scanner.lookUp(barcode: code, profile: profile.selected) }
                    }
                    .disabled(typedBarcode.trimmingCharacters(in: .whitespaces).count < 8)
                }
            }
        }
    }

    private var isShowingResult: Binding<Bool> {
        Binding(
            get: { if case .done = scanner.state { return true } else { return false } },
            set: { if !$0 { scanner.reset() } }
        )
    }
}
