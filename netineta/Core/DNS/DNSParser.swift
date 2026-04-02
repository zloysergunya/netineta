import Foundation

enum DNSError: Error, Sendable {
    case invalidDomain
    case queryBuildFailed
    case responseTooShort
    case responseError(rcode: UInt8)
    case noAnswers
    case timeout
    case connectionFailed
}

struct DNSParser: Sendable {

    static func buildQuery(domain: String, id: UInt16 = UInt16.random(in: 0...UInt16.max)) -> Data? {
        var data = Data()

        // Header: ID (2) + Flags (2) + QDCOUNT (2) + ANCOUNT (2) + NSCOUNT (2) + ARCOUNT (2)
        data.append(UInt8(id >> 8))
        data.append(UInt8(id & 0xFF))
        // Flags: standard query, recursion desired
        data.append(0x01)
        data.append(0x00)
        // QDCOUNT = 1
        data.append(0x00)
        data.append(0x01)
        // ANCOUNT = 0
        data.append(0x00)
        data.append(0x00)
        // NSCOUNT = 0
        data.append(0x00)
        data.append(0x00)
        // ARCOUNT = 0
        data.append(0x00)
        data.append(0x00)

        // QNAME
        let labels = domain.split(separator: ".")
        for label in labels {
            guard let labelData = label.data(using: .ascii), labelData.count < 64 else {
                return nil
            }
            data.append(UInt8(labelData.count))
            data.append(labelData)
        }
        data.append(0x00) // root label

        // QTYPE = A (1)
        data.append(0x00)
        data.append(0x01)
        // QCLASS = IN (1)
        data.append(0x00)
        data.append(0x01)

        return data
    }

    struct DNSResponse: Sendable {
        let id: UInt16
        let rcode: UInt8
        let addresses: [String]
    }

    static func parseResponse(_ data: Data) throws -> DNSResponse {
        guard data.count >= 12 else {
            throw DNSError.responseTooShort
        }

        let bytes = [UInt8](data)
        let id = UInt16(bytes[0]) << 8 | UInt16(bytes[1])
        let rcode = bytes[3] & 0x0F
        let ancount = Int(bytes[6]) << 8 | Int(bytes[7])

        if rcode != 0 {
            throw DNSError.responseError(rcode: rcode)
        }

        // Skip header (12 bytes) and question section
        var offset = 12
        // Skip QNAME
        offset = skipName(bytes: bytes, offset: offset)
        // Skip QTYPE (2) + QCLASS (2)
        offset += 4

        var addresses: [String] = []

        for _ in 0..<ancount {
            guard offset < bytes.count else { break }

            // Skip NAME (could be pointer)
            offset = skipName(bytes: bytes, offset: offset)

            guard offset + 10 <= bytes.count else { break }

            let rtype = Int(bytes[offset]) << 8 | Int(bytes[offset + 1])
            // let rclass = Int(bytes[offset + 2]) << 8 | Int(bytes[offset + 3])
            // let ttl = ... (4 bytes)
            let rdlength = Int(bytes[offset + 8]) << 8 | Int(bytes[offset + 9])
            offset += 10

            if rtype == 1 && rdlength == 4 && offset + 4 <= bytes.count {
                // A record
                let ip = "\(bytes[offset]).\(bytes[offset + 1]).\(bytes[offset + 2]).\(bytes[offset + 3])"
                addresses.append(ip)
            }

            offset += rdlength
        }

        return DNSResponse(id: id, rcode: rcode, addresses: addresses)
    }

    private static func skipName(bytes: [UInt8], offset: Int) -> Int {
        var pos = offset
        while pos < bytes.count {
            let len = bytes[pos]
            if len == 0 {
                return pos + 1
            }
            if len & 0xC0 == 0xC0 {
                // Pointer — 2 bytes
                return pos + 2
            }
            pos += Int(len) + 1
        }
        return pos
    }
}
