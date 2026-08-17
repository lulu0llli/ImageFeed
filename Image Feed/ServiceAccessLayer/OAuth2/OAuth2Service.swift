import Foundation

final class OAuth2Service {
    static let shared = OAuth2Service()
    private let urlSession = URLSession.shared
    private let storage = OAuth2TokenStorage()
    
    private init() {}
    
    func fetchOAuthToken(
        _ code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let request = makeTokenRequest(code: code) else {
            let error = NSError(domain: "InvalidRequest", code: 0)
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // 1. Проверяем ошибку сети
            if let error = error {
                print("[OAuth2Service] Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // 2. Проверяем HTTP-статус
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[OAuth2Service] Invalid response")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "InvalidResponse", code: 0)))
                }
                return
            }
            
            guard 200..<300 ~= httpResponse.statusCode else {
                print("[OAuth2Service] HTTP Error: \(httpResponse.statusCode)")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "HTTPError", code: httpResponse.statusCode)))
                }
                return
            }
            
            // 3. Проверяем данные
            guard let data = data else {
                print("[OAuth2Service] No data received")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "NoData", code: 0)))
                }
                return
            }
            
            // 4. Декодируем ответ
            do {
                let responseBody = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
                let token = responseBody.accessToken
                self.storage.token = token
                DispatchQueue.main.async {
                    completion(.success(token))
                }
            } catch {
                print("[OAuth2Service] Decoding error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
    
    private func makeTokenRequest(code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token") else {
            print("[OAuth2Service] Failed to create URLComponents")
            return nil
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        
        guard let url = urlComponents.url else {
            print("[OAuth2Service] Failed to create URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
}
