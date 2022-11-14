import Foundation
import CryptoKit
import OSLog

class SSHAgent {
    
    enum AgentError: Error {
        case unhandledType
        case noMatchingKey
        case unsupportedKeyType
    }
    
    private let store: SecureEnclaveStore
    private let writer = OpenSSHKeyWriter()
    private var consumedData = Data()
    private var expectedSize = 0
    
    init(store: SecureEnclaveStore) {
        self.store = store
    }
    
    /// Handles an incoming request.
    /// - Parameters:
    ///   - reader: A ``FileHandleReader`` to read the content of the request.
    ///   - writer: A ``FileHandleWriter`` to write the response to.
    /// - Return value:
    ///   - Boolean if data could be read
    @discardableResult public func handle(reader: FileHandleReader, writer: FileHandleWriter) -> Bool {
        Logger().debug("Agent handling new data")
        
        let sizeLength = 4
        
        let newData = reader.availableData
        guard !newData.isEmpty else { return false }
        consumedData.append(newData)
        
        if expectedSize == 0 {
            guard consumedData.count >= sizeLength else { return true }
            let sizeData = consumedData.extractFirst(sizeLength)
            let size = sizeData.length
            expectedSize = Int(size)
        }
        
        guard consumedData.count >= expectedSize else { return true }
        
        var payload = consumedData.extractFirst(expectedSize)
        
        let requestTypeInt = payload.extractFirst()
        
        guard let requestType = SSHAgent.RequestType(rawValue: requestTypeInt) else {
            writer.write(OpenSSHKeyWriter().lengthAndData(of: SSHAgent.ResponseType.agentFailure.data))
            Logger().debug("Agent returned \(SSHAgent.ResponseType.agentFailure.debugDescription)")
            consumedData = Data()
            expectedSize = 0
            return true
        }
        
        Logger().debug("Agent handling request of type \(requestType.debugDescription)")
        let response = handle(requestType: requestType, data: payload, reader: reader)
        writer.write(response)
        
        expectedSize = 0
        
        return true
    }

    // MARK: Private
    
    private func handle(requestType: SSHAgent.RequestType, data: Data, reader: FileHandleReader) -> Data {
        var response = Data()
        do {
            switch requestType {
            case .requestIdentities:
                response.append(SSHAgent.ResponseType.agentIdentitiesAnswer.data)
                response.append(identities())
                Logger().debug("Agent returned \(SSHAgent.ResponseType.agentIdentitiesAnswer.debugDescription)")
            case .signRequest:
                response.append(SSHAgent.ResponseType.agentSignResponse.data)
                response.append(try sign(data: data, processName: SigningRequestTracer.processName(from: reader)))
                Logger().debug("Agent returned \(SSHAgent.ResponseType.agentSignResponse.debugDescription)")
            }
        } catch {
            response.removeAll()
            response.append(SSHAgent.ResponseType.agentFailure.data)
            Logger().debug("Agent returned \(SSHAgent.ResponseType.agentFailure.debugDescription)")
        }
        let full = OpenSSHKeyWriter().lengthAndData(of: response)
        return full
    }
    
    // Lists the identities available for signing operations
    /// - Returns: An OpenSSH formatted Data payload listing the identities available for signing operations.
    private func identities() -> Data {
        let secrets = store.secrets
        var count = UInt32(secrets.count).bigEndian
        let countData = Data(bytes: &count, count: UInt32.bitWidth/8)
        var keyData = Data()
        let writer = OpenSSHKeyWriter()
        for secret in secrets {
            let keyBlob = writer.data(secret: secret)
            keyData.append(writer.lengthAndData(of: keyBlob))
            let curveData = writer.curveType(for: secret.algorithm, length: secret.keySize).data(using: .utf8)!
            keyData.append(writer.lengthAndData(of: curveData))
        }
        Logger().debug("Agent enumerated \(secrets.count) identities")
        return countData + keyData
    }
    
    /// Notifies witnesses of a pending signature request, and performs the signing operation if none object.
    /// - Parameters:
    ///   - data: The data to sign.
    /// - Returns: An OpenSSH formatted Data payload containing the signed data response.
    private func sign(data: Data, processName: String) throws -> Data {
        let reader = OpenSSHReader(data: data)
        let hash = reader.readNextChunk()
        guard let secret = secret(matching: hash) else {
            Logger().debug("Agent did not have a key matching \(hash as NSData)")
            throw AgentError.noMatchingKey
        }

//        if let witness = witness {
//            try witness.speakNowOrForeverHoldYourPeace(forAccessTo: secret, from: store, by: provenance)
//        }

        let dataToSign = reader.readNextChunk()
        let flags = reader.readNextInt()
        let signed = try store.sign(data: dataToSign, with: secret, for: processName, isRaw: flags == 0x40000000)
        let derSignature = signed

        let curveData = writer.curveType(for: secret.algorithm, length: secret.keySize).data(using: .utf8)!

        // Convert from DER formatted rep to raw (r||s)

        let rawRepresentation: Data
        switch (secret.algorithm, secret.keySize) {
        case (.ellipticCurve, 256):
            rawRepresentation = try CryptoKit.P256.Signing.ECDSASignature(derRepresentation: derSignature).rawRepresentation
        case (.ellipticCurve, 384):
            rawRepresentation = try CryptoKit.P384.Signing.ECDSASignature(derRepresentation: derSignature).rawRepresentation
        default:
            throw AgentError.unsupportedKeyType
        }

        let rawLength = rawRepresentation.count/2
        // Check if we need to pad with 0x00 to prevent certain
        // ssh servers from thinking r or s is negative
        let paddingRange: ClosedRange<UInt8> = 0x80...0xFF
        var r = Data(rawRepresentation[0..<rawLength])
        if paddingRange ~= r.first! {
            r.insert(0x00, at: 0)
        }
        var s = Data(rawRepresentation[rawLength...])
        if paddingRange ~= s.first! {
            s.insert(0x00, at: 0)
        }

        var signatureChunk = Data()
        signatureChunk.append(writer.lengthAndData(of: r))
        signatureChunk.append(writer.lengthAndData(of: s))

        var signedData = Data()
        var sub = Data()
        sub.append(writer.lengthAndData(of: curveData))
        sub.append(writer.lengthAndData(of: signatureChunk))
        signedData.append(writer.lengthAndData(of: sub))

//        if let witness = witness {
//            try witness.witness(accessTo: secret, from: store, by: provenance)
//        }

        Logger().debug("Agent signed request")

        return signedData
    }
    
    private func secret(matching hash: Data) -> Secret? {
        store.secrets.first { secret in
            hash == writer.data(secret: secret)
        }
    }
}
