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

import Testing

@testable import Glob_Primitives

extension Glob.Pattern {
    @Suite struct Tests {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}
    }
}

extension Glob.Pattern.Tests.Unit {
    @Test
    func `literal pattern has one literal segment`() throws {
        let pattern = try Glob.Pattern("file.txt")
        #expect(pattern.raw == "file.txt")
        #expect(pattern.segments.count == 1)
        #expect(pattern.isRecursive == false)
    }

    @Test
    func `single star wildcard parses as pattern segment`() throws {
        let pattern = try Glob.Pattern("*.swift")
        #expect(pattern.segments.count == 1)
        #expect(pattern.isRecursive == false)
    }

    @Test
    func `double star marks pattern as recursive`() throws {
        let pattern = try Glob.Pattern("**/*.txt")
        #expect(pattern.isRecursive == true)
    }

    @Test
    func `multi-segment pattern splits on path separator`() throws {
        let pattern = try Glob.Pattern("Sources/*/Tests")
        #expect(pattern.segments.count == 3)
    }
}

extension Glob.Pattern.Tests.`Edge Case` {
    @Test
    func `empty pattern parses to a single empty literal segment`() throws {
        let pattern = try Glob.Pattern("")
        #expect(pattern.raw.isEmpty)
    }

    @Test
    func `unterminated bracket class throws Glob.Error`() {
        #expect(throws: Glob.Error.self) {
            _ = try Glob.Pattern("[abc")
        }
    }
}

extension Glob.Pattern.Tests.Integration {
    @Test
    func `Glob.isPattern detects metacharacters`() {
        #expect(Glob.isPattern("*.txt") == true)
        #expect(Glob.isPattern("file?.txt") == true)
        #expect(Glob.isPattern("[abc].txt") == true)
        #expect(Glob.isPattern("plain-file.txt") == false)
    }

    @Test
    func `equal patterns compare equal and hash equal`() throws {
        let a = try Glob.Pattern("*.swift")
        let b = try Glob.Pattern("*.swift")
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }
}
