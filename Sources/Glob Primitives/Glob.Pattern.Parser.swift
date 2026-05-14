// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-glob-primitives open source project
//
// Copyright (c) 2026 Coen ten Thije Boonkkamp and the swift-glob-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Collection_Primitives
public import Parser_Primitives

extension Glob.Pattern {
    /// Byte-stream parser for glob patterns — participates in larger
    /// `Parser_Primitives.Parser.\`Protocol\``-bound grammars.
    ///
    /// Composes with the institute parser ecosystem (HTTP header parsers,
    /// package-manifest parsers, registry-locator parsers) that operate
    /// on `UInt8` byte streams. The Parser is the canonical source of
    /// glob-pattern validation logic; ``Glob/Pattern/init(_:)`` is a
    /// thin String adapter that runs this parser over the UTF-8 view of
    /// the supplied string.
    ///
    /// ## Implementation Approach
    ///
    /// The parser body decodes the consumed byte slice to a
    /// `Swift.String` once and then operates on
    /// `Swift.String.UnicodeScalarView` to perform segment-splitting,
    /// metacharacter detection, and character-class parsing. Glob
    /// escape semantics (`\X` makes `X` literal regardless of whether
    /// `X` is a metacharacter) require Unicode-scalar-level iteration
    /// so multi-byte escaped characters can be appended to literal
    /// atoms as their full UTF-8 byte run. Raw-byte iteration without
    /// scalar boundary detection would mis-categorize continuation
    /// bytes — a byte-level port would either re-implement UTF-8
    /// decoding inline or call `Swift.String.UnicodeScalarView`
    /// anyway, so the parser decodes once at the boundary and operates
    /// on scalars internally. Approach (b) per the Parseable adoption
    /// brief, justified by the substantial-rewrite carve-out.
    ///
    /// The parser is greedy over the entire input — glob patterns have
    /// no canonical terminator within the character class. `parse(_:)`
    /// consumes everything from `input.startIndex` to `input.endIndex`
    /// as the pattern text; trailing-bytes assertion is the caller's
    /// responsibility when composing within a larger grammar.
    ///
    /// ```swift
    /// var input = Parser_Primitives_Core.Parser.Input.Bytes(utf8: "src/*.swift")
    /// let pattern = try Glob.Pattern.Parser<Parser.Input.Bytes>().parse(&input)
    /// // pattern.segments.count == 2
    /// ```
    public struct Parser<Input: Collection.Slice.`Protocol` & Swift.Collection>: Swift.Sendable
    where Input: Swift.Sendable, Input.Element == Swift.UInt8 {
        /// Creates a glob-pattern byte-stream parser.
        ///
        /// Stateless — instances are interchangeable.
        @inlinable
        public init() {}
    }
}

extension Glob.Pattern.Parser: Parser_Primitives.Parser.`Protocol` {
    /// The parsed value: a validated ``Glob/Pattern``.
    public typealias Output = Glob.Pattern

    /// The error type thrown on parse failure: ``Glob/Error``.
    public typealias Failure = Glob.Error

    /// Consumes the entire remaining input as a glob pattern and
    /// returns the parsed ``Glob/Pattern``.
    ///
    /// Decodes the input bytes as UTF-8 and performs segment-splitting
    /// on the canonical `/` separator, then parses each non-literal
    /// segment's atoms (metacharacter detection, character classes,
    /// escape handling). On success, the input is advanced to
    /// `endIndex`.
    public func parse(_ input: inout Input) throws(Glob.Error) -> Glob.Pattern {
        let bytes = input[input.startIndex..<input.endIndex]
        let patternString = Swift.String(decoding: bytes, as: Swift.UTF8.self)
        let parts = patternString.split(separator: "/", omittingEmptySubsequences: false)
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
                compiledSegments.append(.literal(Swift.Array(part.utf8)))
                continue
            }

            // Parse as pattern segment
            let atoms = try Self.parseAtoms(partString, segmentIndex: index)
            compiledSegments.append(.pattern(atoms))
        }

        input = input[input.endIndex...]

        return Glob.Pattern(
            raw: patternString,
            segments: compiledSegments,
            isRecursive: hasDoubleStar
        )
    }

    /// Parses atoms from a pattern segment string.
    ///
    /// Iterates Unicode scalars for correct metacharacter detection,
    /// but accumulates literal content as UTF-8 bytes for byte-level
    /// matching at L3.
    @usableFromInline
    static func parseAtoms(
        _ segment: Swift.String,
        segmentIndex: Swift.Int
    ) throws(Glob.Error) -> [Glob.Atom] {
        var atoms: [Glob.Atom] = []
        var literal: [Swift.UInt8] = []
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
    @usableFromInline
    static func appendUTF8(_ scalar: Unicode.Scalar, to bytes: inout [Swift.UInt8]) {
        let v = scalar.value
        if v < 0x80 {
            bytes.append(Swift.UInt8(truncatingIfNeeded: v))
        } else if v < 0x800 {
            bytes.append(Swift.UInt8(0xC0 | (v >> 6)))
            bytes.append(Swift.UInt8(0x80 | (v & 0x3F)))
        } else if v < 0x1_0000 {
            bytes.append(Swift.UInt8(0xE0 | (v >> 12)))
            bytes.append(Swift.UInt8(0x80 | ((v >> 6) & 0x3F)))
            bytes.append(Swift.UInt8(0x80 | (v & 0x3F)))
        } else {
            bytes.append(Swift.UInt8(0xF0 | (v >> 18)))
            bytes.append(Swift.UInt8(0x80 | ((v >> 12) & 0x3F)))
            bytes.append(Swift.UInt8(0x80 | ((v >> 6) & 0x3F)))
            bytes.append(Swift.UInt8(0x80 | (v & 0x3F)))
        }
    }

    /// Parses a character class `[...]` from the pattern.
    @usableFromInline
    static func parseScalarClass(
        _ iterator: inout Swift.String.UnicodeScalarView.Iterator,
        pattern: Swift.String,
        startPosition: Swift.Int
    ) throws(Glob.Error) -> Glob.Scalar.Class {
        var position = startPosition
        var negated = false
        var scalars: Swift.Set<Swift.UInt32> = []
        var ranges: [Swift.ClosedRange<Swift.UInt32>] = []
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
