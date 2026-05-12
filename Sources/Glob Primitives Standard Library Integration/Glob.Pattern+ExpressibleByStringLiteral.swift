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

public import Glob_Primitives

extension Glob.Pattern: ExpressibleByStringLiteral {
    /// Constructs a `Glob.Pattern` from a string literal.
    ///
    /// Parses the literal eagerly via `Glob.Pattern.init(_:)`. A malformed
    /// literal traps with `fatalError` — literals authored at the call site
    /// are reviewable surface text, so a parse failure indicates an
    /// authoring-time defect that surfaces at build-load time rather than
    /// at the first matching call. Use the throwing `init(_:)` directly
    /// for patterns whose validity cannot be guaranteed at compile time.
    @inlinable
    public init(stringLiteral value: Swift.String) {
        do {
            self = try Glob.Pattern(value)
        } catch {
            fatalError("Glob.Pattern literal failed to parse: \(value): \(error)")
        }
    }
}
