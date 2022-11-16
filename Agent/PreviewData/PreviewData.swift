import Foundation

#if DEBUG
extension GithubUser {
    static let preview = Self(username: "User", avatarUrl: "")
}

extension GPGKey {
    static func preview(isUploaded: Bool = true) -> Self {
        .init(id: "GPG_ID", value: "GPG_PREVIEW", fullName: "User", email: "user@keeta.com", isUploaded: isUploaded)
    }
}

extension SSHKey {
    static func preview(isUploaded: Bool = true) -> Self {
        .init(value: "SSH_PREVIEW", isUploaded: isUploaded)
    }
}
#endif
