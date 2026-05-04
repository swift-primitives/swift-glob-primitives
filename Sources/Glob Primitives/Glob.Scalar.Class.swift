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

extension Glob.Scalar {
    /// A character class operating on Unicode scalar values.
    ///
    /// Uses `UInt32` (Unicode scalar values) for deterministic,
    /// platform-independent matching. Ranges are well-defined over
    /// scalar values, unlike Swift `Character` (extended grapheme clusters).
    ///
    /// ## Why UInt32?
    ///
    /// - `Character` represents extended grapheme clusters (variable width)
    /// - `Unicode.Scalar` is a single 21-bit code point
    /// - `UInt32` is the underlying storage, enabling efficient Set/Range ops
    /// - Ranges like `[a-z]` are well-defined over scalar values
    public struct Class: Sendable, Hashable {
        /// If true, matches scalars NOT in the class.
        public let negated: Bool

        /// Scalar ranges (e.g., `a-z` → `0x61...0x7A`).
        public let ranges: [ClosedRange<UInt32>]

        /// Individual scalars.
        public let scalars: Set<UInt32>

        /// Creates a scalar class.
        ///
        /// - Parameters:
        ///   - negated: If true, matches scalars NOT in the class.
        ///   - ranges: Scalar ranges.
        ///   - scalars: Individual scalars.
        public init(
            negated: Bool,
            ranges: [ClosedRange<UInt32>],
            scalars: Set<UInt32>
        ) {
            self.negated = negated
            self.ranges = ranges
            self.scalars = scalars
        }
    }
}

extension Glob.Scalar.Class {
    /// Tests whether a scalar matches this class.
    ///
    /// - Parameter scalar: The Unicode scalar to test.
    /// - Returns: `true` if the scalar matches this class.
    @inlinable
    public func matches(_ scalar: Unicode.Scalar) -> Bool {
        let value = scalar.value
        let inClass = scalars.contains(value) || ranges.contains { $0.contains(value) }
        return negated ? !inClass : inClass
    }
}
