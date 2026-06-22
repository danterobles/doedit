import Foundation

// MARK: - Match

public struct MatchPosition: Equatable, Sendable {
    public let line: Int
    public let startColumn: Int
    public let endColumn: Int

    public init(line: Int, startColumn: Int, endColumn: Int) {
        self.line = line
        self.startColumn = startColumn
        self.endColumn = endColumn
    }
}

// MARK: - TextBuffer search

extension TextBuffer {
    public func search(for term: String, caseSensitive: Bool) -> [MatchPosition] {
        guard !term.isEmpty else { return [] }
        var matches: [MatchPosition] = []

        for (lineIdx, line) in lines.enumerated() {
            let haystack = caseSensitive ? line : line.lowercased()
            let needle = caseSensitive ? term : term.lowercased()
            var searchFrom = haystack.startIndex

            while searchFrom < haystack.endIndex {
                guard let range = haystack.range(of: needle, range: searchFrom..<haystack.endIndex) else { break }
                let col = haystack.distance(from: haystack.startIndex, to: range.lowerBound)
                let endCol = haystack.distance(from: haystack.startIndex, to: range.upperBound)
                matches.append(MatchPosition(line: lineIdx, startColumn: col, endColumn: endCol))
                // Avoid infinite loop on empty match
                searchFrom = range.upperBound > range.lowerBound ? range.upperBound : haystack.index(after: range.upperBound)
            }
        }

        return matches
    }
}
