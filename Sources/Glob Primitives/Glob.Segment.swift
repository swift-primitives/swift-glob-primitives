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
    /// A compiled glob pattern segment (between path separators).
    ///
    /// Segments are the top-level units of a compiled pattern,
    /// split by path separators. Literal values are stored as
    /// UTF-8 bytes — the canonical encoding of the pattern text.
    /// Platform implementations match these bytes against the
    /// filesystem's native encoding (POSIX: `[UInt8]`, Windows:
    /// transcode to `[UInt16]` at match setup).
    public enum Segment: Sendable, Hashable {
        /// Literal path segment - exact byte match.
        case literal([UInt8])

        /// Pattern segment containing wildcards.
        case pattern([Atom])

        /// `**` - matches zero or more path segments.
        case doubleStar
    }
}
