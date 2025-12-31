import PhotosUI
import SwiftUI

struct CreateProofView: View {
    @EnvironmentObject private var container: AppContainer

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedData: Data?

    @State private var statusText: String = "Pick an image to create a proof."
    @State private var lastRecordID: String?

    var body: some View {
        List {
            Section("Content Proofs") {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Choose Photo", systemImage: "photo")
                }

                Button {
                    Task {
                        guard let data = selectedData else {
                            statusText = "No image selected."
                            return
                        }
                        do {
                            let record = try await container.proofStore.createProof(for: data, label: "Photo", mediaUTType: "public.image")
                            lastRecordID = record.id.uuidString
                            statusText = "Proof created."
                        } catch {
                            statusText = "Failed to create proof: \(error)"
                        }
                    }
                } label: {
                    Label("Create Proof", systemImage: "checkmark.seal")
                }
                .disabled(selectedData == nil)

                Text(statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let lastRecordID {
                    Text("Record ID: \(lastRecordID)")
                        .font(.footnote.monospaced())
                }
            }
        }
        .navigationTitle("Create Proof")
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else {
                selectedData = nil
                return
            }
            Task {
                do {
                    if let data = try await newItem.loadTransferable(type: Data.self) {
                        selectedData = data
                        statusText = "Image selected. Ready to sign."
                    } else {
                        selectedData = nil
                        statusText = "Could not load image data."
                    }
                } catch {
                    selectedData = nil
                    statusText = "Failed to load image: \(error)"
                }
            }
        }
    }
}

#Preview {
    NavigationStack { CreateProofView() }
        .environmentObject(AppContainer())
}

