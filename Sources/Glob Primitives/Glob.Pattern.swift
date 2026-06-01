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

public import Array_Primitives
public import Byte_Parser_Primitives
public import Parser_Primitives

extension Glob {
    /// A parsed glob pattern compiled into segments.
    ///
    /// ## Escape Semantics
    ///
    /// **Normative semantics:**
    /// - `\` (backslash, 0x5C) is the escape character within patterns
    /// - `\*`, `\?`, `\[`, `\\` match literal `*`, `?`, `[`, `\`
    /// - Backslash before non-metacharacter is literal (e.g., `\a` → `\a`)
    /// - **Path separators:** Glob grammar uses `/` as the canonical separator.
    ///   Within patterns, `\` is always escape, never separator.
    ///   Use `/` for path separation on all platforms.
    ///
    /// ## Metacharacters (from swift-ascii)
    ///
    /// Uses `ASCII.Character.Graphic` constants for metacharacter detection:
    /// - `ASCII.Character.Graphic.asterisk` (0x2A) - `*`
    /// - `ASCII.Character.Graphic.questionMark` (0x3F) - `?`
    /// - `ASCII.Character.Graphic.leftBracket` (0x5B) - `[`
    /// - `ASCII.Character.Graphic.rightBracket` (0x5D) - `]`
    /// - `ASCII.Character.Graphic.backslash` (0x5C) - `\`
    /// - `ASCII.Character.Graphic.slash` (0x2F) - `/`
    /// - `ASCII.Character.Graphic.period` (0x2E) - `.`
    public struct Pattern: Sendable, Hashable {
        /// The original pattern string.
        public let raw: Swift.String

        /// The compiled segments (split by path separator).
        public let segments: [Segment]

        /// Whether this pattern contains `**` (recursive matching).
        public let isRecursive: Bool
    }
}

extension Glob.Pattern {
    /// Creates a pattern from a string.
    ///
    /// String adapter over ``Glob/Pattern/Parser``. Constructs a
    /// `Byte.Input` over the string's
    /// UTF-8 view and runs the canonical parser; the parser consumes
    /// the entire input as the glob pattern, so no trailing-bytes
    /// assertion is needed.
    ///
    /// Mirrors the shape of
    /// `swift-version-primitives/Sources/Version Primitives/Version.Semantic.swift:107`
    /// (`Version.Semantic.init(parsing:)`) — the parser is the
    /// canonical source of truth, this init is the thin String adapter.
    ///
    /// - Parameter pattern: The glob pattern string.
    /// - Throws: ``Glob/Error`` if the pattern is invalid.
    @inlinable
    public init(_ pattern: Swift.String) throws(Glob.Error) {
        var input = Byte.Input(utf8: pattern)
        self = try Glob.Pattern.Parser<Byte.Input>().parse(&input)
    }
}
