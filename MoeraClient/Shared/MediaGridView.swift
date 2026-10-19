import SwiftUI
import AVKit

/// Картинки, видео и файлы, прикреплённые к посту или комментарию.
struct MediaGridView: View {
    @Environment(SessionStore.self) private var session
    let attachments: [MediaAttachment]

    private var files: [MediaFile] {
        attachments.filter { !$0.embedded }.compactMap(\.media)
    }

    var body: some View {
        if let node = session.nodeURL, !files.isEmpty {
            VStack(spacing: 4) {
                ForEach(files) { file in
                    if file.malware == true {
                        Label("Файл заблокирован: в списке вредоносных", systemImage: "exclamationmark.shield")
                            .foregroundStyle(.red)
                    } else if file.isImage, let url = file.url(node: node) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Rectangle().fill(.quaternary).aspectRatio(aspect(file), contentMode: .fit)
                        }
                    } else if file.isVideo, let url = file.url(node: node) {
                        VideoPlayer(player: AVPlayer(url: url))
                            .aspectRatio(aspect(file), contentMode: .fit)
                    } else if let url = file.url(node: node) {
                        Link(destination: url) {
                            Label(file.title ?? "Файл", systemImage: "doc")
                        }
                    }
                }
            }
        }
    }

    private func aspect(_ file: MediaFile) -> CGFloat {
        guard let w = file.width, let h = file.height, h > 0 else { return 16 / 9 }
        return CGFloat(w) / CGFloat(h)
    }
}
