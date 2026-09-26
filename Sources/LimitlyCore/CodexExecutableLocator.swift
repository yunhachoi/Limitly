import Foundation

/// Locates the official Codex CLI bundled with the installed macOS app.
///
/// The application bundle is the stable anchor. Its internal `Contents`,
/// `Resources`, and CLI directory layout can change between Codex releases,
/// so those subdirectories are searched instead of being hardcoded.
/// `FileManager.isExecutableFile(atPath:)` also returns true for executable
/// directories on macOS. The regular-file check is therefore intentional:
/// an old `Resources/codex-cli` directory must never be passed to `Process`.
public enum CodexExecutableLocator {
    public static let applicationDirectories: [URL] = [
        URL(fileURLWithPath: "/Applications", isDirectory: true),
        URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
            .appendingPathComponent("Applications", isDirectory: true)
    ]

    public static func isUsableExecutable(
        at url: URL,
        fileManager: FileManager = .default
    ) -> Bool {
        guard fileManager.fileExists(atPath: url.path),
              let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isExecutableKey]),
              values.isRegularFile == true,
              values.isExecutable == true else {
            return false
        }
        return true
    }

    /// Searches a fixed application/bundle root recursively for an executable
    /// named `codex`. This method is public so the path strategy can be tested
    /// against future bundle layouts without depending on a user's install.
    public static func locate(
        in applicationRoot: URL,
        fileManager: FileManager = .default
    ) -> URL? {
        guard fileManager.fileExists(atPath: applicationRoot.path) else { return nil }

        var matches: [URL] = []
        let keys: [URLResourceKey] = [.isRegularFileKey, .isExecutableKey]
        if let enumerator = fileManager.enumerator(
            at: applicationRoot,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) {
            for case let candidate as URL in enumerator {
                guard candidate.lastPathComponent == "codex",
                      isUsableExecutable(at: candidate, fileManager: fileManager) else {
                    continue
                }
                matches.append(candidate)
            }
        }

        return matches.sorted {
            if $0.path.count != $1.path.count {
                return $0.path.count < $1.path.count
            }
            return $0.path < $1.path
        }.first
    }

    public static func locate(
        fileManager: FileManager = .default,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> URL? {
        for directory in applicationDirectories {
            let applicationRoot = directory.appendingPathComponent("Codex.app", isDirectory: true)
            if let candidate = locate(in: applicationRoot, fileManager: fileManager) {
                return candidate
            }
        }

        let pathEntries = environment["PATH"]?.split(separator: ":") ?? []
        for entry in pathEntries {
            let candidate = URL(fileURLWithPath: String(entry)).appendingPathComponent("codex")
            if isUsableExecutable(at: candidate, fileManager: fileManager) {
                return candidate
            }
        }
        return nil
    }
}
