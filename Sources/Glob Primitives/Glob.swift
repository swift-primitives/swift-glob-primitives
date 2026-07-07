// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-glob-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-glob-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

// Item 3.5 Option B relocation cycle (2026-05-02): top-level `Glob` namespace
// anchor at L1 — relocated from L2 swift-iso-9945's `ISO_9945.Kernel.Glob`
// per principal Q3 disposition (top-level shape, NOT `Kernel.Glob.*` prefix —
// Glob is paradigm-agnostic pattern-matching vocabulary, not OS-syscall
// vocabulary). Per Q4, package name is `swift-glob-primitives` matching the
// established `swift-X-primitives` convention.

public import ASCII_Primitives

/// Glob pattern matching primitives.
///
/// Defines the canonical contract for glob pattern matching across platforms.
/// Platform packages (POSIX, Windows) provide implementations.
///
/// ## Canonical Grammar
///
/// - `*` matches any sequence of characters (except path separator)
/// - `**` matches zero or more path segments (recursive)
/// - `?` matches any single Unicode scalar
/// - `[abc]` matches any scalar in the set
/// - `[!abc]` or `[^abc]` matches any scalar not in the set
///
/// ## Not Supported
///
/// Brace expansion `{a,b,c}` is shell policy, not glob core.
/// Pre-expand patterns at a higher layer if needed.
public enum Glob {}

extension Glob {
    /// Returns true if the string contains glob metacharacters.
    ///
    /// Checks for: `*`, `?`, `[`, `\`
    /// Use this to determine whether a string needs glob processing.
    ///
    /// - Parameter string: The string to check.
    /// - Returns: `true` if the string contains glob metacharacters.
    @inlinable
    public static func isPattern(_ string: Swift.String) -> Bool {
        for byte in string.utf8 {
            switch byte {
            case ASCII.Character.Graphic.asterisk,  // *
                ASCII.Character.Graphic.questionMark,  // ?
                ASCII.Character.Graphic.leftBracket,  // [
                ASCII.Character.Graphic.reverseSlant:  // \
                return true

            default:
                continue
            }
        }
        return false
    }
}
