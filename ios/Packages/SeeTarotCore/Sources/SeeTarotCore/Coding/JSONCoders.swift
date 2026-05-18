import Foundation

// Shared JSON coders. The BE already returns camelCase, so we use the DEFAULT
// key strategy — do NOT apply `.convertFromSnakeCase` (BE doc §5). Dates are
// ISO-8601 strings kept as `String` and parsed at the edges.
// Shared singletons — `JSONDecoder`/`JSONEncoder` are safe to reuse
// concurrently for decode/encode once configured (default config here), so
// allocate once instead of per request.
public extension JSONDecoder {
    static let api = JSONDecoder()
}

public extension JSONEncoder {
    static let api = JSONEncoder()
}
