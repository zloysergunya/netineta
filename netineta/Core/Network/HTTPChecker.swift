import Foundation

actor HTTPChecker {

    static let shared = HTTPChecker()

    func check(domain: String, timeout: TimeInterval = 5) async -> Bool {
        let urlString = "https://\(domain)"
        guard let url = URL(string: urlString) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = timeout

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return (200...499).contains(httpResponse.statusCode)
            }
            return false
        } catch {
            return false
        }
    }
}
