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
    /// Options for glob pattern matching.
    ///
    /// Options are organized into three categories:
    /// - **Matching policy**: Affects how patterns match filenames (case, dotfiles)
    /// - **Traversal policy**: Affects how directories are walked (symlinks, depth)
    /// - **Result policy**: Affects output format (ordering, error handling)
    ///
    /// All options are supported uniformly across POSIX and Windows platforms.
    ///
    /// ## Case Folding (Normative)
    ///
    /// When `caseInsensitive = true`:
    /// - ASCII letters A-Z (0x41-0x5A) are treated equal to a-z (0x61-0x7A)
    /// - Uses `INCITS_4_1986.CaseConversion` (via swift-ascii) for deterministic folding
    /// - Non-ASCII scalars (>= 0x80) are matched **case-sensitively**
    /// - Non-letter ASCII characters are unaffected
    public struct Options: Sendable, Hashable {
        // MARK: - Matching Policy

        /// Case-insensitive matching using ASCII case folding.
        public var caseInsensitive: Bool

        /// Dotfile (hidden file) matching behavior.
        public var dotfiles: Dotfile

        // MARK: - Traversal Policy

        /// Follow symbolic links when recursing into directories.
        public var followSymlinks: Bool

        /// Maximum directory depth for `**` patterns.
        public var maxDepth: Int?

        // MARK: - Result Policy

        /// Result ordering.
        public var ordering: Ordering

        /// Error handling during traversal.
        public var onError: Error.Policy

        /// Creates options with specified values.
        ///
        /// - Parameters:
        ///   - caseInsensitive: Case-insensitive matching using ASCII folding. Default: `false`.
        ///   - dotfiles: Dotfile matching behavior. Default: `.explicit`.
        ///   - followSymlinks: Follow symlinks during traversal. Default: `false`.
        ///   - maxDepth: Maximum recursion depth. Default: `nil` (unlimited).
        ///   - ordering: Result ordering. Default: `.deterministic`.
        ///   - onError: Error handling policy. Default: `.fail`.
        public init(
            caseInsensitive: Bool = false,
            dotfiles: Dotfile = .explicit,
            followSymlinks: Bool = false,
            maxDepth: Int? = nil,
            ordering: Ordering = .deterministic,
            onError: Error.Policy = .fail
        ) {
            self.caseInsensitive = caseInsensitive
            self.dotfiles = dotfiles
            self.followSymlinks = followSymlinks
            self.maxDepth = maxDepth
            self.ordering = ordering
            self.onError = onError
        }
    }
}

