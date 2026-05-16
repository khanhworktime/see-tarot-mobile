import Foundation

/// Sequential mock transport: pops one scripted response per request so retry
/// behaviour (e.g. 429 then 200) is testable. No real network.
final class MockURLProtocol: URLProtocol {
    struct Stub { let status: Int; let headers: [String: String]; let body: Data }

    nonisolated(unsafe) static var stubs: [Stub] = []
    nonisolated(unsafe) static private(set) var requests: [URLRequest] = []
    static let lock = NSLock()

    static func reset(_ newStubs: [Stub]) {
        lock.lock(); defer { lock.unlock() }
        stubs = newStubs
        requests = []
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for r: URLRequest) -> URLRequest { r }

    override func startLoading() {
        MockURLProtocol.lock.lock()
        MockURLProtocol.requests.append(request)
        let stub = MockURLProtocol.stubs.isEmpty
            ? MockURLProtocol.Stub(status: 500, headers: [:], body: Data())
            : MockURLProtocol.stubs.removeFirst()
        MockURLProtocol.lock.unlock()

        let response = HTTPURLResponse(
            url: request.url!, statusCode: stub.status,
            httpVersion: "HTTP/1.1", headerFields: stub.headers)!
        client?.urlProtocol(self, didReceive: response,
                            cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

extension URLSession {
    static var mocked: URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}
