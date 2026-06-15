import Foundation

// MARK: - Match

struct MatchPosition: Equatable, Sendable {
    let line: Int
    let startColumn: Int
    let endColumn: Int
}

// MARK: - TextBuffer search

extension TextBuffer {
    func search(for term: String, caseSensitive: Bool) -> [MatchPosition] {
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
