import Foundation

protocol SecretStore: ObservableObject, Identifiable {
    var secrets: [Secret] { get }
    func sign(data: Data, with secret: Secret, for processName: String?, isRaw: Bool) throws -> Data
}
