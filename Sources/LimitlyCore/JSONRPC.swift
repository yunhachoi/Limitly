import Foundation

public enum JSONValue: Codable, Equatable, Sendable {
    case null
    case bool(Bool)
    case integer(Int)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .integer(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .integer(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}

public struct JSONRPCRequest: Encodable, Equatable, Sendable {
    public let method: String
    public let id: Int?
    public let params: JSONValue?

    public init(method: String, id: Int?, params: JSONValue? = nil) {
        self.method = method
        self.id = id
        self.params = params
    }

    public static func initialize(clientName: String, version: String, id: Int = 1) -> JSONRPCRequest {
        JSONRPCRequest(
            method: "initialize",
            id: id,
            params: .object([
                "clientInfo": .object([
                    "name": .string(clientName),
                    "title": .string("Limitly"),
                    "version": .string(version)
                ])
            ])
        )
    }

    public static func initialized() -> JSONRPCRequest {
        JSONRPCRequest(method: "initialized", id: nil, params: .object([:]))
    }

    public static func accountRead(id: Int) -> JSONRPCRequest {
        JSONRPCRequest(
            method: "account/read",
            id: id,
            params: .object(["refreshToken": .bool(false)])
        )
    }

    public static func rateLimitsRead(id: Int) -> JSONRPCRequest {
        JSONRPCRequest(method: "account/rateLimits/read", id: id)
    }

    public func encodedLine(using encoder: JSONEncoder = JSONEncoder()) throws -> Data {
        var data = try encoder.encode(self)
        data.append(0x0A)
        return data
    }

    private enum CodingKeys: String, CodingKey {
        case method
        case id
        case params
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(method, forKey: .method)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(params, forKey: .params)
    }
}

public struct JSONRPCError: Codable, Equatable, Sendable, Error {
    public let code: Int?
    public let message: String?
    public let data: JSONValue?

    public init(code: Int?, message: String?, data: JSONValue? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
}

public struct JSONRPCResponse<Result: Decodable>: Decodable {
    public let id: Int?
    public let result: Result?
    public let error: JSONRPCError?

    public init(id: Int?, result: Result?, error: JSONRPCError?) {
        self.id = id
        self.result = result
        self.error = error
    }
}

public struct JSONLFramer: Sendable {
    private var buffer = Data()

    public init() {}

    public mutating func append(_ data: Data) -> [Data] {
        buffer.append(data)
        var lines: [Data] = []

        while let newline = buffer.firstIndex(of: 0x0A) {
            var line = Data(buffer[..<newline])
            buffer.removeSubrange(...newline)
            if line.last == 0x0D {
                line.removeLast()
            }
            if !line.isEmpty {
                lines.append(line)
            }
        }

        return lines
    }
}
