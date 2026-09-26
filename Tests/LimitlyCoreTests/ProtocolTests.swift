import XCTest
@testable import LimitlyCore

final class ProtocolTests: XCTestCase {
    func testRateLimitResponseDecodesBothBucketViews() throws {
        let json = #"""
        {
          "id": 6,
          "result": {
            "rateLimits": {
              "limitId": "codex",
              "primary": { "usedPercent": 25, "windowDurationMins": 300, "resetsAt": 1730947200 },
              "secondary": { "usedPercent": 42, "windowDurationMins": 10080, "resetsAt": 1730950800 }
            },
            "rateLimitsByLimitId": {
              "codex": {
                "limitId": "codex",
                "primary": { "usedPercent": 25, "windowDurationMins": 300, "resetsAt": 1730947200 },
                "secondary": null
              }
            }
          }
        } 
        """#.data(using: .utf8)!

        let response = try JSONDecoder().decode(JSONRPCResponse<RateLimitsResult>.self, from: json)
        XCTAssertEqual(response.id, 6)
        XCTAssertEqual(response.result?.rateLimits?.limitId, "codex")
        XCTAssertEqual(response.result?.rateLimitsByLimitId?["codex"]?.primary?.windowDurationMins, 300)
    }

    func testJSONLFramerHandlesSplitMessages() throws {
        var framer = JSONLFramer()
        XCTAssertEqual(framer.append(Data(#"{"id":1,"result":{}"#.utf8)), [])
        let lines = framer.append(Data("}\n{\"id\":2}\n".utf8))
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(String(decoding: lines[0], as: UTF8.self), #"{"id":1,"result":{}}"#)
        XCTAssertEqual(String(decoding: lines[1], as: UTF8.self), #"{"id":2}"#)
    }

    func testInitializeRequestHasClientMetadata() throws {
        let request = JSONRPCRequest.initialize(clientName: "limitly", version: "1.0.0")
        let data = try JSONEncoder().encode(request)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["method"] as? String, "initialize")
        let params = try XCTUnwrap(object["params"] as? [String: Any])
        let clientInfo = try XCTUnwrap(params["clientInfo"] as? [String: Any])
        XCTAssertEqual(clientInfo["name"] as? String, "limitly")
        XCTAssertEqual(clientInfo["version"] as? String, "1.0.0")
    }
}
