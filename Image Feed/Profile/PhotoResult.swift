import Foundation

struct PhotoResult: Codable {
    let id: String
    let createdAt: String?
    let width: Int
    let height: Int
    let likes: Int
    let likedByUser: Bool
    let description: String?
    let urls: UrlsResult

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case width
        case height
        case likes
        case likedByUser = "liked_by_user"
        case description
        case urls
    }
}

struct UrlsResult: Codable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

extension PhotoResult {
    func toPhoto() -> Photo {
        let size = CGSize(width: width, height: height)
        let dateFormatter = ISO8601DateFormatter()
        let createdAtDate = createdAt.flatMap { dateFormatter.date(from: $0) }

        return Photo(
            id: id,
            size: size,
            createdAt: createdAtDate,
            welcomeDescription: description,
            thumbImageURL: urls.thumb,
            largeImageURL: urls.full,
            fullImageURL: urls.full,
            isLiked: likedByUser
        )
    }
}
