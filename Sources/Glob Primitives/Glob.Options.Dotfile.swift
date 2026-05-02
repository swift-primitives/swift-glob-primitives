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


extension Glob.Options {
    /// Dotfile (hidden file) matching behavior.
    ///
    /// **Normative semantics:**
    /// - A "dotfile" is any filename whose first character is `.` (0x2E).
    /// - Detection uses `ASCII.Character.Graphic.period` from swift-ascii.
    public enum Dotfile: Sendable, Hashable {
        /// `*` matches `.foo` only if segment explicitly starts with `.`
        ///
        /// Under this policy:
        /// - `*` and `?` at segment start do NOT match a leading `.`
        /// - Pattern `.*` explicitly matches dotfiles at that segment
        /// - `**` does NOT traverse into dot-directories unless an explicit
        ///   `.`-prefixed segment follows (e.g., `**/.git` matches `.git` dirs)
        case explicit

        /// Always include dotfiles; `*` matches `.foo`
        case always

        /// Never include dotfiles regardless of pattern
        case never
    }
}

