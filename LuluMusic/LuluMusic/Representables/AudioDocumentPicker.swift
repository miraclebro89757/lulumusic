import SwiftUI
import UniformTypeIdentifiers

struct AudioDocumentPicker: UIViewControllerRepresentable {
    var allowsMultiple: Bool = true
    var onPick: ([URL]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: Self.audioTypes, asCopy: true)
        picker.allowsMultipleSelection = allowsMultiple
        picker.shouldShowFileExtensions = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        context.coordinator.onPick = onPick
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPick: ([URL]) -> Void
        init(onPick: @escaping ([URL]) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls)
        }
    }

    static var audioTypes: [UTType] {
        var types: [UTType] = [.audio, .mp3, .mpeg4Audio, .wav, .aiff]
        if let aac = UTType("public.aac-audio") { types.append(aac) }
        if let flac = UTType("org.xiph.flac") { types.append(flac) }
        types.append(contentsOf: ["mp3", "m4a", "aac", "wav", "flac", "aiff", "caf"].compactMap {
            UTType(filenameExtension: $0)
        })
        return types
    }
}
