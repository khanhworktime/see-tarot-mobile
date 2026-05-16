import Foundation

/// Shared JSON coders. The BE already returns camelCase, so we use the DEFAULT
/// key strategy — do NOT apply `.convertFromSnakeCase` (BE doc §5). Dates are
/// ISO-8601 strings kept as `String` and parsed at the edges.
public extension JSONDecoder {
    static var api: JSONDecoder { JSONDecoder() }
}

public extension JSONEncoder {
    static var api: JSONEncoder { JSONEncoder() }
}
