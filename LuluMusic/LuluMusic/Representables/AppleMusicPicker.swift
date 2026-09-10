import MediaPlayer
import SwiftUI

struct AppleMusicPicker: UIViewControllerRepresentable {
    var onPick: ([MPMediaItem]) -> Void
    var onCancel: () -> Void = {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick, onCancel: onCancel) }

    func makeUIViewController(context: Context) -> MPMediaPickerController {
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.delegate = context.coordinator
        picker.allowsPickingMultipleItems = true
        picker.showsCloudItems = true
        picker.showsItemsWithProtectedAssets = true
        picker.prompt = "选择要拷进陆陆音乐的歌曲"
        return picker
    }

    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {
        context.coordinator.onPick = onPick
        context.coordinator.onCancel = onCancel
    }

    final class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        var onPick: ([MPMediaItem]) -> Void
        var onCancel: () -> Void

        init(onPick: @escaping ([MPMediaItem]) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            onPick(mediaItemCollection.items)
            mediaPicker.dismiss(animated: true)
        }

        func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            onCancel()
            mediaPicker.dismiss(animated: true)
        }
    }
}

enum MusicLibraryAuth {
    static func request() async -> MPMediaLibraryAuthorizationStatus {
        let current = MPMediaLibrary.authorizationStatus()
        if current != .notDetermined { return current }
        return await withCheckedContinuation { continuation in
            MPMediaLibrary.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
