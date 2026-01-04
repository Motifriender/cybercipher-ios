import PhotosUI
import SwiftUI

struct VerifyProofView: View {
    @EnvironmentObject private var container: AppContainer

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedData: Data?

    @State private var statusText: String = "Pick an image to verify against stored proofs."
    @State private var matchedRecordID: String?

    var body: some View {
        List {
            Section("Verify") {
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
                            let result = try await container.proofStore.verify(data: data)
                            matchedRecordID = result.matchedRecord?.id.uuidString
                            statusText = result.isValid ? "VALID: \(result.reason)" : "INVALID: \(result.reason)"
                        } catch {
                            statusText = "Verify failed: \(error)"
                        }
                    }
                } label: {
                    Label("Verify", systemImage: "magnifyingglass")
                }
                .disabled(selectedData == nil)

                Text(statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let matchedRecordID {
                    Text("Matched Record ID: \(matchedRecordID)")
                        .font(.footnote.monospaced())
                }
            }
        }
        .navigationTitle("Verify")
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else {
                selectedData = nil
                return
            }
            Task {
                do {
                    if let data = try await newItem.loadTransferable(type: Data.self) {
                        selectedData = data
                        statusText = "Image selected. Ready to verify."
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
    NavigationStack { VerifyProofView() }
        .environmentObject(AppContainer())
}

