import Foundation

enum DebugNetworkBlocker {
    static func enableIfNeeded() {
#if DEBUG && targetEnvironment(simulator)
        guard !isEnabled else { return }
        isEnabled = true
        URLProtocol.registerClass(BlockingURLProtocol.self)
        print("[DebugNetworkBlocker] Enabled: blocking all network requests on simulator (with auth stubs)")
#endif
    }

#if DEBUG && targetEnvironment(simulator)
    private static var isEnabled = false

    private final class BlockingURLProtocol: URLProtocol {
        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else { return false }
            return url.scheme != "file"
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        override func startLoading() {
            let method = request.httpMethod ?? "GET"
            let urlString = request.url?.absoluteString ?? "(unknown url)"
            let path = request.url?.path ?? ""

            if let stub = stubbedResponse(method: method, path: path) {
                let response = HTTPURLResponse(
                    url: request.url ?? URL(string: "http://localhost")!,
                    statusCode: stub.statusCode,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "application/json"]
                )!
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: stub.data)
                client?.urlProtocolDidFinishLoading(self)
                print("[DebugNetworkBlocker] Stubbed: \(method) \(urlString)")
                return
            }

            print("[DebugNetworkBlocker] Blocked: \(method) \(urlString)")

            let error = NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorNotConnectedToInternet,
                userInfo: [NSLocalizedDescriptionKey: "Network disabled in DEBUG simulator"]
            )
            client?.urlProtocol(self, didFailWithError: error)
        }

        override func stopLoading() {
            // no-op
        }
    }

    private static func stubbedResponse(method: String, path: String) -> (statusCode: Int, data: Data)? {
        guard method.uppercased() == "POST" || method.uppercased() == "GET" else { return nil }

        if method.uppercased() == "POST", path.contains("/auth/signup") || path.contains("/auth/signin") {
            return (200, makeAuthResponse(emailFromBody: nil))
        }

        if method.uppercased() == "GET", path.contains("/user/me") || path.contains("/me") {
            return (200, makeUserResponse())
        }

        return nil
    }

    private static func makeAuthResponse(emailFromBody: String?) -> Data {
        let email = emailFromBody ?? "test@anchor.app"
        let now = ISO8601DateFormatter().string(from: Date())
        let payload: [String: Any] = [
            "user": [
                "id": UUID().uuidString,
                "email": email,
                "username": "anchor_test",
                "display_name": "Anchor Test",
                "first_name": "Anchor",
                "last_name": "Tester",
                "birthday": "2000-01-01",
                "created_at": now,
                "role": "user"
            ],
            "access_token": "debug_access_token",
            "refresh_token": "debug_refresh_token"
        ]
        return (try? JSONSerialization.data(withJSONObject: payload)) ?? Data()
    }

    private static func makeUserResponse() -> Data {
        let now = ISO8601DateFormatter().string(from: Date())
        let payload: [String: Any] = [
            "id": UUID().uuidString,
            "email": "test@anchor.app",
            "username": "anchor_test",
            "display_name": "Anchor Test",
            "first_name": "Anchor",
            "last_name": "Tester",
            "birthday": "2000-01-01",
            "created_at": now,
            "role": "user"
        ]
        return (try? JSONSerialization.data(withJSONObject: payload)) ?? Data()
    }
#endif
}
