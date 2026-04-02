import Foundation
import Network

actor DNSResolver {

    static let shared = DNSResolver()

    struct ResolveResult: Sendable {
        let server: String
        let addresses: [String]
        let isNXDomain: Bool
    }

    func resolve(domain: String, server: String, timeout: TimeInterval = 5) async throws -> ResolveResult {
        guard let queryData = DNSParser.buildQuery(domain: domain) else {
            throw DNSError.invalidDomain
        }

        let host = NWEndpoint.Host(server)
        let port = NWEndpoint.Port(integerLiteral: 53)
        let connection = NWConnection(host: host, port: port, using: .udp)

        return try await withCheckedThrowingContinuation { continuation in
            var resumed = false
            let lock = NSLock()

            func resumeOnce(with result: Result<ResolveResult, Error>) {
                lock.lock()
                defer { lock.unlock() }
                guard !resumed else { return }
                resumed = true
                continuation.resume(with: result)
            }

            // Timeout
            let deadline = DispatchTime.now() + timeout
            DispatchQueue.global().asyncAfter(deadline: deadline) {
                connection.cancel()
                resumeOnce(with: .failure(DNSError.timeout))
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.send(content: queryData, completion: .contentProcessed { error in
                        if let error {
                            connection.cancel()
                            resumeOnce(with: .failure(error))
                            return
                        }

                        connection.receiveMessage { content, _, _, error in
                            defer { connection.cancel() }

                            if let error {
                                resumeOnce(with: .failure(error))
                                return
                            }

                            guard let content else {
                                resumeOnce(with: .failure(DNSError.noAnswers))
                                return
                            }

                            do {
                                let response = try DNSParser.parseResponse(content)
                                let result = ResolveResult(
                                    server: server,
                                    addresses: response.addresses,
                                    isNXDomain: false
                                )
                                resumeOnce(with: .success(result))
                            } catch let error as DNSError {
                                if case .responseError(let rcode) = error, rcode == 3 {
                                    // NXDOMAIN
                                    resumeOnce(with: .success(ResolveResult(
                                        server: server,
                                        addresses: [],
                                        isNXDomain: true
                                    )))
                                } else {
                                    resumeOnce(with: .failure(error))
                                }
                            } catch {
                                resumeOnce(with: .failure(error))
                            }
                        }
                    })

                case .failed(let error):
                    connection.cancel()
                    resumeOnce(with: .failure(error))

                case .cancelled:
                    resumeOnce(with: .failure(DNSError.connectionFailed))

                default:
                    break
                }
            }

            connection.start(queue: .global())
        }
    }
}
