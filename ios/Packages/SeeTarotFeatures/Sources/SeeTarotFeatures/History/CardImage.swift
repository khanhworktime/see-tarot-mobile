import SwiftUI
import SeeTarotCore
import SeeTarotCardEngine
import SeeTarotPersistence

/// Card artwork backed by the offline `CardImageLoader` (cache-first). Falls
/// back to the E02 `RealCardSurface` placeholder when bytes are unavailable
/// (nil url, cold cache + offline) — never blank, never crashes.
struct CardImage: View {
    let card: ReadingCard
    let loader: CardImageLoader
    @State private var data: Data?

    var body: some View {
        Group {
            if let data, let image = Self.decode(data) {
                image.resizable().scaledToFit()
            } else {
                RealCardSurface(name: card.name, reversed: card.reversed)
                    .cardView(imageURL: nil, faceUp: true,
                              position: card.position)
            }
        }
        .task(id: card.id) {
            data = await loader.image(
                cardId: card.id, url: card.imageUrl.flatMap(URL.init))
        }
    }

    private static func decode(_ data: Data) -> Image? {
        #if canImport(UIKit)
        if let ui = UIImage(data: data) { return Image(uiImage: ui) }
        #elseif canImport(AppKit)
        if let ns = NSImage(data: data) { return Image(nsImage: ns) }
        #endif
        return nil
    }
}
