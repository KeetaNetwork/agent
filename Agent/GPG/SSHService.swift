import Foundation
import Combine
import OSLog

final class SSHService {
    
    private let logger = Logger()
    private let fileManager = FileManager.default
    private var secretsSubscription: AnyCancellable?
    private let directory: String
    private let keyWriter = OpenSSHKeyWriter()

    init(homeDirectory: String, secrets: AnyPublisher<[Secret], Never>) {
        directory = homeDirectory.appending("/PublicKeys")
        
        secretsSubscription = secrets
            .removeDuplicates { $0.map { $0.id } == $1.map { $0.id } }
            .sink(receiveValue: generatePublicKeys(for:))
    }
    
    func setup() {
        try? fileManager.createDirectory(at: URL(fileURLWithPath: directory), withIntermediateDirectories: false)
    }
    
    private func generatePublicKeys(for secrets: [Secret]) {
        logger.log("Writing public keys to disk if needed")
        
        for secret in secrets {
            let path = path(for: secret)
            
            if fileManager.fileExists(atPath: path) { continue }
            
            if let data = keyWriter.openSSHString(secret: secret).data(using: .utf8) {
                fileManager.createFile(atPath: path, contents: data)
                logger.log("Write new public key to path: \(path)")
            }
        }
    }

    private func path(for secret: Secret) -> String {
        let filename = secret.publicKey.base64EncodedString().hash
        return directory.appending("/").appending("\(filename).pub")
    }
}
