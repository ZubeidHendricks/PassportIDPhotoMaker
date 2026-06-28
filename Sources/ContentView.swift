import SwiftUI
import PhotosUI
import AppFactoryKit

// Passport / ID Photo Maker — pick a selfie, get a compliant ID photo: white
// background + cropped to the chosen country's size. Free tier does US size; Pro
// unlocks all country specs and saving.
struct ContentView: View {
    @EnvironmentObject private var factory: AppFactory
    private let service = IDPhotoService()

    @State private var pickerItem: PhotosPickerItem?
    @State private var inputImage: UIImage?
    @State private var outputImage: UIImage?
    @State private var spec: PhotoSpec = .all[0]
    @State private var isProcessing = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    preview
                    specRow
                    actions
                    if let errorText { Text(errorText).font(.footnote).foregroundStyle(.red) }
                }
                .padding(20)
            }
            .navigationTitle("ID Photo")
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await load(item) }
        }
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18).fill(.quaternary)
            if let shown = outputImage ?? inputImage {
                Image(uiImage: shown).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                VStack(spacing: 10) { Image(systemName: "person.crop.rectangle").font(.system(size: 52)).foregroundStyle(.blue); Text("Pick a selfie").foregroundStyle(.secondary) }
            }
            if isProcessing { ProgressView().controlSize(.large) }
        }
        .frame(height: 360)
    }

    private var specRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(PhotoSpec.all) { sp in
                    Button { select(sp) } label: {
                        VStack(spacing: 4) {
                            Text(sp.name).font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).strokeBorder(spec == sp ? .blue : .secondary.opacity(0.3), lineWidth: spec == sp ? 2 : 1))
                        .overlay(alignment: .topTrailing) {
                            if sp.isPremium && !factory.subscriptions.isSubscribed {
                                Image(systemName: "lock.fill").font(.system(size: 9)).padding(3)
                            }
                        }
                    }
                    .buttonStyle(.plain).tint(.blue)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label(inputImage == nil ? "Choose Selfie" : "Choose Another", systemImage: "photo").frame(maxWidth: .infinity, minHeight: 50)
            }.buttonStyle(.bordered)
            if outputImage != nil {
                Button { factory.requirePremium(feature: "save_id") { save() } } label: {
                    Label("Save to Photos", systemImage: "square.and.arrow.down").frame(maxWidth: .infinity, minHeight: 50)
                }.buttonStyle(.bordered)
            }
        }
    }

    private func select(_ sp: PhotoSpec) {
        if sp.isPremium && !factory.subscriptions.isSubscribed { factory.presentPaywall(placement: "spec_\(sp.id)"); return }
        spec = sp
        if inputImage != nil { Task { await process() } }
    }

    private func load(_ item: PhotosPickerItem) async {
        errorText = nil
        if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
            inputImage = img; outputImage = nil
            await process()
        } else { errorText = "Couldn't load that photo." }
    }

    private func process() async {
        guard let inputImage else { return }
        isProcessing = true; errorText = nil
        defer { isProcessing = false }
        do { outputImage = try await service.make(from: inputImage, spec: spec) }
        catch { errorText = "Couldn't process that — use a clear, front-facing photo." }
    }

    private func save() {
        guard let outputImage else { return }
        UIImageWriteToSavedPhotosAlbum(outputImage, nil, nil, nil)
    }
}
