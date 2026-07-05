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

public import Array_Primitives
public import Ownership_Shared_Primitive
public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives
public import Byte_Parser_Primitives
public import Parser_Primitives

extension Glob.Pattern: Parseable {
    /// Pin the `Parseable.Parser` associatedtype to the canonical
    /// glob-pattern byte-stream parser instantiation.
    ///
    /// Uses `@_implements(Parseable, Parser)` to bind the protocol's
    /// `Parser` associated type to a differently-named typealias
    /// (`_ParseableParser`). Without `@_implements` the existing
    /// nested generic ``Glob/Pattern/Parser`` collides with the
    /// protocol's `Parser` associated-type-name slot at synthesis
    /// time ("invalid redeclaration of synthesized implementation
    /// for protocol requirement 'Parser'"), because the nested type
    /// is generic over `Input` and cannot bind to `Parseable.Parser`
    /// as a single concrete witness.
    ///
    /// `@_implements(Protocol, Name)` is a `BASELINE_LANGUAGE_FEATURE`
    /// in the Swift compiler — always-on, stable in practice though
    /// underscored. Documented in
    /// `swift-institute/Blog/Published/2026-04-20-associated-type-trap.md`
    /// for the parallel `Body`-associated-type case in HTML rendering;
    /// adopted in `swift-version-primitives` for `Version.Semantic`
    /// (commit `3b4eb5d`) as the canonical exemplar. Empirically
    /// validated by
    /// `swift-institute/Experiments/parseable-associatedtype-implements/`
    /// (2026-05-14).
    @_implements(Parseable, Parser)
    public typealias _ParseableParser = Glob_Primitives.Glob.Pattern.Parser<Byte.Input>

    /// The canonical glob-pattern byte-stream parser instance.
    ///
    /// Conforming to ``Parseable`` from `swift-parser-primitives`
    /// declares ``Glob/Pattern/Parser`` (instantiated over
    /// `Byte.Input`) as the type's
    /// canonical parser, which enables generic parser-discovery
    /// algorithms over `Parseable` types AND surfaces the free
    /// `init(ascii:)` initializer from `Parseable`'s byte-input
    /// extension:
    ///
    /// ```swift
    /// let pattern = try Glob.Pattern(ascii: Swift.Array("src/*.swift".utf8))
    /// ```
    @inlinable
    public static var parser: _ParseableParser { _ParseableParser() }
}
