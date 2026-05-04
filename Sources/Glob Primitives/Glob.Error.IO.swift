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

extension Glob.Error {
    /// Stable I/O error categories (not raw errno/Win32 codes).
    ///
    /// Platform-specific error codes are mapped to these stable categories
    /// for cross-platform consistency.
    public enum IO: Sendable, Hashable {
        /// General read error during directory traversal.
        case read

        /// Too many open file descriptors.
        case tooManyOpenFiles

        /// Path component exceeds filesystem name length limit.
        case nameTooLong

        /// Symbolic link loop detected during traversal.
        case loopDetected

        /// Other I/O error not covered by specific categories.
        case other
    }
}
