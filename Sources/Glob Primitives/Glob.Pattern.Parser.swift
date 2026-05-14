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
    /// on `UInt8` byte streams.
    ///
    /// ## Implementation Approach
    ///
    /// The Parser body decodes the consumed byte slice to a `Swift.String`
    /// and delegates to ``Glob/Pattern/init(_:)``'s established
    /// segment-splitting + character-class parsing logic. The existing
    /// implementation operates on `Swift.String.UnicodeScalarView` to
    /// support escape semantics over the full Unicode scalar set —
    /// porting that logic into byte-level form would substantially
    /// rewrite working code with no behavioral gain at this layer. The
    /// thin-wrapper shape is the institute-permitted approach (b) per
    /// the Parseable adoption brief, justified because the byte-level
    /// port would require Unicode-scalar decoding at parse time anyway.
    ///
    /// The parser is greedy over the entire input — glob patterns have
    /// no canonical terminator within the SemVer-style character class.
    /// `parse(_:)` consumes everything from `input.startIndex` to
    /// `input.endIndex` as the pattern text; trailing-bytes assertion
    /// is the caller's responsibility when composing within a larger
    /// grammar.
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
    /// Decodes the input bytes as UTF-8 into a `Swift.String` and
    /// delegates to ``Glob/Pattern/init(_:)``. On success, the input
    /// is advanced to `endIndex`.
    public func parse(_ input: inout Input) throws(Glob.Error) -> Glob.Pattern {
        let bytes = input[input.startIndex..<input.endIndex]
        let patternString = Swift.String(decoding: bytes, as: Swift.UTF8.self)
        let pattern = try Glob.Pattern(patternString)
        input = input[input.endIndex...]
        return pattern
    }
}
