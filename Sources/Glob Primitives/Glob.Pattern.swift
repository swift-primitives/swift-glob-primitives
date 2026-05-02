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


import ASCII_Primitives

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
    /// - Parameter pattern: The glob pattern string.
    /// - Throws: `Glob.Error` if the pattern is invalid.
    public init(_ pattern: Swift.String) throws(Glob.Error) {
        self.raw = pattern

        // Split by canonical separator /
        // Note: Backslash is the escape character, not a path separator.
        // Users must use / as path separator in glob patterns (cross-platform).
        let parts = pattern.split(separator: "/", omittingEmptySubsequences: false)
        var compiledSegments: [Glob.Segment] = []
        var hasDoubleStar = false

        for (index, part) in parts.enumerated() {
            // Check for **
            if part == "**" {
                compiledSegments.append(.doubleStar)
                hasDoubleStar = true
                continue
            }

            let partString = Swift.String(part)

            // Check if segment has any metacharacters
            if !Glob.isPattern(partString) {
                compiledSegments.append(.literal(Array(part.utf8)))
                continue
            }

            // Parse as pattern segment
            let atoms = try Self.parseAtoms(partString, segmentIndex: index)
            compiledSegments.append(.pattern(atoms))
        }

        self.segments = compiledSegments
        self.isRecursive = hasDoubleStar
    }

    /// Parses atoms from a pattern segment string.
    ///
    /// Iterates Unicode scalars for correct metacharacter detection,
    /// but accumulates literal content as UTF-8 bytes for byte-level
    /// matching at L3.
    private static func parseAtoms(
        _ segment: Swift.String,
        segmentIndex: Int
    ) throws(Glob.Error) -> [Glob.Atom] {
        var atoms: [Glob.Atom] = []
        var literal: [UInt8] = []
        var iterator = segment.unicodeScalars.makeIterator()
        var position = 0

        func flushLiteral() {
            if !literal.isEmpty {
                atoms.append(.literal(literal))
                literal = []
            }
        }

        while let scalar = iterator.next() {
            position += 1

            switch scalar {
            case "*":
                flushLiteral()
                atoms.append(.star)

            case "?":
                flushLiteral()
                atoms.append(.question)

            case "[":
                flushLiteral()
                let scalarClass = try parseScalarClass(
                    &iterator,
                    pattern: segment,
                    startPosition: position
                )
                atoms.append(.scalar(scalarClass))

            case "\\":
                // Escape: next character is literal
                if let next = iterator.next() {
                    position += 1
                    appendUTF8(next, to: &literal)
                } else {
                    throw .invalidPattern(
                        pattern: segment,
                        position: position,
                        reason: .unexpectedEnd
                    )
                }

            default:
                appendUTF8(scalar, to: &literal)
            }
        }

        flushLiteral()
        return atoms
    }

    /// Encodes a Unicode scalar to UTF-8 bytes and appends to the buffer.
    private static func appendUTF8(_ scalar: Unicode.Scalar, to bytes: inout [UInt8]) {
        let v = scalar.value
        if v < 0x80 {
            bytes.append(UInt8(truncatingIfNeeded: v))
        } else if v < 0x800 {
            bytes.append(UInt8(0xC0 | (v >> 6)))
            bytes.append(UInt8(0x80 | (v & 0x3F)))
        } else if v < 0x1_0000 {
            bytes.append(UInt8(0xE0 | (v >> 12)))
            bytes.append(UInt8(0x80 | ((v >> 6) & 0x3F)))
            bytes.append(UInt8(0x80 | (v & 0x3F)))
        } else {
            bytes.append(UInt8(0xF0 | (v >> 18)))
            bytes.append(UInt8(0x80 | ((v >> 12) & 0x3F)))
            bytes.append(UInt8(0x80 | ((v >> 6) & 0x3F)))
            bytes.append(UInt8(0x80 | (v & 0x3F)))
        }
    }

    /// Parses a character class `[...]` from the pattern.
    private static func parseScalarClass(
        _ iterator: inout Swift.String.UnicodeScalarView.Iterator,
        pattern: Swift.String,
        startPosition: Int
    ) throws(Glob.Error) -> Glob.Scalar.Class {
        var position = startPosition
        var negated = false
        var scalars: Set<UInt32> = []
        var ranges: [ClosedRange<UInt32>] = []
        var previousScalar: Unicode.Scalar? = nil
        var expectingRangeEnd = false
        var hasContent = false  // Track if class has any content (for ] detection after ranges)

        // Check for negation
        if let first = iterator.next() {
            position += 1
            if first == "!" || first == "^" {
                negated = true
            } else if first == "]" {
                // Empty class is invalid
                throw .invalidPattern(
                    pattern: pattern,
                    position: position,
                    reason: .emptyClass
                )
            } else {
                previousScalar = first
                scalars.insert(first.value)
                hasContent = true
            }
        } else {
            throw .invalidPattern(
                pattern: pattern,
                position: position,
                reason: .unterminatedClass
            )
        }

        while let scalar = iterator.next() {
            position += 1

            if scalar == "]" && (hasContent || negated) {
                // End of class
                if expectingRangeEnd {
                    // Trailing - is literal
                    scalars.insert(Unicode.Scalar("-").value)
                }
                return Glob.Scalar.Class(
                    negated: negated,
                    ranges: ranges,
                    scalars: scalars
                )
            }

            if scalar == "-" && previousScalar != nil {
                expectingRangeEnd = true
                continue
            }

            if expectingRangeEnd {
                // This is the end of a range
                if let start = previousScalar {
                    if start.value <= scalar.value {
                        ranges.append(start.value...scalar.value)
                        // Remove the start from individual scalars since it's now in a range
                        scalars.remove(start.value)
                        hasContent = true
                    } else {
                        throw .invalidPattern(
                            pattern: pattern,
                            position: position,
                            reason: .invalidRange
                        )
                    }
                }
                expectingRangeEnd = false
                previousScalar = nil
            } else {
                scalars.insert(scalar.value)
                previousScalar = scalar
                hasContent = true
            }
        }

        // Reached end without closing ]
        throw .invalidPattern(
            pattern: pattern,
            position: position,
            reason: .unterminatedClass
        )
    }
}

