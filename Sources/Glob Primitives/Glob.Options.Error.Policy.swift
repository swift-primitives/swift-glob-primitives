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


extension Glob.Options.Error {
    /// Error handling policy during traversal.
    public enum Policy: Sendable, Hashable {
        /// Stop and throw on first error.
        case fail

        /// Skip inaccessible paths, continue collecting results.
        case skip
    }
}

