import Foundation

private struct LikeResponse: Decodable {
    let photo: PhotoResult
}

final class ImagesListService {
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")

    private init() {}

    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    private var task: URLSessionTask?
    private let urlSession = URLSession.shared

    func fetchPhotosNextPage() {
        guard task == nil else { return }

        let nextPage = (lastLoadedPage ?? 0) + 1

        guard let request = makePhotosRequest(page: nextPage, perPage: 10) else {
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.task = nil

                switch result {
                case .success(let photoResults):
                    let newPhotos = photoResults.map { $0.toPhoto() }
                    self.photos.append(contentsOf: newPhotos)
                    self.lastLoadedPage = nextPage

                    NotificationCenter.default.post(
                        name: ImagesListService.didChangeNotification,
                        object: self
                    )

                case .failure(let error):
                    print("[ImagesListService] Ошибка загрузки: \(error.localizedDescription)")
                }
            }
        }

        self.task = task
        task.resume()
    }

    private func makePhotosRequest(page: Int, perPage: Int) -> URLRequest? {
        guard let url = URL(string: "\(Constants.defaultBaseURLString)/photos?page=\(page)&per_page=\(perPage)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(OAuth2TokenStorage.shared.token ?? "")", forHTTPHeaderField: "Authorization")
        return request
    }

    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        guard task == nil else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        guard let request = makeLikeRequest(photoId: photoId, isLike: isLike) else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<LikeResponse, Error>) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.task = nil

                switch result {
                case .success(let likeResponse):
                    let photoResult = likeResponse.photo
                    if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                        let photo = self.photos[index]
                        let newPhoto = Photo(
                            id: photo.id,
                            size: photo.size,
                            createdAt: photo.createdAt,
                            welcomeDescription: photo.welcomeDescription,
                            thumbImageURL: photo.thumbImageURL,
                            largeImageURL: photo.largeImageURL,
                            fullImageURL: photo.fullImageURL,
                            isLiked: photoResult.likedByUser
                        )
                        self.photos[index] = newPhoto
                    }
                    completion(.success(()))

                case .failure(let error):
                    print("[ImagesListService] Ошибка изменения лайка: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }

        self.task = task
        task.resume()
    }

    private func makeLikeRequest(photoId: String, isLike: Bool) -> URLRequest? {
        guard let url = URL(string: "\(Constants.defaultBaseURLString)/photos/\(photoId)/like") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        request.setValue("Bearer \(OAuth2TokenStorage.shared.token ?? "")", forHTTPHeaderField: "Authorization")
        return request
    }

    func cleanPhotos() {
        photos = []
        lastLoadedPage = nil
        task?.cancel()
        task = nil
    }
}
