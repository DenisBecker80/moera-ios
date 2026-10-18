import SwiftUI

/// Упрощённый вывод HTML из тела поста: пока просто убирает теги.
struct HTMLText: View {
    let html: String

    var body: some View {
        Text(plain)
    }

    private var plain: String {
        html.replacingOccurrences(of: "<br ?/?>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "</p>", with: "\n\n")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct AvatarView: View {
    let name: String
    var size: CGFloat = 40

    var body: some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: size, height: size)
            .overlay(Text(String(name.prefix(1)).uppercased()).font(.headline))
    }
}
