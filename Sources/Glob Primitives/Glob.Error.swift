// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-glob-primitives open source project
//
// Copyright (c) 2024 Coen ten Thije Boonkkamp and the swift-glob-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//


extension Glob {
    /// Errors that can occur during glob operations.
    ///
    /// Closed error type for typed throws. Platform-specific errors
    /// are mapped to these stable categories.
    ///
    /// ## Path Representation
    ///
    /// Error paths are `String` (not `Path`) by design:
    /// - Layer 1 primitives avoid cross-package dependencies
    /// - Error paths are for diagnostics/logging, not further processing
    /// - Encoding: UTF-8 (platform-native paths transcoded if necessary)
    /// - Windows: `\` separators preserved in error messages
    /// - POSIX: `/` separators preserved
    public enum Error: Swift.Error, Sendable, Hashable {
        /// Invalid pattern syntax.
        case invalidPattern(pattern: Swift.String, position: Int, reason: Parse)

        /// Directory access denied.
        case accessDenied(path: Swift.String)

        /// Path does not exist.
        case notFound(path: Swift.String)

        /// Path is not a directory (expected directory for traversal).
        case notDirectory(path: Swift.String)

        /// I/O failure during traversal.
        case io(path: Swift.String, category: IO)
    }
}

