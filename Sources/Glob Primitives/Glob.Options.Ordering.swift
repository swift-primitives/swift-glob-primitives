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


extension Glob.Options {
    /// Result ordering policy.
    public enum Ordering: Sendable, Hashable {
        /// Sort results lexicographically for reproducibility.
        ///
        /// **Collation key definition:**
        /// - Compare **relative path strings** from the root directory
        /// - Use canonical separator `/` (Windows `\` normalized to `/`)
        /// - Compare by **Unicode scalar values** (not locale collation)
        /// - Component-wise comparison: `a/b` < `a/c` < `ab`
        case deterministic

        /// Return in filesystem traversal order (faster, platform-dependent).
        case filesystemOrder
    }
}

