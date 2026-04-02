import Foundation

extension String {

    var normalizedDomain: String {
        var domain = self
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        // Remove protocol
        if let range = domain.range(of: "://") {
            domain = String(domain[range.upperBound...])
        }

        // Remove www.
        if domain.hasPrefix("www.") {
            domain = String(domain.dropFirst(4))
        }

        // Remove path
        if let slashIndex = domain.firstIndex(of: "/") {
            domain = String(domain[..<slashIndex])
        }

        // Remove port
        if let colonIndex = domain.firstIndex(of: ":") {
            domain = String(domain[..<colonIndex])
        }

        // Remove trailing dot
        if domain.hasSuffix(".") {
            domain = String(domain.dropLast())
        }

        return domain
    }

    var isValidDomain: Bool {
        let domain = normalizedDomain
        guard !domain.isEmpty else { return false }

        let parts = domain.split(separator: ".")
        guard parts.count >= 2 else { return false }

        let validCharSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))

        for part in parts {
            if part.isEmpty || part.count > 63 { return false }
            if part.hasPrefix("-") || part.hasSuffix("-") { return false }
            if !part.unicodeScalars.allSatisfy({ validCharSet.contains($0) }) { return false }
        }

        return true
    }
}
