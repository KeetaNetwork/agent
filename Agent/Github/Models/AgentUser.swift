import Foundation

struct AgentUser: Codable {
    let githubUser: GithubUser
    let gpgKey: GPGKey
    let sshKey: SSHKey
}
