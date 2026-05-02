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
    /// An atom within a pattern segment.
    ///
    /// Atoms are the building blocks of pattern segments.
    /// Literal values are stored as UTF-8 bytes, enabling
    /// direct byte-level matching against filesystem entries
    /// without String allocation.
    public enum Atom: Sendable, Hashable {
        /// Literal bytes (UTF-8 encoded).
        case literal([UInt8])

        /// `*` - matches zero or more bytes (except separator).
        case star

        /// `?` - matches one UTF-8 character (1-4 bytes).
        case question

        /// `[...]` - matches one scalar in/not-in the class.
        case scalar(Scalar.Class)
    }
}

