import Foundation
import LimitlyCore
import os

enum CodexClientError: LocalizedError, Equatable {
    case executableNotFound
    case notAuthenticated
    case timeout
    case malformedResponse
    case server(String)
    case process(String)

    var errorDescription: String? {
        switch self {
        case .executableNotFound:
            return "공식 Codex 실행 파일을 찾을 수 없습니다."
        case .notAuthenticated:
            return "Codex 로그인 세션을 확인할 수 없습니다."
        case .timeout:
            return "Codex 응답 시간이 초과되었습니다."
        case .malformedResponse:
            return "Codex 응답을 해석할 수 없습니다."
        case .server(let message):
            return "Codex 서버 오류: \(message)"
        case .process(let message):
            return "Codex 프로세스를 시작할 수 없습니다: \(message)"
        }
    }
}

protocol RateLimitProvider: Sendable {
    func readRateLimits() async throws -> RateLimitsResult
}

final class CodexAppServerClient: RateLimitProvider, @unchecked Sendable {
    private let executableURL: URL?
    private let timeout: TimeInterval
    private let logger = Logger(subsystem: "local.limitly.usage-menubar", category: "codex")

    init(executableURL: URL? = nil, timeout: TimeInterval = 10) {
        self.executableURL = executableURL
        self.timeout = timeout
    }

    func readRateLimits() async throws -> RateLimitsResult {
        guard let executable = executableURL ?? CodexExecutableLocator.locate() else {
            throw CodexClientError.executableNotFound
        }

        return try await withCheckedThrowingContinuation { continuation in
            let session = Session(
                executableURL: executable,
                timeout: timeout,
                logger: logger,
                continuation: continuation
            )
            session.start()
        }
    }

    private final class Session: @unchecked Sendable {
        private enum RequestID {
            static let initialize = 1
            static let account = 2
            static let rateLimits = 3
        }

        private let process = Process()
        private let input = Pipe()
        private let output = Pipe()
        private let executableURL: URL
        private let timeout: TimeInterval
        private let logger: Logger
        private let continuation: CheckedContinuation<RateLimitsResult, Error>
        private let lock = NSLock()
        private var framer = JSONLFramer()
        private var didFinish = false
        private var didSendInitialized = false
        private var didSendRateLimits = false
        private let encoder = JSONEncoder()
        private let decoder = JSONDecoder()

        init(
            executableURL: URL,
            timeout: TimeInterval,
            logger: Logger,
            continuation: CheckedContinuation<RateLimitsResult, Error>
        ) {
            self.executableURL = executableURL
            self.timeout = timeout
            self.logger = logger
            self.continuation = continuation
        }

        func start() {
            process.executableURL = executableURL
            process.arguments = ["app-server", "--stdio"]
            process.standardInput = input
            process.standardOutput = output
            process.standardError = FileHandle.nullDevice

            output.fileHandleForReading.readabilityHandler = { [self] handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                self.consume(data)
            }

            process.terminationHandler = { [self] process in
                guard process.terminationStatus != 0 else { return }
                self.finish(.failure(CodexClientError.process("종료 코드 \(process.terminationStatus)")))
            }

            do {
                try process.run()
                try send(.initialize(clientName: "limitly", version: "1.0.0", id: RequestID.initialize))
            } catch {
                finish(.failure(CodexClientError.process(error.localizedDescription)))
                return
            }

            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout) { [weak self] in
                self?.finish(.failure(CodexClientError.timeout))
            }
        }

        private func send(_ request: JSONRPCRequest) throws {
            try input.fileHandleForWriting.write(contentsOf: request.encodedLine(using: encoder))
        }

        private func consume(_ data: Data) {
            lock.lock()
            let lines = framer.append(data)
            lock.unlock()

            for line in lines {
                handle(line)
            }
        }

        private func handle(_ line: Data) {
            guard let envelope = try? decoder.decode(JSONRPCResponse<JSONValue>.self, from: line) else {
                logger.debug("Ignoring non-JSON app-server line")
                return
            }

            if let error = envelope.error {
                let message = error.message ?? "알 수 없는 오류"
                if envelope.id == RequestID.account || message.localizedCaseInsensitiveContains("auth") || message.localizedCaseInsensitiveContains("login") {
                    finish(.failure(CodexClientError.notAuthenticated))
                } else {
                    finish(.failure(CodexClientError.server(message)))
                }
                return
            }

            guard let id = envelope.id else { return }

            do {
                if id == RequestID.initialize && !didSendInitialized {
                    didSendInitialized = true
                    try send(.initialized())
                    try send(.accountRead(id: RequestID.account))
                } else if id == RequestID.account && !didSendRateLimits {
                    didSendRateLimits = true
                    try send(.rateLimitsRead(id: RequestID.rateLimits))
                } else if id == RequestID.rateLimits {
                    guard let resultValue = envelope.result else {
                        finish(.failure(CodexClientError.malformedResponse))
                        return
                    }
                    let resultData = try encoder.encode(resultValue)
                    let result = try decoder.decode(RateLimitsResult.self, from: resultData)
                    finish(.success(result))
                }
            } catch {
                finish(.failure(CodexClientError.malformedResponse))
            }
        }

        private func finish(_ result: Result<RateLimitsResult, Error>) {
            lock.lock()
            guard !didFinish else {
                lock.unlock()
                return
            }
            didFinish = true
            lock.unlock()

            output.fileHandleForReading.readabilityHandler = nil
            process.terminationHandler = nil
            input.fileHandleForWriting.closeFile()
            if process.isRunning {
                process.terminate()
            }
            continuation.resume(with: result)
        }
    }
}
