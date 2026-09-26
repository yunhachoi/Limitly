import Foundation
import XCTest
@testable import LimitlyCore

final class CodexExecutableLocatorTests: XCTestCase {
    func testExecutableDirectoryIsNotSelectedAsCodexBinary() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("limitly-codex-directory-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        XCTAssertFalse(CodexExecutableLocator.isUsableExecutable(at: directory))
    }

    func testRegularExecutableFileIsAccepted() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("limitly-codex-file-\(UUID().uuidString)")
        FileManager.default.createFile(atPath: file.path, contents: Data("#!/bin/sh\n".utf8))
        defer { try? FileManager.default.removeItem(at: file) }
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: file.path)

        XCTAssertTrue(CodexExecutableLocator.isUsableExecutable(at: file))
    }

    func testSearchUsesResourceRootInsteadOfHardcodedNestedPath() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("limitly-codex-root-\(UUID().uuidString)", isDirectory: true)
        let executable = root.appendingPathComponent("future-layout/tools/codex")
        try FileManager.default.createDirectory(
            at: executable.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        FileManager.default.createFile(atPath: executable.path, contents: Data("#!/bin/sh\n".utf8))
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)

        XCTAssertEqual(
            CodexExecutableLocator.locate(in: root)?.resolvingSymlinksInPath().path,
            executable.resolvingSymlinksInPath().path
        )
    }
}
